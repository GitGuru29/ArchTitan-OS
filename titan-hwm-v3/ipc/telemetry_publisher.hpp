// =============================================================================
// titan-hwm-v3/ipc/telemetry_publisher.hpp
//
// Telemetry sidecar for THM v3.
//
// The v3 daemon is a workload orchestrator and, by design, publishes nothing to
// userspace. The desktop shell still needs to *see* what it is doing, so this
// publisher emits a compact JSON snapshot of the daemon's live state to a
// well-known runtime path on every tick (rate-limited to ~1 Hz / on change).
//
// Consumer: subsystems/titan-sysmon (the left-edge System Monitor overlay).
// Beneficiaries: titan-hwm-waybar, titan-hud-context, titanfetch (which
// previously read a dead `/tmp/titan_hwm_state`).
// =============================================================================
#pragma once

#include "../core/types.hpp"

#include <string>
#include <vector>
#include <cstdint>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// TelemetryWorkload — one classified workload, flattened for JSON.
// ─────────────────────────────────────────────────────────────────────────────
struct TelemetryWorkload {
    uint32_t    id           = 0;
    pid_t       root_pid     = 0;
    int         workspace_id = -1;
    std::string name;                 // root cmdline (human label)
    std::string type;                 // to_string(WorkloadType)
    std::string state;                // to_string(WorkloadState)
    int         pid_count    = 0;
    long        mem_kb       = 0;     // summed RSS of member PIDs
    float       cpu_pct      = 0.0f;  // summed CPU% of member PIDs
    bool        observed     = false; // telemetry-only (no enforcement authority)
    // v3.3 intent — shows why a workload landed in a particular CPU slice.
    bool        latency_critical = false;
    bool        throughput_bulk  = false;
    bool        gpu_feeding      = false;
};

// ─────────────────────────────────────────────────────────────────────────────
// UnmanagedProc — a process tree root THM sees but does not manage.
// Surfaced by `titan-hwm scan` so an empty registry is never a mystery.
// ─────────────────────────────────────────────────────────────────────────────
struct UnmanagedProc {
    pid_t       pid      = 0;
    std::string comm;
    float       cpu_pct  = 0.0f;
    long        rss_kb   = 0;
    std::string reason;               // why it is not a tracked workload
};

// ─────────────────────────────────────────────────────────────────────────────
// TelemetrySnapshot — full daemon state for one tick.
// ─────────────────────────────────────────────────────────────────────────────
struct TelemetrySnapshot {
    std::string version     = "3.2.0";
    long long   timestamp_ms = 0;     // wall clock (epoch ms)
    long long   uptime_seconds = 0;

    // Resource pressure
    std::string pressure_level = "NORMAL";   // NORMAL|MODERATE|HIGH|CRITICAL
    float       psi_some_avg10 = 0.0f;
    float       psi_full_avg10 = 0.0f;
    float       mem_used_pct   = 0.0f;
    long        mem_total_kb     = 0;
    long        mem_available_kb = 0;

    // CPU pressure & asymmetric scheduling (HC-CPU-1: scheduling/headroom only, never kills)
    std::string cpu_pressure_level       = "NORMAL";
    std::string composite_pressure_level = "NORMAL";
    bool        cpu_psi_valid    = false;
    float       cpu_psi_avg10    = 0.0f;
    float       cpu_psi_avg60    = 0.0f;
    float       cpu_psi_avg300   = 0.0f;
    float       cpu_psi_inst     = -1.0f; // per-tick PSI delta (-1 = unavailable)
    float       load1            = 0.0f;
    float       load5            = 0.0f;
    float       load15           = 0.0f;
    float       load_ratio       = 0.0f;
    int         online_cpus      = 1;
    int         runnable_procs   = 0;
    int         total_procs      = 0;
    int         protected_cpu_weight   = 2000;
    int         active_cpu_weight      = 500;
    int         latency_cpu_weight     = 450;
    int         background_cpu_weight  = 50;
    float       background_cpu_max_pct = 100.0f;
    bool        cpu_headroom_engaged   = false;
    int         reserved_headroom_cores = 0; // v3.4 adaptive reservation (logical CPUs)
    bool        smt_isolation_active    = false; // v3.5 whole-core placement in effect
    int         isolated_physical_cores = 0;
    std::string latency_cpuset;                  // e.g. "0,4,1,5"
    std::string background_cpuset;               // e.g. "2,3,6,7"
    bool        background_cpu_idle    = false;
    bool        unattended_lift        = false;
    float       cpu_temp_c             = 0.0f;
    unsigned long long bg_nr_periods   = 0;
    unsigned long long bg_nr_throttled = 0;
    unsigned long long bg_throttled_usec = 0;

    // Orchestration
    std::string governor = "schedutil";      // powersave|schedutil|performance
    int         workload_count      = 0;     // all tracked entries
    int         active_workloads    = 0;     // ACTIVE + BACKGROUND_EXECUTING
    int         classified_workloads = 0;    // non-observed (enforcement-eligible)
    int         observed_workloads   = 0;    // telemetry-only

    // Process inventory — makes `0 workloads` self-explanatory.
    int         processes_seen      = 0;
    int         processes_protected = 0;
    int         processes_assigned  = 0;     // covered by a tracked workload
    int         processes_unmanaged = 0;     // seen, not protected, not assigned
    bool        hyprland_connected  = false;

    // Top unmanaged user processes (bounded list, sorted by CPU desc).
    std::vector<UnmanagedProc> top_unmanaged;

    // Most recent non-trivial enforcement action ("" when none yet).
    bool        has_last_action = false;
    std::string last_action;                 // THROTTLE|FREEZE|RECLAIM
    std::string last_action_target;          // workload name
    pid_t       last_action_pid = 0;

    std::vector<TelemetryWorkload> workloads;
};

// ─────────────────────────────────────────────────────────────────────────────
// TelemetryPublisher — atomic, change-detected JSON writer.
// ─────────────────────────────────────────────────────────────────────────────
class TelemetryPublisher {
public:
    explicit TelemetryPublisher(std::string path = "/run/archtitan/thm-state.json");

    // Serialize `snap` and write it if the payload changed or more than
    // `min_interval_ms` elapsed since the last write. Atomic (tmp + rename).
    void publish(const TelemetrySnapshot& snap, long long min_interval_ms = 1000);

    const std::string& path() const { return path_; }

private:
    std::string path_;
    std::string last_payload_;
    long long   last_write_ms_ = 0;
};

// Compact JSON serializer (exposed for unit tests).
std::string serialize_snapshot(const TelemetrySnapshot& snap);

} // namespace thm
