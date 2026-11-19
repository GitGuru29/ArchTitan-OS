// =============================================================================
// titan-hwm-v3/resources/pressure_level.cpp
// Phase 11 — implementation
// =============================================================================
#include "pressure_level.hpp"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <system_error>
#include <unistd.h>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// read_meminfo — parse /proc/meminfo
// ─────────────────────────────────────────────────────────────────────────────
MemInfo read_meminfo() {
    MemInfo m;
    std::ifstream f("/proc/meminfo");
    if (!f.is_open()) return m;
    std::string key;
    long val = 0;
    while (f >> key >> val) {
        if      (key == "MemTotal:")     m.total_kb      = val;
        else if (key == "MemAvailable:") m.available_kb  = val;
        else if (key == "SwapTotal:")    m.swap_total_kb = val;
        else if (key == "SwapFree:")     m.swap_free_kb  = val;
        f.ignore(256, '\n'); // skip rest of line (e.g. "kB")
    }
    return m;
}

// ─────────────────────────────────────────────────────────────────────────────
// read_memory_psi — parse /proc/pressure/memory
// Format: "some avg10=X.XX avg60=Y.YY avg300=Z.ZZ total=N"
//         "full avg10=X.XX avg60=Y.YY avg300=Z.ZZ total=N"
// ─────────────────────────────────────────────────────────────────────────────
PSIStats read_memory_psi() {
    PSIStats p;
    std::ifstream f("/proc/pressure/memory");
    if (!f.is_open()) return p; // PSI not available (kernel < 4.20)

    std::string line;
    while (std::getline(f, line)) {
        std::istringstream ss(line);
        std::string kind;
        ss >> kind;

        float avg10 = 0.0f;
        std::string tok;
        while (ss >> tok) {
            if (tok.rfind("avg10=", 0) == 0) {
                try { avg10 = std::stof(tok.substr(6)); } catch (...) {}
                break;
            }
        }

        if (kind == "some") p.some_avg10 = avg10;
        if (kind == "full") p.full_avg10 = avg10;
    }
    p.valid = true;
    return p;
}

// ─────────────────────────────────────────────────────────────────────────────
// read_cpu_psi — parse /proc/pressure/cpu
//
// NOTE: this is telemetry only. `full` is intentionally not parsed because the
// CPU PSI "full" line is always zero (CPU is not a fully-preemptible resource),
// and CPU pressure must never drive compute_pressure() — see HC-CPU-1.
// ─────────────────────────────────────────────────────────────────────────────
CpuPSIStats read_cpu_psi() {
    CpuPSIStats p;
    std::ifstream f("/proc/pressure/cpu");
    if (!f.is_open()) return p;

    std::string line;
    while (std::getline(f, line)) {
        std::istringstream ss(line);
        std::string kind;
        ss >> kind;
        if (kind != "some") continue;

        std::string tok;
        while (ss >> tok) {
            auto grab = [&](const char* key, float& out) {
                const std::string k(key);
                if (tok.rfind(k + "=", 0) == 0)
                    try { out = std::stof(tok.substr(k.size() + 1)); } catch (...) {}
            };
            grab("avg10",  p.some_avg10);
            grab("avg60",  p.some_avg60);
            grab("avg300", p.some_avg300);
            const std::string total_key = "total=";
            if (tok.rfind(total_key, 0) == 0)
                try { p.some_total_us = std::stoull(tok.substr(total_key.size())); }
                catch (...) {}
        }
    }
    p.valid = true;
    return p;
}

// ─────────────────────────────────────────────────────────────────────────────
// read_loadavg — parse /proc/loadavg
// Format: "0.52 0.58 0.59 2/812 12345"
// ─────────────────────────────────────────────────────────────────────────────
LoadAverage read_loadavg() {
    LoadAverage l;
    std::ifstream f("/proc/loadavg");
    if (!f.is_open()) return l;
    std::string run;
    if (f >> l.load1 >> l.load5 >> l.load15 >> run) {
        auto slash = run.find('/');
        if (slash != std::string::npos) {
            try {
                l.running = std::stoi(run.substr(0, slash));
                l.total   = std::stoi(run.substr(slash + 1));
            } catch (...) {}
        }
    }
    return l;
}

// ─────────────────────────────────────────────────────────────────────────────
// compute_pressure — aggregate MemInfo + PSI → PressureLevel
// ─────────────────────────────────────────────────────────────────────────────
PressureLevel compute_pressure(const MemInfo& mem, const PSIStats& psi) {
    const float free_pct = mem.free_pct();

    // Fast-path: critically low RAM regardless of PSI availability
    if (free_pct < 15.0f) return PressureLevel::CRITICAL;

    if (psi.valid) {
        // PSI-based decisions (preferred — more precise than raw RAM %)
        if (psi.full_avg10 >= 15.0f || psi.some_avg10 >= 40.0f)
            return PressureLevel::CRITICAL;
        if (psi.some_avg10 >= 20.0f || free_pct < 25.0f)
            return PressureLevel::HIGH;
        if (psi.some_avg10 >= 5.0f  || free_pct < 50.0f)
            return PressureLevel::MODERATE;
        return PressureLevel::NORMAL;
    }

    // PSI unavailable — RAM-only fallback
    if (free_pct < 25.0f) return PressureLevel::CRITICAL;
    if (free_pct < 50.0f) return PressureLevel::HIGH;
    return PressureLevel::NORMAL;
}

// ═════════════════════════════════════════════════════════════════════════════
// CPU pressure engine
// ═════════════════════════════════════════════════════════════════════════════
int read_online_cpus() {
    const long n = ::sysconf(_SC_NPROCESSORS_ONLN);
    return n < 1 ? 1 : static_cast<int>(n);
}

float read_cpu_temp_c() {
    namespace fs = std::filesystem;
    float hottest = 0.0f;
    std::error_code ec;
    for (const auto& entry : fs::directory_iterator("/sys/class/thermal", ec)) {
        const std::string name = entry.path().filename().string();
        if (name.rfind("thermal_zone", 0) != 0) continue;

        std::string type;
        { std::ifstream tf(entry.path() / "type"); std::getline(tf, type); }
        const bool cpu_like =
            type.find("x86_pkg") != std::string::npos ||
            type.find("coretemp") != std::string::npos ||
            type.find("k10temp") != std::string::npos ||
            type.find("cpu")     != std::string::npos ||
            type.find("CPU")     != std::string::npos ||
            type.find("TCPU")    != std::string::npos ||
            type.find("acpitz")  != std::string::npos;
        if (!cpu_like) continue;

        std::ifstream vf(entry.path() / "temp");
        long milli = 0;
        if (vf >> milli && milli > 0 && milli < 150000)
            hottest = std::max(hottest, static_cast<float>(milli) / 1000.0f);
    }
    return hottest;
}

PressureLevel compute_cpu_pressure_raw(const CpuPSIStats& cpu_psi,
                                       const LoadAverage& loadavg,
                                       int online_cpus,
                                       float instant_some_pct) {
    if (!cpu_psi.valid) return PressureLevel::NORMAL;

    const int   cpus        = online_cpus < 1 ? 1 : online_cpus;
    const float load1_ratio = loadavg.load1 / static_cast<float>(cpus);
    // Combine 60s EWMA load1_ratio with instantaneous runnable ratio so heavy
    // multi-thread saturation escalates as soon as PSI climbs (~2-4s) instead
    // of waiting 15-18s for the kernel's 5s LOAD_FREQ decay window, while still
    // filtering out single-thread spikes (adj_running == 1 -> 1/cpus < 1.0).
    const int   adj_running = loadavg.running > 1 ? (loadavg.running - 1) : loadavg.running;
    const float runq_ratio  = static_cast<float>(adj_running) / static_cast<float>(cpus);
    const float ratio       = std::max(load1_ratio, runq_ratio);

    auto classify = [&](float psi) {
        if (psi >= 60.0f && ratio >= 2.5f) return PressureLevel::CRITICAL;
        if (psi >= 30.0f && ratio >= 1.5f) return PressureLevel::HIGH;
        if (psi >= 15.0f && ratio >= 1.0f) return PressureLevel::MODERATE;
        return PressureLevel::NORMAL;
    };

    // The averaged signal is authoritative at the top, but the per-tick delta
    // can only ever raise the level. Both require the same runqueue gate, so a
    // saturated single core (high PSI, runq ratio < 1.0) still cannot escalate.
    PressureLevel level = classify(cpu_psi.some_avg10);
    if (instant_some_pct >= 0.0f)
        level = std::max(level, classify(instant_some_pct));
    return level;
}

float CpuPressureController::release_threshold(PressureLevel level) {
    switch (level) {
        case PressureLevel::CRITICAL: return 30.0f;
        case PressureLevel::HIGH:     return 15.0f;
        case PressureLevel::MODERATE: return 10.0f;
        case PressureLevel::NORMAL:   return 0.0f;
    }
    return 0.0f;
}

SystemPressure CpuPressureController::evaluate(const MemInfo& mem,
                                               const PSIStats& mem_psi,
                                               const CpuPSIStats& cpu_psi,
                                               const LoadAverage& loadavg,
                                               int online_cpus,
                                               long long elapsed_us) {
    const int cpus = online_cpus < 1 ? 1 : online_cpus;

    // Per-tick PSI delta. The kernel's `total=` counter is monotonic
    // microseconds, so the fraction of this tick that had at least one runnable
    // task stalled is delta / elapsed. This is the fastest truthful rejection
    // signal available: no 10 s EWMA, no reliance on loadavg's 5 s sampling.
    float inst_pct = -1.0f;
    if (cpu_psi.valid && cpu_psi.some_total_us > 0 && elapsed_us > 0) {
        if (have_prev_total_ && cpu_psi.some_total_us >= prev_total_us_) {
            const double delta = static_cast<double>(cpu_psi.some_total_us - prev_total_us_);
            inst_pct = static_cast<float>(
                std::clamp(100.0 * delta / static_cast<double>(elapsed_us), 0.0, 100.0));
        }
        prev_total_us_   = cpu_psi.some_total_us;
        have_prev_total_ = true;
    } else {
        have_prev_total_ = false;
        prev_total_us_   = 0;
    }

    // Feed only a two-sample minimum to the classifier: one 200 ms blip must not
    // engage a bandwidth cap that then has to cool down for several seconds.
    float sustained_inst = -1.0f;
    if (inst_pct >= 0.0f && prev_inst_pct_ >= 0.0f)
        sustained_inst = std::min(inst_pct, prev_inst_pct_);
    prev_inst_pct_ = inst_pct;

    const PressureLevel raw =
        compute_cpu_pressure_raw(cpu_psi, loadavg, cpus, sustained_inst);

    if (raw >= current_cpu_) {
        // Escalate (or hold) immediately.
        current_cpu_ = raw;
        cool_ticks_  = 0;
    } else {
        // Raw signal is lower than what is applied. Only release after the
        // stall signal has stayed under this level's release threshold long
        // enough. Prefer the instantaneous delta: avg10 lags a finished build
        // by up to 10 s, which used to keep the cap on after the build exited.
        const float release_signal =
            (inst_pct >= 0.0f) ? inst_pct : cpu_psi.some_avg10;
        if (release_signal < release_threshold(current_cpu_)) {
            if (++cool_ticks_ >= release_ticks_required_) {
                current_cpu_ = raw;
                cool_ticks_  = 0;
            }
        } else {
            cool_ticks_ = 0;
        }
    }

    SystemPressure sp;
    sp.memory         = compute_pressure(mem, mem_psi);
    sp.cpu            = current_cpu_;
    sp.composite      = std::max(sp.memory, sp.cpu);
    sp.cpu_some_avg10 = cpu_psi.some_avg10;
    sp.cpu_some_avg60 = cpu_psi.some_avg60;
    sp.cpu_some_inst  = inst_pct;
    sp.mem_some_avg10 = mem_psi.some_avg10;
    const int   adj_running = loadavg.running > 1 ? (loadavg.running - 1) : loadavg.running;
    const float runq_ratio  = static_cast<float>(adj_running) / static_cast<float>(cpus);
    sp.load_ratio     = std::max(loadavg.load1 / static_cast<float>(cpus), runq_ratio);
    sp.online_cpus    = cpus;
    return sp;
}

} // namespace thm
