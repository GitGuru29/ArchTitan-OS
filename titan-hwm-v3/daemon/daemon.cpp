// =============================================================================
// titan-hwm-v3/daemon/daemon.cpp
// Phase 12 — Main daemon entry point
//
// Wires all phases together into a single event-driven tick loop:
//   1. Bootstrap protected registry + ownership graph
//   2. Start Hyprland IPC listener
//   3. Every tick_ms:
//      a. Refresh /proc snapshot
//      b. Classify new processes (FusionClassifier)
//      c. Detect execution state per workload
//      d. Drive state machine (WorkloadManager)
//      e. Evaluate policy decisions (PolicyEngine)
//      f. Enforce decisions (EnforcementPlane / ReclaimEngine)
//      g. Update governor from aggregate demand
// =============================================================================
#include "../core/types.hpp"
#include "../core/protected_registry.hpp"
#include "../workload/ownership_graph.hpp"
#include "../workload/workload_manager.hpp"
#include "../classifier/fusion_classifier.hpp"
#include "../classifier/execution_detector.hpp"
#include "../policy/policy_engine.hpp"
#include "../policy/reclaim_engine.hpp"
#include "../enforcement/cgroup_controller.hpp"
#include "../enforcement/enforcement_plane.hpp"
#include "../resources/pressure_level.hpp"
#include "../ipc/workspace_monitor.hpp"
#include "../ipc/telemetry_publisher.hpp"
#include "../ipc/command_server.hpp"

#include <iostream>
#include <fstream>
#include <csignal>
#include <chrono>
#include <thread>
#include <mutex>
#include <filesystem>
#include <algorithm>
#include <sstream>
#include <deque>
#include <iomanip>
#include <ctime>
#include <unordered_set>
#include <unistd.h>
#include <sys/stat.h>

namespace fs = std::filesystem;

// ─────────────────────────────────────────────────────────────────────────────
// Global shutdown flag (SIGTERM / SIGINT handler)
// ─────────────────────────────────────────────────────────────────────────────
static volatile sig_atomic_t g_shutdown = 0;
static void handle_signal(int) { g_shutdown = 1; }

// ─────────────────────────────────────────────────────────────────────────────
// GovernorHint → wire string for the telemetry snapshot.
// ─────────────────────────────────────────────────────────────────────────────
static const char* governor_to_string(thm::GovernorHint h) {
    switch (h) {
        case thm::GovernorHint::POWERSAVE:   return "powersave";
        case thm::GovernorHint::PERFORMANCE: return "performance";
        case thm::GovernorHint::SCHEDUTIL:
        default:                             return "schedutil";
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Observation-mode helpers
//
// THM v3 originally registered a workload only when FusionClassifier returned
// a non-NEUTRAL type. On a desktop with no dev project open that means the
// registry is legitimately empty and the system monitor shows "0 workloads",
// which is truthful but useless. Observation mode fills that gap: every
// user-session process tree root is tracked for telemetry only, with no
// enforcement authority whatsoever.
// ─────────────────────────────────────────────────────────────────────────────

// /proc/<pid>/stat truncates comm to TASK_COMM_LEN-1 = 15 characters. Match
// against full names by comparing the truncated prefix, otherwise entries like
// "xdg-document-portal" never match "xdg-document-po".
static bool comm_set_contains(const std::unordered_set<std::string>& set,
                              const std::string& comm) {
    if (set.count(comm)) return true;
    if (comm.size() != 15) return false;
    for (const auto& name : set) {
        if (name.size() > 15 && name.compare(0, 15, comm) == 0)
            return true;
    }
    return false;
}

// Session managers: walking *through* one of these exits the user app tree.
static bool is_session_manager_comm(const std::string& comm) {
    static const std::unordered_set<std::string> kMgrs = {
        "systemd", "init", "Hyprland", "hyprland", "hyprland-wr",
        "dbus-daemon", "dbus-broker", "dbus-broker-lau"
    };
    return comm_set_contains(kMgrs, comm);
}

// Desktop infrastructure that is already protected/managed elsewhere. Tracking
// these as workloads would just add noise to the monitor.
static bool is_desktop_infra_comm(const std::string& comm) {
    static const std::unordered_set<std::string> kInfra = {
        "Hyprland", "hyprland", "waybar", "pipewire", "pipewire-pulse",
        "wireplumber", "dbus-daemon", "dbus-broker", "dbus-broker-lau",
        "systemd", "Xwayland", "xdg-desktop-portal", "xdg-desktop-portal-hyprland",
        "xdg-desktop-portal-gtk", "xdg-document-portal", "xdg-permission-store",
        "gnome-keyring-daemon", "gcr-ssh-agent", "ssh-agent", "kwalletd6",
        "at-spi-bus-launcher", "at-spi2-registryd", "polkit-gnome-authentication-agent-1",
        "xdg-user-dirs-update", "swww-daemon", "hypridle", "hyprlock",
        "cliphist", "wl-paste", "socat", "titan-hwm-daemon",
        // Quickshell-based desktop shell + misc session helpers
        "qs", "quickshell", "easyeffects", "ydotoold", "start-hyprland",
        "sd-pam", "hyprsunset", "dconf-service", "chrome_crashpad_handler",
        "xdg-document-portal", "xdg-permission-store", "gvfsd", "gvfsd-fuse",
        "gvfs-udisks2-volume-monitor", "udisksd", "upowerd"
    };
    return comm_set_contains(kInfra, comm);
}

// Walk up the process tree until the parent is a session manager, a system
// process, or missing. The highest user-owned ancestor below the session
// manager is the application root (terminal, IDE, browser, game, ...).
//
// Smarter rooting (v3.1): prefer systemd scope + session ID to keep trees
// together when processes are reparented to init/PID 1 or spawned oddly.
static pid_t resolve_tree_root(
        pid_t pid,
        const std::unordered_map<pid_t, thm::ProcessNode>& graph) {
    auto it_pid = graph.find(pid);
    if (it_pid == graph.end()) return pid;
    const auto& start = it_pid->second;

    const std::string scope = start.cgroup;
    const pid_t sid = start.sid;
    const uid_t uid = start.uid;
    const bool has_scope = !scope.empty() && (scope.find(".scope") != std::string::npos ||
                                               scope.find("app.slice") != std::string::npos);

    // Prefer scope/sid anchoring - keeps trees together even if reparented
    if (has_scope || sid > 0) {
        pid_t best = pid;
        pid_t cur  = pid;
        for (int depth = 0; depth < 128; ++depth) {
            auto it = graph.find(cur);
            if (it == graph.end()) break;
            pid_t parent = it->second.ppid;
            if (parent <= 0) break;
            auto pit = graph.find(parent);
            if (pit == graph.end()) {
                // parent reparented to init or outside graph
                break;
            }
            const auto& p = pit->second;
            if (p.uid < 1000) break;
            if (is_session_manager_comm(p.comm)) break;
            if (is_desktop_infra_comm(p.comm)) break;
            bool same_scope = has_scope && !p.cgroup.empty() && p.cgroup == scope;
            bool same_sid   = (sid > 0 && p.sid == sid);
            if (!same_scope && !same_sid) {
                // don't cross scope/session boundary to arbitrary process
                break;
            }
            best = parent;
            cur  = parent;
            if (parent == 1) break;
        }
        if (best <= 1) return pid;
        // ensure best is not a session manager
        if (auto bit = graph.find(best); bit != graph.end()) {
            if (is_session_manager_comm(bit->second.comm)) return pid;
            if (bit->second.uid < 1000) return pid;
        }
        return best;
    }

    pid_t root = pid;
    pid_t cur  = pid;
    for (int depth = 0; depth < 64; ++depth) {
        auto it = graph.find(cur);
        if (it == graph.end()) break;
        pid_t parent = it->second.ppid;
        if (parent <= 0) break;
        auto pit = graph.find(parent);
        if (pit == graph.end()) break;
        const auto& p = pit->second;
        if (p.uid < 1000) break;
        if (is_session_manager_comm(p.comm)) break;
        if (is_desktop_infra_comm(p.comm)) break;
        root = parent;
        cur  = parent;
        if (parent == 1) break;
    }
    return root;
}

static std::string wall_clock_hms() {
    std::time_t t = std::time(nullptr);
    std::tm tm{};
    localtime_r(&t, &tm);
    char buf[16];
    std::strftime(buf, sizeof(buf), "%H:%M:%S", &tm);
    return buf;
}

// ─────────────────────────────────────────────────────────────────────────────
// format_status — human-readable reply for the `titan-hwm status` command.
// Built from the last telemetry snapshot (updated once per tick).
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_status(const thm::TelemetrySnapshot& s) {
    std::ostringstream o;
    o << "Titan Hardware Manager v" << s.version << "\n";
    o << "  Uptime:          " << s.uptime_seconds << "s\n";
    o << "  Pressure:        " << s.pressure_level
      << "  (PSI some " << s.psi_some_avg10
      << "% / full " << s.psi_full_avg10 << "%)\n";
    o << "  Memory used:     " << s.mem_used_pct << "%"
      << "  (" << (s.mem_available_kb / 1024) << " MB free of "
      << (s.mem_total_kb / 1024) << " MB)\n";
    o << "  CPU governor:    " << s.governor << "\n";
    o << "  Workloads:       " << s.active_workloads << " active / "
      << s.workload_count << " tracked\n";
    if (s.has_last_action && !s.last_action.empty()) {
        o << "  Last action:     " << s.last_action;
        if (!s.last_action_target.empty())
            o << " (" << s.last_action_target << ")";
        if (s.last_action_pid > 0)
            o << " pid=" << s.last_action_pid;
        o << "\n";
    } else {
        o << "  Last action:     none\n";
    }
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// format_workloads — `titan-hwm workloads [--classified|--observed]`
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_workloads(const thm::TelemetrySnapshot& s,
                                    bool only_classified,
                                    bool only_observed) {
    std::ostringstream o;
    o << std::left
      << std::setw(6)  << "ID"
      << std::setw(8)  << "PID"
      << std::setw(5)  << "WS"
      << std::setw(14) << "TYPE"
      << std::setw(23) << "STATE"
      << std::right << std::setw(8) << "CPU%"
      << std::setw(9) << "MEM"
      << std::setw(7) << "PIDS"
      << "  NAME\n";
    o << std::string(96, '-') << "\n";

    int shown = 0;
    for (const auto& w : s.workloads) {
        if (only_classified && w.observed) continue;
        if (only_observed && !w.observed) continue;
        ++shown;
        o << std::left
          << std::setw(6)  << w.id
          << std::setw(8)  << w.root_pid
          << std::setw(5)  << w.workspace_id
          << std::setw(14) << w.type
          << std::setw(23) << w.state
          << std::right << std::fixed << std::setprecision(1)
          << std::setw(8)  << w.cpu_pct
          << std::setw(9)  << (std::to_string(w.mem_kb / 1024) + "M")
          << std::setw(7)  << w.pid_count
          << "  " << w.name << (w.observed ? " [observed]" : "")
          << "\n";
    }
    o.unsetf(std::ios::fixed);
    o << std::string(96, '-') << "\n";
    o << shown << " shown  |  "
      << s.classified_workloads << " classified, "
      << s.observed_workloads << " observed, "
      << s.active_workloads << " active\n";
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// format_top — `titan-hwm top [N]`
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_top(const thm::TelemetrySnapshot& s, size_t n) {
    std::vector<thm::TelemetryWorkload> wls = s.workloads;
    std::sort(wls.begin(), wls.end(),
              [](const thm::TelemetryWorkload& a, const thm::TelemetryWorkload& b) {
                  return a.cpu_pct > b.cpu_pct;
              });
    if (n < wls.size()) wls.resize(n);

    std::ostringstream o;
    o << std::left
      << std::setw(6) << "ID"
      << std::setw(8) << "PID"
      << std::right << std::setw(8) << "CPU%"
      << std::setw(9) << "MEM"
      << std::left << "  TYPE          NAME\n";
    o << std::string(80, '-') << "\n";
    for (const auto& w : wls) {
        o << std::left << std::setw(6) << w.id << std::setw(8) << w.root_pid
          << std::right << std::fixed << std::setprecision(1)
          << std::setw(8) << w.cpu_pct
          << std::setw(9) << (std::to_string(w.mem_kb / 1024) + "M")
          << std::left << "  " << std::setw(14) << w.type
          << w.name << (w.observed ? " [observed]" : "") << "\n";
    }
    o.unsetf(std::ios::fixed);
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// format_pressure — `titan-hwm pressure`
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_pressure(const thm::TelemetrySnapshot& s) {
    std::ostringstream o;
    o << std::fixed << std::setprecision(2);
    o << "Pressure level:  " << s.pressure_level << "\n";
    o << "Memory PSI:      some " << s.psi_some_avg10
      << "%   full " << s.psi_full_avg10 << "%  (avg10)\n";
    o << "CPU PSI:         ";
    if (s.cpu_psi_valid)
        o << "some " << s.cpu_psi_avg10 << "%  (avg60 "
          << s.cpu_psi_avg60 << "%, avg300 " << s.cpu_psi_avg300 << "%)";
    else
        o << "unavailable (/proc/pressure/cpu missing)";
    o << "\n";
    o << "Load average:    " << s.load1 << " " << s.load5 << " " << s.load15
      << "   (" << s.runnable_procs << " runnable / " << s.total_procs << ")\n";
    o << "Memory used:     " << s.mem_used_pct << "%  ("
      << (s.mem_available_kb / 1024) << " MB free of "
      << (s.mem_total_kb / 1024) << " MB)\n";
    o << "Workloads:       " << s.active_workloads << " active / "
      << s.workload_count << " tracked  ("
      << s.classified_workloads << " classified, "
      << s.observed_workloads << " observed)\n";
    o << "Hyprland IPC:    "
      << (s.hyprland_connected ? "connected" : "DISCONNECTED (retrying)")
      << "\n";
    if (s.has_last_action && !s.last_action.empty())
        o << "Last action:     " << s.last_action << "  " << s.last_action_target
          << " (pid " << s.last_action_pid << ")\n";
    else
        o << "Last action:     none\n";

    // Explain the memory decision from the same thresholds compute_pressure()
    // uses, so the level is never a black box.
    o << "Reason:          ";
    if (s.psi_full_avg10 >= 15.0f || s.psi_some_avg10 >= 40.0f)
        o << "memory PSI full >= 15% or some >= 40% -> CRITICAL\n";
    else if (s.psi_some_avg10 >= 20.0f)
        o << "memory PSI some >= 20% -> HIGH\n";
    else if (s.psi_some_avg10 >= 5.0f)
        o << "memory PSI some >= 5% -> MODERATE\n";
    else if (s.mem_total_kb > 0 && s.mem_used_pct >= 85.0f)
        o << "RAM used >= 85% -> CRITICAL\n";
    else if (s.mem_total_kb > 0 && s.mem_used_pct >= 75.0f)
        o << "RAM used >= 75% -> HIGH\n";
    else if (s.mem_total_kb > 0 && s.mem_used_pct >= 50.0f)
        o << "RAM used >= 50% -> MODERATE\n";
    else
        o << "all memory signals below thresholds -> NORMAL\n";
    o << "Note:            CPU pressure is telemetry-only; it can never "
         "produce RECLAIM (HC-CPU-1).\n";
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// format_scan — `titan-hwm scan` : why is the workload count what it is?
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_scan(const thm::TelemetrySnapshot& s) {
    std::ostringstream o;
    o << "Process inventory\n";
    o << "  seen:          " << s.processes_seen << "\n";
    o << "  protected:     " << s.processes_protected << "\n";
    o << "  assigned:      " << s.processes_assigned << "\n";
    o << "  unmanaged:     " << s.processes_unmanaged << "\n\n";
    o << "Workloads\n";
    o << "  classified:    " << s.classified_workloads
      << "   (enforcement-eligible)\n";
    o << "  observed:      " << s.observed_workloads
      << "   (telemetry only, never throttled/frozen/reclaimed)\n";
    o << "  active:        " << s.active_workloads << "\n\n";
    o << "Hyprland IPC:    "
      << (s.hyprland_connected ? "connected"
                               : "DISCONNECTED — window-title signal unavailable")
      << "\n";
    if (!s.has_last_action || s.last_action.empty()) {
        // nothing notable
    }

    o << "\nTop unmanaged user processes";
    if (s.top_unmanaged.empty()) {
        o << ": none\n";
    } else {
        o << "\n";
        o << std::left << std::setw(8) << "PID" << std::setw(20) << "COMM"
          << std::right << std::setw(8) << "CPU%"
          << std::setw(9) << "MEM" << std::left << "  REASON\n";
        o << std::string(86, '-') << "\n";
        for (const auto& u : s.top_unmanaged) {
            o << std::left << std::setw(8) << u.pid
              << std::setw(20) << u.comm
              << std::right << std::fixed << std::setprecision(1)
              << std::setw(8) << u.cpu_pct
              << std::setw(9) << (std::to_string(u.rss_kb / 1024) + "M")
              << std::left << "  " << u.reason << "\n";
        }
        o.unsetf(std::ios::fixed);
    }
    o << "\nClassified workloads need a dev signal (LSP/build child, project "
         "CWD marker,\nwindow title, or a recognised service/VM/browser root). "
         "Observed workloads\nare shown for visibility and are never enforced.\n";
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// format_explain — `titan-hwm explain <workload-id|root-pid|name>`
// ─────────────────────────────────────────────────────────────────────────────
static std::string format_explain(const thm::TelemetrySnapshot& s,
                                  const std::string& needle) {
    const thm::TelemetryWorkload* found = nullptr;
    for (const auto& w : s.workloads) {
        if (std::to_string(w.id) == needle ||
            std::to_string(w.root_pid) == needle ||
            w.name == needle ||
            (!needle.empty() && w.name.find(needle) != std::string::npos)) {
            found = &w;
            break;
        }
    }

    std::ostringstream o;
    if (!found) {
        o << "No tracked workload matches '" << needle << "'.\n";
        for (const auto& u : s.top_unmanaged) {
            if (std::to_string(u.pid) == needle || u.comm == needle) {
                o << "Found unmanaged process pid " << u.pid << " (" << u.comm
                  << "): " << u.reason << "\n"
                  << "It is not a workload, so no policy is applied to it.\n";
                return o.str();
            }
        }
        o << "Try `titan-hwm scan` to see unmanaged processes, or "
             "`titan-hwm workloads`.\n";
        return o.str();
    }

    const auto& w = *found;
    o << "Workload " << w.id << "\n";
    o << "  root pid:    " << w.root_pid << "\n";
    o << "  name:        " << w.name << "\n";
    o << "  type:        " << w.type << "\n";
    o << "  state:       " << w.state << "\n";
    o << "  workspace:   " << w.workspace_id
      << (w.workspace_id == -2 ? " (headless / unknown)" : "") << "\n";
    o << "  members:     " << w.pid_count << "\n";
    o << "  CPU:         " << std::fixed << std::setprecision(1)
      << w.cpu_pct << "%\n";
    o << "  memory:      " << (w.mem_kb / 1024) << " MB\n";
    o.unsetf(std::ios::fixed);
    if (w.observed) {
        o << "  authority:   OBSERVED — telemetry only. No dev signal matched,\n"
             "               so THM will never throttle, freeze or reclaim it.\n";
    } else {
        o << "  authority:   CLASSIFIED — eligible for policy enforcement,\n"
             "               subject to the protected-domain and HC invariants.\n";
    }
    return o.str();
}

// ─────────────────────────────────────────────────────────────────────────────
// Build a fresh /proc snapshot (like v2 MemoryGraph::build())
// ─────────────────────────────────────────────────────────────────────────────
static void refresh_proc_graph(std::unordered_map<pid_t, thm::ProcessNode>& graph) {
    graph.clear();
    for (const auto& entry : fs::directory_iterator("/proc")) {
        if (!entry.is_directory()) continue;
        const std::string d = entry.path().filename().string();
        if (!std::all_of(d.begin(), d.end(), ::isdigit)) continue;
        pid_t pid = 0;
        try { pid = static_cast<pid_t>(std::stoi(d)); } catch (...) { continue; }
        if (pid <= 1) continue;

        thm::ProcessNode n;
        n.pid = pid;

        // Read comm, state, ppid from /proc/<pid>/stat
        std::ifstream sf("/proc/" + d + "/stat");
        std::string line;
        if (std::getline(sf, line)) {
            size_t lp = line.find('('), rp = line.rfind(')');
            if (lp != std::string::npos && rp != std::string::npos) {
                n.comm = line.substr(lp + 1, rp - lp - 1);
                std::istringstream iss(line.substr(rp + 2));
                iss >> n.proc_state >> n.ppid;
            }
        }

        // Read cmdline
        {
            std::ifstream cf("/proc/" + d + "/cmdline", std::ios::binary);
            std::string raw;
            std::getline(cf, raw, '\0');
            auto slash = raw.rfind('/');
            n.cmdline = (slash != std::string::npos) ? raw.substr(slash + 1) : raw;
        }

        // Read RSS from /proc/<pid>/statm (field 2, pages)
        {
            std::ifstream mf("/proc/" + d + "/statm");
            long total_pages = 0, rss_pages = 0;
            if (mf >> total_pages >> rss_pages)
                n.rss_kb = rss_pages * 4; // 4 KB pages
        }

        // Ownership — one stat() syscall on /proc/<pid> gives the real UID.
        // Used to keep observation mode scoped to interactive user apps.
        {
            struct stat st{};
            if (::stat(("/proc/" + d).c_str(), &st) == 0)
                n.uid = st.st_uid;
        }

        // Session ID for grouping
        {
            pid_t sid = ::getsid(pid);
            if (sid >= 0) n.sid = sid;
        }

        // Exe + cgroup for smarter rooting/classification
        {
            char buf[4096];
            std::string exe_link = "/proc/" + d + "/exe";
            ssize_t elen = readlink(exe_link.c_str(), buf, sizeof(buf) - 1);
            if (elen > 0) {
                buf[elen] = '\0';
                std::string es(buf);
                auto spd = es.find(" (deleted)");
                if (spd != std::string::npos) es = es.substr(0, spd);
                n.exe = std::move(es);
            }
        }
        {
            std::ifstream cf("/proc/" + d + "/cgroup");
            std::string line;
            while (std::getline(cf, line)) {
                if (line.find(".scope") != std::string::npos ||
                    line.find("app.slice") != std::string::npos ||
                    line.find("user.slice") != std::string::npos) {
                    auto colon = line.rfind(':');
                    if (colon != std::string::npos && colon + 1 < line.size()) {
                        n.cgroup = line.substr(colon + 1);
                        break;
                    }
                }
            }
            if (n.cgroup.empty()) {
                cf.clear();
                cf.seekg(0);
                std::string last;
                while (std::getline(cf, line)) {
                    auto colon = line.rfind(':');
                    if (colon != std::string::npos && colon + 1 < line.size())
                        last = line.substr(colon + 1);
                }
                n.cgroup = last;
            }
        }

        graph[pid] = std::move(n);
    }

    // Build child lists
    for (auto& [pid, node] : graph) {
        if (node.ppid > 0 && graph.count(node.ppid))
            graph[node.ppid].children.push_back(pid);
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// HC-11 FIX: startup_thaw_sweep
// Scans /proc for any user-owned processes in state 'T' (stopped by SIGSTOP)
// and issues SIGCONT to recover from a previous unexpected THM crash.
// Called once before the main loop on every daemon start.
// ─────────────────────────────────────────────────────────────────────────────
static int startup_thaw_sweep() {
    uid_t my_uid = getuid();
    int thawed = 0;
    for (const auto& entry : fs::directory_iterator("/proc")) {
        if (!entry.is_directory()) continue;
        const std::string d = entry.path().filename().string();
        if (!std::all_of(d.begin(), d.end(), ::isdigit)) continue;
        pid_t pid = 0;
        try { pid = static_cast<pid_t>(std::stoi(d)); } catch (...) { continue; }
        if (pid <= 1) continue;

        // Check UID ownership — only thaw our own processes
        std::ifstream status_f("/proc/" + d + "/status");
        uid_t proc_uid = UINT32_MAX;
        char state = '?';
        std::string key, val;
        while (status_f >> key) {
            if (key == "Uid:") { status_f >> proc_uid; }
            if (key == "State:") { status_f >> val; if (!val.empty()) state = val[0]; }
            if (proc_uid != UINT32_MAX && state != '?') break;
        }
        if (proc_uid != my_uid) continue;      // not ours
        if (state != 'T' && state != 't') continue; // not stopped

        // Issue SIGCONT to recover from previous crash
        if (::kill(pid, SIGCONT) == 0) {
            std::cout << "[THM] Startup thaw: sent SIGCONT to frozen PID " << pid << "\n";
            ++thawed;
        }
    }
    if (thawed > 0)
        std::cout << "[THM] Startup thaw sweep complete: " << thawed
                  << " process(es) recovered from previous crash.\n";
    else
        std::cout << "[THM] Startup thaw sweep: no frozen processes found.\n";
    return thawed;
}

// ─────────────────────────────────────────────────────────────────────────────
// main
// ─────────────────────────────────────────────────────────────────────────────
int main(int argc, char* argv[]) {
    // Flush every insertion. Under systemd, stdout/stderr are pipes and are
    // block-buffered by default — without this, THM log lines would not reach
    // the journal until a 4 KiB buffer fills, making `journalctl -u titan-hwm`
    // appear empty during normal operation.
    std::cout << std::unitbuf;

    std::cout << "╔══════════════════════════════════════════╗\n"
              << "║  Titan Hardware Manager v3               ║\n"
              << "║  Workload-centric resource management    ║\n"
              << "╚══════════════════════════════════════════╝\n";

    // ── Signal handlers ─────────────────────────────────────────────────────
    signal(SIGTERM, handle_signal);
    signal(SIGINT,  handle_signal);

    // ── Command-line arguments ──────────────────────────────────────────────
    bool dry_run = false;
    int max_ticks = -1;
    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--dry-run") {
            dry_run = true;
            std::cout << "[THM] Dry-run mode enabled: decisions logged without kernel enforcement.\n";
        } else if (arg == "--ticks" && i + 1 < argc) {
            try { max_ticks = std::stoi(argv[++i]); } catch (...) {}
            std::cout << "[THM] Scheduled to run for " << max_ticks << " ticks.\n";
        } else if (arg == "--help" || arg == "-h") {
            std::cout << "Usage: titan-hwm-v3 [--dry-run] [--ticks N]\n"
                      << "  --dry-run    Evaluate policy and log decisions without issuing signals\n"
                      << "  --ticks N    Run for N ticks (200ms each) then exit cleanly\n";
            return 0;
        }
    }

    // ── Configuration ────────────────────────────────────────────────────────
    const int tick_ms = 200; // 5 Hz tick rate

    // ── Phase 0: Protected Domain Registry ──────────────────────────────────
    thm::ProtectedRegistry registry;
    registry.register_pid(getpid(), "THM-self");
    registry.bootstrap_from_systemd();

    // ── HC-11: Startup thaw sweep (crash recovery) ───────────────────────────
    // Must run before the main loop so that any processes frozen by a previous
    // THM crash are immediately released before new policy kicks in.
    startup_thaw_sweep();

    // ── Phase 7: cgroup hierarchy ───────────────────────────────────────────
    thm::CgroupController cgroup;
    if (!cgroup.setup_slices()) {
        std::cerr << "[THM] WARNING: cgroup hierarchy setup failed — "
                  << "enforcement will use SIGSTOP/SIGCONT only.\n";
    }

    // ── Phase 9/10: Enforcement + Reclaim ───────────────────────────────────
    thm::EnforcementPlane enforcement(cgroup, registry);
    thm::ExecutionDetector detector;
    thm::ReclaimEngine reclaimer(registry, detector);

    // ── Phase 5: Workload registry ──────────────────────────────────────────
    thm::WorkloadManager workload_mgr;
    thm::OwnershipGraph  ownership;
    thm::FusionClassifier classifier;
    thm::PolicyEngine     policy;

    // ── Phase 2: Cold-start bootstrap ───────────────────────────────────────
    uint32_t next_workload_id = 1;
    auto bootstrap = ownership.bootstrap(next_workload_id);
    for (auto& wl : bootstrap) {
        workload_mgr.add(std::move(wl));
    }
    std::cout << "[THM] Bootstrap: " << bootstrap.size()
              << " workload(s) discovered.\n";

    // ── Phase 8: Workspace monitor ──────────────────────────────────────────
    thm::WorkspaceMonitor ws_monitor;
    ws_monitor.on_workspace_change([](int id, bool focused) {
        std::cout << "[WS] Switch → workspace " << id << "\n";
    });
    ws_monitor.on_window_change([](int ws, const std::string& cls,
                                    const std::string& title) {
        std::cout << "[WS] Window: " << cls << " — " << title << "\n";
    });
    if (!ws_monitor.start()) {
        std::cerr << "[THM] Hyprland IPC unavailable — running in headless mode.\n";
    }

    // ── Proc graph (reused each tick) ───────────────────────────────────────
    std::unordered_map<pid_t, thm::ProcessNode> proc_graph;

    // ── Previous child sets for execution detection ─────────────────────────
    std::unordered_map<pid_t, std::vector<pid_t>> prev_children;

    // Governor hint currently applied — feeds compute_governor's hysteresis band
    thm::GovernorHint current_gov = thm::GovernorHint::SCHEDUTIL;

    // ── Phase 13: Telemetry sidecar ─────────────────────────────────────────
    thm::TelemetryPublisher telemetry;
    const auto start_time = std::chrono::steady_clock::now();
    std::string last_action;
    std::string last_action_target;
    pid_t       last_action_pid  = 0;
    bool        has_last_action  = false;

    // ── Command server: restores the user control channel ───────────────────
    // `titan-hwm status` is answered from the last telemetry snapshot, which is
    // rebuilt every tick under snap_mutex. `switch` is intentionally NOT
    // implemented: v3 has no static workspace profiles (that was v1/v2-only).
    thm::CommandServer cmd_server;
    std::mutex snap_mutex;
    thm::TelemetrySnapshot shared_snap;

    // Bounded history of enforcement actions, exposed by `titan-hwm decisions`.
    // Guarded by snap_mutex (written from the tick loop, read from the command
    // thread).
    std::deque<std::string> decision_log;
    constexpr size_t kMaxDecisionLog = 64;

    cmd_server.set_handler([&](const std::string& raw) -> std::string {
        // Split verb + arguments. One line per connection, so a simple
        // whitespace split is sufficient.
        std::string cmd = raw;
        std::string verb, args;
        auto sp = cmd.find(' ');
        if (sp == std::string::npos) {
            verb = cmd;
        } else {
            verb = cmd.substr(0, sp);
            args = cmd.substr(sp + 1);
            while (!args.empty() &&
                   (args.front() == ' ' || args.front() == '\t')) args.erase(args.begin());
            while (!args.empty() &&
                   (args.back() == ' ' || args.back() == '\t')) args.pop_back();
        }

        if (verb == "ping")
            return "pong\n";

        std::lock_guard<std::mutex> lk(snap_mutex);

        if (verb == "status")    return format_status(shared_snap);
        if (verb == "pressure")  return format_pressure(shared_snap);
        if (verb == "scan")      return format_scan(shared_snap);
        if (verb == "dump")      return thm::serialize_snapshot(shared_snap) + "\n";

        if (verb == "workloads") {
            bool only_classified = args.find("--classified") != std::string::npos;
            bool only_observed   = args.find("--observed")   != std::string::npos;
            return format_workloads(shared_snap, only_classified, only_observed);
        }

        if (verb == "top") {
            size_t n = 10;
            if (!args.empty()) {
                try { n = static_cast<size_t>(std::stoul(args)); } catch (...) {}
            }
            if (n == 0 || n > 256) n = 10;
            return format_top(shared_snap, n);
        }

        if (verb == "explain") {
            if (args.empty())
                return "usage: titan-hwm explain <workload-id|root-pid|name>\n";
            return format_explain(shared_snap, args);
        }

        if (verb == "decisions") {
            size_t n = 20;
            if (!args.empty()) {
                try { n = static_cast<size_t>(std::stoul(args)); } catch (...) {}
            }
            if (n == 0 || n > kMaxDecisionLog) n = kMaxDecisionLog;
            std::ostringstream o;
            if (decision_log.empty()) {
                o << "No enforcement actions recorded yet.\n";
            } else {
                size_t start = decision_log.size() > n ? decision_log.size() - n : 0;
                for (size_t i = start; i < decision_log.size(); ++i)
                    o << decision_log[i] << "\n";
            }
            return o.str();
        }

        return "titan-hwm: unknown command '" + verb + "'\n";
    });
    if (!cmd_server.start()) {
        std::cerr << "[THM] WARNING: command server failed to start — "
                  << "`titan-hwm status` will be unavailable.\n";
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MAIN TICK LOOP
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    std::cout << "[THM] Entering main tick loop (" << tick_ms << "ms interval)\n";

    int tick_count = 0;
    while (!g_shutdown) {
        if (max_ticks > 0 && ++tick_count > max_ticks) {
            std::cout << "[THM] Reached target tick count (" << max_ticks << "). Exiting cleanly.\n";
            break;
        }

        auto tick_start = std::chrono::steady_clock::now();

        // ── (a) Refresh /proc snapshot ──────────────────────────────────────
        refresh_proc_graph(proc_graph);

        // ── (b) Refresh workspace visibility ────────────────────────────────
        ws_monitor.refresh_visibility();
        auto workspaces = ws_monitor.snapshot_workspaces();

        // ── (c) Read pressure ───────────────────────────────────────────────
        thm::MemInfo    mem = thm::read_meminfo();
        thm::PSIStats   psi = thm::read_memory_psi();
        thm::CpuPSIStats cpu_psi = thm::read_cpu_psi();
        thm::LoadAverage loadavg = thm::read_loadavg();
        // HC-CPU-1: compute_pressure() intentionally receives memory signals
        // only. CPU pressure is read for telemetry but never escalates.
        thm::PressureLevel pressure = thm::compute_pressure(mem, psi);

        // ── (d) Classify + assign new processes (observation-aware) ─────────
        // Counters feed the telemetry `processes` block and `titan-hwm scan`,
        // so an empty registry is always explainable instead of mysterious.
        int processes_seen      = 0;
        int processes_protected = 0;
        int processes_assigned  = 0;

        // Cap observed workloads so a pathological fork storm cannot turn the
        // telemetry into an unbounded registry.
        constexpr int kMaxObserved = 128;
        int observed_count = 0;
        for (uint32_t id : workload_mgr.all_ids()) {
            auto* w = workload_mgr.get(id);
            if (w && w->observed) ++observed_count;
        }

        for (auto& [pid, node] : proc_graph) {
            ++processes_seen;
            if (registry.is_protected(pid, node.comm)) {
                ++processes_protected;
                continue; // skip protected
            }

            uint32_t existing_wl_id = ownership.workload_of(pid);

            if (existing_wl_id != 0) {
                ++processes_assigned;
                // HC-10: Dynamic re-classification — detect cmdline drift.
                // Observed workloads are retried periodically: a terminal that
                // starts a build later has no cmdline drift but does gain a
                // classifying child, and should be promoted to enforcement.
                auto* wl = workload_mgr.get(existing_wl_id);
                if (wl && wl->root_pid == pid) {
                    bool try_reclassify = false;
                    if (wl->observed) {
                        try_reclassify = (tick_count % 10 == 0);
                    } else if (wl->is_reclassifiable &&
                               !node.cmdline.empty() &&
                               node.cmdline != wl->root_cmdline) {
                        std::cout << "[THM] Cmdline drift on workload " << existing_wl_id
                                  << ": '" << wl->root_cmdline << "' → '" << node.cmdline << "'\n";
                        try_reclassify = true;
                    }

                    if (try_reclassify) {
                        int ws_id = ws_monitor.focused_workspace();
                        std::string title;
                        auto ws_it = workspaces.find(ws_id);
                        if (ws_it != workspaces.end()) title = ws_it->second.active_window_title;
                        auto result = classifier.classify(pid, title, proc_graph);
                        if (result.type != thm::WorkloadType::NEUTRAL) {
                            wl->type          = result.type;
                            wl->confidence    = result.confidence;
                            wl->is_building   = result.is_building;
                            wl->has_lsp       = result.has_lsp;
                            wl->latency_sensitive = result.latency_sensitive;
                            wl->is_browser_root   = result.is_browser_root;
                            if (wl->observed) {
                                std::cout << "[THM] Promoted observed workload " << wl->id
                                          << " (" << wl->root_cmdline << ") to "
                                          << thm::to_string(result.type) << "\n";
                                wl->observed = false;
                            }
                            wl->root_cmdline  = node.cmdline;
                            wl->is_reclassifiable = false; // reset until next drift
                        } else if (!wl->observed) {
                            wl->root_cmdline = node.cmdline;
                        }
                    }
                }
                continue; // already assigned
            }

            // Get window title for this workspace
            // HC-03: Headless processes (no window root) must NOT inherit the
            // focused workspace. Assign WS=-2 to avoid polluting WS telemetry.
            bool has_window = false;
            int ws_id = -2; // HC-03: default = headless / unknown workspace
            {
                // A process is considered window-rooted if its cmdline matches
                // a known IDE, terminal, or browser command.
                // Simple heuristic: check if any workspace reports it as focused.
                auto focused_ws = ws_monitor.focused_workspace();
                auto ws_it2 = workspaces.find(focused_ws);
                if (ws_it2 != workspaces.end()) {
                    // Only assign to focused WS if the process comm matches
                    // the active window class (i.e., it IS the foreground app).
                    const auto& ws_state = ws_it2->second;
                    if (!ws_state.active_window_class.empty() &&
                        node.comm.find(ws_state.active_window_class.substr(0,8)) != std::string::npos) {
                        ws_id = focused_ws;
                        has_window = true;
                    }
                }
            }

            std::string title;
            if (has_window) {
                auto ws_it = workspaces.find(ws_id);
                if (ws_it != workspaces.end()) title = ws_it->second.active_window_title;
            }

            auto result = classifier.classify(pid, title, proc_graph);
            if (result.type != thm::WorkloadType::NEUTRAL) {
                thm::Workload wl;
                wl.id               = next_workload_id++;
                wl.type             = result.type;
                wl.confidence       = result.confidence;
                wl.ai_owned         = result.ai_modifier;
                wl.is_building      = result.is_building;
                wl.latency_sensitive = result.latency_sensitive;
                wl.is_browser_root  = result.is_browser_root;  // HC-05/06
                wl.is_reclassifiable = true;                   // HC-10: all new workloads eligible
                wl.root_pid         = pid;
                wl.root_cmdline     = node.cmdline.empty() ? node.comm
                                                           : node.cmdline; // HC-10
                wl.state            = thm::WorkloadState::DISCOVERED;
                wl.workspace_id     = ws_id;                   // HC-03: -2 if headless
                wl.created_at       = thm::ms_clock::now();
                wl.last_active      = thm::ms_clock::now();
                wl.pids.push_back(pid);
                ownership.assign(pid, wl.id);
                workload_mgr.add(std::move(wl));
            } else {
                // ── Observation-mode fallback (v3.1) ──────────────────────────
                // No dev signal matched. If this PID is not the root of its
                // user-session process tree, leave it: the root creates the
                // observed workload and the child inherits it on a later tick.
                pid_t root = resolve_tree_root(pid, proc_graph);
                if (root != pid)
                    continue;

                // Only interactive user processes. Kernel threads and system
                // daemons stay unmanaged by design.
                if (node.uid < 1000) continue;
                if (is_session_manager_comm(node.comm) ||
                    is_desktop_infra_comm(node.comm)) continue;
                if (observed_count >= kMaxObserved) continue;

                thm::Workload wl;
                wl.id               = next_workload_id++;
                wl.type             = thm::WorkloadType::NEUTRAL;
                wl.observed         = true;                    // telemetry only
                wl.is_reclassifiable = true;                   // may be promoted
                wl.root_pid         = pid;
                wl.root_cmdline     = node.cmdline.empty() ? node.comm : node.cmdline;
                wl.state            = thm::WorkloadState::DISCOVERED;
                wl.workspace_id     = ws_id;                   // HC-03: -2 if headless
                wl.created_at       = thm::ms_clock::now();
                wl.last_active      = thm::ms_clock::now();
                wl.pids.push_back(pid);
                ownership.assign(pid, wl.id);
                workload_mgr.add(std::move(wl));
                ++observed_count;
            }
        }

        // ── (d2) Process inventory for `titan-hwm scan` ─────────────────────
        int processes_unmanaged = 0;
        std::vector<thm::UnmanagedProc> top_unmanaged;
        for (auto& [pid, node] : proc_graph) {
            if (registry.is_protected(pid, node.comm)) continue;
            if (ownership.workload_of(pid) != 0) continue;
            ++processes_unmanaged;
            if (node.uid < 1000) continue;
            if (is_session_manager_comm(node.comm) ||
                is_desktop_infra_comm(node.comm)) continue;
            thm::UnmanagedProc u;
            u.pid     = pid;
            u.comm    = node.comm;
            u.cpu_pct = node.cpu_pct;
            u.rss_kb  = node.rss_kb;
            u.reason  = (observed_count >= kMaxObserved)
                            ? "observed-workload cap reached"
                            : "no classification signal";
            top_unmanaged.push_back(std::move(u));
        }
        std::sort(top_unmanaged.begin(), top_unmanaged.end(),
                  [](const thm::UnmanagedProc& a, const thm::UnmanagedProc& b) {
                      return a.cpu_pct > b.cpu_pct;
                  });
        if (top_unmanaged.size() > 10)
            top_unmanaged.resize(10);

        // ── (e) Detect execution state per process + aggregate ──────────────
        for (auto& [pid, node] : proc_graph) {
            auto& prev = prev_children[pid];
            detector.detect(node, prev);
            prev = node.children; // snapshot for next tick
        }

        // ── (f) Drive state machine + evaluate policy + enforce ─────────────
        // Build temporary registry snapshot for reclaim dependency check
        std::unordered_map<uint32_t, thm::Workload> all_workloads;
        for (uint32_t id : workload_mgr.all_ids()) {
            auto* wl = workload_mgr.get(id);
            if (wl) all_workloads[id] = *wl;
        }

        for (uint32_t id : workload_mgr.all_ids()) {
            auto* wl = workload_mgr.get(id);
            if (!wl || wl->state == thm::WorkloadState::TERMINATED) continue;

            // Find workspace state
            static const thm::WorkspaceState default_ws{};
            const thm::WorkspaceState* ws = &default_ws;
            auto ws_it = workspaces.find(wl->workspace_id);
            if (ws_it != workspaces.end()) ws = &ws_it->second;

            // Aggregate activity
            thm::ActivityState activity = detector.aggregate(*wl, proc_graph);

            // Drive state machine
            workload_mgr.tick(*wl, *ws, activity, pressure);

            // Observation-only workloads have no enforcement authority. Skip
            // the policy plane entirely: no cgroup moves, no signals, no
            // governor contribution. This is belt-and-braces on top of the
            // PolicyEngine guard.
            if (wl->observed)
                continue;

            // Evaluate policy
            thm::PolicyDecision decision = policy.evaluate(*wl, *ws, activity,
                                                            pressure, registry);

            // Enforce
            if (dry_run) {
                static const char* dec_names[] = {
                    "KEEP_FULL", "KEEP_BACKGROUND", "THROTTLE", "FREEZE", "RECLAIM"
                };
                int d_idx = static_cast<int>(decision);
                std::cout << "[DRY-RUN] Workload " << wl->id << " (" << wl->pids.size()
                          << " PIDs) -> Decision: " << (d_idx >= 0 && d_idx <= 4 ? dec_names[d_idx] : "UNKNOWN") << "\n";
            } else {
                auto record_action = [&](thm::PolicyDecision d) {
                    const std::string dec = thm::to_string(d);
                    const bool changed = (dec != last_action ||
                                          wl->root_cmdline != last_action_target);
                    last_action        = dec;
                    last_action_target = wl->root_cmdline;
                    last_action_pid    = wl->root_pid;
                    has_last_action    = true;

                    // Log transitions, not every tick of a sustained action.
                    if (changed) {
                        std::lock_guard<std::mutex> lk(snap_mutex);
                        std::ostringstream line;
                        line << wall_clock_hms()
                             << "  wl " << wl->id
                             << "  " << (wl->root_cmdline.empty() ? "?" : wl->root_cmdline)
                             << "  " << dec
                             << "  pressure=" << thm::to_string(pressure);
                        decision_log.push_back(line.str());
                        if (decision_log.size() > kMaxDecisionLog)
                            decision_log.pop_front();
                    }
                };

                if (decision == thm::PolicyDecision::RECLAIM) {
                    if (reclaimer.reclaim(*wl, proc_graph, all_workloads))
                        wl->state = thm::WorkloadState::TERMINATED;
                    record_action(decision);
                } else {
                    enforcement.apply(*wl, decision);
                    if (decision == thm::PolicyDecision::THROTTLE ||
                        decision == thm::PolicyDecision::FREEZE) {
                        record_action(decision);
                    }
                }
            }
        }

        // ── (g) Governor update ─────────────────────────────────────────────
        // Prune reclaimed/exited worklets so the registry stays bounded to live
        // processes (unbounded registry retention is a slow memory leak).
        workload_mgr.prune_dead();
        auto gov = thm::WorkspaceMonitor::compute_governor(all_workloads, pressure,
                                                           current_gov);
        current_gov = gov;
        if (!dry_run) {
            thm::WorkspaceMonitor::apply_governor(gov);
        }

        // ── (h) Clean up dead processes ─────────────────────────────────────
        std::vector<pid_t> dead;
        for (const auto& [pid, _] : prev_children) {
            if (!proc_graph.count(pid)) dead.push_back(pid);
        }
        for (pid_t pid : dead) {
            ownership.remove(pid);
            detector.remove_baseline(pid);
            prev_children.erase(pid);
        }

        // Drop exited members from each workload's pid list so it reflects the
        // current process set rather than every PID seen since discovery.
        std::unordered_set<pid_t> live_pids;
        live_pids.reserve(proc_graph.size());
        for (const auto& [pid, node] : proc_graph) {
            if (node.proc_state != 'Z') live_pids.insert(pid);
        }
        for (uint32_t wl_id : workload_mgr.all_ids()) {
            workload_mgr.prune_dead_pids(wl_id, live_pids);
        }

        // Evict worklets whose member processes have all exited (or were
        // reclaimed this tick) so the workload registry never outlives its
        // processes. ::kill(pid, 0) == 0 means the pid still exists — but a
        // zombie also answers 0, so consult the tick's proc_graph and treat
        // state 'Z' as exited. Without this a workload whose root is an
        // unreaped zombie is never evicted.
        std::vector<uint32_t> expired;
        for (uint32_t wl_id : workload_mgr.all_ids()) {
            auto* wl = workload_mgr.get(wl_id);
            if (!wl) continue;
            bool any_live = false;
            for (pid_t p : wl->pids) {
                if (p <= 1) continue;
                if (::kill(p, 0) != 0) continue;
                auto node = proc_graph.find(p);
                if (node != proc_graph.end() && node->second.proc_state == 'Z')
                    continue;
                any_live = true;
                break;
            }
            if (!any_live) expired.push_back(wl_id);
        }
        for (uint32_t wl_id : expired) {
            workload_mgr.remove(wl_id);
        }

        // ── (i) Publish telemetry snapshot ──────────────────────────────────
        {
            thm::TelemetrySnapshot snap;
            snap.timestamp_ms = std::chrono::duration_cast<std::chrono::milliseconds>(
                std::chrono::system_clock::now().time_since_epoch()).count();
            snap.uptime_seconds = std::chrono::duration_cast<std::chrono::seconds>(
                std::chrono::steady_clock::now() - start_time).count();
            snap.pressure_level  = thm::to_string(pressure);
            snap.psi_some_avg10  = psi.some_avg10;
            snap.psi_full_avg10  = psi.full_avg10;
            snap.mem_used_pct    = mem.used_pct();
            snap.mem_total_kb     = mem.total_kb;
            snap.mem_available_kb = mem.available_kb;
            snap.cpu_psi_valid  = cpu_psi.valid;
            snap.cpu_psi_avg10  = cpu_psi.some_avg10;
            snap.cpu_psi_avg60  = cpu_psi.some_avg60;
            snap.cpu_psi_avg300 = cpu_psi.some_avg300;
            snap.load1          = loadavg.load1;
            snap.load5          = loadavg.load5;
            snap.load15         = loadavg.load15;
            snap.runnable_procs = loadavg.running;
            snap.total_procs    = loadavg.total;

            snap.governor        = governor_to_string(current_gov);
            snap.workload_count  = static_cast<int>(workload_mgr.all_ids().size());
            snap.processes_seen      = processes_seen;
            snap.processes_protected = processes_protected;
            snap.processes_assigned  = processes_assigned;
            snap.processes_unmanaged = processes_unmanaged;
            snap.top_unmanaged       = top_unmanaged;
            snap.hyprland_connected  = ws_monitor.connected();
            snap.has_last_action    = has_last_action;
            snap.last_action        = last_action;
            snap.last_action_target = last_action_target;
            snap.last_action_pid    = last_action_pid;

            for (uint32_t id : workload_mgr.all_ids()) {
                auto* wl = workload_mgr.get(id);
                if (!wl || wl->state == thm::WorkloadState::TERMINATED) continue;

                thm::TelemetryWorkload tw;
                tw.id           = wl->id;
                tw.root_pid     = wl->root_pid;
                tw.workspace_id = wl->workspace_id;
                tw.name         = !wl->root_cmdline.empty()
                                      ? wl->root_cmdline
                                      : [&]() {
                                            auto it = proc_graph.find(wl->root_pid);
                                            return (it != proc_graph.end() && !it->second.comm.empty())
                                                       ? it->second.comm
                                                       : std::string("?");
                                        }();
                tw.type         = thm::to_string(wl->type);
                tw.state        = thm::to_string(wl->state);
                tw.pid_count    = static_cast<int>(wl->pids.size());
                tw.observed     = wl->observed;

                long  mem_kb  = 0;
                float cpu_pct = 0.0f;
                for (pid_t p : wl->pids) {
                    auto it = proc_graph.find(p);
                    if (it != proc_graph.end()) {
                        mem_kb  += it->second.rss_kb;
                        cpu_pct += it->second.cpu_pct;
                    }
                }
                tw.mem_kb  = mem_kb;
                tw.cpu_pct = cpu_pct;

                if (wl->observed) snap.observed_workloads++;
                else              snap.classified_workloads++;

                if (wl->state == thm::WorkloadState::ACTIVE ||
                    wl->state == thm::WorkloadState::BACKGROUND_EXECUTING)
                    snap.active_workloads++;

                snap.workloads.push_back(std::move(tw));
            }
            telemetry.publish(snap);

            // Publish the same snapshot to the command server so that
            // `titan-hwm status` reflects the live state.
            {
                std::lock_guard<std::mutex> lk(snap_mutex);
                shared_snap = snap;
            }
        }

        // ── Sleep remaining tick budget ─────────────────────────────────────
        auto elapsed = std::chrono::steady_clock::now() - tick_start;
        auto sleep_for = std::chrono::milliseconds(tick_ms) - elapsed;
        if (sleep_for.count() > 0)
            std::this_thread::sleep_for(sleep_for);
    }

    // ── Shutdown ────────────────────────────────────────────────────────────
    std::cout << "\n[THM] Shutdown initiated.\n";

    // Thaw all frozen processes before exiting
    if (!dry_run) {
        for (uint32_t id : workload_mgr.all_ids()) {
            auto* wl = workload_mgr.get(id);
            if (wl) enforcement.sigcont_tree(wl->pids);
        }
        cgroup.set_freeze(thm::SLICE_FROZEN, false);
    }

    ws_monitor.stop();
    cmd_server.stop();

    std::cout << "[THM] Clean shutdown complete.\n";
    return 0;
}
