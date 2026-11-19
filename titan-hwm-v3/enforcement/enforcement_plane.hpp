// =============================================================================
// titan-hwm-v3/enforcement/enforcement_plane.hpp
// Phase 9 — Enforcement Plane
//
// Consumes PolicyDecision + Workload and translates it into concrete kernel
// actions: cgroup moves, SIGSTOP/SIGCONT, OOM scores, cpu.weight.
// Contains the protected-domain hard-block at the top of every code path.
// =============================================================================
#pragma once

#include "../core/types.hpp"
#include "../core/protected_registry.hpp"
#include "cgroup_controller.hpp"

#include <csignal>
#include <unordered_map>

namespace thm {

// OOM scores used by THM
static constexpr int OOM_PROTECT  = -500; // active workloads — harder to kill
static constexpr int OOM_NORMAL   =    0; // background workloads
static constexpr int OOM_EXPOSE   =  500; // aging/reclaimable — OOM prefers these

// CPU weight THROTTLE caps the background slice at. The dynamic CPU policy
// (compute_cpu_slice_policy) owns every other weight; a memory-driven THROTTLE
// decision can only ever push the background slice lower, never higher.
static constexpr int CPU_WEIGHT_THROTTLE = 20;

// Pure helper: should an OBSERVED workload be placed in a managed CPU slice
// this tick? Unclassified games, renderers and training jobs must not run
// outside the managed hierarchy just because system CPU pressure is NORMAL.
// `to_active` is set for focused/visible work, otherwise the background slice
// is used. No signal is ever sent and no policy decision is involved (HC-CPU-1).
bool observed_slice_assignment(const Workload&       wl,
                               const WorkspaceState& ws,
                               ActivityState         activity,
                               bool&                 to_active);

class EnforcementPlane {
public:
    explicit EnforcementPlane(CgroupController& cgroup,
                               const ProtectedRegistry& registry)
        : cgroup_(cgroup), registry_(registry) {}

    // Apply a PolicyDecision to a workload.
    // Returns false if the hard-block fires (workload is protected).
    bool apply(const Workload& wl, PolicyDecision decision);

    // Thaw all stopped PIDs (used during startup recovery / crash thaw)
    void sigcont_tree(const std::vector<pid_t>& pids);

    // ── CPU arbitration (HC-CPU-1: scheduling only, never a signal) ─────────
    // Translate the CPU pressure channel into cpu.weight on the protected /
    // active / background slices plus a cpu.max headroom cap on the background
    // slice. Call once per tick AFTER the per-workload apply() loop. Writes are
    // change-detected, so steady state costs zero syscalls. Returns the policy
    // that is in effect (also what telemetry should publish).
    CpuSlicePolicy apply_cpu_pressure_policy(PressureLevel cpu_pressure,
                                             int online_cpus,
                                             bool user_unattended_idle);

    const CpuSlicePolicy& current_cpu_policy() const { return effective_policy_; }

private:
    CgroupController&        cgroup_;
    const ProtectedRegistry& registry_;

    // Last values successfully written to the kernel (-1 / -2 = never written).
    struct WrittenState {
        int  protected_weight  = -1;
        int  active_weight     = -1;
        int  background_weight = -1;
        long background_quota  = -2;
        int  background_idle   = -1;
    } written_;

    CpuSlicePolicy effective_policy_;
    bool           throttle_seen_  = false; // a THROTTLE decision landed this tick
    int            write_backoff_  = 0;     // ticks to wait after a failed write

    // Send signal to all PIDs in list; skip protected PIDs (extra safety)
    void signal_tree(const std::vector<pid_t>& pids, int sig);

    // SIGCONT any PIDs currently in T (stopped) state
    void sigcont_if_stopped(const std::vector<pid_t>& pids);
};

} // namespace thm
