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
#include "../resources/smt_topology.hpp"
#include "../resources/input_feedforward.hpp"
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

// Effective SMT-aware cpuset split (empty strings = whole machine).
struct CpuIsolationState {
    bool active = false;
    int  reserved_physical_cores = 0;
    std::string latency_cpus;
    std::string background_cpus;
};

// Pure helper: should an OBSERVED workload be placed in a managed CPU slice
// this tick? Unclassified games, renderers and training jobs must not run
// outside the managed hierarchy just because system CPU pressure is NORMAL.
// `to_active` is set for focused/visible work, otherwise the background slice
// is used. No signal is ever sent and no policy decision is involved (HC-CPU-1).
bool observed_slice_assignment(const Workload&       wl,
                               const WorkspaceState& ws,
                               ActivityState         activity,
                               bool&                 to_active);

// Pure helper (also used by the test harness): which slice does a workload's
// v3.3 intent select for a background/throttled decision? Latency-critical
// games and GPU dataloaders use the uncapped latency slice.
const char* slice_for_intent(const Workload& wl, PolicyDecision decision);

// Pure memory-orchestration helpers used by the daemon tick and by tests.
// compute_memory_high_bytes() returns 0 (meaning "max") when nothing is
// throttled, otherwise 75% of the summed RSS with a 16 MiB floor so a tiny
// workload cannot produce an unusably small soft limit.
// compute_memory_low_bytes() protects up to the full active/protected RSS but
// never more than half of total RAM.
long compute_memory_high_bytes(long rss_kb);
long compute_memory_low_bytes(long rss_kb, long total_kb);

// Fail-closed decision gate. If the cgroup hierarchy is not delegated/writable,
// destructive and freezing decisions are downgraded to KEEP_BACKGROUND so THM
// never falls back to raw signals it cannot safely audit. Destructive reclaim
// is additionally gated behind an explicit opt-in until its lifecycle has a
// real RAM-pressure benchmark.
PolicyDecision sanitize_decision(PolicyDecision decision,
                                 bool cgroup_healthy,
                                 bool allow_destructive_reclaim);

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
                                             bool user_unattended_idle,
                                             const CpuDemandHint* demand = nullptr,
                                             int reserved_cores_override = -1,
                                             const InputBoost* input_boost = nullptr);

    const CpuSlicePolicy& current_cpu_policy() const { return effective_policy_; }

    // v3.5: place latency work on whole physical cores and keep their SMT
    // siblings out of the bulk background slice. Change-detected: in steady
    // state this performs no cgroup writes. Never signals a process.
    CpuIsolationState apply_smt_isolation(const SmtTopology& topology,
                                          const CpuDemandHint& demand,
                                          PressureLevel cpu_pressure,
                                          bool user_unattended_idle);

    const CpuIsolationState& current_isolation() const { return isolation_; }

private:
    CgroupController&        cgroup_;
    const ProtectedRegistry& registry_;

    // Last values successfully written to the kernel (-1 / -2 = never written).
    struct WrittenState {
        int  protected_weight  = -1;
        int  active_weight     = -1;
        int  latency_weight    = -1;
        int  background_weight = -1;
        long background_quota  = -2;
        int  background_idle   = -1;
    } written_;

    CpuSlicePolicy effective_policy_;
    CpuIsolationState isolation_;
    bool cpuset_written_ = false;
    std::string written_latency_cpuset_;
    std::string written_bg_cpuset_;

    bool           throttle_seen_  = false; // a THROTTLE decision landed this tick
    int            write_backoff_  = 0;     // ticks to wait after a failed write

    // Send signal to all PIDs in list; skip protected PIDs (extra safety)
    void signal_tree(const std::vector<pid_t>& pids, int sig);

    // SIGCONT any PIDs currently in T (stopped) state
    void sigcont_if_stopped(const std::vector<pid_t>& pids);
};

} // namespace thm
