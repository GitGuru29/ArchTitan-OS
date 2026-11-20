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
#include <chrono>
#include <unistd.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>

namespace fs = std::filesystem;

namespace thm {

namespace {

long long now_steady_ms() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(steady_clock::now().time_since_epoch()).count();
}

std::vector<std::string> split_tokens(const std::string& s) {
    std::vector<std::string> out;
    std::istringstream ss(s);
    std::string tok;
    while (ss >> tok) out.push_back(tok);
    return out;
}

bool has_token(const std::vector<std::string>& toks, const char* name) {
    for (const auto& t : toks)
        if (t == name) return true;
    return false;
}

std::string read_first_line(const std::string& path) {
    std::ifstream f(path);
    std::string line;
    std::getline(f, line);
    while (!line.empty() && (line.back() == '\n' || line.back() == '\r' ||
                             line.back() == ' '  || line.back() == '\t'))
        line.pop_back();
    return line;
}

bool write_line(const std::string& path, const std::string& value) {
    std::ofstream f(path);
    if (!f.is_open()) return false;
    f << value;
    f.flush();
    const bool ok = f.good();
    f.close();
    return ok;
}

// Check /run/systemd/sessions/* for IDLE_HINT=1 or IDLE_HINT=yes
bool systemd_session_idle_hint() {
    std::error_code ec;
    for (const auto& entry : fs::directory_iterator("/run/systemd/sessions", ec)) {
        if (!entry.is_regular_file(ec)) continue;
        const std::string fname = entry.path().filename().string();
        if (fname.find(".ref") != std::string::npos) continue;
        std::ifstream f(entry.path());
        std::string line;
        while (std::getline(f, line)) {
            if (line == "IDLE_HINT=1" || line == "IDLE_HINT=yes")
                return true;
        }
    }
    return false;
}

} // namespace

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
            std::lock_guard<std::mutex> lk(conn_mtx_);
            hypr_runtime_dir_  = xdg;
            hypr_instance_sig_ = sig;
            return p;
        }
    }

    // 2) Discover the active instance under /run/user/<uid>/hypr/<instance>/.
    std::string best;
    std::string best_dir;
    std::string best_sig;
    fs::file_time_type best_time{};
    std::error_code ec;
    // THM_RUN_USER_DIR overrides the scan root (test seam; default /run/user).
    const char* root_env = std::getenv("THM_RUN_USER_DIR");
    const fs::path run_user = (root_env && *root_env) ? root_env : "/run/user";
    for (const auto& userdir : fs::directory_iterator(run_user, ec)) {
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
                best      = sock.string();
                best_time = t;
                best_dir  = userdir.path().string();
                best_sig  = inst.path().filename().string();
            }
        }
    }
    if (!best.empty()) {
        std::lock_guard<std::mutex> lk(conn_mtx_);
        hypr_runtime_dir_  = best_dir;
        hypr_instance_sig_ = best_sig;
    }
    return best;
}

// ─────────────────────────────────────────────────────────────────────────────
// start / stop / user presence
// ─────────────────────────────────────────────────────────────────────────────
void WorkspaceMonitor::mark_activity() {
    last_activity_ms_.store(now_steady_ms(), std::memory_order_relaxed);
}

long long WorkspaceMonitor::seconds_since_last_activity() const {
    const long long last = last_activity_ms_.load(std::memory_order_relaxed);
    if (last <= 0) return 0;
    const long long delta = now_steady_ms() - last;
    return delta > 0 ? (delta / 1000) : 0;
}

bool WorkspaceMonitor::user_unattended(long idle_threshold_s) const {
    if (systemd_session_idle_hint()) return true;
    // Conservative: if Hyprland IPC is disconnected, assume user is PRESENT
    // unless systemd explicitly reports idle hint above.
    if (!connected_.load(std::memory_order_relaxed)) return false;
    return seconds_since_last_activity() >= idle_threshold_s;
}

bool WorkspaceMonitor::start() {
    if (running_.exchange(true))
        return true; // already started
    mark_activity();
    listener_thread_ = std::thread(&WorkspaceMonitor::listen_loop, this);
    return true;
}

void WorkspaceMonitor::stop() {
    running_ = false;
    if (listener_thread_.joinable())
        listener_thread_.join();
    connected_ = false;
}

void WorkspaceMonitor::sleep_while_running(int ms) {
    // Chunked so stop() never waits more than ~100ms for the thread to notice.
    for (int waited = 0; waited < ms && running_; waited += 100)
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
}

// ─────────────────────────────────────────────────────────────────────────────
// listen_loop — discover → connect → stream, retrying for the daemon's lifetime.
//
// THM is a system service and can come up before the SDDM autologin session has
// created Hyprland's socket (the daemon used to look exactly once and then run
// "headless" forever). It must also survive Hyprland exiting or restarting.
// Failures are logged once per outage rather than on every retry.
// ─────────────────────────────────────────────────────────────────────────────
void WorkspaceMonitor::listen_loop() {
    constexpr int kRetryMs = 2000;
    bool announced_wait = false;

    while (running_) {
        const std::string path = discover_socket_path();
        if (path.empty()) {
            if (!announced_wait) {
                std::cerr << "[WS] No Hyprland instance yet — will keep retrying "
                             "(workspace monitoring pending).\n";
                announced_wait = true;
            }
            sleep_while_running(kRetryMs);
            continue;
        }

        if (listen_once(path)) {
            // Was connected; it dropped (compositor exited/restarted).
            if (running_)
                std::cerr << "[WS] Hyprland connection lost — reconnecting.\n";
            announced_wait = false;
        } else if (!announced_wait) {
            std::cerr << "[WS] Hyprland socket not accepting connections yet — "
                         "will keep retrying.\n";
            announced_wait = true;
        }
        sleep_while_running(kRetryMs);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// listen_once — one connection's lifetime: blocking read from socket2 (events)
// ─────────────────────────────────────────────────────────────────────────────
bool WorkspaceMonitor::listen_once(const std::string& path) {
    int fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        std::cerr << "[WS] socket() failed: " << std::strerror(errno) << "\n";
        return false;
    }

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, path.c_str(), sizeof(addr.sun_path) - 1);

    if (connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
        close(fd);
        return false;
    }

    connected_ = true;
    std::cout << "[WS] Listening on " << path << "\n";

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

    connected_ = false;
    close(fd);
    return true;
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

    if (event == "workspace" || event == "workspacev2" ||
        event == "focusedmon" || event == "activewindow" ||
        event == "activewindowv2" || event == "openwindow" ||
        event == "closewindow" || event == "movewindow" ||
        event == "fullscreen") {
        mark_activity();
    }

    if (event == "workspace") {
        int ws_id = 0;
        try { ws_id = std::stoi(payload); } catch (...) { return; }

        int prev = focused_ws_.exchange(ws_id);

        {
            std::lock_guard<std::mutex> lk(ws_mtx_);
            // Mark previous workspace as unfocused
            if (workspaces_.count(prev))
                workspaces_[prev].is_focused = false;
            // Mark new workspace as focused. Stamp the Hyprland event so the
            // v3.4 context layer can protect the recently-left workspace for
            // kRecentFocusWindowS after the user switches away.
            workspaces_[ws_id].id = ws_id;
            workspaces_[ws_id].is_focused = true;
            workspaces_[ws_id].last_focused = ms_clock::now();
            workspaces_[ws_id].last_user_activity = ms_clock::now();
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
    std::string rdir, isig;
    {
        // Snapshot: the listener thread may re-discover these concurrently.
        std::lock_guard<std::mutex> lk(conn_mtx_);
        rdir = hypr_runtime_dir_;
        isig = hypr_instance_sig_;
    }
    if (!rdir.empty() && !isig.empty()) {
        cmd = "env XDG_RUNTIME_DIR=" + rdir +
              " HYPRLAND_INSTANCE_SIGNATURE=" + isig +
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
        GovernorHint current,
        PressureLevel cpu_pressure,
        bool thermally_constrained) {

    bool any_active     = false;
    bool any_building   = false;
    bool any_latency    = false;
    bool all_idle       = true;

    for (const auto& [id, wl] : workloads) {
        // Observation-only workloads are unclassified, NOT idle. A game,
        // Blender render or training job that the classifier does not yet know
        // is still real demand: ignoring it used to leave all_idle=true and
        // pin the governor at POWERSAVE under NORMAL pressure. Only observed
        // workloads with measurable CPU use (or confirmed executing state)
        // count, so a file manager window does not block idle downclocking.
        if (wl.observed &&
            wl.cpu_pct < OBSERVED_CPU_DEMAND_PCT &&
            wl.state != WorkloadState::BACKGROUND_EXECUTING) continue;
        if (wl.state == WorkloadState::ACTIVE) {
            any_active = true;
            all_idle   = false;
        } else if (wl.state == WorkloadState::BACKGROUND_EXECUTING) {
            all_idle = false;
        }
        // v3.3: a background game or GPU dataloader is still demand — it keeps
        // a full slice and must not be clocked down just because its workspace
        // lost focus (streaming while playing, training while browsing).
        if (wl.latency_critical || wl.gpu_feeding) {
            any_active = true;
            all_idle   = false;
            any_latency = true;
        }
        if (wl.state == WorkloadState::BACKGROUND_EXECUTING && wl.is_building)
            any_building = true;
        // A focused render / compile / training job gets the same boost as a
        // classic build daemon, but only while it is actually consuming CPU.
        if (wl.state == WorkloadState::ACTIVE && wl.throughput_bulk &&
            wl.cpu_pct >= OBSERVED_CPU_DEMAND_PCT)
            any_building = true;
        if (wl.state == WorkloadState::ACTIVE && wl.latency_sensitive)
            any_latency = true;
    }

    const bool cpu_contended_active =
        (cpu_pressure >= PressureLevel::MODERATE) && any_active;

    if (any_building || any_latency || cpu_contended_active) {
        if (thermally_constrained)
            return GovernorHint::SCHEDUTIL;

        const bool may_hold_performance =
            (current == GovernorHint::PERFORMANCE)
                ? (pressure <= PressureLevel::MODERATE)
                : (pressure <  PressureLevel::HIGH);
        if (may_hold_performance) return GovernorHint::PERFORMANCE;
        return GovernorHint::SCHEDUTIL;
    }

    if (all_idle && pressure == PressureLevel::NORMAL &&
        cpu_pressure == PressureLevel::NORMAL) {
        return GovernorHint::POWERSAVE;
    }
    return GovernorHint::SCHEDUTIL;
}

// ─────────────────────────────────────────────────────────────────────────────
// Governor translation — hints are abstract; kernels expose different names
// ─────────────────────────────────────────────────────────────────────────────
std::string choose_scaling_governor(GovernorHint hint,
                                    const std::string& available) {
    const auto toks = split_tokens(available);
    if (toks.empty()) return "";

    switch (hint) {
        case GovernorHint::PERFORMANCE:
            if (has_token(toks, "performance")) return "performance";
            break;
        case GovernorHint::POWERSAVE:
            if (has_token(toks, "powersave")) return "powersave";
            if (has_token(toks, "ondemand"))  return "ondemand";
            if (has_token(toks, "schedutil")) return "schedutil";
            break;
        case GovernorHint::SCHEDUTIL:
            if (has_token(toks, "schedutil"))    return "schedutil";
            if (has_token(toks, "ondemand"))     return "ondemand";
            if (has_token(toks, "conservative")) return "conservative";
            // intel_pstate/amd-pstate active mode: "powersave" is the balanced,
            // kernel-autoscaling governor (not a fixed minimum frequency).
            if (has_token(toks, "powersave"))    return "powersave";
            break;
    }
    return toks.front(); // last resort: whatever the platform considers default
}

std::string choose_energy_preference(GovernorHint hint,
                                     const std::string& available) {
    const auto toks = split_tokens(available);
    if (toks.empty()) return "";

    switch (hint) {
        case GovernorHint::PERFORMANCE:
            if (has_token(toks, "performance"))        return "performance";
            if (has_token(toks, "balance_performance")) return "balance_performance";
            break;
        case GovernorHint::SCHEDUTIL:
            if (has_token(toks, "balance_performance")) return "balance_performance";
            if (has_token(toks, "default"))             return "default";
            if (has_token(toks, "balance_power"))       return "balance_power";
            break;
        case GovernorHint::POWERSAVE:
            if (has_token(toks, "power"))               return "power";
            if (has_token(toks, "balance_power"))       return "balance_power";
            if (has_token(toks, "default"))             return "default";
            break;
    }
    return "";
}

// ─────────────────────────────────────────────────────────────────────────────
// apply_governor — program scaling_governor + energy_performance_preference
//
// Writes are change-detected: steady state costs only the sysfs reads needed to
// notice an external change, never a write per CPU per tick. Returns the
// governor name applied to the first policy ("" when no cpufreq driver exists).
// ─────────────────────────────────────────────────────────────────────────────
std::string WorkspaceMonitor::apply_governor(GovernorHint hint) {
    std::string applied;
    bool found_policy = false;

    // error_code overloads throughout: a partially delegated/restricted sysfs
    // must not throw out of the 200 ms daemon loop.
    std::error_code ec;
    fs::directory_iterator it("/sys/devices/system/cpu", ec);
    const fs::directory_iterator end;
    for (; !ec && it != end; it.increment(ec)) {
        const std::string cpu_dir = it->path().string();
        const std::string dir     = cpu_dir + "/cpufreq";
        const std::string gov_path = dir + "/scaling_governor";

        std::error_code path_ec;
        if (!fs::exists(gov_path, path_ec)) continue;

        found_policy = true;

        const std::string avail = read_first_line(dir + "/scaling_available_governors");
        const std::string target = choose_scaling_governor(hint, avail);
        if (!target.empty()) {
            std::string actual = read_first_line(gov_path);
            if (actual != target) {
                write_line(gov_path, target);
                // Report what the kernel accepted, not what we asked for. A
                // restricted/undelegated sysfs can silently reject the write.
                const std::string after = read_first_line(gov_path);
                if (!after.empty()) actual = after;
            }
            if (applied.empty())
                applied = actual.empty() ? target : actual;
        }

        // HWP/EPP gives finer power/performance control on pstate drivers, where
        // "powersave" and "schedutil" can map to the same governor.
        const std::string epp_path = dir + "/energy_performance_preference";
        if (fs::exists(epp_path, path_ec)) {
            const std::string epp_avail =
                read_first_line(dir + "/energy_performance_available_preferences");
            const std::string pref = choose_energy_preference(hint, epp_avail);
            if (!pref.empty() && read_first_line(epp_path) != pref)
                write_line(epp_path, pref);
        }
    }

    if (ec)
        std::cerr << "[Governor] Failed to enumerate CPUs: " << ec.message() << "\n";
    return found_policy ? applied : std::string();
}

} // namespace thm
