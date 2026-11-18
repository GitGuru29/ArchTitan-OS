// =============================================================================
// titan-hwm-v3/resources/pressure_level.hpp
// Phase 11 — Pressure Level Engine
//
// Aggregates /proc/meminfo + PSI memory pressure into a single PressureLevel.
// PSI is preferred (kernel 4.20+); falls back to RAM-only if unavailable.
// =============================================================================
#pragma once

#include "../core/types.hpp"
#include <string>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// MemInfo — snapshot of /proc/meminfo (in kB)
// ─────────────────────────────────────────────────────────────────────────────
struct MemInfo {
    long total_kb     = 0;
    long available_kb = 0;
    long swap_total_kb = 0;
    long swap_free_kb  = 0;

    float used_pct() const {
        if (total_kb <= 0) return 0.0f;
        return 100.0f * (1.0f - static_cast<float>(available_kb) /
                                 static_cast<float>(total_kb));
    }
    float free_pct() const { return 100.0f - used_pct(); }
};

// ─────────────────────────────────────────────────────────────────────────────
// PSIStats — /proc/pressure/memory (avg10 only; sufficient for policy decisions)
// ─────────────────────────────────────────────────────────────────────────────
struct PSIStats {
    bool  valid      = false;
    float some_avg10 = 0.0f; // % of time at least one task stalled on memory
    float full_avg10 = 0.0f; // % of time ALL tasks stalled on memory
};

// ─────────────────────────────────────────────────────────────────────────────
// CpuPSIStats / LoadAverage — CPU-pressure inputs
//
// CPU pressure never feeds compute_pressure() (the memory channel), so it can
// never influence a kill/freeze decision (invariant HC-CPU-1). It feeds
// CpuPressureController, which only ever arbitrates scheduling (cpu.weight /
// cpu.max) — see the CPU pressure engine section below.
// ─────────────────────────────────────────────────────────────────────────────
struct CpuPSIStats {
    bool  valid       = false;
    float some_avg10  = 0.0f; // % of time at least one task was runnable-stalled
    float some_avg60  = 0.0f;
    float some_avg300 = 0.0f;
};

struct LoadAverage {
    float load1  = 0.0f;
    float load5  = 0.0f;
    float load15 = 0.0f;
    int   running = 0; // currently runnable
    int   total   = 0; // total schedulable
};

// ─────────────────────────────────────────────────────────────────────────────
// Readers
// ─────────────────────────────────────────────────────────────────────────────
MemInfo  read_meminfo();
PSIStats read_memory_psi();
CpuPSIStats read_cpu_psi();
LoadAverage read_loadavg();

// ─────────────────────────────────────────────────────────────────────────────
// compute_pressure — derive PressureLevel from combined signals
//
// This is the MEMORY channel only. It deliberately takes no CPU input.
//
// Priority order:
//   1. RAM free < 15%                        → CRITICAL  (fast-path)
//   2. PSI full_avg10 >= 15% OR some >= 40%  → CRITICAL
//   3. PSI some_avg10 >= 20% OR RAM free <25%→ HIGH
//   4. PSI some_avg10 >= 5%  OR RAM free <50%→ MODERATE
//   5. Otherwise                             → NORMAL
// ─────────────────────────────────────────────────────────────────────────────
PressureLevel compute_pressure(const MemInfo& mem, const PSIStats& psi);

// ═════════════════════════════════════════════════════════════════════════════
// CPU pressure engine  (RFC: docs/thm_v3_cpu_pressure_architecture.typ)
//
// Memory pressure is solved by freeing pages (FREEZE / RECLAIM). CPU pressure
// cannot be solved that way: killing a compile does not make it "less CPU
// bound", it just destroys legitimate developer work. CPU contention is
// therefore resolved ONLY by scheduling arbitration (cgroup cpu.weight and
// cpu.max headroom) and never by a signal.
//
// ┌──────────────────────────────────────────────────────────────────────────┐
// │ HC-CPU-1  CPU pressure may never produce FREEZE, RECLAIM, SIGSTOP or     │
// │           SIGKILL. The memory plane (WorkloadManager::tick,              │
// │           PolicyEngine::evaluate, ReclaimEngine::reclaim) must only ever │
// │           receive memory_plane_pressure(), never .cpu or .composite.     │
// └──────────────────────────────────────────────────────────────────────────┘
// ═════════════════════════════════════════════════════════════════════════════

// Differentiated pressure channels for one tick.
struct SystemPressure {
    PressureLevel memory    = PressureLevel::NORMAL; // drives FREEZE / RECLAIM / memory.high
    PressureLevel cpu       = PressureLevel::NORMAL; // drives cpu.weight + cpu.max headroom
    PressureLevel composite = PressureLevel::NORMAL; // max(memory, cpu) — telemetry only

    float cpu_some_avg10 = 0.0f;
    float cpu_some_avg60 = 0.0f;
    float mem_some_avg10 = 0.0f;
    float load_ratio     = 0.0f; // load1 / online_cpus
    int   online_cpus    = 1;
};

// The ONLY accessor the memory plane is allowed to use (see HC-CPU-1).
inline PressureLevel memory_plane_pressure(const SystemPressure& sp) {
    return sp.memory;
}

// Online logical CPUs, never less than 1.
int read_online_cpus();

// Hottest CPU package/core sensor in °C, or 0 when no sensor is exposed
// (virtual machines, some SBCs). Used only to veto a governor boost.
float read_cpu_temp_c();

// Un-smoothed classification of one sample. A level requires BOTH the PSI
// signal and the runqueue-saturation signal, which filters out bursty
// single-threaded spikes (high PSI, low load) and mere high utilisation with no
// actual contention (high load only briefly, PSI near zero).
//
//   level      CPU PSI some avg10   AND   load1 / online_cpus
//   MODERATE        >= 15 %                   >= 1.0
//   HIGH            >= 30 %                   >= 1.5
//   CRITICAL        >= 60 %                   >= 2.5
//
// An invalid PSI sample (kernel without CONFIG_PSI) always yields NORMAL: with no
// signal there is nothing to arbitrate.
PressureLevel compute_cpu_pressure_raw(const CpuPSIStats& cpu_psi,
                                       const LoadAverage& loadavg,
                                       int online_cpus);

// Anti-flap smoothing around compute_cpu_pressure_raw().
//
//  * Escalation is immediate: starving the compositor for even a few seconds is
//    exactly what this engine exists to prevent.
//  * De-escalation requires CPU PSI avg10 to sit below the release threshold of
//    the *current* level for `release_ticks_required` consecutive ticks, then
//    drops straight to the raw level. A build oscillating around a boundary
//    therefore cannot make the cgroup weights flap every tick.
//
//   current level   release threshold (PSI some avg10)
//   MODERATE              < 10 %
//   HIGH                  < 15 %
//   CRITICAL              < 30 %
class CpuPressureController {
public:
    explicit CpuPressureController(int release_ticks_required = 3)
        : release_ticks_required_(release_ticks_required < 1 ? 1 : release_ticks_required) {}

    SystemPressure evaluate(const MemInfo& mem,
                            const PSIStats& mem_psi,
                            const CpuPSIStats& cpu_psi,
                            const LoadAverage& loadavg,
                            int online_cpus);

    PressureLevel current_cpu_level() const { return current_cpu_; }
    void reset() { current_cpu_ = PressureLevel::NORMAL; cool_ticks_ = 0; }

private:
    static float release_threshold(PressureLevel level);

    int           release_ticks_required_;
    PressureLevel current_cpu_ = PressureLevel::NORMAL;
    int           cool_ticks_  = 0;
};

} // namespace thm
