// =============================================================================
// titan-hwm-v3/enforcement/enforcement_plane.cpp
// Phase 9 — implementation
// =============================================================================
#include "enforcement_plane.hpp"
#include "../core/signal_utils.hpp"

#include <algorithm>
#include <fstream>
#include <iostream>
#include <csignal>
#include <cstring>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// signal_tree — send signal to all PIDs; skip protected PIDs (extra safety)
// ─────────────────────────────────────────────────────────────────────────────
void EnforcementPlane::signal_tree(const std::vector<pid_t>& pids, int sig) {
    for (pid_t pid : pids) {
        // Read comm for the protected check
        std::string comm;
        std::ifstream sf("/proc/" + std::to_string(pid) + "/stat");
        std::string tok;
        if (sf >> tok && sf >> tok &&
            tok.size() >= 2 && tok.front() == '(' && tok.back() == ')')
            comm = tok.substr(1, tok.size() - 2);

        // Hard block — never signal a protected process
        if (registry_.is_protected(pid, comm)) {
            std::cerr << "[Enforce] BLOCKED signal " << sig
                      << " to protected PID " << pid << " (" << comm << ")\n";
            continue;
        }

        // signal_process() opens a pidfd, so the protected check above and the
        // delivery are atomic with respect to PID recycling. Gone is a normal
        // outcome for a workload that exited between ticks.
        if (signal_process(pid, sig) == SignalResult::Failed)
            std::cerr << "[Enforce] signal(" << pid << ", " << sig
                      << ") failed: " << std::strerror(errno) << "\n";
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// sigcont_if_stopped — SIGCONT only PIDs in T (stopped) state
// ─────────────────────────────────────────────────────────────────────────────
void EnforcementPlane::sigcont_if_stopped(const std::vector<pid_t>& pids) {
    for (pid_t pid : pids) {
        std::ifstream sf("/proc/" + std::to_string(pid) + "/stat");
        std::string tok;
        char state = '?';
        if (sf >> tok && sf >> tok && sf >> state) {
            if (state == 'T' || state == 't')
                (void)signal_process(pid, SIGCONT);
        }
    }
}

void EnforcementPlane::sigcont_tree(const std::vector<pid_t>& pids) {
    signal_tree(pids, SIGCONT);
}

// ─────────────────────────────────────────────────────────────────────────────
// apply — translate PolicyDecision into kernel actions
// ─────────────────────────────────────────────────────────────────────────────
bool EnforcementPlane::apply(const Workload& wl, PolicyDecision decision) {
    // ── Hard block ─────────────────────────────────────────────────────────
    if (wl.is_protected || registry_.is_protected_any(wl.pids)) {
        // Silently ensure protected workload sits in the PROTECTED slice (not
        // the active one: an active-slice burst would otherwise compete with
        // it, an inversion of what "protected" means) and is not stopped.
        cgroup_.move_to_slice(wl.pids, SLICE_PROTECTED);
        sigcont_if_stopped(wl.pids);
        return false; // indicates protected — caller can log if needed
    }

    // cpu.weight / cpu.max are NOT written here. They are owned by
    // apply_cpu_pressure_policy(), which derives them from the CPU pressure
    // channel once per tick; writing them per workload decision made the two
    // fight and cost a syscall per workload per tick.
    //
    // v3.3: latency-critical work (games, real-time media) and GPU dataloaders
    // use the dedicated latency slice when they are not foreground. It shares
    // the elevated weight but is never given cpu.max or cpu.idle — capping a
    // dataloader starves the GPU, and capping a background game drops frames.
    const char* bg_slice = slice_for_intent(wl, decision);
    switch (decision) {

    case PolicyDecision::KEEP_FULL:
        cgroup_.move_to_slice(wl.pids, SLICE_ACTIVE);
        cgroup_.set_oom_score(wl.pids, OOM_PROTECT);
        sigcont_if_stopped(wl.pids);       // unfreeze if previously stopped
        cgroup_.set_freeze(SLICE_FROZEN, false); // ensure frozen slice is thawed
        break;

    case PolicyDecision::KEEP_BACKGROUND:
        cgroup_.move_to_slice(wl.pids, bg_slice);
        cgroup_.set_oom_score(wl.pids, OOM_NORMAL);
        sigcont_if_stopped(wl.pids);       // background ≠ stopped
        break;

    case PolicyDecision::THROTTLE:
        cgroup_.move_to_slice(wl.pids, bg_slice);
        throttle_seen_ = true; // apply_cpu_pressure_policy() lowers the BG weight
        // Reduce memory.high to 75% of current RSS as a soft cap
        // (exact calculation deferred to daemon tick which has RSS info)
        cgroup_.set_oom_score(wl.pids, OOM_EXPOSE);
        break;

    case PolicyDecision::FREEZE:
        // HC-05: Browser roots must NOT receive SIGSTOP — their network utility
        // processes (TCP keepalive, WebSocket, WebRTC DTLS) run in child threads
        // that share the parent's file descriptors and will lose their connections.
        // For browsers: use cgroup CPU throttle + freeze slice only (no signal).
        if (wl.is_browser_root) {
            cgroup_.move_to_slice(wl.pids, SLICE_FROZEN);
            cgroup_.set_freeze(SLICE_FROZEN, true);
            throttle_seen_ = true;
            cgroup_.set_oom_score(wl.pids, OOM_EXPOSE);
            std::cout << "[Enforce] Cgroup-froze browser workload " << wl.id
                      << " (SIGSTOP skipped — keeping network alive)\n";
        } else {
            // Normal FREEZE: SIGSTOP first — cgroup freeze alone doesn't stop kernel threads
            signal_tree(wl.pids, SIGSTOP);
            cgroup_.move_to_slice(wl.pids, SLICE_FROZEN);
            cgroup_.set_freeze(SLICE_FROZEN, true);
            cgroup_.set_oom_score(wl.pids, OOM_EXPOSE);
            std::cout << "[Enforce] Froze workload " << wl.id
                      << " (" << wl.pids.size() << " PIDs)\n";
        }
        break;

    case PolicyDecision::RECLAIM:
        // ReclaimEngine handles the full 9-step safety sequence.
        // EnforcementPlane only handles the signal delivery part.
        // This case should not be called directly from EnforcementPlane;
        // the daemon calls ReclaimEngine::reclaim() which calls signal_tree.
        std::cerr << "[Enforce] RECLAIM reached enforcement plane directly "
                  << "— use ReclaimEngine::reclaim() instead\n";
        break;
    }

    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// slice_for_intent — pure slice routing used by apply() and by the tests.
const char* slice_for_intent(const Workload& wl, PolicyDecision decision) {
    const bool latency_bg = wl.latency_critical || wl.gpu_feeding;
    switch (decision) {
        case PolicyDecision::KEEP_FULL:      return SLICE_ACTIVE;
        case PolicyDecision::THROTTLE:       return latency_bg ? SLICE_LATENCY
                                                               : SLICE_THROTTLED;
        case PolicyDecision::FREEZE:
        case PolicyDecision::RECLAIM:        return SLICE_FROZEN;
        case PolicyDecision::KEEP_BACKGROUND:
        default:                             return latency_bg ? SLICE_LATENCY
                                                               : SLICE_BACKGROUND;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// Memory-orchestration math (pure — no syscalls, no signals)
//
// THROTTLE is a soft pressure signal: memory.high at 75% of the workload's
// current RSS makes the kernel reclaim from that slice first, rather than
// THM killing the process. memory.low protects only what is actually active
// and never locks more than half of RAM.
// ─────────────────────────────────────────────────────────────────────────────
static constexpr long kMemHighFloorBytes = 16L * 1024 * 1024;

long compute_memory_high_bytes(long rss_kb) {
    if (rss_kb <= 0) return 0; // 0 => memory.high "max"
    const long bytes = (rss_kb * 1024LL * 75) / 100;
    return std::max(bytes, kMemHighFloorBytes);
}

long compute_memory_low_bytes(long rss_kb, long total_kb) {
    if (rss_kb <= 0 || total_kb <= 0) return 0;
    const long wanted = rss_kb * 1024LL;
    const long cap    = (total_kb * 1024LL) / 2;
    return std::min(wanted, cap);
}

// ─────────────────────────────────────────────────────────────────────────────
// sanitize_decision — fail-closed enforcement gate
// ─────────────────────────────────────────────────────────────────────────────
PolicyDecision sanitize_decision(PolicyDecision decision,
                                 bool cgroup_healthy,
                                 bool allow_destructive_reclaim) {
    if (!cgroup_healthy &&
        (decision == PolicyDecision::FREEZE ||
         decision == PolicyDecision::RECLAIM)) {
        return PolicyDecision::KEEP_BACKGROUND;
    }
    if (!allow_destructive_reclaim && decision == PolicyDecision::RECLAIM)
        return PolicyDecision::FREEZE;
    return decision;
}

// ─────────────────────────────────────────────────────────────────────────────
// observed_slice_assignment — bring real unclassified CPU work into the managed
// hierarchy on the very first tick it is seen.
//
// Previously observed workloads were only moved when CPU pressure had already
// reached MODERATE. A focused game / Blender render / training job therefore
// spent the ramp-up phase outside archtitan.slice, where no asymmetric weights
// protected it. Membership is now driven by the workload's own demand, and is
// change-detected by the daemon so this costs no syscalls in steady state.
// ─────────────────────────────────────────────────────────────────────────────
bool observed_slice_assignment(const Workload&       wl,
                               const WorkspaceState& ws,
                               ActivityState         activity,
                               bool&                 to_active) {
    to_active = false;
    if (!wl.observed) return false; // classified work goes through PolicyEngine

    const bool doing_work = (activity == ActivityState::EXECUTING) ||
                            (wl.state == WorkloadState::BACKGROUND_EXECUTING) ||
                            (wl.cpu_pct >= OBSERVED_CPU_DEMAND_PCT);
    if (!doing_work) return false;

    to_active = ws.context_active() && doing_work;
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// apply_cpu_pressure_policy — CPU channel -> cpu.weight + cpu.max headroom
//
// HC-CPU-1: this function only ever writes cgroup scheduling files. It has no
// access to a signal path and takes no workload, so CPU pressure cannot cause a
// freeze or a kill by construction.
// ─────────────────────────────────────────────────────────────────────────────
CpuSlicePolicy EnforcementPlane::apply_cpu_pressure_policy(PressureLevel cpu_pressure,
                                                           int online_cpus,
                                                           bool user_unattended_idle,
                                                           const CpuDemandHint* demand,
                                                           int reserved_cores_override,
                                                           const InputBoost* input_boost) {
    CpuSlicePolicy policy = compute_cpu_slice_policy(cpu_pressure, online_cpus,
                                                     user_unattended_idle,
                                                     demand, reserved_cores_override);
    if (input_boost) apply_input_boost(policy, *input_boost, online_cpus);

    // A memory-driven THROTTLE only lowers the dedicated throttled slice.
    // Executing background work must keep the CPU-policy weight: penalising it
    // here caused the 9.8x compile regression in the QEMU A/B.
    int throttled_weight = policy.background_weight;
    if (throttle_seen_)
        throttled_weight = std::min(throttled_weight, CPU_WEIGHT_THROTTLE);
    throttle_seen_ = false;

    effective_policy_ = policy;

    // After a failed write (hierarchy not delegated / not root) back off instead
    // of spamming the log and sysfs at 5 Hz.
    if (write_backoff_ > 0) { --write_backoff_; return policy; }

    bool failed = false;
    auto put_weight = [&](const char* slice, int want, int& have) {
        if (want == have) return;
        if (cgroup_.set_cpu_weight(slice, want)) have = want; else failed = true;
    };
    put_weight(SLICE_PROTECTED,  policy.protected_weight,  written_.protected_weight);
    put_weight(SLICE_ACTIVE,     policy.active_weight,     written_.active_weight);
    put_weight(SLICE_LATENCY,    policy.latency_weight,    written_.latency_weight);
    put_weight(SLICE_BACKGROUND, policy.background_weight, written_.background_weight);
    put_weight(SLICE_THROTTLED,  throttled_weight,         written_.throttled_weight);

    if (policy.background_quota_us != written_.background_quota) {
        if (cgroup_.set_cpu_max(SLICE_BACKGROUND, policy.background_quota_us, policy.period_us))
            written_.background_quota = policy.background_quota_us;
        else
            failed = true;
    }
    if (policy.background_quota_us != written_.throttled_quota) {
        if (cgroup_.set_cpu_max(SLICE_THROTTLED, policy.background_quota_us, policy.period_us))
            written_.throttled_quota = policy.background_quota_us;
        else
            failed = true;
    }

    const int want_idle = policy.background_idle ? 1 : 0;
    if (want_idle != written_.background_idle) {
        if (cgroup_.set_cpu_idle(SLICE_BACKGROUND, policy.background_idle))
            written_.background_idle = want_idle;
        else
            failed = true;
    }
    if (want_idle != written_.throttled_idle) {
        if (cgroup_.set_cpu_idle(SLICE_THROTTLED, policy.background_idle))
            written_.throttled_idle = want_idle;
        else
            failed = true;
    }

    if (failed) write_backoff_ = 25; // ~5 s at the 200 ms daemon tick
    return policy;
}

// ─────────────────────────────────────────────────────────────────────────────
// apply_smt_isolation — v3.5 whole-core placement (HC-CPU-1: scheduling only)
// ─────────────────────────────────────────────────────────────────────────────
CpuIsolationState EnforcementPlane::apply_smt_isolation(
        const SmtTopology& topology,
        const CpuDemandHint& demand,
        PressureLevel cpu_pressure,
        bool user_unattended_idle) {
    if (!topology.valid()) return isolation_; // cannot safely change cpusets

    const auto plan = plan_smt_isolation(topology,
                                         demand.latency_workloads,
                                         demand.gpu_feeders,
                                         cpu_pressure,
                                         user_unattended_idle);

    std::vector<int> all;
    for (int cpu = 0; cpu < topology.logical_cpus; ++cpu) all.push_back(cpu);
    const std::string want_latency = plan.active ? format_cpu_list(plan.latency_ids)
                                                 : format_cpu_list(all);
    const std::string want_bg = plan.active ? format_cpu_list(plan.background_ids)
                                            : format_cpu_list(all);

    const bool latency_changed = !cpuset_written_ ||
                                 want_latency != written_latency_cpuset_;
    const bool bg_changed = !cpuset_written_ || want_bg != written_bg_cpuset_;

    bool ok = true;
    if (latency_changed) {
        // Foreground and latency slices share the reserved physical cores.
        ok &= cgroup_.set_cpuset(SLICE_ACTIVE, want_latency);
        ok &= cgroup_.set_cpuset(SLICE_LATENCY, want_latency);
    }
    if (bg_changed) {
        ok &= cgroup_.set_cpuset(SLICE_BACKGROUND, want_bg);
        ok &= cgroup_.set_cpuset(SLICE_THROTTLED,  want_bg);
    }
    if (!ok) return isolation_; // report only writes the kernel accepted

    written_latency_cpuset_ = want_latency;
    written_bg_cpuset_ = want_bg;
    cpuset_written_ = true;

    isolation_.active = plan.active;
    isolation_.reserved_physical_cores = plan.reserved_physical_cores;
    isolation_.latency_cpus = plan.active ? want_latency : "";
    isolation_.background_cpus = plan.active ? want_bg : "";
    return isolation_;
}

} // namespace thm
