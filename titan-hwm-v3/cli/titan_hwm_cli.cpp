// =============================================================================
// titan-hwm-v3/cli/titan_hwm_cli.cpp
//
// Titan Hardware Manager CLI — talks to the v3 daemon over its UNIX command
// socket. No external dependencies (no socat/nc/bash).
//
// Usage:
//   titan-hwm status     Query live daemon state (pressure, memory, workloads)
//   titan-hwm metrics    Live terminal telemetry dashboard (PSI + cgroups)
//
// NOTE: `switch <profile>` was a v1/v2 concept. THM v3 has no static workspace
// profiles — it classifies each workload individually — so the command was
// removed. `status` is answered by the daemon over /tmp/titan_hwm.sock.
// =============================================================================

#include <chrono>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <thread>

#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

static const char* SOCK_PATH = "/tmp/titan_hwm.sock";

static void print_usage() {
    std::cerr << "Titan Hardware Manager CLI\n\n"
              << "Usage: titan-hwm <command>\n\n"
              << "Commands:\n"
              << "  status    Show live daemon state (pressure, memory, workloads)\n"
              << "  metrics   Live telemetry dashboard (PSI, cgroups)\n";
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

// ── metrics: client-side /proc + /sys readers ────────────────────────────────
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

int main(int argc, char* argv[]) {
    if (argc < 2) {
        print_usage();
        return 1;
    }

    std::string cmd = argv[1];

    if (cmd == "metrics") {
        while (true) {
            show_metrics();
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }
        return 0;
    }

    if (cmd == "status") {
        std::string reply;
        if (!query_daemon("status", reply))
            return 1;
        std::cout << reply;
        return 0;
    }

    std::cerr << "titan-hwm: unknown command '" << cmd << "'\n\n";
    print_usage();
    return 1;
}
