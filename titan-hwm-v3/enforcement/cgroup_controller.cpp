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
    static const char* kWanted[] = { "cpu", "memory", "pids" };

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
                              SLICE_BACKGROUND, SLICE_FROZEN}) {
        ok &= mkdir_p(slice_path(name));
    }

    // Enable memory accounting in the slices we manage
    for (const char* name : {SLICE_ACTIVE, SLICE_BACKGROUND, SLICE_FROZEN}) {
        ok &= write_file(slice_path(name) + "/memory.oom.group", "1");
    }

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
// compute_cpu_slice_policy — pure (pressure, cores, presence) -> cgroup values
// ─────────────────────────────────────────────────────────────────────────────
CpuSlicePolicy compute_cpu_slice_policy(PressureLevel cpu_pressure,
                                        int online_cpus,
                                        bool user_unattended_idle) {
    const int cpus = online_cpus < 1 ? 1 : online_cpus;

    CpuSlicePolicy p;
    p.period_us = CFS_SMOOTH_PERIOD_US;

    switch (cpu_pressure) {
        case PressureLevel::NORMAL:
            p.protected_weight = 2000; p.active_weight =  500; p.background_weight = 50;
            break;
        case PressureLevel::MODERATE:
            p.protected_weight = 2000; p.active_weight =  800; p.background_weight = 25;
            break;
        case PressureLevel::HIGH:
            p.protected_weight = 2000; p.active_weight = 1000; p.background_weight = 10;
            break;
        case PressureLevel::CRITICAL:
            p.protected_weight = 5000; p.active_weight = 1000; p.background_weight = 10;
            break;
    }

    const bool wants_cap = (cpu_pressure >= PressureLevel::HIGH);
    if (!wants_cap) {
        return p; // quota 0 == max, background_max_pct stays 100
    }

    if (user_unattended_idle) {
        p.unattended_lift = true; // nobody is here to feel latency: lift the cap
        return p;
    }

    // (N-1) cores of bandwidth; 75% of the single core when N == 1.
    p.background_quota_us = (cpus >= 2)
        ? static_cast<long>(cpus - 1) * p.period_us
        : (p.period_us * 3) / 4;
    p.background_max_pct = 100.0f * static_cast<float>(p.background_quota_us) /
                           (static_cast<float>(p.period_us) * static_cast<float>(cpus));
    p.headroom_engaged = true;
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
