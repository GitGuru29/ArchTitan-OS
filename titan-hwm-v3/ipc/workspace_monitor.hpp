// =============================================================================
// titan-hwm-v3/ipc/workspace_monitor.hpp
// Phase 8 — Workspace Transition Engine + Hardware Policy
//
// Monitors Hyprland IPC for workspace/window events.
// Feeds WorkspaceState changes into the policy tick loop.
// Also computes the CPU governor policy from aggregate system demand.
// =============================================================================
#pragma once

#include "../core/types.hpp"

#include <functional>
#include <string>
#include <unordered_map>
#include <mutex>
#include <atomic>
#include <thread>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// GovernorPolicy — what the CPU governor should be set to
// Derived from aggregate demand across ALL workspaces + latency requirements,
// NOT from the type of the focused workspace (user-approved correction).
// ─────────────────────────────────────────────────────────────────────────────
enum class GovernorHint {
    POWERSAVE,      // all idle, no builds, no active user input
    SCHEDUTIL,      // default — let kernel autoscale
    PERFORMANCE,    // any build executing OR latency-sensitive workload active
};

// Callback type for workspace events
using WorkspaceCallback = std::function<void(int workspace_id, bool is_focused)>;
using WindowCallback    = std::function<void(int workspace_id,
                                              const std::string& window_class,
                                              const std::string& window_title)>;

// ─────────────────────────────────────────────────────────────────────────────
// WorkspaceMonitor — Hyprland IPC socket listener
// ─────────────────────────────────────────────────────────────────────────────
class WorkspaceMonitor {
public:
    // Set callbacks before calling start()
    void on_workspace_change(WorkspaceCallback cb)  { ws_cb_  = std::move(cb); }
    void on_window_change(WindowCallback cb)        { win_cb_ = std::move(cb); }

    // Start the IPC listener thread. Non-blocking; runs in background.
    //
    // The thread owns Hyprland socket discovery AND reconnection: if the
    // compositor is not up yet (THM is a system service that can start before
    // the SDDM autologin session creates Hyprland's socket), or if it exits or
    // restarts later, the thread keeps retrying until stop(). It therefore
    // returns true whenever the thread was launched, regardless of whether a
    // Hyprland instance exists yet; use connected() to query the live state.
    bool start();

    // True while the listener holds an open connection to a Hyprland socket.
    bool connected() const { return connected_.load(); }

    // Stop the listener thread (call from destructor or shutdown).
    void stop();

    // ── State queries ────────────────────────────────────────────────────────
    int  focused_workspace() const { return focused_ws_.load(); }

    // Get current WorkspaceState map (thread-safe snapshot)
    std::unordered_map<int, WorkspaceState> snapshot_workspaces() const;

    // Update visibility info from hyprctl workspaces (called during tick)
    void refresh_visibility();

    // ── Governor hint ────────────────────────────────────────────────────────
    // Compute from aggregate system demand. Called each tick.
    // `current` is the hint currently applied; it selects the hysteresis band so
    // the governor cannot flap when demand and pressure sit on a boundary.
    static GovernorHint compute_governor(
        const std::unordered_map<uint32_t, Workload>& workloads,
        PressureLevel pressure,
        GovernorHint current = GovernorHint::SCHEDUTIL);

    // Apply governor hint to /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
    static bool apply_governor(GovernorHint hint);

    ~WorkspaceMonitor() { stop(); }

private:
    WorkspaceCallback ws_cb_;
    WindowCallback    win_cb_;

    std::atomic<int>  focused_ws_{1};
    std::atomic<bool> running_{false};
    std::atomic<bool> connected_{false};
    std::thread       listener_thread_;

    mutable std::mutex ws_mtx_;
    std::unordered_map<int, WorkspaceState> workspaces_;

    // Resolved Hyprland IPC endpoint (re-discovered on every connect attempt).
    // The daemon runs as a root system service, so the session's
    // XDG_RUNTIME_DIR / HYPRLAND_INSTANCE_SIGNATURE are usually absent; we
    // discover the active instance under /run/user/<uid>/hypr/<instance>/.
    //
    // Written by the listener thread, read by refresh_visibility() on the tick
    // thread — always access under conn_mtx_.
    mutable std::mutex conn_mtx_;
    std::string hypr_runtime_dir_;
    std::string hypr_instance_sig_;

    // IPC socket path discovery. Returns "" if no live instance is found and,
    // on success, publishes the runtime dir / signature under conn_mtx_.
    std::string discover_socket_path();

    // Thread entry: discover → connect → stream, retrying until stop().
    void listen_loop();

    // Connect to `path` and stream events until the peer closes or stop().
    // Returns true if a connection was established (even if later lost).
    bool listen_once(const std::string& path);

    // Sleep up to `ms`, waking early (<=100ms latency) once stop() is called.
    void sleep_while_running(int ms);

    // Parse Hyprland IPC event lines
    void handle_event(const std::string& line);
};

} // namespace thm
