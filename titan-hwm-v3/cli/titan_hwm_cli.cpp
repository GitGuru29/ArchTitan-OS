// =============================================================================
// titan-hwm-v3/cli/titan_hwm_cli.cpp
//
// Titan Hardware Manager CLI — talks to the v3 daemon over its UNIX command
// socket. No external dependencies (no socat/nc/bash).
//
// Usage:
//   titan-hwm status              Live daemon state (pressure, memory, workloads)
//   titan-hwm workloads [flags]   Every tracked workload (--classified/--observed)
//   titan-hwm top [N]             Top N workloads by CPU
//   titan-hwm pressure            Pressure signals + the rule that fired
//   titan-hwm scan                Process inventory: why is the count what it is?
//   titan-hwm explain <id|pid>    Full decision context for one workload
//   titan-hwm decisions [N]       Recent enforcement actions
//   titan-hwm slices              cgroup v2 slice state (CPU/memory/freeze)
//   titan-hwm doctor              Health checks (socket, telemetry, cgroups, IPC)
//   titan-hwm dump                Full telemetry JSON (bug reports)
//   titan-hwm metrics             Live terminal telemetry dashboard
//
// NOTE: `switch <profile>` was a v1/v2 concept. THM v3 has no static workspace
// profiles — it classifies each workload individually — so the command was
// removed. All commands are answered by the daemon over /tmp/titan_hwm.sock.
// =============================================================================

#include <chrono>
#include <cstring>
#include <dirent.h>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>
#include <vector>

#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

static const char* SOCK_PATH = "/tmp/titan_hwm.sock";

static void print_usage() {
    std::cerr << "Titan Hardware Manager CLI\n\n"
              << "Usage: titan-hwm <command> [args]\n\n"
              << "Commands:\n"
              << "  status                  Show live daemon state\n"
              << "  workloads [--classified|--observed]\n"
              << "                          List tracked workloads\n"
              << "  top [N]                 Top N workloads by CPU (default 10)\n"
              << "  pressure                Pressure signals + reason\n"
              << "  scan                    Process inventory / classification gaps\n"
              << "  explain <id|pid|name>   Explain one workload\n"
              << "  decisions [N]           Recent enforcement actions\n"
              << "  slices                  cgroup v2 slice state\n"
              << "  doctor                  Health checks\n"
              << "  dump                    Full telemetry JSON\n"
              << "  metrics                 Live telemetry dashboard\n";
}

// ── Daemon socket helpers ────────────────────────────────────────────────────
static bool daemon_connect(int& fd) {
    struct stat st{};
    if (stat(SOCK_PATH, &st) != 0 || !S_ISSOCK(st.st_mode)) {
        std::cerr << "titan-hwm: daemon socket not found at " << SOCK_PATH << "\n"
                  << "           Is titan-hwm running?  (systemctl status titan-hwm)\n";
        return false;
    }

    fd = socket(AF_UNIX, SOCK_STREAM, 0);
    if (fd < 0) {
        std::perror("titan-hwm: socket");
        return false;
    }

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, SOCK_PATH, sizeof(addr.sun_path) - 1);

    if (connect(fd, reinterpret_cast<struct sockaddr*>(&addr), sizeof(addr)) < 0) {
        std::perror("titan-hwm: connect");
        close(fd);
        fd = -1;
        return false;
    }
    return true;
}

static bool query_daemon(const std::string& cmd, std::string& reply) {
    int fd = -1;
    if (!daemon_connect(fd))
        return false;

    if (write(fd, cmd.c_str(), cmd.size()) < 0) {
        std::perror("titan-hwm: write");
        close(fd);
        return false;
    }

    char buf[4096];
    reply.clear();
    ssize_t n;
    while ((n = read(fd, buf, sizeof(buf))) > 0)
        reply.append(buf, static_cast<size_t>(n));
    close(fd);
    return true;
}

// Forward a command (plus any CLI arguments) to the daemon.
static int run_daemon_cmd(const std::string& cmd, const std::string& args = "") {
    std::string reply;
    const std::string full = args.empty() ? cmd : cmd + " " + args;
    if (!query_daemon(full, reply))
        return 1;
    std::cout << reply;
    return 0;
}

// ── metrics/doctor client-side /proc + /sys readers ──────────────────────────
struct PSI { float avg10 = 0, avg60 = 0, avg300 = 0; };

static PSI read_psi(const std::string& path, const std::string& prefix) {
    PSI p;
    std::ifstream f(path);
    std::string line;
    while (std::getline(f, line)) {
        if (line.rfind(prefix, 0) == 0) {
            auto extract = [&](const std::string& key, float& out) {
                auto pos = line.find(key + "=");
                if (pos != std::string::npos)
                    try { out = std::stof(line.substr(pos + key.size() + 1)); } catch (...) {}
            };
            extract("avg10", p.avg10);
            extract("avg60", p.avg60);
            extract("avg300", p.avg300);
        }
    }
    return p;
}

static std::string read_file(const std::string& path) {
    std::ifstream f(path);
    std::string s;
    if (f) f >> s;
    return s;
}

static std::string read_text(const std::string& path) {
    std::ifstream f(path);
    std::ostringstream ss;
    ss << f.rdbuf();
    return ss.str();
}

static long read_slice_mem_mb(const std::string& slice) {
    std::string val = read_file("/sys/fs/cgroup/archtitan.slice/" + slice + "/memory.current");
    try { return std::stol(val) / 1024 / 1024; } catch (...) { return 0; }
}

static void show_metrics() {
    std::cout << "\033[2J\033[H"; // clear + home
    std::cout << "\033[1;36m=== Titan Hardware Manager Telemetry ===\033[0m\n\n";

    PSI mem_some = read_psi("/proc/pressure/memory", "some");
    PSI mem_full = read_psi("/proc/pressure/memory", "full");
    PSI cpu_some = read_psi("/proc/pressure/cpu", "some");
    PSI io_some  = read_psi("/proc/pressure/io", "some");

    std::cout << "\033[1;33m[ Pressure Stall Information (PSI) - 10s avg ]\033[0m\n";
    std::cout << std::fixed << std::setprecision(2);
    std::cout << "  Memory (Some): " << mem_some.avg10 << "%\n";
    std::cout << "  Memory (Full): " << mem_full.avg10 << "%\n";
    std::cout << "  CPU    (Some): " << cpu_some.avg10 << "%\n";
    std::cout << "  I/O    (Some): " << io_some.avg10 << "%\n\n";

    std::cout << "\033[1;32m[ Cgroup v2 Slices - Memory ]\033[0m\n";
    std::cout << "  Active Slice:     " << read_slice_mem_mb("archtitan-active.slice") << " MB\n";
    std::cout << "  Background Slice: " << read_slice_mem_mb("archtitan-background.slice") << " MB\n";
    std::cout << "  Frozen Slice:     " << read_slice_mem_mb("archtitan-frozen.slice") << " MB\n\n";

    std::cout << "\033[1;35m[ Daemon State ]\033[0m\n";
    std::string reply;
    if (query_daemon("status", reply)) {
        std::cout << reply;
    } else {
        std::cout << "  Daemon offline (start titan-hwm.service)\n";
    }

    std::cout << "\n\033[90mPress Ctrl+C to exit...\033[0m\n";
    std::cout.flush();
}

// ── slices ───────────────────────────────────────────────────────────────────
static void show_slices() {
    struct SliceInfo { const char* name; const char* dir; };
    const SliceInfo slices[] = {
        {"active",     "archtitan-active.slice"},
        {"background", "archtitan-background.slice"},
        {"frozen",     "archtitan-frozen.slice"},
    };

    const std::string base = "/sys/fs/cgroup/archtitan.slice/";
    std::cout << std::left
              << std::setw(12) << "SLICE"
              << std::setw(12) << "CPU.WEIGHT"
              << std::setw(22) << "CPU.MAX"
              << std::right << std::setw(10) << "MEM"
              << std::setw(10) << "MEM.HIGH"
              << std::setw(8)  << "PIDS"
              << std::setw(8)  << "FROZEN"
              << "  POPULATED\n";
    std::cout << std::string(92, '-') << "\n";

    for (const auto& s : slices) {
        const std::string root = base + s.dir;
        struct stat st{};
        if (stat(root.c_str(), &st) != 0) {
            std::cout << std::left << std::setw(12) << s.name
                      << "  (missing)\n";
            continue;
        }
        auto mb = [&](const char* f) -> std::string {
            std::string v = read_file(root + "/" + f);
            try { return std::to_string(std::stoll(v) / 1024 / 1024) + "M"; }
            catch (...) { return "max"; }
        };
        std::string weight = read_file(root + "/cpu.weight");
        std::string cmax   = read_file(root + "/cpu.max");
        std::string mem    = mb("memory.current");
        std::string mhigh  = mb("memory.high");
        std::string pids   = read_file(root + "/pids.current");
        std::string frozen = read_file(root + "/cgroup.freeze");
        std::string pop    = read_file(root + "/cgroup.populated");

        std::cout << std::left << std::setw(12) << s.name
                  << std::setw(12) << (weight.empty() ? "?" : weight)
                  << std::setw(22) << (cmax.empty() ? "?" : cmax)
                  << std::right << std::setw(10) << mem
                  << std::setw(10) << mhigh
                  << std::setw(8)  << (pids.empty() ? "?" : pids)
                  << std::setw(8)  << (frozen.empty() ? "?" : frozen)
                  << "  " << (pop.empty() ? "?" : pop) << "\n";
    }

    std::string parent_max = read_file(base + "cpu.max");
    std::cout << "\nParent archtitan.slice cpu.max: "
              << (parent_max.empty() ? "unset (no CPU cap)" : parent_max) << "\n";
}

// ── doctor ───────────────────────────────────────────────────────────────────
static bool latest_telemetry_age_ms(const std::string& path, long long& age_ms) {
    const std::string body = read_text(path);
    if (body.empty()) return false;
    auto pos = body.find("\"timestamp_ms\":");
    if (pos == std::string::npos) return false;
    pos += std::strlen("\"timestamp_ms\":");
    long long ts = 0;
    try { ts = std::stoll(body.substr(pos)); } catch (...) { return false; }
    if (ts <= 0) return false;
    const long long now = std::chrono::duration_cast<std::chrono::milliseconds>(
        std::chrono::system_clock::now().time_since_epoch()).count();
    age_ms = now - ts;
    return true;
}

static int show_doctor() {
    int failures = 0;
    auto pass = [](const std::string& what) {
        std::cout << "  [PASS] " << what << "\n";
    };
    auto warn = [](const std::string& what) {
        std::cout << "  [WARN] " << what << "\n";
    };
    auto fail = [&](const std::string& what) {
        std::cout << "  [FAIL] " << what << "\n";
        ++failures;
    };

    std::cout << "Titan Hardware Manager — doctor\n\n";

    // 1. Daemon socket + ping.
    std::string pong;
    if (query_daemon("ping", pong) && pong.find("pong") != std::string::npos)
        pass("daemon socket reachable (" + std::string(SOCK_PATH) + ")");
    else
        fail("daemon socket unreachable — is titan-hwm.service running?");

    // 2. Telemetry freshness.
    const char* env = std::getenv("THM_TELEMETRY_PATH");
    std::string telem_path = (env && *env) ? env : "/run/archtitan/thm-state.json";
    long long age_ms = 0;
    if (latest_telemetry_age_ms(telem_path, age_ms)) {
        if (age_ms < 5000)
            pass("telemetry fresh (" + telem_path + ", " +
                 std::to_string(age_ms) + " ms old)");
        else
            warn("telemetry stale (" + telem_path + ", " +
                 std::to_string(age_ms) + " ms old)");
    } else {
        fail("telemetry missing or unparseable (" + telem_path + ")");
    }

    // 3. PSI availability.
    std::string missing;
    for (const char* p : {"/proc/pressure/memory", "/proc/pressure/cpu",
                          "/proc/pressure/io"}) {
        if (!std::ifstream(p).good()) missing += std::string(" ") + p;
    }
    if (missing.empty()) pass("PSI available (memory, cpu, io)");
    else                 warn("PSI partially unavailable:" + missing +
                              " (kernel < 4.20?)");

    // 4. cgroup v2 delegation + slices.
    std::string controllers = read_text("/sys/fs/cgroup/cgroup.controllers");
    if (controllers.empty()) {
        warn("cgroup v2 unified hierarchy not detected");
    } else {
        bool has_cpu = controllers.find("cpu") != std::string::npos;
        bool has_mem = controllers.find("memory") != std::string::npos;
        if (has_cpu && has_mem)
            pass("cgroup v2 controllers: cpu + memory");
        else
            warn("cgroup v2 controllers missing cpu or memory");
    }

    std::string subtree = read_text("/sys/fs/cgroup/archtitan.slice/cgroup.subtree_control");
    if (subtree.find("cpu") != std::string::npos &&
        subtree.find("memory") != std::string::npos)
        pass("archtitan.slice delegates cpu + memory");
    else
        warn("archtitan.slice delegation incomplete (cpu/memory)");

    for (const char* s : {"archtitan-active.slice",
                          "archtitan-background.slice",
                          "archtitan-frozen.slice"}) {
        struct stat st{};
        std::string p = std::string("/sys/fs/cgroup/archtitan.slice/") + s;
        if (stat(p.c_str(), &st) == 0) pass(std::string("slice present: ") + s);
        else                          fail(std::string("slice missing: ") + s);
    }

    // 5. Hyprland IPC — read the daemon's own connection state from telemetry.
    const std::string body = read_text(telem_path);
    if (body.find("\"hyprland_connected\":true") != std::string::npos) {
        pass("Hyprland IPC connected");
    } else if (body.find("\"hyprland_connected\":false") != std::string::npos) {
        warn("Hyprland IPC disconnected — window/workspace signals unavailable "
             "(listener retries automatically)");
    } else {
        // Fallback: look for a live socket2 in any user runtime dir.
        bool found = false;
        std::string rundir = "/run/user";
        if (DIR* d = opendir(rundir.c_str())) {
            while (dirent* e = readdir(d)) {
                if (e->d_name[0] == '.') continue;
                std::string hypr = rundir + "/" + e->d_name + "/hypr";
                if (DIR* h = opendir(hypr.c_str())) {
                    while (dirent* i = readdir(h)) {
                        if (i->d_name[0] == '.') continue;
                        std::string sock = hypr + "/" + i->d_name + "/.socket2.sock";
                        struct stat st{};
                        if (stat(sock.c_str(), &st) == 0) found = true;
                    }
                    closedir(h);
                }
            }
            closedir(d);
        }
        if (found) pass("Hyprland socket exists on disk");
        else       warn("no Hyprland socket found");
    }

    // 6. CPU governor visibility.
    std::string gov = read_file("/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor");
    if (!gov.empty()) pass("scaling_governor = " + gov);
    else              warn("no cpufreq scaling_governor (VM or unsupported CPU)");

    std::cout << "\n";
    if (failures == 0)
        std::cout << "Result: OK (warnings are informational)\n";
    else
        std::cout << "Result: " << failures << " failure(s)\n";
    return failures == 0 ? 0 : 1;
}

// ── pressure fallback (daemon offline) ───────────────────────────────────────
static void show_pressure_local() {
    PSI ms = read_psi("/proc/pressure/memory", "some");
    PSI mf = read_psi("/proc/pressure/memory", "full");
    PSI cs = read_psi("/proc/pressure/cpu", "some");
    PSI io = read_psi("/proc/pressure/io", "some");

    std::ifstream la("/proc/loadavg");
    std::string l1, l5, l15, run;
    la >> l1 >> l5 >> l15 >> run;

    std::cout << std::fixed << std::setprecision(2)
              << "Pressure level:  unavailable (daemon offline)\n"
              << "Memory PSI:      some " << ms.avg10 << "%  full "
              << mf.avg10 << "%  (avg10)\n"
              << "CPU PSI:         some " << cs.avg10 << "%  (avg10)\n"
              << "I/O PSI:         some " << io.avg10 << "%  (avg10)\n"
              << "Load average:    " << l1 << " " << l5 << " " << l15
              << "   (" << run << ")\n"
              << "Note:            CPU pressure is telemetry-only; it can never "
                 "produce RECLAIM (HC-CPU-1).\n";
}

int main(int argc, char* argv[]) {
    if (argc < 2) {
        print_usage();
        return 1;
    }

    std::string cmd = argv[1];

    // Build the argument tail (everything after the verb).
    std::string args;
    for (int i = 2; i < argc; ++i) {
        if (!args.empty()) args += ' ';
        args += argv[i];
    }

    if (cmd == "help" || cmd == "-h" || cmd == "--help") {
        print_usage();
        return 0;
    }

    if (cmd == "metrics") {
        while (true) {
            show_metrics();
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
        return 0;
    }

    if (cmd == "status")      return run_daemon_cmd("status");
    if (cmd == "workloads")   return run_daemon_cmd("workloads", args);
    if (cmd == "top")         return run_daemon_cmd("top", args);
    if (cmd == "scan")        return run_daemon_cmd("scan");
    if (cmd == "explain")     return run_daemon_cmd("explain", args);
    if (cmd == "decisions")   return run_daemon_cmd("decisions", args);
    if (cmd == "dump")        return run_daemon_cmd("dump");

    if (cmd == "pressure") {
        if (run_daemon_cmd("pressure") != 0) {
            show_pressure_local();
            return 1;
        }
        return 0;
    }

    if (cmd == "slices") {
        show_slices();
        return 0;
    }

    if (cmd == "doctor") {
        return show_doctor();
    }

    std::cerr << "titan-hwm: unknown command '" << cmd << "'\n\n";
    print_usage();
    return 1;
}
