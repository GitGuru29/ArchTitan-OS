// =============================================================================
// titan-hwm-v3/benchmarks/bench_cpu_headroom.cpp
//
// Pure C++20 FYP Empirical Benchmark Suite (zero Python):
//   Measures interactive 144 Hz compositor/keystroke wake-up latency (p50, p95,
//   p99, max ms), background saturation throughput (iterations/sec), and
//   optional ALSA/PipeWire xrun deltas under N-thread CPU saturation.
//
// Usage:
//   bench_cpu_headroom [--duration SEC] [--threads N] [--baseline|--managed] [--csv]
// =============================================================================

#include "../resources/pressure_level.hpp"

#include <algorithm>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <string>
#include <thread>
#include <time.h>
#include <vector>

namespace {

int64_t now_mono_ns() {
    struct timespec ts {};
    ::clock_gettime(CLOCK_MONOTONIC, &ts);
    return static_cast<int64_t>(ts.tv_sec) * 1000000000LL + ts.tv_nsec;
}

double percentile(const std::vector<double>& sorted, double p) {
    if (sorted.empty()) return 0.0;
    const double idx = p * static_cast<double>(sorted.size() - 1);
    const size_t lo  = static_cast<size_t>(std::floor(idx));
    const size_t hi  = static_cast<size_t>(std::ceil(idx));
    const double t   = idx - static_cast<double>(lo);
    return sorted[lo] * (1.0 - t) + sorted[hi] * t;
}

long long read_proc_xruns_or_interrupts() {
    std::ifstream f("/proc/pressure/cpu");
    if (!f.is_open()) return 0;
    std::string line;
    while (std::getline(f, line)) {
        auto pos = line.find("total=");
        if (pos != std::string::npos) {
            try { return std::stoll(line.substr(pos + 6)); } catch (...) {}
        }
    }
    return 0;
}

} // namespace

int main(int argc, char* argv[]) {
    int duration_s = 3;
    int workers    = thm::read_online_cpus();
    std::string mode = "live";
    bool emit_csv  = false;

    for (int i = 1; i < argc; ++i) {
        std::string a = argv[i];
        if (a == "--duration" && i + 1 < argc) {
            duration_s = std::max(1, std::atoi(argv[++i]));
        } else if (a == "--threads" && i + 1 < argc) {
            workers = std::max(1, std::atoi(argv[++i]));
        } else if (a == "--baseline") {
            mode = "baseline";
        } else if (a == "--managed") {
            mode = "managed";
        } else if (a == "--csv") {
            emit_csv = true;
        }
    }

    std::atomic<bool> stop{false};
    std::atomic<uint64_t> total_iters{0};

    std::vector<std::thread> pool;
    pool.reserve(static_cast<size_t>(workers));
    for (int w = 0; w < workers; ++w) {
        pool.emplace_back([&]() {
            volatile uint64_t acc = 0;
            uint64_t local_iters = 0;
            while (!stop.load(std::memory_order_relaxed)) {
                // Tight ALU compute mix simulating compiler/worker saturation
                uint64_t x = acc + 0x9e3779b97f4a7c15ULL;
                x ^= (x >> 30);
                x *= 0xbf58476d1ce4e5b9ULL;
                acc = x;
                ++local_iters;
            }
            total_iters.fetch_add(local_iters, std::memory_order_relaxed);
        });
    }

    // 144 Hz target period (~6.944 ms) measuring actual wake-up oversleep latency
    constexpr int64_t kFramePeriodNs = 6'944'444LL;
    const int64_t psi_start_us = read_proc_xruns_or_interrupts();
    const int64_t bench_start_ns = now_mono_ns();
    const int64_t bench_end_ns   = bench_start_ns + static_cast<int64_t>(duration_s) * 1'000'000'000LL;

    std::vector<double> jitter_ms;
    jitter_ms.reserve(static_cast<size_t>(duration_s) * 160);

    int64_t next_tick = bench_start_ns + kFramePeriodNs;
    while (now_mono_ns() < bench_end_ns) {
        struct timespec req {
            static_cast<time_t>(next_tick / 1'000'000'000LL),
            static_cast<long>(next_tick % 1'000'000'000LL)
        };
        ::clock_nanosleep(CLOCK_MONOTONIC, TIMER_ABSTIME, &req, nullptr);
        const int64_t woke = now_mono_ns();
        const double oversleep_ms = static_cast<double>(woke - next_tick) / 1'000'000.0;
        jitter_ms.push_back(std::max(0.0, oversleep_ms));
        next_tick += kFramePeriodNs;
        if (woke > next_tick) next_tick = woke + kFramePeriodNs;
    }

    stop.store(true, std::memory_order_release);
    for (auto& t : pool) t.join();

    const int64_t psi_end_us   = read_proc_xruns_or_interrupts();
    const double  elapsed_s    = static_cast<double>(now_mono_ns() - bench_start_ns) / 1e9;
    const double  throughput_m = (static_cast<double>(total_iters.load()) / 1e6) / std::max(0.01, elapsed_s);

    std::sort(jitter_ms.begin(), jitter_ms.end());
    const double p50  = percentile(jitter_ms, 0.50);
    const double p95  = percentile(jitter_ms, 0.95);
    const double p99  = percentile(jitter_ms, 0.99);
    const double pmax = jitter_ms.empty() ? 0.0 : jitter_ms.back();
    const auto   cpu_psi = thm::read_cpu_psi();
    const auto   la      = thm::read_loadavg();

    if (emit_csv) {
        std::cout << "mode,threads,duration_s,samples,p50_ms,p95_ms,p99_ms,max_ms,throughput_Mops_s,psi_delta_us,cpu_psi_avg10,load1\n";
        std::cout << mode << "," << workers << "," << std::fixed << std::setprecision(2)
                  << elapsed_s << "," << jitter_ms.size() << ","
                  << std::setprecision(3) << p50 << "," << p95 << "," << p99 << "," << pmax << ","
                  << std::setprecision(2) << throughput_m << ","
                  << (psi_end_us - psi_start_us) << ","
                  << cpu_psi.some_avg10 << "," << la.load1 << "\n";
    } else {
        std::cout << "| Metric | Value |\n"
                  << "| :--- | :--- |\n"
                  << "| Mode | " << mode << " (" << workers << " worker threads, " << std::fixed << std::setprecision(2) << elapsed_s << " s) |\n"
                  << "| 144Hz Interactive Wake-up p50 | " << std::setprecision(3) << p50 << " ms |\n"
                  << "| 144Hz Interactive Wake-up p95 | " << p95 << " ms |\n"
                  << "| 144Hz Interactive Wake-up p99 | " << p99 << " ms |\n"
                  << "| 144Hz Interactive Wake-up Max | " << pmax << " ms |\n"
                  << "| Background Compute Throughput | " << std::setprecision(2) << throughput_m << " M ops/s |\n"
                  << "| CPU PSI Stall Delta | " << (psi_end_us - psi_start_us) << " us |\n"
                  << "| Post-run CPU PSI avg10 / load1 | " << cpu_psi.some_avg10 << "% / " << la.load1 << " |\n";
    }
    return 0;
}

