// =============================================================================
// titan-hwm-v3/ipc/workspace_monitor.cpp
// Phase 8 — implementation
// =============================================================================
#include "workspace_monitor.hpp"

#include <fstream>
#include <iostream>
#include <sstream>
#include <filesystem>
#include <cstring>
#include <cstdlib>
#include <unistd.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>

namespace fs = std::filesystem;

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// Hyprland IPC socket discovery.
//
// Preference order:
//   1. $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock
//      (explicit; works when THM is installed as a user-session service)
//   2. Scan /run/user/<uid>/hypr/<instance>/.socket2.sock and pick the most
//      recently active instance. The unit runs as root (getuid()==0), so we
//      must NOT derive the UID from getuid() — we scan every user instead.
// ─────────────────────────────────────────────────────────────────────────────
std::string WorkspaceMonitor::discover_socket_path() {
    // 1) Explicit session environment.
    const char* xdg = std::getenv("XDG_RUNTIME_DIR");
    const char* sig = std::getenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (xdg && sig) {
        std::string p = std::string(xdg) + "/hypr/" + sig + "/.socket2.sock";
        std::error_code ec;
        if (fs::exists(p, ec)) {
            hypr_runtime_dir_  = xdg;
            hypr_instance_sig_ = sig;
            return p;
        }
    }

    // 2) Discover the active instance under /run/user/<uid>/hypr/<instance>/.
    std::string best;
    fs::file_time_type best_time{};
    std::error_code ec;
    for (const auto& userdir : fs::directory_iterator("/run/user", ec)) {
        if (!userdir.is_directory())
            continue;
        fs::path hypr = userdir.path() / "hypr";
        std::error_code ec2;
        if (!fs::is_directory(hypr, ec2))
            continue;
        for (const auto& inst : fs::directory_iterator(hypr, ec2)) {
            if (!inst.is_directory())
                continue;
            fs::path sock = inst.path() / ".socket2.sock";
            std::error_code ec3;
            if (!fs::exists(sock, ec3))
                continue;
            auto t = fs::last_write_time(sock, ec3);
            if (ec3)
                t = fs::file_time_type{};
            if (best.empty() || t > best_time) {
                best               = sock.string();
                best_time          = t;
                hypr_runtime_dir_  = userdir.path().string();
                hypr_instance_sig_ = inst.path().filename().string();
            }
        }
    }
    if (!best.empty())
        std::cerr << "[WS] Discovered Hyprland instance: " << best << "\n";
    return best;
}

// ─────────────────────────────────────────────────────────────────────────────
// start / stop
// ─────────────────────────────────────────────────────────────────────────────
bool WorkspaceMonitor::start() {
    // The listener thread always starts. When the compositor is not up yet
    // (very common at boot: titan-hwm.service is pulled in by graphical.target
    // and may win the race against Hyprland), discover_socket_path() returns
    // empty and the thread retries with exponential backoff until the session
    // appears — no daemon restart required.
    sock_path_ = discover_socket_path();
    running_ = true;
    listener_thread_ = std::thread(&WorkspaceMonitor::listen_loop, this);

    if (sock_path_.empty())
        std::cerr << "[WS] No Hyprland instance yet — will retry in background.\n";
    else
        std::cout << "[WS] Listener started for " << sock_path_ << "\n";
    return true;
}

void WorkspaceMonitor::stop() {
    running_ = false;
    if (listener_thread_.joinable())
        listener_thread_.join();
    connected_ = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// listen_loop — blocking read from Hyprland socket2 (event stream)
// ─────────────────────────────────────────────────────────────────────────────
void WorkspaceMonitor::listen_loop() {
    // Reconnect/backoff loop. The compositor may not exist yet at boot, may
    // restart during the session, or may live at a different instance path
    // after a restart — so the socket is re-discovered on every attempt.
    int backoff_ms = 1000;
    const int backoff_max_ms = 30000;

    while (running_) {
        if (sock_path_.empty() || !fs::exists(sock_path_)) {
            sock_path_ = discover_socket_path();
        }
        if (sock_path_.empty()) {
            connected_ = false;
            for (int slept = 0; slept < backoff_ms && running_; slept += 250)
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
            backoff_ms = std::min(backoff_ms * 2, backoff_max_ms);
            continue;
        }

        int fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if (fd < 0) {
            std::cerr << "[WS] socket() failed: " << std::strerror(errno) << "\n";
            return;
        }

        struct sockaddr_un addr{};
        addr.sun_family = AF_UNIX;
        std::strncpy(addr.sun_path, sock_path_.c_str(), sizeof(addr.sun_path) - 1);

        if (connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
            std::cerr << "[WS] connect(" << sock_path_ << ") failed: "
                      << std::strerror(errno) << " — retrying in "
                      << (backoff_ms / 1000) << "s\n";
            close(fd);
            connected_ = false;
            for (int slept = 0; slept < backoff_ms && running_; slept += 250)
                std::this_thread::sleep_for(std::chrono::milliseconds(250));
            backoff_ms = std::min(backoff_ms * 2, backoff_max_ms);
            sock_path_.clear(); // re-discover on the next attempt
            continue;
        }

        connected_  = true;
        backoff_ms  = 1000;
        std::cout << "[WS] Connected to Hyprland event socket " << sock_path_ << "\n";

        char buf[4096];
        std::string leftover;

        while (running_) {
            // Poll with a bounded timeout instead of a blocking read(). A blocking
            // read() would leave this thread stuck when stop() flips running_=false,
            // making join() hang forever and preventing clean daemon shutdown.
            struct pollfd pfd{};
            pfd.fd = fd;
            pfd.events = POLLIN;

            int pr = ::poll(&pfd, 1, 500 /* ms */);
            if (pr < 0) {
                if (errno == EINTR) continue;
                break;
            }
            if (pr == 0)
                continue; // timeout — re-check running_
            if (!(pfd.revents & POLLIN))
                break;

            ssize_t n = read(fd, buf, sizeof(buf) - 1);
            if (n <= 0) {
                if (n < 0 && errno == EINTR) continue;
                break;
            }
            buf[n] = '\0';
            leftover += buf;

            // Split on newlines (Hyprland events are newline-delimited)
            size_t pos;
            while ((pos = leftover.find('\n')) != std::string::npos) {
                std::string line = leftover.substr(0, pos);
                leftover = leftover.substr(pos + 1);
                if (!line.empty()) handle_event(line);
            }
        }

        close(fd);
        connected_ = false;
        if (running_) {
            std::cerr << "[WS] Hyprland connection lost — reconnecting.\n";
            sock_path_.clear();
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// handle_event — parse Hyprland IPC event lines
//
// Events we care about:
//   workspace>>N         — user switched to workspace N
//   activewindowv2>>ADDR — active window changed
//   activewindow>>CLASS,TITLE — active window class + title
// ─────────────────────────────────────────────────────────────────────────────
void WorkspaceMonitor::handle_event(const std::string& line) {
    auto split = line.find(">>");
    if (split == std::string::npos) return;

    std::string event   = line.substr(0, split);
    std::string payload = line.substr(split + 2);

    if (event == "workspace") {
        int ws_id = 0;
        try { ws_id = std::stoi(payload); } catch (...) { return; }

        int prev = focused_ws_.exchange(ws_id);

        {
            std::lock_guard<std::mutex> lk(ws_mtx_);
            // Mark previous workspace as unfocused
            if (workspaces_.count(prev))
                workspaces_[prev].is_focused = false;
            // Mark new workspace as focused
            workspaces_[ws_id].id = ws_id;
            workspaces_[ws_id].is_focused = true;
        }

        if (ws_cb_) ws_cb_(ws_id, true);
    }
    else if (event == "activewindow") {
        // Format: CLASS,TITLE
        auto comma = payload.find(',');
        if (comma == std::string::npos) return;
        std::string cls   = payload.substr(0, comma);
        std::string title = payload.substr(comma + 1);

        int ws_id = focused_ws_.load();

        {
            std::lock_guard<std::mutex> lk(ws_mtx_);
            workspaces_[ws_id].active_window_class = cls;
            workspaces_[ws_id].active_window_title = title;
        }

        if (win_cb_) win_cb_(ws_id, cls, title);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// snapshot_workspaces — thread-safe copy of current state
// ─────────────────────────────────────────────────────────────────────────────
std::unordered_map<int, WorkspaceState> WorkspaceMonitor::snapshot_workspaces() const {
    std::lock_guard<std::mutex> lk(ws_mtx_);
    return workspaces_;
}

// ─────────────────────────────────────────────────────────────────────────────
// refresh_visibility — call hyprctl to update is_visible flags
// Needed because Hyprland IPC doesn't emit events for split/group visibility.
// ─────────────────────────────────────────────────────────────────────────────
void WorkspaceMonitor::refresh_visibility() {
    // Use hyprctl monitors to get visible workspaces on each monitor.
    // As a root system service we must inject the session env so hyprctl can
    // locate the compositor; otherwise it exits silently with no output.
    std::string cmd;
    if (!hypr_runtime_dir_.empty() && !hypr_instance_sig_.empty()) {
        cmd = "env XDG_RUNTIME_DIR=" + hypr_runtime_dir_ +
              " HYPRLAND_INSTANCE_SIGNATURE=" + hypr_instance_sig_ +
              " hyprctl monitors -j 2>/dev/null";
    } else {
        cmd = "hyprctl monitors -j 2>/dev/null";
    }
    FILE* pipe = popen(cmd.c_str(), "r");
    if (!pipe) return;

    char buf[8192];
    std::string json;
    while (fgets(buf, sizeof(buf), pipe))
        json += buf;
    pclose(pipe);

    // Simple JSON parsing for workspace IDs visible on monitors.
    // Format: "activeWorkspace": { "id": N, ... }
    // We don't bring in a JSON library — just grep for the pattern.
    std::lock_guard<std::mutex> lk(ws_mtx_);

    // Reset all visibility flags
    for (auto& [id, ws] : workspaces_)
        ws.is_visible = ws.is_focused; // focused is always visible

    // Find all "activeWorkspace":{"id":N patterns
    std::string key = "\"id\":";
    size_t pos = 0;
    while ((pos = json.find("\"activeWorkspace\"", pos)) != std::string::npos) {
        pos = json.find(key, pos);
        if (pos == std::string::npos) break;
        pos += key.size();
        // Skip whitespace
        while (pos < json.size() && (json[pos] == ' ' || json[pos] == '\t')) ++pos;
        int ws_id = 0;
        try { ws_id = std::stoi(json.substr(pos)); } catch (...) { continue; }
        workspaces_[ws_id].id = ws_id;
        workspaces_[ws_id].is_visible = true;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// compute_governor — aggregate system demand → governor hint
//
// Rules (from approved plan):
//   - ANY workload in BACKGROUND_EXECUTING + is_building → PERFORMANCE
//   - ANY workload in ACTIVE + latency_sensitive         → PERFORMANCE
//   - ALL idle + NORMAL pressure                         → POWERSAVE
//   - Otherwise                                          → SCHEDUTIL
//
// Pressure is authoritative over demand: at HIGH or CRITICAL the hint is capped
// at SCHEDUTIL, because PressureLevel::CRITICAL is documented (types.hpp) as
// "drop governor". Hysteresis is asymmetric — climbing to PERFORMANCE requires
// pressure below HIGH, holding it tolerates MODERATE — so a build running while
// pressure oscillates on the HIGH boundary cannot flap the governor every tick.
// ─────────────────────────────────────────────────────────────────────────────
GovernorHint WorkspaceMonitor::compute_governor(
        const std::unordered_map<uint32_t, Workload>& workloads,
        PressureLevel pressure,
        GovernorHint current) {

    bool any_building   = false;
    bool any_latency    = false;
    bool all_idle       = true;

    for (const auto& [id, wl] : workloads) {
        // Observation-only workloads must not influence power policy: they are
        // always present in large numbers and would pin the governor above
        // POWERSAVE even when nothing classified is running.
        if (wl.observed) continue;
        if (wl.state == WorkloadState::ACTIVE ||
            wl.state == WorkloadState::BACKGROUND_EXECUTING) {
            all_idle = false;
        }
        if (wl.state == WorkloadState::BACKGROUND_EXECUTING && wl.is_building)
            any_building = true;
        if (wl.state == WorkloadState::ACTIVE && wl.latency_sensitive)
            any_latency = true;
    }

    if (any_building || any_latency) {
        const bool may_hold_performance =
            (current == GovernorHint::PERFORMANCE)
                ? (pressure <= PressureLevel::MODERATE)
                : (pressure <  PressureLevel::HIGH);
        if (may_hold_performance) return GovernorHint::PERFORMANCE;
        return GovernorHint::SCHEDUTIL;
    }

    if (all_idle && pressure == PressureLevel::NORMAL) return GovernorHint::POWERSAVE;
    return GovernorHint::SCHEDUTIL;
}

// ─────────────────────────────────────────────────────────────────────────────
// apply_governor — write to all CPU scaling_governor files
// ─────────────────────────────────────────────────────────────────────────────
bool WorkspaceMonitor::apply_governor(GovernorHint hint) {
    const char* name = "schedutil";
    switch (hint) {
        case GovernorHint::POWERSAVE:   name = "powersave";   break;
        case GovernorHint::SCHEDUTIL:   name = "schedutil";   break;
        case GovernorHint::PERFORMANCE: name = "performance"; break;
    }

    bool ok = true;
    try {
        for (const auto& entry : fs::directory_iterator("/sys/devices/system/cpu")) {
            std::string gov_path = entry.path().string() + "/cpufreq/scaling_governor";
            if (!fs::exists(gov_path)) continue;
            std::ofstream f(gov_path);
            if (f.is_open()) {
                f << name;
                ok &= f.good();
            }
        }
    } catch (...) {
        std::cerr << "[Governor] Failed to enumerate CPUs\n";
        return false;
    }
    return ok;
}

} // namespace thm
