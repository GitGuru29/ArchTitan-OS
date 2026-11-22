// =============================================================================
// titan-hwm-v3/enforcement/cgroup_controller.cpp
// Phase 7 — implementation
// =============================================================================
#include "cgroup_controller.hpp"

#include <algorithm>
#include <fstream>
#include <iostream>
#include <filesystem>
#include <system_error>
#include <unistd.h>

namespace fs = std::filesystem;

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::write_file(const std::string& path, const std::string& value) {
    std::ofstream f(path);
    if (!f.is_open()) {
        std::cerr << "[cgroup] Cannot write " << path << "\n";
        return false;
    }
    f << value;
    // The kernel receives the data on flush/close, and can reject it (EINVAL for
    // a malformed cgroup.subtree_control, for example) only then. Checking
    // good() before flushing reported success for writes that never happened,
    // which is how enforcement silently degraded to a no-op.
    f.flush();
    const bool ok = f.good();
    f.close();
    if (!ok) {
        std::cerr << "[cgroup] Write to " << path << " failed"
                  << " (value='" << value << "')\n";
        return false;
    }
    return true;
}

bool CgroupController::mkdir_p(const std::string& path) {
    std::error_code ec;
    fs::create_directories(path, ec);
    if (ec) {
        std::cerr << "[cgroup] mkdir_p failed for " << path
                  << ": " << ec.message() << "\n";
        return false;
    }
    return true;
}

std::string CgroupController::slice_path(const std::string& slice_name) {
    return std::string(SLICE_ROOT) + "/" + slice_name;
}

// ─────────────────────────────────────────────────────────────────────────────
// setup_slices — create the 4 sub-slices under archtitan.slice (idempotent)
// Requires Delegate=yes in /etc/systemd/system/archtitan.slice
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// enable_controllers — delegate the controllers THM needs into the slice
//
// On cgroup v2 a controller interface file (cpu.weight, memory.high, ...) only
// exists in a child cgroup if that controller is enabled in the PARENT's
// cgroup.subtree_control. systemd programs subtree_control from the unit's
// accounting settings, and for this slice that yields "memory pids" but not
// "cpu" — so archtitan-active.slice and friends come up with no cpu.weight and
// set_cpu_weight() silently fails, leaving CPU throttling a no-op.
//
// The sub-slices are created by THM via mkdir, not by systemd, so systemd has no
// reason to delegate cpu to them. THM therefore enables the controllers it
// actually uses. Best-effort: a failure here degrades enforcement but must not
// stop the daemon, so it is logged and the caller continues.
// ─────────────────────────────────────────────────────────────────────────────
void CgroupController::enable_controllers() {
    static const char* kWanted[] = { "cpu", "cpuset", "memory", "pids" };

    const std::string subtree = std::string(SLICE_ROOT) + "/cgroup.subtree_control";

    // Only request controllers this kernel actually offers, to avoid EBUSY on
    // a controller the parent never delegated down.
    std::string available;
    {
        std::ifstream f(std::string(SLICE_ROOT) + "/cgroup.controllers");
        if (f.good()) std::getline(f, available);
    }

    std::string want;
    for (const char* c : kWanted) {
        if (available.find(c) == std::string::npos) continue;
        // Tokens MUST be space separated. cgroup.subtree_control rejects the
        // unseparated form ("+cpu+memory") with EINVAL.
        if (!want.empty()) want += ' ';
        want += '+';
        want += c;
    }
    if (want.empty()) {
        std::cerr << "[cgroup] No controllers available in " << SLICE_ROOT << "\n";
        return;
    }

    // subtree_control is write-only for reads of current state; a write of
    // "+cpu" is idempotent, so simply re-requesting everything is correct.
    write_file(subtree, want);
}

bool CgroupController::setup_slices() {
    // Verify the root slice exists (systemd must have created it)
    if (!fs::exists(SLICE_ROOT)) {
        std::cerr << "[cgroup] archtitan.slice not found at " << SLICE_ROOT
                  << " — is systemd unit loaded?\n";
        return false;
    }

    // Must happen before the sub-slices are created: a controller enabled in the
    // slice's subtree_control is what materialises the interface files below it.
    enable_controllers();

    bool ok = true;
    for (const char* name : {SLICE_PROTECTED, SLICE_ACTIVE,
                              SLICE_BACKGROUND, SLICE_THROTTLED,
                              SLICE_LATENCY, SLICE_FROZEN}) {
        ok &= mkdir_p(slice_path(name));
    }

    // Enable memory accounting in the slices we manage
    for (const char* name : {SLICE_ACTIVE, SLICE_BACKGROUND,
                              SLICE_THROTTLED, SLICE_LATENCY,
                              SLICE_FROZEN}) {
        ok &= write_file(slice_path(name) + "/memory.oom.group", "1");
    }

    // A previous THM version may have left a slice-wide memory.high on the
    // background slice. Clear it once at startup so executing builds never
    // inherit a stale soft ceiling from an older daemon.
    ok &= write_file(slice_path(SLICE_BACKGROUND) + "/memory.high", "max");

    // Definitive writability probe. The sub-slice directories existing is NOT
    // sufficient: under an undelegated slice they exist (created by systemd, or
    // by a previous privileged run) but every control-file write fails EACCES,
    // so enforcement silently degrades to a no-op. Writing cgroup.freeze=0 is
    // idempotent and succeeds only when we can actually drive the hierarchy.
    ok &= write_file(slice_path(SLICE_FROZEN) + "/cgroup.freeze", "0");

    if (ok) {
        std::cout << "[cgroup] archtitan.slice hierarchy ready.\n";
    } else {
        std::cerr << "[cgroup] archtitan.slice hierarchy NOT writable by uid "
                  << getuid() << " — enforcement would be a no-op here.\n";
    }
    return ok;
}

// ─────────────────────────────────────────────────────────────────────────────
// move_to_slice — write PIDs to cgroup.procs of target slice
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::move_to_slice(const std::vector<pid_t>& pids,
                                      const std::string& slice_name) {
    std::string procs_path = slice_path(slice_name) + "/cgroup.procs";
    bool ok = true;
    for (pid_t pid : pids) {
        // Skip if /proc/<pid> no longer exists
        if (!fs::exists("/proc/" + std::to_string(pid))) continue;
        ok &= write_file(procs_path, std::to_string(pid));
    }
    return ok;
}

// ─────────────────────────────────────────────────────────────────────────────
// set_cpu_weight — write cpu.weight (1–10000)
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_cpu_weight(const std::string& slice_name, int weight) {
    weight = std::max(1, std::min(10000, weight));
    return write_file(slice_path(slice_name) + "/cpu.weight",
                      std::to_string(weight));
}

// ─────────────────────────────────────────────────────────────────────────────
// set_cpu_max — write cpu.max as "<quota_us|max> <period_us>"
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_cpu_max(const std::string& slice_name,
                                   long quota_us, long period_us) {
    // The kernel rejects periods outside 1 ms .. 1 s.
    period_us = std::max(1000L, std::min(1000000L, period_us));
    const std::string dir   = slice_path(slice_name);
    const std::string quota = (quota_us <= 0) ? std::string("max")
                                              : std::to_string(quota_us);
    // Smooth period-boundary unthrottle spikes via cpu.max.burst (20% of one
    // core's period when capped, 0 when uncapped) if supported by the kernel.
    const std::string burst_path = dir + "/cpu.max.burst";
    if (fs::exists(burst_path)) {
        const long burst_us = (quota_us > 0) ? std::min(quota_us, period_us / 5) : 0L;
        write_file(burst_path, std::to_string(burst_us));
    }
    return write_file(dir + "/cpu.max",
                      quota + " " + std::to_string(period_us));
}

// ─────────────────────────────────────────────────────────────────────────────
// set_cpuset — v3.5 SMT-aware placement (scheduling only, no signals)
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_cpuset(const std::string& slice_name,
                                  const std::string& cpus) {
    const std::string dir = slice_path(slice_name);
    if (!fs::exists(dir + "/cpuset.cpus")) return true; // kernel without cpuset

    // An empty list means "give the slice the whole machine again".
    std::string full;
    if (cpus.empty()) {
        std::ifstream f(std::string(SLICE_ROOT) + "/cpuset.cpus.effective");
        if (!(f >> full)) {
            f.clear();
            f.open(std::string(SLICE_ROOT) + "/cpuset.cpus");
            if (!(f >> full)) full = "0";
        }
    }
    const std::string value = cpus.empty() ? full : cpus;

    // cpuset.mems must be non-empty before tasks can be placed; inherit the
    // parent's node list instead of assuming NUMA node 0.
    std::string mems;
    {
        std::ifstream f(std::string(SLICE_ROOT) + "/cpuset.mems.effective");
        if (!(f >> mems)) {
            f.clear();
            f.open(std::string(SLICE_ROOT) + "/cpuset.mems");
            if (!(f >> mems)) mems = "0";
        }
    }
    write_file(dir + "/cpuset.mems", mems);
    return write_file(dir + "/cpuset.cpus", value);
}

// ─────────────────────────────────────────────────────────────────────────────
// set_cpu_idle — write cpu.idle (1 = run only when the CPU would be idle)
//
// Unsupported kernels simply do not have the file; that is not an enforcement
// failure, so report success and let the caller continue.
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_cpu_idle(const std::string& slice_name, bool idle) {
    const std::string path = slice_path(slice_name) + "/cpu.idle";
    if (!fs::exists(path)) return true;
    return write_file(path, idle ? "1" : "0");
}

// ─────────────────────────────────────────────────────────────────────────────
// read_cpu_stat — parse cpu.stat counters
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::read_cpu_stat(const std::string& slice_name,
                                     CpuSliceStat& out) const {
    std::ifstream f(slice_path(slice_name) + "/cpu.stat");
    if (!f.is_open()) return false;
    std::string key;
    uint64_t val = 0;
    while (f >> key >> val) {
        if      (key == "nr_periods")     out.nr_periods     = val;
        else if (key == "nr_throttled")   out.nr_throttled   = val;
        else if (key == "throttled_usec") out.throttled_usec = val;
    }
    return true;
}

// ─────────────────────────────────────────────────────────────────────────────
// compute_reserved_cores — v3.4 adaptive headroom (pure, no syscalls)
//
// The fixed "one core at HIGH, two at CRITICAL" rule was blind to what was
// actually running. A foreground game plus a GPU dataloader needs more room;
// a thermally throttled laptop doing only bulk work can afford less. The
// reservation is expressed in LOGICAL cpus because cpu.max counts those, and
// is multiplied on SMT systems where siblings share execution units.
// ─────────────────────────────────────────────────────────────────────────────
int compute_reserved_cores(PressureLevel cpu_pressure,
                           int online_cpus,
                           bool user_unattended_idle,
                           const CpuDemandHint& demand) {
    const int cpus = std::max(1, online_cpus);
    if (user_unattended_idle || cpus < 2 || cpu_pressure < PressureLevel::HIGH)
        return 0; // no cap below HIGH, or nobody is here to feel the latency

    int reserve = (cpu_pressure >= PressureLevel::CRITICAL) ? 2 : 1;

    // A running game / real-time app and a GPU dataloader each need their own
    // core; otherwise they lose frames or starve the accelerator under cpu.max.
    if (demand.latency_workloads > 0) ++reserve;
    if (demand.gpu_feeders > 0)       ++reserve;

    // If the foreground is already close to saturating the cores we left it,
    // grow the reservation instead of making it contend with bulk work.
    const int left_for_fg = std::max(1, cpus - reserve);
    if (demand.foreground_cpu_pct >= 0.85f * 100.0f * left_for_fg) ++reserve;

    // SMT siblings compete for the same execution units: reserve whole
    // physical cores, not a single logical thread of one.
    if (demand.smt_siblings) reserve *= 2;

    // Thermal throttling already caps foreground clocks. Clawing back one
    // logical CPU keeps bulk throughput without a visible desktop regression.
    if (demand.cpu_temp_c >= 80.0f && reserve > 1) --reserve;

    // Never take more than half the machine, never leave the BG slice empty.
    const int cap = std::max(1, cpus / 2);
    return std::clamp(reserve, 1, std::min(cap, cpus - 1));
}

// ─────────────────────────────────────────────────────────────────────────────
// AdaptiveHeadroomTracker — 3-tick confirmation, immediate reset on transitions
// ─────────────────────────────────────────────────────────────────────────────
int AdaptiveHeadroomTracker::update(int target, PressureLevel pressure,
                                    bool unattended) {
    if (current_ < 0 || pressure != last_pressure_ || unattended != last_unattended_) {
        current_ = candidate_ = target;
        streak_ = 0;
        last_pressure_ = pressure;
        last_unattended_ = unattended;
        return current_;
    }
    if (target == current_) {
        candidate_ = target;
        streak_ = 0;
        return current_;
    }
    if (target == candidate_) {
        ++streak_;
    } else {
        candidate_ = target;
        streak_ = 0;
    }
    if (streak_ >= kRequiredStreak) {
        current_ = candidate_;
        streak_ = 0;
    }
    return current_;
}

// ─────────────────────────────────────────────────────────────────────────────
// should_lift_unattended_cap — presence gate for the background bandwidth cap
//
// Idle detection alone is not enough: an unattended game, benchmark or GPU
// dataloader produces no keyboard/mouse events but still needs every core it
// can get. Only lift the cap when no latency-critical or GPU-feeding workload
// is active. Bulk-only work (a compile left running) still gets the lift.
// ─────────────────────────────────────────────────────────────────────────────
bool should_lift_unattended_cap(bool user_unattended_idle,
                                const CpuDemandHint& demand) {
    if (!user_unattended_idle) return false;
    return demand.latency_workloads == 0 && demand.gpu_feeders == 0;
}

// ─────────────────────────────────────────────────────────────────────────────
// compute_cpu_slice_policy — pure (pressure, cores, presence, demand) -> cgroup
// ─────────────────────────────────────────────────────────────────────────────
CpuSlicePolicy compute_cpu_slice_policy(PressureLevel cpu_pressure,
                                        int online_cpus,
                                        bool user_unattended_idle,
                                        const CpuDemandHint* demand,
                                        int reserved_cores_override) {
    const int cpus = online_cpus < 1 ? 1 : online_cpus;

    CpuSlicePolicy p;
    p.period_us = CFS_SMOOTH_PERIOD_US;

    switch (cpu_pressure) {
        case PressureLevel::NORMAL:
            p.protected_weight = 2000; p.active_weight =  500;
            p.latency_weight = 450;   p.background_weight = 50;
            break;
        case PressureLevel::MODERATE:
            p.protected_weight = 2000; p.active_weight =  800;
            p.latency_weight = 750;   p.background_weight = 25;
            break;
        case PressureLevel::HIGH:
            p.protected_weight = 2000; p.active_weight = 1000;
            p.latency_weight = 950;   p.background_weight = 10;
            break;
        case PressureLevel::CRITICAL:
            p.protected_weight = 5000; p.active_weight = 1000;
            p.latency_weight = 1000;  p.background_weight = 10;
            break;
    }

    const bool wants_cap = (cpu_pressure >= PressureLevel::HIGH);
    if (!wants_cap) {
        return p; // quota 0 == max, background_max_pct stays 100
    }

    const CpuDemandHint empty_hint;
    if (should_lift_unattended_cap(user_unattended_idle,
                                   demand ? *demand : empty_hint)) {
        p.unattended_lift = true; // nobody is here to feel latency: lift the cap
        return p;
    }

    // v3.4: adaptive reservation. The daemon passes a 3-tick-smoothed value;
    // direct callers (benchmarks, tests) get the pure computation from the
    // hint, or the classic fixed rule when no hint is supplied.
    // If the cap was not lifted, the user is effectively present for CPU
    // arbitration — even when raw idle detection said "away" but a game or GPU
    // feeder suppressed the lift. Passing raw idle here would reserve 0 cores.
    const int reserve_cores = (reserved_cores_override >= 0)
        ? reserved_cores_override
        : compute_reserved_cores(cpu_pressure, cpus, false,
                                 demand ? *demand : empty_hint);
    p.reserved_cores = reserve_cores;
    const long quota_cores  = static_cast<long>(std::max(1, cpus - reserve_cores));
    p.background_quota_us = (cpus >= 2)
        ? quota_cores * p.period_us
        : (p.period_us * 3) / 4;
    p.background_max_pct = 100.0f * static_cast<float>(p.background_quota_us) /
                           (static_cast<float>(p.period_us) * static_cast<float>(cpus));
    p.headroom_engaged = true;
    p.background_idle  = (cpu_pressure >= PressureLevel::CRITICAL);
    return p;
}

// ─────────────────────────────────────────────────────────────────────────────
// set_memory_high — limit memory.high (bytes; 0 = max / remove limit)
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_memory_high(const std::string& slice_name, long bytes) {
    std::string val = (bytes <= 0) ? "max" : std::to_string(bytes);
    return write_file(slice_path(slice_name) + "/memory.high", val);
}

// ─────────────────────────────────────────────────────────────────────────────
// set_memory_low — soft memory protection (bytes; 0 = remove)
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_memory_low(const std::string& slice_name, long bytes) {
    std::string val = (bytes <= 0) ? "0" : std::to_string(bytes);
    return write_file(slice_path(slice_name) + "/memory.low", val);
}

// ─────────────────────────────────────────────────────────────────────────────
// set_freeze — write cgroup.freeze (1 = frozen, 0 = thawed)
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::set_freeze(const std::string& slice_name, bool freeze) {
    return write_file(slice_path(slice_name) + "/cgroup.freeze",
                      freeze ? "1" : "0");
}

// ─────────────────────────────────────────────────────────────────────────────
// set_oom_score — write /proc/<pid>/oom_score_adj (-1000 to +1000)
// ─────────────────────────────────────────────────────────────────────────────
void CgroupController::set_oom_score(const std::vector<pid_t>& pids, int score) {
    score = std::max(-1000, std::min(1000, score));
    for (pid_t pid : pids) {
        std::string path = "/proc/" + std::to_string(pid) + "/oom_score_adj";
        write_file(path, std::to_string(score));
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// hierarchy_healthy — verify cgroup.controllers has "cpu memory" delegated
// ─────────────────────────────────────────────────────────────────────────────
bool CgroupController::hierarchy_healthy() const {
    std::ifstream f(std::string(SLICE_ROOT) + "/cgroup.controllers");
    if (!f.is_open()) return false;
    std::string content((std::istreambuf_iterator<char>(f)),
                         std::istreambuf_iterator<char>());
    return content.find("cpu") != std::string::npos &&
           content.find("memory") != std::string::npos;
}

} // namespace thm
