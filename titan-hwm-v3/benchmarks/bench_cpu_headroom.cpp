// =============================================================================
// titan-hwm-v3/benchmarks/bench_cpu_headroom.cpp  (installed as titan-cpu-bench)
//
// Pure C++20 Empirical CPU Pressure & Asymmetric Scheduling Benchmark Suite
// (Zero Python — native Linux cgroup v2, POSIX timers, PSI, & THM v3.2 IPC)
//
// Architecture:
//   - Forks SEPARATE foreground probe (fg) and background saturation worker (bg)
//     processes communicating via MAP_SHARED anonymous memory so Linux cgroup v2
//     (cgroup.procs is per-process) applies genuine kernel CFS cpu.weight &
//     25 ms cpu.max bandwidth headroom between competing slices.
//   - Automatically provisions an isolated archtitan-bench-<pid> hierarchy
//     ({fg, bg}) under the root cgroup when privileged, or under the user's
//     delegated user@<uid>.service cgroup when unprivileged, tearing it down
//     cleanly on exit or SIGINT/SIGTERM. Falls back to nice(+19) simulation
//     only when no cgroup cpu controller is delegated (never misrepresenting
//     the active isolation mechanism).
//   - Measures BOTH wake-up oversleep latency AND calibrated foreground frame
//     completion time (144 Hz compositor 6.944 ms budget or 48 kHz/128-sample
//     2.667 ms audio DSP quantum), deadline misses, background throughput
//     retention, CPU PSI stall delta, and HC-CPU-1 zero-kill survival.
//
// Usage:
//   titan-cpu-bench [--compare|--baseline|--managed|--ramp|--live|--suite]
//                   [--profile interactive|audio|mixed]
//                   [--duration SEC] [--threads N] [--bg-procs P]
//                   [--work-us US] [--csv [FILE]] [--json FILE]
//                   [--markdown FILE] [--no-color]
// =============================================================================

#include "../enforcement/cgroup_controller.hpp"
#include "../resources/pressure_level.hpp"

#include <algorithm>
#include <array>
#include <atomic>
#include <chrono>
#include <cmath>
#include <csignal>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <numeric>
#include <sstream>
#include <string>
#include <sys/mman.h>
#include <sys/prctl.h>
#include <sys/resource.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <thread>
#include <time.h>
#include <unistd.h>
#include <vector>

namespace {

// =============================================================================
// Global Signal Handling
// =============================================================================
volatile sig_atomic_t g_interrupted = 0;

// v3.4: optional workload intent for the managed phase. Empty by default, so
// all existing A/B runs keep the classic fixed headroom.
thm::CpuDemandHint g_demand;

void handle_signal(int) {
    g_interrupted = 1;
}

// =============================================================================
// ANSI Styling Helper
// =============================================================================
struct Style {
    bool color = true;
    const char* reset()  const { return color ? "\033[0m"    : ""; }
    const char* bold()   const { return color ? "\033[1m"    : ""; }
    const char* dim()    const { return color ? "\033[2m"    : ""; }
    const char* cyan()   const { return color ? "\033[36m"   : ""; }
    const char* green()  const { return color ? "\033[32m"   : ""; }
    const char* yellow() const { return color ? "\033[33m"   : ""; }
    const char* red()    const { return color ? "\033[31m"   : ""; }
    const char* blue()   const { return color ? "\033[34m"   : ""; }
    const char* mag()    const { return color ? "\033[35m"   : ""; }
};

// =============================================================================
// Low-Level Time & System Telemetry Readers
// =============================================================================
int64_t now_mono_ns() {
    struct timespec ts {};
    ::clock_gettime(CLOCK_MONOTONIC, &ts);
    return static_cast<int64_t>(ts.tv_sec) * 1'000'000'000LL + ts.tv_nsec;
}

int64_t read_cpu_psi_total_us() {
    std::ifstream f("/proc/pressure/cpu");
    if (!f.is_open()) return 0;
    std::string line;
    while (std::getline(f, line)) {
        if (line.rfind("some ", 0) == 0) {
            auto pos = line.find("total=");
            if (pos != std::string::npos) {
                try { return std::stoll(line.substr(pos + 6)); } catch (...) {}
            }
        }
    }
    return 0;
}

char read_proc_state(pid_t pid) {
    std::ifstream f("/proc/" + std::to_string(pid) + "/stat");
    if (!f.is_open()) return '?';
    std::string line;
    std::getline(f, line);
    auto rparen = line.rfind(')');
    if (rparen == std::string::npos || rparen + 2 >= line.size()) return '?';
    return line[rparen + 2];
}

std::string read_file_trimmed(const std::string& path) {
    std::ifstream f(path);
    if (!f.is_open()) return "";
    std::string s;
    std::getline(f, s);
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r' || s.back() == ' '))
        s.pop_back();
    return s;
}

bool write_sysfs(const std::string& path, const std::string& val) {
    std::ofstream f(path);
    if (!f.is_open()) return false;
    f << val;
    f.flush();
    return f.good();
}

// Lightweight JSON value extractors for /run/archtitan/thm-state.json
struct LiveTelemetry {
    bool        valid               = false;
    bool        fresh               = false;
    std::string version;
    std::string mem_pressure        = "UNKNOWN";
    std::string cpu_pressure        = "UNKNOWN";
    std::string composite_pressure  = "UNKNOWN";
    std::string governor            = "UNKNOWN";
    double      cpu_psi_some        = 0.0;
    double      load_ratio          = 0.0;
    int         active_weight       = 0;
    int         background_weight   = 0;
    double      background_max_pct  = 100.0;
    bool        headroom_engaged    = false;
    bool        unattended_lift     = false;
    double      temp_c              = -1.0;
};

std::string extract_json_string(const std::string& blob, const std::string& key) {
    const std::string needle = "\"" + key + "\":\"";
    auto p = blob.find(needle);
    if (p == std::string::npos) return "";
    p += needle.size();
    auto e = blob.find('"', p);
    if (e == std::string::npos) return "";
    return blob.substr(p, e - p);
}

double extract_json_number(const std::string& blob, const std::string& key, double def = 0.0) {
    const std::string needle = "\"" + key + "\":";
    auto p = blob.find(needle);
    if (p == std::string::npos) return def;
    p += needle.size();
    while (p < blob.size() && (blob[p] == ' ' || blob[p] == '"')) ++p;
    char* end = nullptr;
    double v = std::strtod(blob.c_str() + p, &end);
    return (end != blob.c_str() + p) ? v : def;
}

bool extract_json_bool(const std::string& blob, const std::string& key, bool def = false) {
    const std::string needle = "\"" + key + "\":";
    auto p = blob.find(needle);
    if (p == std::string::npos) return def;
    p += needle.size();
    while (p < blob.size() && blob[p] == ' ') ++p;
    if (blob.compare(p, 4, "true") == 0) return true;
    if (blob.compare(p, 5, "false") == 0) return false;
    return def;
}

LiveTelemetry read_live_telemetry(const std::string& path = "/run/archtitan/thm-state.json") {
    LiveTelemetry t;
    struct stat st {};
    if (::stat(path.c_str(), &st) != 0) return t;
    const auto now_s = std::time(nullptr);
    t.fresh = (std::abs(now_s - st.st_mtime) <= 15);

    std::ifstream f(path);
    if (!f.is_open()) return t;
    std::ostringstream ss;
    ss << f.rdbuf();
    const std::string raw = ss.str();
    if (raw.empty()) return t;

    t.valid       = true;
    t.version     = extract_json_string(raw, "version");
    t.governor    = extract_json_string(raw, "governor");

    auto cpu_pos = raw.find("\"cpu\":{");
    if (cpu_pos != std::string::npos) {
        auto cpu_end = raw.find('}', cpu_pos);
        const std::string cpu_obj = (cpu_end != std::string::npos)
            ? raw.substr(cpu_pos, cpu_end - cpu_pos + 1)
            : raw.substr(cpu_pos);
        t.cpu_pressure       = extract_json_string(cpu_obj, "pressure");
        t.composite_pressure = extract_json_string(cpu_obj, "composite_pressure");
        t.cpu_psi_some       = extract_json_number(cpu_obj, "psi_some_avg10", 0.0);
        t.load_ratio         = extract_json_number(cpu_obj, "load_ratio", 0.0);
        t.active_weight      = static_cast<int>(extract_json_number(cpu_obj, "active_weight", 0));
        t.background_weight  = static_cast<int>(extract_json_number(cpu_obj, "background_weight", 0));
        t.background_max_pct = extract_json_number(cpu_obj, "background_cpu_max_pct", 100.0);
        t.headroom_engaged   = extract_json_bool(cpu_obj, "headroom_engaged", false);
        t.unattended_lift    = extract_json_bool(cpu_obj, "unattended_lift", false);
        t.temp_c             = extract_json_number(cpu_obj, "temp_c", -1.0);
    }
    auto p_pos = raw.find("\"pressure\":{");
    if (p_pos != std::string::npos) {
        auto p_end = raw.find('}', p_pos);
        const std::string p_obj = (p_end != std::string::npos)
            ? raw.substr(p_pos, p_end - p_pos + 1)
            : raw.substr(p_pos);
        t.mem_pressure = extract_json_string(p_obj, "level");
    }
    return t;
}

// =============================================================================
// Isolated cgroup v2 Harness (Real Kernel CFS cpu.weight + cpu.max)
// =============================================================================
class BenchCgroupEnv {
public:
    bool        available = false;
    std::string root_dir;
    std::string fg_dir;
    std::string bg_dir;
    std::string reason;

    bool init() {
        const std::string controllers = read_file_trimmed("/sys/fs/cgroup/cgroup.controllers");
        if (controllers.find("cpu") == std::string::npos) {
            reason = "cgroup v2 cpu controller unavailable";
            return false;
        }

        // Try the root first (when privileged), then the systemd user manager's
        // delegated subtree. Most desktop sessions have cpu delegated to
        // user@<uid>.service, which is enough for real cpu.weight/cpu.max A/B
        // testing without asking the operator for a root password.
        const std::string uid = std::to_string(::getuid());
        const std::vector<std::string> bases = {
            "/sys/fs/cgroup",
            "/sys/fs/cgroup/user.slice/user-" + uid + ".slice/user@" + uid + ".service",
        };

        for (const auto& base : bases) {
            root_dir = base + "/archtitan-bench-" + std::to_string(::getpid());
            fg_dir   = root_dir + "/fg";
            bg_dir   = root_dir + "/bg";

            if (::mkdir(root_dir.c_str(), 0755) != 0) {
                reason = "cannot create " + root_dir;
                continue;
            }
            if (!write_sysfs(root_dir + "/cgroup.subtree_control", "+cpu")) {
                reason = "cannot enable +cpu in " + root_dir;
                cleanup();
                continue;
            }
            if (::mkdir(fg_dir.c_str(), 0755) != 0 || ::mkdir(bg_dir.c_str(), 0755) != 0) {
                reason = "cannot create fg/bg child cgroups in " + root_dir;
                cleanup();
                continue;
            }
            // Verify write access to cpu.weight and cpu.max
            if (!write_sysfs(fg_dir + "/cpu.weight", "100") ||
                !write_sysfs(bg_dir + "/cpu.weight", "100") ||
                !write_sysfs(bg_dir + "/cpu.max", "max 25000")) {
                reason = "cgroup cpu.weight/cpu.max not writable in " + root_dir;
                cleanup();
                continue;
            }

            available = true;
            reason    = "kernel cgroup v2 (" + root_dir + ")";
            return true;
        }

        return false;
    }

    bool configure_baseline() const {
        if (!available) return false;
        bool ok = true;
        ok &= write_sysfs(fg_dir + "/cpu.weight", "100");
        ok &= write_sysfs(fg_dir + "/cpu.max", "max 100000");
        write_sysfs(fg_dir + "/cpu.max.burst", "0");
        ok &= write_sysfs(bg_dir + "/cpu.weight", "100");
        ok &= write_sysfs(bg_dir + "/cpu.max", "max 100000");
        write_sysfs(bg_dir + "/cpu.max.burst", "0");
        return ok;
    }

    struct CpuStat {
        int64_t usage_usec     = 0;
        int64_t nr_throttled   = 0;
        int64_t throttled_usec = 0;
    };

    static CpuStat read_cpu_stat(const std::string& dir) {
        CpuStat st;
        std::ifstream f(dir + "/cpu.stat");
        if (!f.is_open()) return st;
        std::string key;
        int64_t val = 0;
        while (f >> key >> val) {
            if (key == "usage_usec")          st.usage_usec = val;
            else if (key == "nr_throttled")   st.nr_throttled = val;
            else if (key == "throttled_usec") st.throttled_usec = val;
        }
        return st;
    }

    CpuStat read_bg_stat() const { return available ? read_cpu_stat(bg_dir) : CpuStat{}; }
    CpuStat read_fg_stat() const { return available ? read_cpu_stat(fg_dir) : CpuStat{}; }

    bool configure_managed(const thm::CpuSlicePolicy& policy, int fg_weight_override = -1) const {
        if (!available) return false;
        const int fg_w = (fg_weight_override > 0) ? fg_weight_override : policy.active_weight;
        bool ok = true;
        ok &= write_sysfs(fg_dir + "/cpu.weight", std::to_string(fg_w));
        ok &= write_sysfs(fg_dir + "/cpu.max", "max " + std::to_string(policy.period_us));
        write_sysfs(fg_dir + "/cpu.max.burst", "0");
        ok &= write_sysfs(bg_dir + "/cpu.weight", std::to_string(policy.background_weight));
        const long burst_us = (policy.background_quota_us > 0)
            ? std::min(policy.background_quota_us, policy.period_us / 5)
            : 0L;
        write_sysfs(bg_dir + "/cpu.max.burst", std::to_string(burst_us));
        const std::string max_str = (policy.background_quota_us > 0)
            ? (std::to_string(policy.background_quota_us) + " " + std::to_string(policy.period_us))
            : ("max " + std::to_string(policy.period_us));
        ok &= write_sysfs(bg_dir + "/cpu.max", max_str);
        return ok;
    }

    bool move_fg(pid_t pid) const {
        return available && write_sysfs(fg_dir + "/cgroup.procs", std::to_string(pid));
    }

    bool move_bg(pid_t pid) const {
        return available && write_sysfs(bg_dir + "/cgroup.procs", std::to_string(pid));
    }

    void cleanup() {
        if (!bg_dir.empty())   ::rmdir(bg_dir.c_str());
        if (!fg_dir.empty())   ::rmdir(fg_dir.c_str());
        if (!root_dir.empty()) ::rmdir(root_dir.c_str());
        available = false;
    }

    ~BenchCgroupEnv() { cleanup(); }
};

// =============================================================================
// Shared Memory IPC Layout (Zero-Copy across Forked FG + BG Processes)
// =============================================================================
constexpr uint32_t kMaxSamples = 65536;
constexpr int      kMaxBgProcs = 32;

struct SharedBenchState {
    std::atomic<int>      go{0};
    std::atomic<int>      stop{0};
    std::atomic<uint32_t> sample_count{0};
    std::atomic<uint64_t> bg_iters[kMaxBgProcs];
    std::atomic<uint64_t> fg_work_done{0};
    std::atomic<int>      fg_ready{0};
    std::atomic<int>      bg_ready_count{0};

    double wakeup_ms[kMaxSamples];
    double frame_ms[kMaxSamples];
};

static_assert(std::atomic<int>::is_always_lock_free, "atomic<int> must be lock-free for mmap IPC");
static_assert(std::atomic<uint64_t>::is_always_lock_free, "atomic<uint64_t> must be lock-free for mmap IPC");

// =============================================================================
// Workload Kernels & Foreground Work Calibration
// =============================================================================
enum class Profile { INTERACTIVE, AUDIO, MIXED };

std::string profile_name(Profile p) {
    switch (p) {
        case Profile::INTERACTIVE: return "interactive";
        case Profile::AUDIO:       return "audio";
        case Profile::MIXED:       return "mixed";
    }
    return "interactive";
}

// Deterministic interactive compositor / UI render micro-kernel
inline uint64_t run_interactive_work(uint64_t iters) {
    volatile uint64_t s = 0x123456789abcdef0ULL;
    for (uint64_t i = 0; i < iters; ++i) {
        uint64_t x = s + 0x9e3779b97f4a7c15ULL;
        x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ULL;
        x = (x ^ (x >> 27)) * 0x94d049bb133111ebULL;
        s = x ^ (x >> 31);
    }
    return s;
}

// Deterministic stereo float32 biquad DSP filter loop (simulates PipeWire/JACK audio)
inline float run_audio_dsp_work(uint64_t iters) {
    volatile float x1 = 0.25f, x2 = -0.15f, y1 = 0.0f, y2 = 0.0f;
    const float b0 = 0.067455f, b1 = 0.13491f, b2 = 0.067455f;
    const float a1 = -1.14298f, a2 = 0.41280f;
    for (uint64_t i = 0; i < iters; ++i) {
        float in  = (i & 1) ? 0.5f : -0.5f;
        float out = b0 * in + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2;
        x2 = x1; x1 = in;
        y2 = y1; y1 = out;
    }
    return y1;
}

// Calibrate exact iteration count for target_us on an uncontended core
uint64_t calibrate_fg_work(Profile profile, int target_us) {
    if (target_us <= 0) return 0;
    const uint64_t probe_iters = 50'000;
    // Warmup
    if (profile == Profile::AUDIO) (void)run_audio_dsp_work(probe_iters);
    else                           (void)run_interactive_work(probe_iters);

    const int64_t t0 = now_mono_ns();
    if (profile == Profile::AUDIO) (void)run_audio_dsp_work(probe_iters * 4);
    else                           (void)run_interactive_work(probe_iters * 4);
    const int64_t dt_ns = std::max<int64_t>(1, now_mono_ns() - t0);

    const double ns_per_iter = static_cast<double>(dt_ns) / static_cast<double>(probe_iters * 4);
    const double needed      = (static_cast<double>(target_us) * 1000.0) / std::max(0.1, ns_per_iter);
    return std::max<uint64_t>(100, static_cast<uint64_t>(needed));
}

// Background saturation worker body (runs inside forked child process)
void run_bg_worker_process(SharedBenchState* shm, int proc_idx, int threads, Profile profile,
                           bool nice_fallback) {
    ::prctl(PR_SET_PDEATHSIG, SIGKILL);
    if (nice_fallback) {
        (void)::setpriority(PRIO_PROCESS, 0, 19);
    }

    std::atomic<uint64_t> proc_iters{0};
    std::vector<std::thread> pool;
    pool.reserve(static_cast<size_t>(threads));
    std::atomic<int> local_ready{0};

    for (int t = 0; t < threads; ++t) {
        pool.emplace_back([&, t]() {
            // Optional 4 MB L3 cache-thrash buffer for MIXED profile
            std::vector<uint64_t> mem_buf;
            const bool is_mem_worker   = (profile == Profile::MIXED) && ((t % 4) == 2);
            const bool is_burst_worker = (profile == Profile::MIXED) && ((t % 4) == 3);
            if (is_mem_worker) {
                mem_buf.resize(524288, static_cast<uint64_t>(t + 1)); // 4 MiB
            }

            local_ready.fetch_add(1, std::memory_order_release);
            while (shm->go.load(std::memory_order_acquire) == 0 &&
                   shm->stop.load(std::memory_order_relaxed) == 0) {
                std::this_thread::yield();
            }

            volatile uint64_t acc = static_cast<uint64_t>(proc_idx * 97 + t * 31 + 1);
            uint64_t local_iters = 0;
            size_t mem_idx = 0;

            while (shm->stop.load(std::memory_order_relaxed) == 0) {
                if (is_mem_worker) {
                    // Cache-line stride (64 bytes = 8 uint64_t)
                    for (int k = 0; k < 64; ++k) {
                        mem_idx = (mem_idx + 8) & (mem_buf.size() - 1);
                        mem_buf[mem_idx] = (mem_buf[mem_idx] ^ acc) + 0x9e3779b97f4a7c15ULL;
                        acc = mem_buf[mem_idx];
                    }
                    local_iters += 64;
                } else if (is_burst_worker) {
                    // Short intense compile-like burst + tiny yield simulating fork/IO churn
                    for (int k = 0; k < 2048; ++k) {
                        uint64_t x = acc + 0x9e3779b97f4a7c15ULL;
                        x ^= (x >> 30);
                        x *= 0xbf58476d1ce4e5b9ULL;
                        acc = x;
                    }
                    local_iters += 2048;
                    if ((local_iters & 0x7ffffULL) == 0) {
                        ::usleep(200);
                    }
                } else {
                    for (int k = 0; k < 256; ++k) {
                        uint64_t x = acc + 0x9e3779b97f4a7c15ULL;
                        x ^= (x >> 30);
                        x *= 0xbf58476d1ce4e5b9ULL;
                        acc = x;
                    }
                    local_iters += 256;
                }
            }
            proc_iters.fetch_add(local_iters, std::memory_order_relaxed);
        });
    }

    while (local_ready.load(std::memory_order_acquire) < threads &&
           shm->stop.load(std::memory_order_relaxed) == 0) {
        ::usleep(500);
    }
    shm->bg_ready_count.fetch_add(1, std::memory_order_release);

    for (auto& th : pool) th.join();
    shm->bg_iters[proc_idx].store(proc_iters.load(std::memory_order_relaxed), std::memory_order_release);
    ::_exit(0);
}

// Foreground interactive/audio probe process body
void run_fg_probe_process(SharedBenchState* shm, Profile profile, int64_t period_ns,
                          uint64_t work_iters, int duration_s) {
    ::prctl(PR_SET_PDEATHSIG, SIGKILL);
    shm->fg_ready.store(1, std::memory_order_release);

    while (shm->go.load(std::memory_order_acquire) == 0 &&
           shm->stop.load(std::memory_order_relaxed) == 0) {
        ::usleep(500);
    }

    const int64_t start_ns = now_mono_ns();
    const int64_t end_ns   = start_ns + static_cast<int64_t>(duration_s) * 1'000'000'000LL;
    int64_t next_tick      = start_ns + period_ns;
    uint64_t sink          = 0;

    while (shm->stop.load(std::memory_order_relaxed) == 0) {
        const int64_t now_before = now_mono_ns();
        if (now_before >= end_ns) break;

        struct timespec req {
            static_cast<time_t>(next_tick / 1'000'000'000LL),
            static_cast<long>(next_tick % 1'000'000'000LL)
        };
        ::clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &req, nullptr);
        const int64_t woke_ns = now_mono_ns();

        if (work_iters > 0) {
            if (profile == Profile::AUDIO) sink += static_cast<uint64_t>(run_audio_dsp_work(work_iters) * 1000.0f);
            else                           sink += run_interactive_work(work_iters);
        }
        const int64_t done_ns = now_mono_ns();

        const uint32_t idx = shm->sample_count.load(std::memory_order_relaxed);
        if (idx < kMaxSamples) {
            shm->wakeup_ms[idx] = std::max(0.0, static_cast<double>(woke_ns - next_tick) / 1'000'000.0);
            shm->frame_ms[idx]  = std::max(0.0, static_cast<double>(done_ns - next_tick) / 1'000'000.0);
            shm->sample_count.store(idx + 1, std::memory_order_release);
        }

        next_tick += period_ns;
        if (done_ns > next_tick) {
            // Re-sync cleanly after a missed frame without burst-catching up
            next_tick = done_ns + period_ns;
        }
    }

    shm->fg_work_done.store(sink, std::memory_order_release);
    ::_exit(0);
}

// =============================================================================
// Statistics & Run Result Structure
// =============================================================================
struct LatencyStats {
    double p50   = 0.0;
    double p90   = 0.0;
    double p95   = 0.0;
    double p99   = 0.0;
    double p999  = 0.0;
    double max   = 0.0;
    double mean  = 0.0;
};

double percentile(const std::vector<double>& sorted, double p) {
    if (sorted.empty()) return 0.0;
    const double idx = p * static_cast<double>(sorted.size() - 1);
    const size_t lo  = static_cast<size_t>(std::floor(idx));
    const size_t hi  = static_cast<size_t>(std::ceil(idx));
    const double t   = idx - static_cast<double>(lo);
    return sorted[lo] * (1.0 - t) + sorted[hi] * t;
}

LatencyStats compute_stats(std::vector<double> vals) {
    LatencyStats st;
    if (vals.empty()) return st;
    std::sort(vals.begin(), vals.end());
    st.p50  = percentile(vals, 0.50);
    st.p90  = percentile(vals, 0.90);
    st.p95  = percentile(vals, 0.95);
    st.p99  = percentile(vals, 0.99);
    st.p999 = percentile(vals, 0.999);
    st.max  = vals.back();
    st.mean = std::accumulate(vals.begin(), vals.end(), 0.0) / static_cast<double>(vals.size());
    return st;
}

constexpr size_t kHistBuckets = 8;
constexpr std::array<double, kHistBuckets - 1> kHistEdges = {
    0.1, 0.5, 1.0, 2.0, 4.0, 6.944, 16.667
};
constexpr std::array<const char*, kHistBuckets> kHistLabels = {
    "< 0.1 ms    ",
    "0.1 - 0.5 ms",
    "0.5 - 1.0 ms",
    "1.0 - 2.0 ms",
    "2.0 - 4.0 ms",
    "4.0 - 6.9 ms",
    "6.9 -16.7 ms",
    "> 16.7 ms   "
};

struct PhaseResult {
    std::string  mode;
    std::string  profile;
    std::string  isolation;
    int          online_cpus          = 1;
    int          bg_threads           = 1;
    int          bg_procs             = 1;
    double       elapsed_s            = 0.0;
    double       budget_ms            = 6.944;
    uint32_t     samples              = 0;
    uint32_t     expected_samples     = 0;

    LatencyStats wakeup;
    LatencyStats frame;
    uint32_t     budget_misses        = 0; // > budget_ms (144Hz or Audio xrun)
    uint32_t     severe_misses_60hz   = 0; // > 16.667 ms (60Hz frame drop)

    std::array<uint32_t, kHistBuckets> frame_hist{};

    double       throughput_mops      = 0.0;
    int64_t      psi_delta_us         = 0;
    double       post_psi_avg10       = 0.0;
    double       post_load1           = 0.0;
    float        peak_temp_c          = -1.0f;

    int          workers_spawned      = 0;
    int          workers_survived     = 0;
    int          workers_stopped_seen = 0; // HC-CPU-1 check: must stay 0

    // Applied cgroup policy snapshot & kernel cpu.stat proof
    int          fg_weight            = 100;
    int          bg_weight            = 100;
    double       bg_max_pct           = 100.0;
    long         bg_quota_us          = 0;
    long         period_us            = 100000;
    double       bg_cpu_cores         = 0.0;
    int64_t      bg_nr_throttled      = 0;
    double       bg_throttled_ms      = 0.0;
};

// =============================================================================
// Core Phase Executor (Baseline or Managed)
// =============================================================================
PhaseResult run_benchmark_phase(const std::string& mode,
                                Profile profile,
                                int duration_s,
                                int total_bg_threads,
                                int bg_procs,
                                uint64_t fg_work_iters,
                                BenchCgroupEnv& cg) {
    PhaseResult res;
    res.mode        = mode;
    res.profile     = profile_name(profile);
    res.online_cpus = thm::read_online_cpus();
    res.bg_procs    = std::clamp(bg_procs, 1, std::min(kMaxBgProcs, total_bg_threads));
    res.bg_threads  = total_bg_threads;

    const bool is_weights_only = (mode == "weights-only");
    const bool is_managed      = (mode == "managed" || is_weights_only);
    const int64_t period_ns = (profile == Profile::AUDIO) ? 2'666'667LL : 6'944'444LL;
    res.budget_ms           = static_cast<double>(period_ns) / 1'000'000.0;
    res.expected_samples    = static_cast<uint32_t>(
        (static_cast<double>(duration_s) * 1e9) / static_cast<double>(period_ns));

    // Compute exact production THM v3.2 policy for HIGH CPU pressure
    thm::CpuSlicePolicy policy = thm::compute_cpu_slice_policy(
        thm::PressureLevel::HIGH, res.online_cpus, false, &g_demand);
    if (is_weights_only) {
        policy.background_quota_us = 0;
        policy.background_max_pct  = 100.0f;
        policy.headroom_engaged    = false;
    }

    bool use_nice_fallback = false;
    int  effective_bg_threads = total_bg_threads;

    if (cg.available) {
        if (is_managed) {
            // Audio daemons (PipeWire/JACK) run in archtitan-protected.slice (weight 2000/5000);
            // interactive desktop apps/compositor run in archtitan-active.slice (weight 1000).
            const int target_fg_weight = (profile == Profile::AUDIO)
                ? policy.protected_weight
                : policy.active_weight;
            cg.configure_managed(policy, target_fg_weight);
            res.fg_weight  = target_fg_weight;
            res.bg_weight  = policy.background_weight;
            res.bg_max_pct = policy.background_max_pct;
            res.bg_quota_us = policy.background_quota_us;
            res.period_us  = policy.period_us;
            res.isolation  = "cgroup-v2";
        } else {
            cg.configure_baseline();
            res.fg_weight  = 100;
            res.bg_weight  = 100;
            res.bg_max_pct = 100.0;
            res.bg_quota_us = 0;
            res.period_us  = 100000;
            res.isolation  = "cgroup-v2";
        }
    } else {
        res.isolation = is_managed ? "nice+19-fallback" : "unprivileged-cfs";
        if (is_managed) {
            use_nice_fallback = true;
            res.fg_weight  = 1024;
            res.bg_weight  = 15;
            res.bg_max_pct = policy.background_max_pct;
            // In unprivileged mode without cpu.max, cap threads to N-1 to approximate headroom
            effective_bg_threads = std::max(1, std::min(total_bg_threads, std::max(1, res.online_cpus - 1)));
        }
    }

    void* mem = ::mmap(nullptr, sizeof(SharedBenchState),
                       PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    if (mem == MAP_FAILED) {
        std::cerr << "[ERROR] mmap failed for SharedBenchState\n";
        return res;
    }
    auto* shm = new (mem) SharedBenchState();
    for (int i = 0; i < kMaxBgProcs; ++i) shm->bg_iters[i].store(0);

    // Fork background worker processes
    std::vector<pid_t> bg_pids;
    bg_pids.reserve(static_cast<size_t>(res.bg_procs));
    const int base_t = effective_bg_threads / res.bg_procs;
    const int rem_t  = effective_bg_threads % res.bg_procs;

    for (int p = 0; p < res.bg_procs; ++p) {
        const int t_for_p = std::max(1, base_t + (p < rem_t ? 1 : 0));
        pid_t pid = ::fork();
        if (pid == 0) {
            run_bg_worker_process(shm, p, t_for_p, profile, use_nice_fallback);
        } else if (pid > 0) {
            bg_pids.push_back(pid);
            if (cg.available) cg.move_bg(pid);
        }
    }
    res.workers_spawned = static_cast<int>(bg_pids.size());

    // Fork foreground interactive/audio probe process.
    // In Baseline (vanilla flat Linux), FG and BG share the SAME flat cgroup
    // (like stock user.slice -> 1:2N contention). In Managed / Weights-Only,
    // FG is isolated into its dedicated high-weight active/protected cgroup.
    pid_t fg_pid = ::fork();
    if (fg_pid == 0) {
        run_fg_probe_process(shm, profile, period_ns, fg_work_iters, duration_s);
    } else if (fg_pid > 0 && cg.available) {
        if (is_managed) cg.move_fg(fg_pid);
        else            cg.move_bg(fg_pid);
    }

    // Wait for all forked workers + fg probe to finish initialization
    const int64_t wait_start = now_mono_ns();
    while ((shm->fg_ready.load(std::memory_order_acquire) == 0 ||
            shm->bg_ready_count.load(std::memory_order_acquire) < res.workers_spawned) &&
           (now_mono_ns() - wait_start < 3'000'000'000LL) && !g_interrupted) {
        ::usleep(1000);
    }

    const auto    bg_stat_start  = cg.read_bg_stat();
    const int64_t psi_start_us   = read_cpu_psi_total_us();
    const int64_t bench_start_ns = now_mono_ns();
    shm->go.store(1, std::memory_order_release);

    // Monitor loop: verify HC-CPU-1 survival & track thermal peak while FG runs
    int fg_status = 0;
    while (!g_interrupted) {
        pid_t r = ::waitpid(fg_pid, &fg_status, WNOHANG);
        if (r == fg_pid || r < 0) break;

        for (pid_t bp : bg_pids) {
            const char st = read_proc_state(bp);
            if (st == 'T' || st == 't') {
                res.workers_stopped_seen++;
            }
        }
        const float tc = thm::read_cpu_temp_c();
        if (tc > res.peak_temp_c) res.peak_temp_c = tc;

        ::usleep(100'000); // 100 ms supervisor cadence
    }

    // Verify every BG worker is STILL ALIVE right before signaling clean stop (HC-CPU-1)
    int alive_before_stop = 0;
    for (pid_t bp : bg_pids) {
        if (::kill(bp, 0) == 0) {
            const char st = read_proc_state(bp);
            if (st != 'Z' && st != 'X' && st != '?') {
                alive_before_stop++;
            }
        }
    }
    res.workers_survived = alive_before_stop;

    // Signal clean stop and reap all children
    shm->stop.store(1, std::memory_order_release);
    if (::waitpid(fg_pid, &fg_status, WNOHANG) == 0) {
        ::usleep(50'000);
        if (::waitpid(fg_pid, &fg_status, WNOHANG) == 0) {
            ::kill(fg_pid, SIGKILL);
            ::waitpid(fg_pid, &fg_status, 0);
        }
    }

    const int64_t reap_deadline = now_mono_ns() + 1'000'000'000LL;
    for (pid_t bp : bg_pids) {
        int st = 0;
        while (::waitpid(bp, &st, WNOHANG) == 0 && now_mono_ns() < reap_deadline) {
            ::usleep(5000);
        }
        if (::waitpid(bp, &st, WNOHANG) == 0) {
            ::kill(bp, SIGKILL);
            ::waitpid(bp, &st, 0);
        }
    }

    const auto    bg_stat_end = cg.read_bg_stat();
    const int64_t psi_end_us  = read_cpu_psi_total_us();
    res.elapsed_s             = static_cast<double>(now_mono_ns() - bench_start_ns) / 1e9;
    res.psi_delta_us          = std::max<int64_t>(0, psi_end_us - psi_start_us);
    if (cg.available) {
        const int64_t usage_us = std::max<int64_t>(0, bg_stat_end.usage_usec - bg_stat_start.usage_usec);
        res.bg_cpu_cores       = static_cast<double>(usage_us) / (std::max(0.01, res.elapsed_s) * 1e6);
        res.bg_nr_throttled    = std::max<int64_t>(0, bg_stat_end.nr_throttled - bg_stat_start.nr_throttled);
        res.bg_throttled_ms    = static_cast<double>(std::max<int64_t>(0, bg_stat_end.throttled_usec - bg_stat_start.throttled_usec)) / 1000.0;
    }

    uint64_t total_iters = 0;
    for (int p = 0; p < res.bg_procs; ++p) {
        total_iters += shm->bg_iters[p].load(std::memory_order_acquire);
    }
    res.throughput_mops = (static_cast<double>(total_iters) / 1e6) / std::max(0.01, res.elapsed_s);

    const uint32_t n = std::min(kMaxSamples, shm->sample_count.load(std::memory_order_acquire));
    res.samples = n;
    std::vector<double> w_vals(n), f_vals(n);
    for (uint32_t i = 0; i < n; ++i) {
        w_vals[i] = shm->wakeup_ms[i];
        f_vals[i] = shm->frame_ms[i];
        if (f_vals[i] > res.budget_ms) res.budget_misses++;
        if (f_vals[i] > 16.667)        res.severe_misses_60hz++;

        size_t b = kHistBuckets - 1;
        for (size_t e = 0; e < kHistEdges.size(); ++e) {
            if (f_vals[i] < kHistEdges[e]) { b = e; break; }
        }
        res.frame_hist[b]++;
    }

    res.wakeup         = compute_stats(std::move(w_vals));
    res.frame          = compute_stats(std::move(f_vals));
    res.post_psi_avg10 = thm::read_cpu_psi().some_avg10;
    res.post_load1     = thm::read_loadavg().load1;

    ::munmap(mem, sizeof(SharedBenchState));
    return res;
}

// =============================================================================
// Step-Load Ramp & Hysteresis Verifier (--ramp)
// =============================================================================
struct RampResult {
    bool   ran                     = false;
    bool   climb_observed          = false;
    bool   hysteresis_held         = false;
    bool   hc_cpu1_all_survived    = true;
    double peak_psi_avg10          = 0.0;
    double peak_load_ratio         = 0.0;
    thm::PressureLevel peak_level  = thm::PressureLevel::NORMAL;
    int    ticks_sampled           = 0;
};

RampResult run_pressure_ramp(int stage_sec, const Style& st) {
    RampResult rr;
    rr.ran = true;
    const int ncpu = thm::read_online_cpus();
    const int half = std::max(1, ncpu / 2);

    struct Stage {
        const char* name;
        int         threads;
    };
    const std::array<Stage, 5> stages = {{
        {"CALM (0T)",       0},
        {"WARMUP (N/2)",    half},
        {"STORM (2xN)",     ncpu * 2},
        {"COOLDOWN (N/2)",  half},
        {"RECOVERY (0T)",   0},
    }};

    thm::CpuPressureController ctrl(/*release_ticks_required=*/10);

    std::cout << "\n" << st.bold() << st.cyan()
              << "═══════════════════════════════════════════════════════════════════════════════\n"
              << "  STAGE RAMP & HYSTERESIS VERIFICATION  (" << ncpu << " logical CPUs, "
              << stage_sec << "s/stage)\n"
              << "═══════════════════════════════════════════════════════════════════════════════"
              << st.reset() << "\n";
    std::cout << std::left
              << std::setw(15) << "Stage"
              << std::setw(8)  << "RunQ"
              << std::setw(9)  << "InstPSI"
              << std::setw(9)  << "PSI_10%"
              << std::setw(8)  << "Load1/N"
              << std::setw(10) << "HystLvl"
              << std::setw(11) << "BG cpu.max"
              << "HC-CPU-1\n";
    std::cout << std::string(79, '-') << "\n";

    thm::PressureLevel prev_hyst = thm::PressureLevel::NORMAL;
    int storm_high_ticks = 0;

    for (const auto& stage : stages) {
        if (g_interrupted) break;

        // Spawn a forked burner process for this stage if threads > 0
        void* mem = ::mmap(nullptr, sizeof(SharedBenchState),
                           PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
        auto* shm = new (mem) SharedBenchState();
        pid_t burner = -1;
        if (stage.threads > 0) {
            burner = ::fork();
            if (burner == 0) {
                run_bg_worker_process(shm, 0, stage.threads, Profile::MIXED, false);
            }
            shm->go.store(1, std::memory_order_release);
        }

        const int ticks = std::max(2, stage_sec * 5); // 200 ms cadence = THM daemon tick rate
        double stage_psi = 0.0, stage_lr = 0.0, stage_runq = 0.0, stage_inst_psi = 0.0;
        thm::PressureLevel stage_raw = thm::PressureLevel::NORMAL;
        thm::PressureLevel stage_hyst = thm::PressureLevel::NORMAL;
        int64_t prev_psi_us = read_cpu_psi_total_us();
        int64_t prev_ts_ns  = now_mono_ns();

        for (int t = 0; t < ticks && !g_interrupted; ++t) {
            ::usleep(200'000);
            const int64_t cur_ts_ns  = now_mono_ns();
            const int64_t cur_psi_us = read_cpu_psi_total_us();
            const double wall_us     = std::max(1.0, static_cast<double>(cur_ts_ns - prev_ts_ns) / 1000.0);
            const double inst_psi    = std::clamp(100.0 * static_cast<double>(std::max<int64_t>(0, cur_psi_us - prev_psi_us)) / wall_us, 0.0, 100.0);
            prev_ts_ns  = cur_ts_ns;
            prev_psi_us = cur_psi_us;

            const auto mem     = thm::read_meminfo();
            const auto mem_psi = thm::read_memory_psi();
            const auto psi     = thm::read_cpu_psi();
            const auto la      = thm::read_loadavg();
            const double lr    = la.load1 / static_cast<double>(std::max(1, ncpu));
            const double rq    = static_cast<double>(la.running) / static_cast<double>(std::max(1, ncpu));

            stage_raw      = thm::compute_cpu_pressure_raw(psi, la, ncpu,
                                                           static_cast<float>(inst_psi));
            stage_hyst     = ctrl.evaluate(mem, mem_psi, psi, la, ncpu,
                                           static_cast<long long>(wall_us)).cpu;
            stage_psi      = psi.some_avg10;
            stage_lr       = lr;
            stage_runq     = std::max(stage_runq, rq);
            stage_inst_psi = std::max(stage_inst_psi, inst_psi);
            rr.ticks_sampled++;

            if (stage_psi > rr.peak_psi_avg10)   rr.peak_psi_avg10  = stage_psi;
            if (stage_lr  > rr.peak_load_ratio)  rr.peak_load_ratio = stage_lr;
            if (static_cast<int>(stage_hyst) > static_cast<int>(rr.peak_level))
                rr.peak_level = stage_hyst;

            if (stage.threads >= ncpu * 2 && (stage_hyst >= thm::PressureLevel::MODERATE || inst_psi >= 30.0)) {
                storm_high_ticks++;
            }
            // Hysteresis hold check: raw dropped below prev_hyst, yet controller held level
            if (static_cast<int>(stage_raw) < static_cast<int>(prev_hyst) &&
                static_cast<int>(stage_hyst) == static_cast<int>(prev_hyst)) {
                rr.hysteresis_held = true;
            }
            prev_hyst = stage_hyst;

            // Verify burner never stopped or killed
            if (burner > 0) {
                const char ps = read_proc_state(burner);
                if (::kill(burner, 0) != 0 || ps == 'T' || ps == 't' || ps == 'Z') {
                    rr.hc_cpu1_all_survived = false;
                }
            }
        }

        const auto pol = thm::compute_cpu_slice_policy(stage_hyst, ncpu, false);
        std::ostringstream max_s;
        if (pol.headroom_engaged) {
            max_s << std::fixed << std::setprecision(1) << pol.background_max_pct << "%";
        } else {
            max_s << "max(100%)";
        }

        std::cout << std::left
                  << std::setw(15) << stage.name
                  << std::setw(8)  << (std::ostringstream() << std::fixed << std::setprecision(2) << stage_runq).str()
                  << std::setw(9)  << (std::ostringstream() << std::fixed << std::setprecision(1) << stage_inst_psi << "%").str()
                  << std::setw(9)  << (std::ostringstream() << std::fixed << std::setprecision(1) << stage_psi << "%").str()
                  << std::setw(8)  << (std::ostringstream() << std::fixed << std::setprecision(2) << stage_lr).str()
                  << std::setw(10) << thm::to_string(stage_hyst)
                  << std::setw(11) << max_s.str()
                  << (rr.hc_cpu1_all_survived ? (std::string(st.green()) + "OK" + st.reset())
                                              : (std::string(st.red())   + "VIOLATED" + st.reset()))
                  << "\n";

        if (burner > 0) {
            shm->stop.store(1, std::memory_order_release);
            int status = 0;
            const int64_t dl = now_mono_ns() + 800'000'000LL;
            while (::waitpid(burner, &status, WNOHANG) == 0 && now_mono_ns() < dl) ::usleep(5000);
            if (::waitpid(burner, &status, WNOHANG) == 0) {
                ::kill(burner, SIGKILL);
                ::waitpid(burner, &status, 0);
            }
        }
        ::munmap(mem, sizeof(SharedBenchState));
    }

    rr.climb_observed = (storm_high_ticks > 0 || rr.peak_psi_avg10 >= 5.0 || rr.peak_load_ratio >= 0.70);
    return rr;
}

// =============================================================================
// Live Daemon Integration Test (--live)
// =============================================================================
struct LiveCheckResult {
    bool        daemon_active      = false;
    bool        schema_v32         = false;
    bool        hc_cpu1_survived   = true;
    bool        headroom_observed  = false;
    std::string initial_level;
    std::string peak_level;
    std::string live_bg_cpu_max;
    std::string live_bg_cpu_weight;
    double      peak_psi           = 0.0;
    double      peak_temp_c        = -1.0;
};

LiveCheckResult run_live_daemon_check(int duration_s, int threads, const Style& st) {
    LiveCheckResult lr;
    const auto t0 = read_live_telemetry();
    if (!t0.valid || !t0.fresh) {
        std::cout << "\n" << st.yellow()
                  << "[LIVE CHECK] titan-hwm-daemon is not active on this host "
                     "(/run/archtitan/thm-state.json missing or stale) — skipping live daemon test."
                  << st.reset() << "\n";
        return lr;
    }

    lr.daemon_active = true;
    lr.schema_v32    = (t0.version.rfind("3.2", 0) == 0);
    lr.initial_level = t0.cpu_pressure;
    lr.peak_level    = t0.cpu_pressure;

    std::cout << "\n" << st.bold() << st.cyan()
              << "═══════════════════════════════════════════════════════════════════════════════\n"
              << "  LIVE titan-hwm-daemon v" << t0.version << " INTEGRATION TEST ("
              << duration_s << "s, " << threads << " threads)\n"
              << "═══════════════════════════════════════════════════════════════════════════════"
              << st.reset() << "\n";

    void* mem = ::mmap(nullptr, sizeof(SharedBenchState),
                       PROT_READ | PROT_WRITE, MAP_SHARED | MAP_ANONYMOUS, -1, 0);
    auto* shm = new (mem) SharedBenchState();

    pid_t worker = ::fork();
    if (worker == 0) {
        run_bg_worker_process(shm, 0, threads, Profile::MIXED, false);
    }
    shm->go.store(1, std::memory_order_release);

    auto rank_level = [](const std::string& s) {
        if (s == "CRITICAL") return 3;
        if (s == "HIGH")     return 2;
        if (s == "MODERATE") return 1;
        return 0;
    };

    std::cout << std::left
              << std::setw(7)  << "Time"
              << std::setw(9)  << "PSI_10%"
              << std::setw(9)  << "Load/N"
              << std::setw(11) << "CPU_Lvl"
              << std::setw(10) << "A:B Wt"
              << std::setw(16) << "BG cpu.max"
              << std::setw(10) << "Headroom"
              << "Worker\n"
              << std::string(79, '-') << "\n";

    const int steps = std::max(2, duration_s * 2);
    for (int i = 0; i < steps && !g_interrupted; ++i) {
        ::usleep(500'000);
        const auto t = read_live_telemetry();
        const char ps = read_proc_state(worker);
        if (::kill(worker, 0) != 0 || ps == 'T' || ps == 't' || ps == 'Z') {
            lr.hc_cpu1_survived = false;
        }
        lr.live_bg_cpu_max    = read_file_trimmed("/sys/fs/cgroup/archtitan.slice/archtitan-background.slice/cpu.max");
        lr.live_bg_cpu_weight = read_file_trimmed("/sys/fs/cgroup/archtitan.slice/archtitan-background.slice/cpu.weight");
        if (t.valid) {
            if (rank_level(t.cpu_pressure) > rank_level(lr.peak_level)) lr.peak_level = t.cpu_pressure;
            if (t.cpu_psi_some > lr.peak_psi) lr.peak_psi = t.cpu_psi_some;
            if (t.temp_c > lr.peak_temp_c)    lr.peak_temp_c = t.temp_c;
            if (t.headroom_engaged)           lr.headroom_observed = true;

            if ((i + 1) % 4 == 0 || i == steps - 1) {
                std::cout << std::left
                          << std::setw(7)  << (std::to_string((i + 1) / 2) + "s")
                          << std::setw(9)  << (std::ostringstream() << std::fixed << std::setprecision(1) << t.cpu_psi_some << "%").str()
                          << std::setw(9)  << (std::ostringstream() << std::fixed << std::setprecision(2) << t.load_ratio).str()
                          << std::setw(11) << t.cpu_pressure
                          << std::setw(10) << (std::to_string(t.active_weight) + ":" + std::to_string(t.background_weight))
                          << std::setw(16) << (lr.live_bg_cpu_max.empty() ? "n/a" : lr.live_bg_cpu_max)
                          << std::setw(10) << (t.headroom_engaged ? "ENGAGED" : (t.unattended_lift ? "LIFTED" : "off"))
                          << ps << "\n";
            }
        }
    }

    shm->stop.store(1, std::memory_order_release);
    int status = 0;
    const int64_t dl = now_mono_ns() + 800'000'000LL;
    while (::waitpid(worker, &status, WNOHANG) == 0 && now_mono_ns() < dl) ::usleep(5000);
    if (::waitpid(worker, &status, WNOHANG) == 0) {
        ::kill(worker, SIGKILL);
        ::waitpid(worker, &status, 0);
    }
    ::munmap(mem, sizeof(SharedBenchState));

    std::cout << "  Schema Version      : " << t0.version << (lr.schema_v32 ? " (v3.2 OK)" : " (mismatch)") << "\n"
              << "  CPU Pressure Shift  : " << lr.initial_level << " -> " << lr.peak_level
              << "  (peak PSI=" << std::fixed << std::setprecision(2) << lr.peak_psi << "%)\n"
              << "  Headroom Engaged    : " << (lr.headroom_observed ? "YES" : "no") << "\n"
              << "  Live BG cgroup      : weight=" << (lr.live_bg_cpu_weight.empty() ? "n/a" : lr.live_bg_cpu_weight)
              << "  cpu.max=" << (lr.live_bg_cpu_max.empty() ? "n/a" : lr.live_bg_cpu_max) << "\n"
              << "  HC-CPU-1 Survival   : " << (lr.hc_cpu1_survived ? "PASS (worker never killed/stopped)" : "FAIL") << "\n";
    return lr;
}

// =============================================================================
// Reporting: Terminal Dashboard, Side-by-Side Histogram, CSV, JSON, Markdown
// =============================================================================
void print_single_phase(const PhaseResult& r, const Style& st) {
    const double miss_pct = r.samples > 0 ? (100.0 * r.budget_misses / r.samples) : 0.0;
    std::cout << "\n" << st.bold() << st.cyan()
              << "┌─────────────────────────────────────────────────────────────────────────────┐\n"
              << "│  MODE: " << std::left << std::setw(10) << r.mode
              << "  PROFILE: " << std::setw(12) << r.profile
              << "  BACKEND: " << std::setw(26) << r.isolation << "│\n"
              << "└─────────────────────────────────────────────────────────────────────────────┘"
              << st.reset() << "\n";
    std::cout << "  Topology          : " << r.online_cpus << " CPUs | " << r.bg_threads
              << " BG threads across " << r.bg_procs << " forked proc(s) | "
              << std::fixed << std::setprecision(2) << r.elapsed_s << " s (" << r.samples << " frames)\n";
    std::cout << "  Slice Policy      : FG weight=" << r.fg_weight << " | BG weight=" << r.bg_weight
              << " | BG cpu.max=" << std::setprecision(1) << r.bg_max_pct << "% (period "
              << (r.period_us / 1000.0) << " ms)\n";
    std::cout << std::setprecision(3)
              << "  Wake-up Jitter    : p50=" << r.wakeup.p50 << " ms | p95=" << r.wakeup.p95
              << " ms | p99=" << r.wakeup.p99 << " ms | max=" << r.wakeup.max << " ms\n"
              << "  Frame Completion  : p50=" << r.frame.p50 << " ms | p95=" << r.frame.p95
              << " ms | p99=" << r.frame.p99 << " ms | max=" << r.frame.max << " ms\n"
              << "  Deadline Misses   : " << r.budget_misses << " / " << r.samples
              << " (" << std::setprecision(2) << miss_pct << "% > " << std::setprecision(2)
              << r.budget_ms << " ms) | 60Hz drops (>16.7ms): " << r.severe_misses_60hz << "\n"
              << "  BG Throughput     : " << std::setprecision(2) << r.throughput_mops << " M ops/s\n"
              << "  CPU PSI Delta     : " << r.psi_delta_us << " us (post avg10="
              << r.post_psi_avg10 << "%, load1=" << r.post_load1 << ")\n"
              << "  HC-CPU-1 Survival : " << r.workers_survived << "/" << r.workers_spawned
              << " alive, " << r.workers_stopped_seen << " stopped\n";
}

void print_comparison(const PhaseResult& base, const PhaseResult& mng, const Style& st) {
    auto fmt_delta = [&](double b, double m, bool lower_is_better) -> std::string {
        if (b <= 1e-6 && m <= 1e-6) return "0.0%";
        const double pct = (b > 1e-6) ? ((m - b) / b) * 100.0 : 0.0;
        std::ostringstream os;
        os << std::showpos << std::fixed << std::setprecision(1) << pct << "%";
        if (lower_is_better && m > 1e-6 && b > m * 1.15) {
            os << " (" << std::noshowpos << std::setprecision(2) << (b / m) << "x faster)";
        }
        return os.str();
    };

    const double base_miss_pct = base.samples ? (100.0 * base.budget_misses / base.samples) : 0.0;
    const double mng_miss_pct  = mng.samples  ? (100.0 * mng.budget_misses  / mng.samples)  : 0.0;
    const double retain_pct    = base.throughput_mops > 1e-6
        ? (100.0 * mng.throughput_mops / base.throughput_mops) : 100.0;

    std::cout << "\n" << st.bold() << st.cyan()
              << "═══════════════════════════════════════════════════════════════════════════════\n"
              << "  A/B EMPIRICAL COMPARISON  —  Profile: " << base.profile
              << "  (" << base.isolation << " -> " << mng.isolation << ")\n"
              << "═══════════════════════════════════════════════════════════════════════════════"
              << st.reset() << "\n";

    std::cout << std::left
              << std::setw(30) << "Metric"
              << std::setw(15) << "Baseline CFS"
              << std::setw(15) << "THM v3.2 Mng"
              << "Delta / Gain\n"
              << std::string(79, '-') << "\n";

    auto row = [&](const std::string& label, const std::string& b, const std::string& m,
                   const std::string& d, const char* color = "") {
        std::cout << std::left << std::setw(30) << label
                  << std::setw(15) << b
                  << std::setw(15) << m
                  << color << d << st.reset() << "\n";
    };

    auto ms = [](double v) {
        std::ostringstream os;
        os << std::fixed << std::setprecision(3) << v << " ms";
        return os.str();
    };

    row("Slice Weights (FG : BG)",
        std::to_string(base.fg_weight) + " : " + std::to_string(base.bg_weight),
        std::to_string(mng.fg_weight)  + " : " + std::to_string(mng.bg_weight),
        "Asymmetric priority", st.cyan());
    row("BG Bandwidth Cap (cpu.max)",
        "max (100%)",
        (std::ostringstream() << std::fixed << std::setprecision(1) << mng.bg_max_pct
                              << (mng.isolation == "cgroup-v2" ? "% @ 25ms" : "% (N-1 sim)")).str(),
        mng.isolation == "cgroup-v2" ? "1-core FG headroom" : "1-core sim (no cgroup)", st.cyan());
    row("Wake-up Jitter p50",  ms(base.wakeup.p50),  ms(mng.wakeup.p50),
        fmt_delta(base.wakeup.p50, mng.wakeup.p50, true),
        mng.wakeup.p50 <= base.wakeup.p50 ? st.green() : st.yellow());
    row("Wake-up Jitter p95",  ms(base.wakeup.p95),  ms(mng.wakeup.p95),
        fmt_delta(base.wakeup.p95, mng.wakeup.p95, true),
        mng.wakeup.p95 <= base.wakeup.p95 ? st.green() : st.yellow());
    row("Wake-up Jitter p99",  ms(base.wakeup.p99),  ms(mng.wakeup.p99),
        fmt_delta(base.wakeup.p99, mng.wakeup.p99, true),
        mng.wakeup.p99 <= base.wakeup.p99 ? st.green() : st.red());
    row("Frame Completion p95", ms(base.frame.p95),  ms(mng.frame.p95),
        fmt_delta(base.frame.p95, mng.frame.p95, true),
        mng.frame.p95 <= base.frame.p95 ? st.green() : st.yellow());
    row("Frame Completion p99", ms(base.frame.p99),  ms(mng.frame.p99),
        fmt_delta(base.frame.p99, mng.frame.p99, true),
        mng.frame.p99 <= base.frame.p99 ? st.green() : st.red());
    row("Frame Completion Max", ms(base.frame.max),  ms(mng.frame.max),
        fmt_delta(base.frame.max, mng.frame.max, true),
        mng.frame.max <= base.frame.max ? st.green() : st.yellow());

    {
        std::ostringstream b_s, m_s;
        b_s << base.budget_misses << " (" << std::fixed << std::setprecision(1) << base_miss_pct << "%)";
        m_s << mng.budget_misses  << " (" << std::fixed << std::setprecision(1) << mng_miss_pct  << "%)";
        row("Deadline Misses (>" + (std::ostringstream() << std::fixed << std::setprecision(1) << base.budget_ms).str() + "ms)",
            b_s.str(), m_s.str(),
            fmt_delta(base.budget_misses, mng.budget_misses, true),
            mng.budget_misses <= base.budget_misses ? st.green() : st.red());
    }
    row("Severe Drops (>16.7ms)",
        std::to_string(base.severe_misses_60hz),
        std::to_string(mng.severe_misses_60hz),
        fmt_delta(base.severe_misses_60hz, mng.severe_misses_60hz, true),
        mng.severe_misses_60hz <= base.severe_misses_60hz ? st.green() : st.red());
    {
        std::ostringstream b_t, m_t, r_t;
        b_t << std::fixed << std::setprecision(1) << base.throughput_mops << " M/s";
        m_t << std::fixed << std::setprecision(1) << mng.throughput_mops  << " M/s";
        r_t << std::fixed << std::setprecision(1) << retain_pct << "% retained";
        row("BG Compute Throughput", b_t.str(), m_t.str(), r_t.str(),
            retain_pct >= 50.0 ? st.green() : st.yellow());
    }
    row("CPU PSI Stall Delta",
        std::to_string(base.psi_delta_us) + " us",
        std::to_string(mng.psi_delta_us)  + " us",
        fmt_delta(static_cast<double>(base.psi_delta_us), static_cast<double>(mng.psi_delta_us), true));
    if (base.isolation == "cgroup-v2" && mng.isolation == "cgroup-v2") {
        std::ostringstream bc, mc, rc, bt, mt;
        bc << std::fixed << std::setprecision(2) << base.bg_cpu_cores << " / " << base.online_cpus;
        mc << std::fixed << std::setprecision(2) << mng.bg_cpu_cores  << " / " << mng.online_cpus;
        const double freed = std::max(0.0, static_cast<double>(mng.online_cpus) - mng.bg_cpu_cores);
        rc << std::fixed << std::setprecision(2) << freed << " cores reserved";
        row("BG CPU Usage (cpu.stat)", bc.str(), mc.str(), rc.str(), st.cyan());

        bt << base.bg_nr_throttled << " (" << std::fixed << std::setprecision(0) << base.bg_throttled_ms << "ms)";
        mt << mng.bg_nr_throttled  << " (" << std::fixed << std::setprecision(0) << mng.bg_throttled_ms  << "ms)";
        row("CFS Throttle (cpu.stat)", bt.str(), mt.str(),
            mng.bg_nr_throttled > 0 ? "cpu.max kernel active" : "not throttled",
            mng.bg_nr_throttled > 0 ? st.green() : st.yellow());
    }
    row("HC-CPU-1 Worker Survival",
        std::to_string(base.workers_survived) + "/" + std::to_string(base.workers_spawned),
        std::to_string(mng.workers_survived)  + "/" + std::to_string(mng.workers_spawned),
        (mng.workers_survived == mng.workers_spawned && mng.workers_stopped_seen == 0) ? "100% (0 killed/stopped)" : "VIOLATED",
        (mng.workers_survived == mng.workers_spawned && mng.workers_stopped_seen == 0) ? st.green() : st.red());

    // Side-by-side ASCII Latency Distribution Histogram
    std::cout << "\n" << st.bold() << "  Frame Latency Distribution  "
              << st.yellow() << "[█ Baseline]" << st.reset() << "  vs  "
              << st.green()  << "[▓ THM v3.2 Managed]" << st.reset() << "\n";
    constexpr int kBarWidth = 24;
    for (size_t i = 0; i < kHistBuckets; ++i) {
        const double bp = base.samples ? (100.0 * base.frame_hist[i] / base.samples) : 0.0;
        const double mp = mng.samples  ? (100.0 * mng.frame_hist[i]  / mng.samples)  : 0.0;
        const int blen  = std::clamp(static_cast<int>(std::round(bp * kBarWidth / 100.0)), 0, kBarWidth);
        const int mlen  = std::clamp(static_cast<int>(std::round(mp * kBarWidth / 100.0)), 0, kBarWidth);

        std::string bbar, mbar;
        for (int k = 0; k < blen; ++k) bbar += "█";
        for (int k = blen; k < kBarWidth; ++k) bbar += " ";
        for (int k = 0; k < mlen; ++k) mbar += "▓";
        for (int k = mlen; k < kBarWidth; ++k) mbar += " ";

        std::cout << "  " << kHistLabels[i] << " │ "
                  << st.yellow() << bbar << st.reset()
                  << std::right << std::setw(5) << std::fixed << std::setprecision(1) << bp << "% │ "
                  << st.green()  << mbar << st.reset()
                  << std::right << std::setw(5) << std::fixed << std::setprecision(1) << mp << "%\n";
    }
}

void write_csv_rows(std::ostream& os, const std::vector<PhaseResult>& results) {
    os << "mode,profile,isolation,cpus,threads,bg_procs,duration_s,samples,"
       << "wakeup_p50_ms,wakeup_p95_ms,wakeup_p99_ms,wakeup_max_ms,"
       << "frame_p50_ms,frame_p95_ms,frame_p99_ms,frame_max_ms,"
       << "budget_ms,budget_misses,severe_60hz_drops,throughput_Mops_s,"
       << "psi_delta_us,cpu_psi_avg10,load1,fg_weight,bg_weight,bg_max_pct,"
       << "workers_survived,workers_spawned,workers_stopped_seen\n";
    for (const auto& r : results) {
        os << r.mode << "," << r.profile << "," << r.isolation << ","
           << r.online_cpus << "," << r.bg_threads << "," << r.bg_procs << ","
           << std::fixed << std::setprecision(2) << r.elapsed_s << "," << r.samples << ","
           << std::setprecision(3)
           << r.wakeup.p50 << "," << r.wakeup.p95 << "," << r.wakeup.p99 << "," << r.wakeup.max << ","
           << r.frame.p50  << "," << r.frame.p95  << "," << r.frame.p99  << "," << r.frame.max  << ","
           << r.budget_ms  << "," << r.budget_misses << "," << r.severe_misses_60hz << ","
           << std::setprecision(2) << r.throughput_mops << ","
           << r.psi_delta_us << "," << r.post_psi_avg10 << "," << r.post_load1 << ","
           << r.fg_weight << "," << r.bg_weight << "," << std::setprecision(1) << r.bg_max_pct << ","
           << r.workers_survived << "," << r.workers_spawned << "," << r.workers_stopped_seen << "\n";
    }
}

void write_json_report(const std::string& path, const std::vector<PhaseResult>& results,
                       const std::vector<std::pair<std::string, bool>>& assertions) {
    std::ofstream os(path);
    if (!os.is_open()) return;
    os << "{\n  \"tool\": \"titan-cpu-bench\",\n  \"results\": [\n";
    for (size_t i = 0; i < results.size(); ++i) {
        const auto& r = results[i];
        os << "    {\n"
           << "      \"mode\": \"" << r.mode << "\",\n"
           << "      \"profile\": \"" << r.profile << "\",\n"
           << "      \"isolation\": \"" << r.isolation << "\",\n"
           << "      \"online_cpus\": " << r.online_cpus << ",\n"
           << "      \"bg_threads\": " << r.bg_threads << ",\n"
           << "      \"elapsed_s\": " << std::fixed << std::setprecision(3) << r.elapsed_s << ",\n"
           << "      \"samples\": " << r.samples << ",\n"
           << "      \"wakeup_ms\": {\"p50\": " << r.wakeup.p50 << ", \"p95\": " << r.wakeup.p95
           << ", \"p99\": " << r.wakeup.p99 << ", \"max\": " << r.wakeup.max << "},\n"
           << "      \"frame_ms\": {\"p50\": " << r.frame.p50 << ", \"p95\": " << r.frame.p95
           << ", \"p99\": " << r.frame.p99 << ", \"max\": " << r.frame.max << "},\n"
           << "      \"budget_ms\": " << r.budget_ms << ",\n"
           << "      \"budget_misses\": " << r.budget_misses << ",\n"
           << "      \"severe_60hz_drops\": " << r.severe_misses_60hz << ",\n"
           << "      \"throughput_mops_s\": " << std::setprecision(2) << r.throughput_mops << ",\n"
           << "      \"psi_delta_us\": " << r.psi_delta_us << ",\n"
           << "      \"hc_cpu1_survived\": " << (r.workers_survived == r.workers_spawned && r.workers_stopped_seen == 0 ? "true" : "false") << "\n"
           << "    }" << (i + 1 < results.size() ? "," : "") << "\n";
    }
    os << "  ],\n  \"assertions\": [\n";
    for (size_t i = 0; i < assertions.size(); ++i) {
        os << "    {\"name\": \"" << assertions[i].first << "\", \"pass\": "
           << (assertions[i].second ? "true" : "false") << "}"
           << (i + 1 < assertions.size() ? "," : "") << "\n";
    }
    os << "  ]\n}\n";
}

void write_markdown_report(const std::string& path, const std::vector<PhaseResult>& results,
                           const std::vector<std::pair<std::string, bool>>& assertions) {
    std::ofstream os(path);
    if (!os.is_open()) return;
    os << "# ArchTitan THM v3.2 CPU Pressure Benchmark Report\n\n";
    os << "| Mode | Profile | Isolation | Wake p50 | Wake p99 | Frame p99 | Budget Misses | Throughput | PSI Delta | HC-CPU-1 |\n";
    os << "| :--- | :--- | :--- | ---: | ---: | ---: | ---: | ---: | ---: | :--- |\n";
    for (const auto& r : results) {
        os << "| " << r.mode << " | " << r.profile << " | " << r.isolation
           << " | " << std::fixed << std::setprecision(3) << r.wakeup.p50 << " ms"
           << " | " << r.wakeup.p99 << " ms"
           << " | " << r.frame.p99 << " ms"
           << " | " << r.budget_misses << "/" << r.samples
           << " | " << std::setprecision(1) << r.throughput_mops << " M/s"
           << " | " << r.psi_delta_us << " us"
           << " | " << (r.workers_survived == r.workers_spawned && r.workers_stopped_seen == 0 ? "PASS" : "FAIL")
           << " |\n";
    }
    os << "\n## Verification Assertions\n\n";
    for (const auto& [name, ok] : assertions) {
        os << "- [" << (ok ? "x" : " ") << "] **" << name << "**: " << (ok ? "PASS" : "FAIL") << "\n";
    }
}

void print_usage(const char* argv0) {
    std::cout
        << "ArchTitan THM v3.2 CPU Pressure & Asymmetric Scheduling Benchmark Tester\n\n"
        << "Usage: " << argv0 << " [OPTIONS]\n\n"
        << "Modes:\n"
        << "  --compare            A/B comparison: Baseline Flat CFS vs THM v3.2 Managed (default)\n"
        << "  --ablation           3-way ablation: Baseline Flat vs Weights-Only vs Full Weights+cpu.max\n"
        << "  --baseline           Run Baseline Flat CFS only\n"
        << "  --weights-only       Run THM Asymmetric Weights only (no cpu.max cap)\n"
        << "  --managed            Run THM v3.2 Managed only (weights + 25ms cpu.max headroom)\n"
        << "  --ramp               Step-load ramp (0 -> N/2 -> 2N -> N/2 -> 0) hysteresis check\n"
        << "  --live               Verify live running titan-hwm-daemon under real saturation\n"
        << "  --suite              Full suite: Interactive A/B + Audio DSP A/B + Ramp + Live check\n\n"
        << "Options:\n"
        << "  --profile <name>     interactive (144Hz, default), audio (48kHz/128), mixed (ALU+L3+burst)\n"
        << "  --duration <sec>     Duration per phase in seconds (default: 4)\n"
        << "  --threads <N>        Background saturation threads (default: 2 * online_cpus)\n"
        << "  --bg-procs <P>       Number of forked background worker processes (default: 2)\n"
        << "  --work-us <us>       Foreground simulated CPU work per tick in us (default: auto)\n"
        << "  --adaptive <kind>    Managed-phase demand hint: none|game|train|both (default: none)\n"
        << "  --csv [file]         Output CSV (stdout if no file, or write to file)\n"
        << "  --json <file>        Write JSON report to file\n"
        << "  --markdown <file>    Write Markdown report to file\n"
        << "  --no-color           Disable ANSI terminal colors\n"
        << "  -h, --help           Show this help\n";
}

} // namespace

// =============================================================================
// Main Entrypoint
// =============================================================================
int main(int argc, char* argv[]) {
    std::signal(SIGINT,  handle_signal);
    std::signal(SIGTERM, handle_signal);

    const int ncpu   = thm::read_online_cpus();
    int duration_s   = 4;
    int threads      = std::max(2, ncpu * 2); // 2x oversubscription exposes true CFS contention
    int bg_procs     = 2;
    int work_us      = -1; // auto by profile
    std::string mode = "compare";
    Profile profile  = Profile::INTERACTIVE;

    bool csv_stdout  = false;
    std::string csv_file;
    std::string json_file;
    std::string md_file;

    Style st;
    st.color = (::isatty(STDOUT_FILENO) == 1);

    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "-h" || a == "--help") {
            print_usage(argv[0]);
            return 0;
        } else if (a == "--compare") {
            mode = "compare";
        } else if (a == "--ablation") {
            mode = "ablation";
        } else if (a == "--baseline") {
            mode = "baseline";
        } else if (a == "--weights-only") {
            mode = "weights-only";
        } else if (a == "--managed") {
            mode = "managed";
        } else if (a == "--ramp") {
            mode = "ramp";
        } else if (a == "--live") {
            mode = "live";
        } else if (a == "--suite") {
            mode = "suite";
        } else if (a == "--profile" && i + 1 < argc) {
            std::string p = argv[++i];
            if (p == "audio")      profile = Profile::AUDIO;
            else if (p == "mixed") profile = Profile::MIXED;
            else                   profile = Profile::INTERACTIVE;
        } else if (a == "--duration" && i + 1 < argc) {
            duration_s = std::max(1, std::atoi(argv[++i]));
        } else if (a == "--threads" && i + 1 < argc) {
            threads = std::max(1, std::atoi(argv[++i]));
        } else if (a == "--bg-procs" && i + 1 < argc) {
            bg_procs = std::clamp(std::atoi(argv[++i]), 1, kMaxBgProcs);
        } else if (a == "--work-us" && i + 1 < argc) {
            work_us = std::max(0, std::atoi(argv[++i]));
        } else if (a == "--adaptive" && i + 1 < argc) {
            std::string kind = argv[++i];
            g_demand = thm::CpuDemandHint{};
            if (kind == "game" || kind == "both") g_demand.latency_workloads = 1;
            if (kind == "train" || kind == "both") g_demand.gpu_feeders = 1;
            if (kind != "none" && kind != "game" && kind != "train" && kind != "both") {
                std::cerr << "Invalid --adaptive value: " << kind << "\n";
                return 2;
            }
        } else if (a == "--csv") {
            if (i + 1 < argc && argv[i + 1][0] != '-') {
                csv_file = argv[++i];
            } else {
                csv_stdout = true;
            }
        } else if (a == "--json" && i + 1 < argc) {
            json_file = argv[++i];
        } else if (a == "--markdown" && i + 1 < argc) {
            md_file = argv[++i];
        } else if (a == "--no-color") {
            st.color = false;
        }
    }

    if (csv_stdout) st.color = false;

    BenchCgroupEnv cg;
    if (mode != "live") {
        cg.init();
    } else {
        cg.reason = "live titan-hwm-daemon cgroups (/sys/fs/cgroup/archtitan.slice)";
    }

    if (!csv_stdout) {
        std::cout << st.bold() << st.cyan()
                  << "╔═════════════════════════════════════════════════════════════════════════════╗\n"
                  << "║     ArchTitan THM v3.2 — CPU Pressure & Asymmetric Scheduling Tester       ║\n"
                  << "╚═════════════════════════════════════════════════════════════════════════════╝"
                  << st.reset() << "\n";
        std::cout << "  Host CPUs     : " << ncpu << " online logical CPUs\n"
                  << "  Isolation     : " << (cg.available ? st.green() : st.yellow())
                  << cg.reason << st.reset() << "\n"
                  << "  Mode / Load   : " << mode << " | " << threads << " BG threads across "
                  << bg_procs << " proc(s) | " << duration_s << " s/phase\n";
        if (g_demand.latency_workloads || g_demand.gpu_feeders)
            std::cout << "  Demand hint   : " << g_demand.latency_workloads << " game(s), "
                      << g_demand.gpu_feeders << " dataloader(s)\n";
    }

    std::vector<PhaseResult> all_results;
    std::vector<std::pair<std::string, bool>> assertions;

    auto record_phase_assertions = [&](const PhaseResult& r, const std::string& tag) {
        const bool hc_ok = (r.workers_survived == r.workers_spawned && r.workers_stopped_seen == 0);
        assertions.emplace_back(tag + ":HC-CPU-1_ZERO_KILL", hc_ok);
        const bool samp_ok = (r.samples >= std::max<uint32_t>(5, r.expected_samples / 3));
        assertions.emplace_back(tag + ":FG_PROBE_ALIVE", samp_ok);
    };

    auto run_ab_pair = [&](Profile prof, const std::string& label) {
        const int target_us = (work_us >= 0) ? work_us : (prof == Profile::AUDIO ? 250 : 1000);
        const uint64_t iters = calibrate_fg_work(prof, target_us);

        if (!csv_stdout) {
            std::cout << "\n" << st.dim() << "  [" << label << "] Calibrated " << target_us
                      << " us foreground work = " << iters << " iters/tick. Running Baseline..."
                      << st.reset() << std::flush;
        }
        PhaseResult base = run_benchmark_phase("baseline", prof, duration_s, threads, bg_procs, iters, cg);
        if (!csv_stdout) {
            std::cout << st.dim() << " done. Cooling 0.5s, running THM v3.2 Managed..."
                      << st.reset() << std::flush;
        }
        ::usleep(500'000);
        PhaseResult mng  = run_benchmark_phase("managed",  prof, duration_s, threads, bg_procs, iters, cg);
        if (!csv_stdout) std::cout << st.dim() << " done.\n" << st.reset();

        all_results.push_back(base);
        all_results.push_back(mng);
        record_phase_assertions(base, label + "_BASE");
        record_phase_assertions(mng,  label + "_MNG");

        // A/B verification checks
        const bool p99_ok = (mng.frame.p99 <= base.frame.p99 * 1.05) || (mng.frame.p99 < mng.budget_ms * 0.5);
        const bool drop_ok = (mng.budget_misses <= base.budget_misses) || (mng.budget_misses == 0);
        const bool thru_ok = (base.throughput_mops <= 0.1) || (mng.throughput_mops >= base.throughput_mops * 0.35);

        assertions.emplace_back(label + ":P99_LATENCY_CONTROLLED", p99_ok);
        assertions.emplace_back(label + ":DEADLINE_MISSES_REDUCED", drop_ok);
        assertions.emplace_back(label + ":THROUGHPUT_PRESERVED", thru_ok);
        if (cg.available && mng.bg_quota_us > 0) {
            const bool enforced = (mng.bg_nr_throttled > 0) ||
                                  (mng.bg_cpu_cores <= static_cast<double>(mng.online_cpus) - 0.5);
            assertions.emplace_back(label + ":CGROUP_HEADROOM_ENFORCED", enforced);
        }

        if (!csv_stdout) {
            print_comparison(base, mng, st);
        }
    };

    if (mode == "baseline" || mode == "managed" || mode == "weights-only") {
        const int target_us = (work_us >= 0) ? work_us : (profile == Profile::AUDIO ? 250 : 1000);
        const uint64_t iters = calibrate_fg_work(profile, target_us);
        PhaseResult r = run_benchmark_phase(mode, profile, duration_s, threads, bg_procs, iters, cg);
        all_results.push_back(r);
        record_phase_assertions(r, mode);
        if (!csv_stdout) print_single_phase(r, st);
    } else if (mode == "ablation") {
        const int target_us = (work_us >= 0) ? work_us : (profile == Profile::AUDIO ? 250 : 1000);
        const uint64_t iters = calibrate_fg_work(profile, target_us);
        if (!csv_stdout) {
            std::cout << "\n" << st.dim() << "  [ABLATION:" << profile_name(profile)
                      << "] Calibrated " << target_us << " us = " << iters
                      << " iters. Running 1) Baseline Flat..." << st.reset() << std::flush;
        }
        PhaseResult base = run_benchmark_phase("baseline", profile, duration_s, threads, bg_procs, iters, cg);
        if (!csv_stdout) std::cout << st.dim() << " done. 2) Weights-Only..." << st.reset() << std::flush;
        ::usleep(500'000);
        PhaseResult w_only = run_benchmark_phase("weights-only", profile, duration_s, threads, bg_procs, iters, cg);
        if (!csv_stdout) std::cout << st.dim() << " done. 3) Full Weights+cpu.max..." << st.reset() << std::flush;
        ::usleep(500'000);
        PhaseResult full = run_benchmark_phase("managed", profile, duration_s, threads, bg_procs, iters, cg);
        if (!csv_stdout) std::cout << st.dim() << " done.\n" << st.reset();

        all_results.push_back(base);
        all_results.push_back(w_only);
        all_results.push_back(full);
        record_phase_assertions(base,   "ABL_BASE");
        record_phase_assertions(w_only, "ABL_WEIGHTS");
        record_phase_assertions(full,   "ABL_FULL");

        if (!csv_stdout) {
            std::cout << "\n" << st.bold() << st.cyan()
                      << "═══════════════════════════════════════════════════════════════════════════════\n"
                      << "  3-WAY ABLATION STUDY  —  Profile: " << base.profile
                      << "  (" << base.isolation << ")\n"
                      << "═══════════════════════════════════════════════════════════════════════════════"
                      << st.reset() << "\n";
            std::cout << std::left
                      << std::setw(26) << "Metric"
                      << std::setw(17) << "1. Flat Linux"
                      << std::setw(18) << "2. Weights-Only"
                      << "3. Full THM v3.2\n"
                      << std::string(79, '-') << "\n";
            auto ms = [](double v) {
                std::ostringstream os; os << std::fixed << std::setprecision(3) << v << " ms"; return os.str();
            };
            auto arow = [&](const std::string& k, const std::string& a, const std::string& b, const std::string& c) {
                std::cout << std::left << std::setw(26) << k << std::setw(17) << a << std::setw(18) << b << c << "\n";
            };
            arow("Wake-up p95",   ms(base.wakeup.p95), ms(w_only.wakeup.p95), ms(full.wakeup.p95));
            arow("Wake-up p99",   ms(base.wakeup.p99), ms(w_only.wakeup.p99), ms(full.wakeup.p99));
            arow("Frame p95",     ms(base.frame.p95),  ms(w_only.frame.p95),  ms(full.frame.p95));
            arow("Frame p99",     ms(base.frame.p99),  ms(w_only.frame.p99),  ms(full.frame.p99));
            arow("Frame Max",     ms(base.frame.max),  ms(w_only.frame.max),  ms(full.frame.max));
            arow("Budget Misses", std::to_string(base.budget_misses) + "/" + std::to_string(base.samples),
                                  std::to_string(w_only.budget_misses) + "/" + std::to_string(w_only.samples),
                                  std::to_string(full.budget_misses) + "/" + std::to_string(full.samples));
            arow("BG Throughput", (std::ostringstream() << std::fixed << std::setprecision(1) << base.throughput_mops << " M/s").str(),
                                  (std::ostringstream() << std::fixed << std::setprecision(1) << w_only.throughput_mops << " M/s").str(),
                                  (std::ostringstream() << std::fixed << std::setprecision(1) << full.throughput_mops << " M/s").str());
            arow("CFS Throttles", std::to_string(base.bg_nr_throttled),
                                  std::to_string(w_only.bg_nr_throttled),
                                  std::to_string(full.bg_nr_throttled));
        }
    } else if (mode == "compare") {
        run_ab_pair(profile, profile_name(profile));
    } else if (mode == "ramp") {
        const int stage_s = std::max(2, duration_s / 2);
        RampResult rr = run_pressure_ramp(stage_s, st);
        assertions.emplace_back("RAMP:PRESSURE_CLIMB_DETECTED", rr.climb_observed);
        assertions.emplace_back("RAMP:HC-CPU-1_SURVIVAL",       rr.hc_cpu1_all_survived);
    } else if (mode == "live") {
        LiveCheckResult lr = run_live_daemon_check(duration_s, threads, st);
        if (lr.daemon_active) {
            assertions.emplace_back("LIVE:SCHEMA_V32",        lr.schema_v32);
            assertions.emplace_back("LIVE:HC-CPU-1_SURVIVAL", lr.hc_cpu1_survived);
        }
    } else if (mode == "suite") {
        run_ab_pair(Profile::INTERACTIVE, "INTERACTIVE_144HZ");
        if (!g_interrupted) {
            ::usleep(500'000);
            run_ab_pair(Profile::AUDIO, "AUDIO_DSP_48KHZ");
        }
        if (!g_interrupted) {
            if (!csv_stdout) std::cout << "\n" << st.dim() << "  Cooling 2.0s before pressure ramp..." << st.reset() << "\n";
            ::usleep(2'000'000);
            RampResult rr = run_pressure_ramp(std::max(2, duration_s / 2), st);
            assertions.emplace_back("RAMP:PRESSURE_CLIMB_DETECTED", rr.climb_observed);
            assertions.emplace_back("RAMP:HC-CPU-1_SURVIVAL",       rr.hc_cpu1_all_survived);
        }
        if (!g_interrupted) {
            cg.cleanup(); // release bench cgroup so live daemon manages the worker directly
            LiveCheckResult lr = run_live_daemon_check(std::max(3, duration_s), threads, st);
            if (lr.daemon_active) {
                assertions.emplace_back("LIVE:SCHEMA_V32",        lr.schema_v32);
                assertions.emplace_back("LIVE:HC-CPU-1_SURVIVAL", lr.hc_cpu1_survived);
            }
        }
    }

    // Export outputs
    if (csv_stdout) {
        write_csv_rows(std::cout, all_results);
    }
    if (!csv_file.empty()) {
        std::ofstream f(csv_file);
        if (f.is_open()) write_csv_rows(f, all_results);
    }
    if (!json_file.empty()) {
        write_json_report(json_file, all_results, assertions);
    }
    if (!md_file.empty()) {
        write_markdown_report(md_file, all_results, assertions);
    }

    // Print Final Assertion Scorecard
    int passed = 0;
    for (const auto& [_, ok] : assertions) {
        if (ok) passed++;
    }

    if (!csv_stdout && !assertions.empty()) {
        std::cout << "\n" << st.bold() << st.cyan()
                  << "═══════════════════════════════════════════════════════════════════════════════\n"
                  << "  VERIFICATION SCORECARD  (" << passed << "/" << assertions.size() << " PASSED)\n"
                  << "═══════════════════════════════════════════════════════════════════════════════"
                  << st.reset() << "\n";
        for (const auto& [name, ok] : assertions) {
            std::cout << "  " << (ok ? (std::string(st.green()) + "[PASS]" + st.reset())
                                     : (std::string(st.red())   + "[FAIL]" + st.reset()))
                      << "  " << name << "\n";
        }
        if (!cg.available && ::geteuid() != 0) {
            std::cout << "\n" << st.yellow()
                      << "  Tip: Run with cgroup cpu delegation (root or systemd user@<uid>.service) "
                         "to engage real cpu.weight + 25ms cpu.max."
                      << st.reset() << "\n";
        }
    }

    cg.cleanup();
    return (passed == static_cast<int>(assertions.size())) ? 0 : 1;
}
