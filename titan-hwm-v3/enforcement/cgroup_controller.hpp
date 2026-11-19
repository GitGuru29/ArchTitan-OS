// =============================================================================
// titan-hwm-v3/enforcement/cgroup_controller.hpp
// Phase 7 — cgroup v2 Controller (systemd-delegation-aware)
//
// Operates entirely within archtitan.slice, which is declared in
// /etc/systemd/system/archtitan.slice with Delegate=yes.
// Never creates cgroups outside that slice.
// =============================================================================
#pragma once

#include "../core/types.hpp"
#include <cstdint>
#include <string>
#include <vector>
#include <sys/types.h>

namespace thm {

// Named slices within archtitan.slice
static constexpr const char* SLICE_ROOT       = "/sys/fs/cgroup/archtitan.slice";
static constexpr const char* SLICE_PROTECTED  = "archtitan-protected.slice";
static constexpr const char* SLICE_ACTIVE     = "archtitan-active.slice";
static constexpr const char* SLICE_BACKGROUND = "archtitan-background.slice";
static constexpr const char* SLICE_FROZEN     = "archtitan-frozen.slice";

// Map PolicyDecision to the target slice name
inline const char* slice_for_decision(PolicyDecision d) {
    switch (d) {
        case PolicyDecision::KEEP_FULL:       return SLICE_ACTIVE;
        case PolicyDecision::KEEP_BACKGROUND: return SLICE_BACKGROUND;
        case PolicyDecision::THROTTLE:        return SLICE_BACKGROUND;
        case PolicyDecision::FREEZE:          return SLICE_FROZEN;
        case PolicyDecision::RECLAIM:         return SLICE_BACKGROUND; // transient until killed
        default:                              return SLICE_BACKGROUND;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// CPU bandwidth policy  (CPU pressure engine — never signals, only schedules)
//
// CFS bandwidth period. The kernel default is 100 ms, which means a capped
// cgroup can sit throttled for up to ~100 ms at the end of every period — a
// visible stutter if that cgroup were ever in the interactive path. 25 ms keeps
// the worst-case throttle stall at one quarter of that while staying far above
// the scheduler tick, so accounting overhead stays negligible.
// ─────────────────────────────────────────────────────────────────────────────
static constexpr long CFS_SMOOTH_PERIOD_US = 25000;

// How long the user must be away before the background cap is lifted so an
// unattended build can use the whole machine.
static constexpr long UNATTENDED_IDLE_SECONDS = 60;

// Result of compute_cpu_slice_policy(): the complete desired cgroup CPU state.
struct CpuSlicePolicy {
    int   protected_weight    = 2000;
    int   active_weight       = 500;
    int   background_weight   = 50;
    long  background_quota_us = 0;      // 0 means "max" (no bandwidth cap)
    long  period_us           = CFS_SMOOTH_PERIOD_US;
    float background_max_pct  = 100.0f; // share of TOTAL machine CPU the BG slice may use
    bool  headroom_engaged    = false;  // a bandwidth cap is currently applied
    bool  background_idle     = false;  // BG is SCHED_IDLE-equivalent (cpu.idle=1)
    bool  unattended_lift     = false;  // cap was lifted because the user is away
};

// Pure, deterministic and root-free: the whole mapping from (CPU pressure, core
// count, user presence) to cgroup values, so it can be unit-tested without
// touching /sys/fs/cgroup.
//
//   CPU pressure   protected  active  background   background cpu.max   cpu.idle
//   NORMAL           2000       500       50         max               0
//   MODERATE         2000       800       25         max               0
//   HIGH             2000      1000       10         (N-1) cores       0
//   CRITICAL         5000      1000       10         (N-2) cores       1
//
// The (N-1) cap permanently reserves one core's worth of bandwidth for
// everything outside the background slice (compositor, input, audio) even when
// the foreground is momentarily idle, where cpu.weight alone could not help
// because weights only bite while slices compete. CRITICAL reserves a second
// core on machines with >= 3 CPUs: at that point the desktop is already
// stuttering, and background throughput is worth less than input latency. On a
// 1-core machine the cap is 75% rather than 0, so a background build is slowed
// but never starved.
//
// At CRITICAL the background slice additionally gets cpu.idle=1. Unlike
// cpu.weight, which only divides *contended* time, cpu.idle makes the kernel
// schedule background tasks only when no non-idle task wants the CPU. A build
// therefore still uses otherwise-idle cores, but cannot add wake-up latency to
// the compositor or audio thread. This is the cgroup-v2 equivalent of
// SCHED_IDLE, and it is cleared automatically when pressure drops.
//
// When the user is unattended (idle >= UNATTENDED_IDLE_SECONDS) the cap is
// lifted at HIGH/CRITICAL: nobody is there to feel latency, so the build gets
// the whole machine. The weights stay biased, so the instant the user returns
// the foreground wins every contention while the cap re-engages.
CpuSlicePolicy compute_cpu_slice_policy(PressureLevel cpu_pressure,
                                        int online_cpus,
                                        bool user_unattended_idle);

// Per-slice CFS bandwidth counters from cpu.stat. Used for telemetry so the
// operator can verify that a cap is actually binding (nr_throttled rising)
// rather than trusting the policy struct alone.
struct CpuSliceStat {
    uint64_t nr_periods     = 0;
    uint64_t nr_throttled   = 0;
    uint64_t throttled_usec = 0;
};

// ─────────────────────────────────────────────────────────────────────────────
// CgroupController
// ─────────────────────────────────────────────────────────────────────────────
class CgroupController {
public:
    // One-time setup — create the 4 named slices under archtitan.slice.
    // Safe to call multiple times (idempotent).
    bool setup_slices();

    // Delegate the controllers THM needs (cpu, memory, pids) into the slice's
    // subtree_control so the sub-slices actually get cpu.weight / memory.high.
    // Best-effort; called from setup_slices() before the sub-slices are made.
    static void enable_controllers();

    // Move a list of PIDs into a named slice (cgroup.procs write)
    bool move_to_slice(const std::vector<pid_t>& pids,
                       const std::string& slice_name);

    // Set cpu.weight inside archtitan.slice/<slice> (1–10000, default 100)
    bool set_cpu_weight(const std::string& slice_name, int weight);

    // Set cpu.max (CFS bandwidth). quota_us <= 0 writes "max" (uncapped); the
    // period is always written so a previously changed period is restored.
    bool set_cpu_max(const std::string& slice_name,
                     long quota_us,
                     long period_us = CFS_SMOOTH_PERIOD_US);

    // Set cpu.idle (1 = SCHED_IDLE-equivalent for the whole slice). Kernels
    // without the file are treated as a successful no-op: the rest of the
    // policy still applies, and the daemon must not enter write-backoff.
    bool set_cpu_idle(const std::string& slice_name, bool idle);

    // Read CFS bandwidth counters. Returns false when cpu.stat is unavailable.
    bool read_cpu_stat(const std::string& slice_name, CpuSliceStat& out) const;

    // Set memory.high limit (bytes; 0 = remove limit / restore to max)
    bool set_memory_high(const std::string& slice_name, long bytes);

    // Set cgroup.freeze (1 = frozen, 0 = thawed)
    bool set_freeze(const std::string& slice_name, bool freeze);

    // Set oom_score_adj for each PID in the list
    void set_oom_score(const std::vector<pid_t>& pids, int score);

    // Per-workload scope path (optional fine-grained isolation)
    static std::string workload_scope(uint32_t workload_id) {
        return std::string(SLICE_ROOT) + "/archtitan-workload-" +
               std::to_string(workload_id) + ".scope";
    }

    // True if the cgroup hierarchy is properly delegated to THM
    bool hierarchy_healthy() const;

private:
    static bool write_file(const std::string& path, const std::string& value);
    static bool mkdir_p(const std::string& path);
    static std::string slice_path(const std::string& slice_name);
};

} // namespace thm
