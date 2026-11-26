# Titan Hardware Manager v3 — Full Technical Report

**Subsystems:** CPU Pressure Engine + Memory Management System  
**Version:** THM v3.2.0 (as reported by `titan-hwm status`)  
**Repository commit:** `bb45fb3` (`fix(thm-v3): classify standalone games and guard unattended cap`)  
**Date:** 2026-11-20  
**Host used for validation:** 11th-gen laptop, 4 physical / 8 logical CPUs (`cpu0` siblings `0,4`), Intel Iris Xe iGPU + NVIDIA GeForce MX350, 15 GB RAM, Linux `6.18.59-1-lts`, Hyprland on Wayland/XWayland.

---

## 1. Executive Summary

Titan Hardware Manager v3 (THM v3) is a **workload-centric resource orchestrator** for ArchTitan OS. It replaces the earlier workspace-profile model with a system that classifies real work, observes execution, and arbitrates resources through Linux cgroup v2.

The system has two distinct resource planes:

| Plane | Problem it solves | Enforcement levers | Signal path |
|---|---|---|---|
| **Memory management** | RAM exhaustion, swapping, OOM risk | `memory.high`, `memory.oom.group`, `oom_score_adj`, `cgroup.freeze`, reclaim | May freeze/reclaim idle work under pressure, with strict safety checks |
| **CPU pressure engine** | Runqueue congestion, foreground starvation, frame/input latency loss | `cpu.weight`, `cpu.max` + `cpu.max.burst`, `cpu.idle`, `cpuset`, governor hints, input boost | **Never signals** — no kill, stop, or freeze (HC-CPU-1) |

The defining invariant is **HC-CPU-1**: CPU pressure can change *scheduling*, never process lifetime. The memory plane receives only `memory_plane_pressure()`, never the CPU or composite channel. This makes it structurally impossible for a compile storm to cause a THM-initiated kill.

Current state at `bb45fb3`:

- `./build/thm_test_runner` → **38/38 PASSED**
- Synthetic CPU headroom benchmark → **8/8 scorecard passed**, zero kills/stops
- Both `origin/main` and `origin/feat/thm-cpu-pressure-engine` point to `bb45fb3`

---

## 2. Architecture Overview

### 2.1 Layered decomposition

```text
┌────────────────────────────────────────────────────────────────────────┐
│ INPUT LAYER                                                            │
│  /proc scanner │ Hyprland IPC │ PSI (cpu/mem) │ meminfo │ loadavg       │
│  /dev/input evdev │ thermal zones │ cgroup cpu.stat                    │
├────────────────────────────────────────────────────────────────────────┤
│ CLASSIFICATION & ACTIVITY LAYER                                        │
│  OwnershipGraph │ FusionClassifier │ ExecutionDetector │ SmtTopology   │
├────────────────────────────────────────────────────────────────────────┤
│ DECISION LAYER                                                         │
│  WorkloadManager state machine │ PolicyEngine │ PressureLevel /        │
│  CpuPressureController │ AdaptiveHeadroomTracker │ InputFeedForward     │
├────────────────────────────────────────────────────────────────────────┤
│ ENFORCEMENT LAYER                                                      │
│  EnforcementPlane │ CgroupController (v2) │ ReclaimEngine (9-step)     │
├────────────────────────────────────────────────────────────────────────┤
│ SAFETY GATE                                                            │
│  ProtectedRegistry (tiered anti-spoof hard block)                      │
└────────────────────────────────────────────────────────────────────────┘
```

### 2.2 Main tick loop

The daemon runs at **200 ms (5 Hz)** (`tick_ms = 200` in `daemon/daemon.cpp`). Each tick:

1. Refreshes the process graph (`refresh_proc_graph`).
2. Refreshes Hyprland workspace/window visibility.
3. Reads memory info, memory PSI, CPU PSI, load average, and CPU temperature.
4. Evaluates `CpuPressureController::evaluate()` → `SystemPressure`.
5. Classifies new workloads and retries observed/classified workloads for drift.
6. Detects execution state and aggregates per-workload CPU%.
7. Drives the workload state machine and memory policy.
8. Builds `CpuDemandHint` and computes CPU slice policy.
9. Applies SMT isolation, input boost, and cgroup writes.
10. Publishes telemetry and enforces memory decisions.

Since Task 7, expensive process metadata is cached: `/proc/<pid>/stat` is read every tick; `cmdline`, `statm`, UID, SID, `exe`, and `cgroup` refresh at 1 Hz. Average scan cost after that change: ~7.5 ms/tick over ~285 PIDs.

---

## 3. CPU Pressure Engine

### 3.1 Problem: the memory-centric gap

Earlier THM versions derived a single pressure scalar from `/proc/meminfo` and `/proc/pressure/memory`. A machine with plenty of free RAM but saturated runqueues (parallel `cargo build`, `ninja`, encoding farms) reported `NORMAL`. Background workers then took all cores, and compositor/input/audio latency spiked.

Memory pressure cannot solve this: killing a compile does not reduce CPU contention in a useful way. CPU pressure needs **runqueue decongestion**, not reclamation.

### 3.2 Signals

| Signal | Source | Role |
|---|---|---|
| CPU PSI `some avg10/avg60/avg300` | `/proc/pressure/cpu` | Sustained runnable-stall trend; authoritative at the top levels |
| CPU PSI `total=` delta | same file, monotonic microseconds | Per-tick instantaneous stall; fast escalation/release |
| `loadavg` | `/proc/loadavg` | Runqueue saturation gate; suppresses single-thread false positives |
| `runnable / total` | `/proc/loadavg` | Instantaneous runnable count gate |
| CPU temperature | `/sys/class/thermal/thermal_zone*` | Thermal veto in reservation sizing |
| `cpu.stat` | per-slice cgroup | `nr_throttled` / `throttled_usec` telemetry: proves cap is binding |

`full` is intentionally not parsed from CPU PSI: CPU is not a fully blockable resource.

The per-tick stall percentage is:

```text
InstPSI = 100 × (delta cpu_psi.some_total_us / elapsed_wall_us)
```

Only a **two-sample minimum** (`min(inst_pct, prev_inst_pct)`) is fed to the classifier, so a lone 200 ms blip cannot engage a cap that would then need seconds to cool down.

### 3.3 Classification thresholds

`compute_cpu_pressure_raw()` requires **both** a PSI signal and a runqueue gate:

```text
ratio = max(load1 / online_cpus, (runnable - 1) / online_cpus)
```

| Level | CPU PSI `some` | Load ratio |
|---|---:|---:|
| NORMAL | < 15% | < 1.0 |
| MODERATE | ≥ 15% | ≥ 1.0 |
| HIGH | ≥ 30% | ≥ 1.5 |
| CRITICAL | ≥ 60% | ≥ 2.5 |

The averaged signal sets the base level; the filtered instantaneous delta can only **raise** it, never lower it.

### 3.4 Hysteresis

`CpuPressureController` (`resources/pressure_level.cpp`) implements dual-window control:

- **Escalation:** immediate when the raw classified level is ≥ current.
- **Release:** only after the instantaneous PSI (falling back to avg10) stays below the level's release threshold for `release_ticks_required` consecutive ticks.

Release thresholds:

| Current level | Release threshold |
|---|---:|
| MODERATE | < 10% |
| HIGH | < 15% |
| CRITICAL | < 30% |

The daemon currently constructs `CpuPressureController cpu_pressure_ctrl(15)`, i.e. **15 ticks = 3.0 s** release hysteresis. This prevents flapping but is a known tuning target.

### 3.5 Dual pressure channels and HC-CPU-1

`SystemPressure` carries three levels:

```cpp
memory    // drives FREEZE / RECLAIM / memory.high
cpu       // drives cpu.weight / cpu.max / cpu.idle / cpuset
composite // max(memory, cpu), telemetry only
```

The only accessor the memory plane may use is:

```cpp
inline PressureLevel memory_plane_pressure(const SystemPressure& sp) {
    return sp.memory;
}
```

TC-19 is the explicit invariant test: CPU pressure never kills or freezes.

### 3.6 Enforcement levers

#### 3.6.1 Slice weights

`compute_cpu_slice_policy()` maps CPU pressure to weights:

| CPU level | Protected | Active | Latency | Background | BG `cpu.max` | BG `cpu.idle` |
|---|---:|---:|---:|---:|---|---|
| NORMAL | 2000 | 500 | 450 | 50 | max | 0 |
| MODERATE | 2000 | 800 | 750 | 25 | max | 0 |
| HIGH | 2000 | 1000 | 950 | 10 | N−reserve | 0 |
| CRITICAL | 5000 | 1000 | 1000 | 10 | N−reserve | 1 |

Slices:

- `archtitan-protected.slice`
- `archtitan-active.slice`
- `archtitan-latency.slice` — **never** receives `cpu.max` or `cpu.idle`
- `archtitan-background.slice` — the only CPU-bandwidth-capped slice
- `archtitan-frozen.slice`

#### 3.6.2 `cpu.max` headroom and burst

`CFS_SMOOTH_PERIOD_US = 25000` (25 ms), replacing the kernel default 100 ms to cut worst-case throttle stall by 4×. `set_cpu_max()` also writes `cpu.max.burst` when supported: 20% of one period while capped, 0 when uncapped.

On an 8-logical-CPU host with one core reserved:

```text
cpu.max = 175000 25000   → 87.5% of total machine CPU
```

With two cores reserved: `150000 25000` → 75%.

#### 3.6.3 Adaptive reservation

`CpuDemandHint` carries descriptive demand:

```cpp
int   latency_workloads;   // games / real-time apps
int   gpu_feeders;         // training dataloaders
int   bulk_workloads;
float foreground_cpu_pct;  // 100% == one core
float cpu_temp_c;
bool  smt_siblings;
```

`compute_reserved_cores()` starts with 1 core at HIGH / 2 at CRITICAL, then:

- +1 per active latency workload
- +1 per GPU feeder
- +1 if foreground CPU ≥ 85% of the cores left to it
- ×2 on SMT systems to reserve whole physical cores
- −1 above 80 °C (thermal clawback)
- clamped to `[1, min(cpus/2, cpus−1)]`

`AdaptiveHeadroomTracker` requires 3 consecutive agreeing ticks (2 confirmation steps after first sighting) before changing `cpu.max`; pressure or presence transitions apply immediately.

#### 3.6.4 SMT / cpuset isolation

`resources/smt_topology.hpp` parses `core_id` and `thread_siblings_list`. `plan_smt_isolation()` gives latency work whole physical cores and removes all siblings of those cores from the background slice.

- Intent alone engages it at any pressure.
- At least two physical cores remain with background work.
- No more than half the physical cores are reserved.
- Unattended user disables isolation.
- `EnforcementPlane::apply_smt_isolation()` writes ACTIVE and LATENCY to the latency set and BACKGROUND to the complement, change-detected.

On this 4c/8t host: one game → latency `[0,4]`, background `[1,2,3,5,6,7]`; game + feeder → latency `[0,1,4,5]`, background `[2,3,6,7]`.

#### 3.6.5 Input feed-forward

`resources/input_feedforward.hpp` reads `/dev/input/event*` non-blockingly and accepts only deliberate input: key press/repeat or non-zero pointer motion. Power/lid/sleep keys and key releases are ignored.

`InputFeedForwardTracker` latches for **1.2 s** after the last event. While active:

- ACTIVE +400, LATENCY +400
- BACKGROUND −5, floored at 10
- one extra core removed from bulk
- if no cap is engaged, a short one is armed (on machines with >2 CPUs)

Unattended users get no boost. Weights clamp at 10000.

#### 3.6.6 Unattended cap lift and its guard

At HIGH/CRITICAL, an unattended user (>60 s without input) normally lifts the BG cap so an overnight build can use the whole machine. But input-only presence detection was wrong for headless games and benchmarks.

`should_lift_unattended_cap()` now requires:

```cpp
user_unattended_idle && latency_workloads == 0 && gpu_feeders == 0
```

When the lift is suppressed, the daemon passes **effective presence = false** to reservation and SMT isolation, preventing a zero-core reservation.

### 3.7 CPU telemetry

`TelemetrySnapshot` exposes, among other fields:

- `cpu_pressure_level`, `composite_pressure_level`
- `cpu_psi_avg10/avg60/avg300`, `cpu_psi_inst`
- `load1/load5/load15`, `load_ratio`, `online_cpus`
- per-slice weights, `background_cpu_max_pct`, `cpu_headroom_engaged`
- `reserved_headroom_cores`
- `smt_isolation_active`, `isolated_physical_cores`, `latency_cpuset`, `background_cpuset`
- `input_feedforward_active`, `input_age_ms`
- `background_cpu_idle`, `unattended_lift`, `cpu_temp_c`
- `bg_nr_periods`, `bg_nr_throttled`, `bg_throttled_usec`

CLI surface: `titan-hwm status|pressure|workloads|scan|explain|decisions|slices|doctor|metrics`.

---

## 4. Memory Management System

### 4.1 Inputs and pressure classification

The 200 ms tick samples:

| Input | Source | Role |
|---|---|---|
| `MemTotal`, `MemAvailable`, `SwapTotal`, `SwapFree` | `/proc/meminfo` via `read_meminfo()` | RAM headroom; swap parsed but unused by `compute_pressure()` |
| Memory PSI `some avg10`, `full avg10` | `/proc/pressure/memory` via `read_memory_psi()` | Primary pressure signal when available |
| CPU PSI, loadavg | `/proc/pressure/cpu`, `/proc/loadavg` | Used by the CPU plane only; never fed to memory policy |

`MemInfo::free_pct() = 100 − used_pct()`, with `used_pct` derived from `MemAvailable / MemTotal`.

`compute_pressure()` (`resources/pressure_level.cpp:132-153`) uses these thresholds:

| Condition | Result |
|---|---|
| `free_pct < 15%` | `CRITICAL` fast path, regardless of PSI |
| PSI valid and `full_avg10 >= 15` or `some_avg10 >= 40` | `CRITICAL` |
| PSI valid and `some_avg10 >= 20` or `free_pct < 25%` | `HIGH` |
| PSI valid and `some_avg10 >= 5` or `free_pct < 50%` | `MODERATE` |
| PSI valid, otherwise | `NORMAL` |
| No PSI and `free_pct < 25%` | `CRITICAL` |
| No PSI and `free_pct < 50%` | `HIGH` |
| No PSI, otherwise | `NORMAL` |

Note the deliberate asymmetry: with PSI, `free < 25%` is `HIGH`; without PSI, the same free-RAM level is `CRITICAL` because the kernel stall signal is missing.

### 4.2 Plane separation

`SystemPressure` carries `memory`, `cpu`, and `composite` levels (`resources/pressure_level.hpp:105-122`). `composite = max(memory, cpu)` is telemetry only.

The memory plane is allowed exactly one view of the system:

```cpp
memory_plane_pressure(sys_pressure)  // returns only sp.memory
```

Passed at `daemon.cpp:986-989` into `WorkloadManager::tick`, `PolicyEngine::evaluate`, and `ReclaimEngine::reclaim`. This is how HC-CPU-1 is enforced structurally: CPU pressure cannot become a freeze or reclaim decision.

### 4.3 Workload state machine

States (`core/types.hpp:33-52`):

```text
DISCOVERED → ACTIVE / BACKGROUND_EXECUTING / IDLE
ACTIVE → BACKGROUND_EXECUTING / IDLE
IDLE → AGING → RECLAIMABLE → (policy / reclaim)
Any state → ACTIVE on refocus or resumed execution
```

Tunables (`workload/workload_manager.hpp:21-25`):

- `age_soft_decay_min = 5`
- `age_hard_decay_min = 15`
- `hysteresis_ticks = 10` (2 s at 200 ms/tick)

Key transitions (`workload/workload_manager.cpp:83-210`):

| Current state | Transition |
|---|---|
| Protected | Forced `ACTIVE`; no aging |
| Observed | Mirrors activity/visibility but never becomes `AGING`/`RECLAIMABLE` |
| `ACTIVE` | Losing focus starts hysteresis; return resets it |
| `IDLE` | Age ≥ 5 min **and** memory pressure ≥ `MODERATE` → `AGING` |
| `AGING` | Age ≥ 15 min **and** pressure ≥ `HIGH` → `RECLAIMABLE` |
| `RECLAIMABLE` | Refocus or new execution rescues; otherwise policy/reclaim acts |

Execution authority therefore depends on **measured execution**, not workspace number.

### 4.4 Execution detector

Config (`classifier/execution_detector.hpp:28-32`):

- `sample_ms = 50`
- `idle_cpu_pct = 0.5%`
- `idle_confirm_count = 3`

Activity is inferred from (`classifier/execution_detector.cpp:66-149`):

1. CPU tick delta from `/proc/<pid>/stat`.
2. Child-set changes.
3. Kernel state `R`/`D`; `Z` → `COMPLETED`.
4. Known build command substrings.
5. Persistent service command matches.
6. `IDLE` only after 3 consecutive inactive samples.

Workload aggregation (`execution_detector.cpp:157-177`): any live executing member makes the workload `EXECUTING`; no live members means `COMPLETED`.

### 4.5 Policy decisions

`PolicyEngine::evaluate()` (`policy/policy_engine.cpp:10-145`) returns one of:

```text
KEEP_FULL
KEEP_BACKGROUND
THROTTLE
FREEZE
RECLAIM
```

Strict precedence:

| Priority | Condition | Decision |
|---:|---|---|
| 1 | Protected workload/PID | `KEEP_FULL`; hard block |
| 1a | Observed workload | `KEEP_BACKGROUND` at every pressure |
| 1a | `latency_critical` | `KEEP_FULL` at any pressure |
| 1a | `gpu_feeding` | `THROTTLE` only at `CRITICAL`; otherwise `KEEP_BACKGROUND` |
| 1b | `SERVICE` / `VM` | Never freeze/reclaim; `THROTTLE` only at `CRITICAL` |
| 2 | `EXECUTING` + focused/visible | `KEEP_FULL` |
| 2 | `EXECUTING` + background | `KEEP_BACKGROUND` |
| 3 | Focused/visible + `ACTIVE` | `KEEP_FULL` |
| 3b | Workspace hysteresis active | Floor at `KEEP_BACKGROUND` |
| 3c | Browser root, latency-sensitive | `KEEP_BACKGROUND` → `THROTTLE` → `FREEZE` as pressure rises |
| 4 | `IDLE` | `KEEP_BACKGROUND` → `THROTTLE` → `FREEZE` |
| 4b | `AGING` | `THROTTLE`; `FREEZE` at `HIGH+` |
| 5 | `RECLAIMABLE` | `ai_owned` → `FREEZE`; otherwise `RECLAIM` |

`KEEP_FOREGROUND` does not exist in code; the closest equivalent is `KEEP_FULL`.

### 4.6 Reclaim engine

Config (`policy/reclaim_engine.hpp:21-35`):

- `grace_period_ms = 2000`
- `sigterm_grace_ms = 3000`
- `recent_focus_s = 30`
- `notify_min_interval_s = 60`

Nine-step sequence (`policy/reclaim_engine.cpp:226-293`):

1. Protected-workload check.
2. Execution-detector check.
3. Active-dependent check.
4. Recent-focus check.
5. Coalesced, non-blocking `notify-send`.
6. Sleep 2 s grace period.
7. Re-run all four safety checks.
8. `SIGTERM` through `kill_tree()`.
9. Sleep 3 s, then `SIGKILL` survivors.

`signal_pid()` uses `pidfd_open`/`pidfd_send_signal` to avoid PID-reuse TOCTOU, falling back to `kill()` only if pidfd is unavailable. `kill_tree()` skips hard-protected PIDs and collateral-only browser PIDs.

### 4.7 Cgroup and signal enforcement

`EnforcementPlane::apply()` (`enforcement/enforcement_plane.cpp:67-145`):

| Decision | Actions |
|---|---|
| Protected hard block | Move to protected slice, `SIGCONT` stopped PIDs, return false |
| `KEEP_FULL` | Active slice, `oom_score_adj = -500`, `SIGCONT`, thaw frozen slice |
| `KEEP_BACKGROUND` | Background/latency slice, `oom_score_adj = 0`, `SIGCONT` |
| `THROTTLE` | Background/latency slice, `oom_score_adj = +500`, cap CPU weight at 20; **no `memory.high` write occurs** |
| `FREEZE` | `SIGSTOP` (except browser root), frozen slice, `cgroup.freeze = 1`, `oom_score_adj = +500` |
| `RECLAIM` | Rejected here; daemon routes it to `ReclaimEngine` |

`slice_for_intent()` routes `latency_critical` and `gpu_feeding` workloads to `archtitan-latency.slice`; bulk work goes to `archtitan-background.slice`.

`CgroupController` memory operations (`enforcement/cgroup_controller.cpp`):

| Operation | Lines | Detail |
|---|---:|---|
| `setup_slices()` | 109-147 | Creates slices; writes `memory.oom.group = 1` for active/background/latency/frozen; probes `cgroup.freeze` writability |
| `move_to_slice()` | 152-162 | Writes PIDs to `cgroup.procs` |
| `set_memory_high()` | 413-416 | Writes `memory.high`; `0` → `max`. **No caller exists** |
| `set_freeze()` | 421-423 | Writes `cgroup.freeze` `1`/`0` |
| `set_oom_score()` | 429-434 | Writes `/proc/<pid>/oom_score_adj` clamped to `[-1000, 1000]` |
| `hierarchy_healthy()` | 440-447 | Checks cgroup controllers contain `cpu` and `memory` |

OOM constants (`enforcement_plane.hpp:22-25`): `OOM_PROTECT = -500`, `OOM_NORMAL = 0`, `OOM_EXPOSE = +500`.

### 4.8 Protected registry

Two tiers:

1. **Hard protection** (`core/protected_registry.hpp:73-118`): explicit PIDs, protected comm names, and exe-path verification to reject spoofing. Covers THM itself, Titan services, audio stack, media players, compositor/session infrastructure, and login managers. Checked first by policy, enforcement, and reclaim.
2. **Collateral-only browser protection** (`protected_registry.hpp:20-71`): browsers are deliberately not hard-protected; they are only skipped on reclaim signal paths so an unrelated browser tree is not swept into another workload's kill.

`is_protected()` order: explicit PID → comm match → exe-path cross-check → spoof warning/deny or exe-only match. `is_collateral_protected()` is consulted by `ReclaimEngine::kill_tree()`.

### 4.9 Workspace focus and governor authority

Workspace state (`core/types.hpp:177-188`) distinguishes `is_visible` (on a monitor) from `is_focused` (keyboard input). Hyprland events update focus/visibility (`ipc/workspace_monitor.cpp:304-336`, `368-419`).

Hysteresis is 10 ticks / 2 s by default. A focus loss does not immediately degrade a workload; a focus return immediately rescues it.

`WorkspaceMonitor::compute_governor()` (`workspace_monitor.cpp:436-503`) treats memory pressure as authoritative: at HIGH/CRITICAL, `PERFORMANCE` is capped to `SCHEDUTIL`. `POWERSAVE` requires all workloads idle and both memory and CPU pressure `NORMAL`.

### 4.10 Telemetry and CLI

`TelemetrySnapshot` (`ipc/telemetry_publisher.hpp:57-132`) publishes memory fields:

- `pressure_level` — the **memory** channel only
- `psi_some_avg10`, `psi_full_avg10`
- `mem_used_pct`, `mem_total_kb`, `mem_available_kb`
- per-workload RSS via `TelemetryWorkload::mem_kb`

CPU and composite levels are separate fields. JSON is written atomically to `/run/archtitan/thm-state.json` (override `THM_TELEMETRY_PATH`) at most once per second.

CLI surface:

| Command | Memory-relevant output |
|---|---|
| `metrics` | Memory PSI, slice `memory.current`, daemon status |
| `slices` / `cgroups` | `memory.current`, `memory.high`, `cgroup.freeze`, PIDs, CPU stats |
| `doctor` | Telemetry freshness, PSI availability, cgroup `cpu+memory` delegation |
| `pressure` | Memory/CPU pressure, PSI, RAM use, threshold explanation |

### 4.11 Memory test coverage

Memory-relevant cases in `thm_test_runner` (38 total):

| Test | Coverage |
|---|---|
| TC-2 | Active AI survives; idle AI freezes; reclaimable AI downgraded to `FREEZE` |
| TC-3 | Idle IDE freezes at HIGH; real `SIGSTOP`; refocus → `KEEP_FULL` + `SIGCONT` |
| TC-4 / TC-5 | Protected names, exe verification, audio whitelist |
| TC-8 | Same decisions on workspace 1 and workspace 99 |
| TC-9 | Reclaim aborts if work resumes during grace period |
| TC-11 | Governor capped to `SCHEDUTIL` at HIGH/CRITICAL pressure |
| TC-12 | Protected PID survives mixed-tree `SIGTERM`/`SIGKILL` |
| TC-13 | Browser collateral tier and anti-spoof |
| TC-14 / TC-15 | Observed workloads never age or escalate |
| TC-19 | HC-CPU-1: CRITICAL CPU + NORMAL memory → no freeze/reclaim |
| TC-23 / TC-24 | Telemetry contract, instant-PSI fast path |
| TC-30 / TC-31 | GPU feeders never frozen/reclaimed; latency-slice routing |

---

## 5. Safety Model and Invariants

### 5.1 Core invariants

1. **Execution authority:** active compilation/build/AI work is never stopped or killed by a workspace switch.
2. **Workspace as priority hint:** workspace ID never determines life or death.
3. **Absolute domain protection:** ArchTitan/session infrastructure is hard-blocked.
4. **AI task scrutiny:** `ai_owned` is a context label, not an infinite shield; idle AI work can be frozen under memory pressure.
5. **Demand-based governor:** frequency scaling follows aggregate demand, not workspace number.
6. **HC-CPU-1:** CPU pressure may never produce FREEZE, RECLAIM, SIGSTOP, or SIGKILL.

### 5.2 Protected registry

Tiered protection:

1. Explicit PIDs (including THM self).
2. Static protected comm names (compositor, audio, session, ArchTitan services).
3. `/proc/<pid>/exe` path verification to reject comm spoofing.

The hard block fires at line 1 of every enforcement path.

### 5.3 Test coverage

`thm_test_runner` currently has 38 test cases:

- TC-1..TC-13: original architecture, safety, governor, protected domain, browser collateral guard.
- TC-14..TC-18: observed-mode semantics, telemetry contract, measured CPU%, Hyprland reconnect.
- TC-19: HC-CPU-1 invariant proof.
- TC-20..TC-26: CPU hysteresis, 25 ms `cpu.max` math, unattended lift, telemetry v3.2, instantaneous PSI, governor availability, CRITICAL extra headroom.
- TC-27..TC-28: observed heavy demand and slice assignment.
- TC-29..TC-31: workload intent, policy guards, latency slice routing.
- TC-32..TC-33: adaptive headroom and no-`cpu.max`-flapping hysteresis.
- TC-34: SMT whole-core planning.
- TC-35: input feed-forward.
- TC-36: cached `/proc` stat parsing.
- TC-37: standalone game engine intent.
- TC-38: unattended game cap guard.

Validation commands:

```bash
cd /home/msfvenom/custom-os-build/titan-hwm-v3
./build/thm_test_runner
./build/bench_cpu_headroom --compare --profile mixed --duration 8 \
  --threads 16 --bg-procs 2 --adaptive both --no-color
./benchmarks/bench_real_workloads.sh --reps 3 --quota 87.5%
./benchmarks/bench_real_workloads.sh --reps 3 --quota 75%
```

---

## 6. Benchmark and Validation History

| Task / commit | Change | Unit tests | Key result |
|---|---|---:|---|
| `72630d1` | Heavy unclassified workloads count as real demand | 28/28 | Governor no longer pins to powersave under observed load |
| `1f3f938` | Intent classes + uncapped latency slice | 31/31 | Wake p95 2.892 → 0.656 ms in synthetic mixed profile |
| `8791d3e` | Adaptive CPU headroom | 33/33 | BG cap 87.5% → 62.5% with game+train hint; throughput 99.3% → 81.8% |
| `564dd12` | Real compile/encode harness | — | 1.12×–1.51× foreground speedup under x264 load |
| `9ada46e` | SMT whole-core isolation | 34/34 | Median compile 6933 → 5800 ms with affinity split; jitter p95 −49.7% |
| `a046bb8` | Input feed-forward | 35/35 | Cap tightens 87.5% → 75% on fresh input; 1.2 s latch |
| `b0cedd3` | `/proc` scan reduction | 36/36 | Daemon tick CPU 3.203 s → ~1.03 s per 30 ticks |
| `bb45fb3` | Standalone game intent + unattended cap guard | 38/38 | Superposition retained 96.8% of baseline score under two encoders |

### 6.1 Unigine Superposition results (Intel iGPU)

| Run | Score | FPS min | FPS avg | FPS max |
|---|---:|---:|---:|---:|
| Baseline, no THM, no encoders | 167 | 1.19 | 1.25 | 1.48 |
| Managed before fix, THM + 2 encoders | 161 | 1.10 | 1.20 | 1.42 |
| Managed after fix, THM + 2 encoders | 162 | 1.13 | 1.21 | 1.47 |

The after-fix run retained 96.8% of baseline score and average FPS while carrying two competing x264 encoders. The dominant limitation was the `powersave` governor at ~1190 MHz on the iGPU, not THM.

### 6.2 Recent GPU/hardware findings (2026-11-20, not yet committed as a benchmark doc)

- A prior NVIDIA-offload Superposition attempt ended in a **hard power-off** (machine stayed off until power button). `last -x` recorded `crash`, journal stopped abruptly at 09:11:22, with no panic, OOM, thermald shutdown, or NVIDIA Xid. This was **not reproducible** in subsequent short tests.
- Power check at rest: AC online, battery 100%, 34.81/38 Wh (91.6% health), 738 cycles, no pre-crash adapter events.
- Sensor check: NVMe idles unusually hot (~78 °C idle, critical 84.8 °C), CPU/GPU ~46–48 °C.
- Superposition under `prime-run` repeatedly aborts with SIGABRT in `WidgetSpriteShader::create → Splash::init → Warming::init → MainLogic::init`; coredumps at 08:28, 09:30, 09:34. This is an application/driver crash, distinct from the system power-off.
- 60 s instrumented Superposition run: max CPU 48 °C, NVMe 64.8 °C, GPU 48 °C, no shutdown. Benchmark never rendered.
- Stable NVIDIA alternative: `glmark2` under `prime-run`, 1280×720 windowed, 40 s:

| Run | Score | FPS | Max CPU | Max NVMe | Max GPU | GPU util |
|---|---:|---:|---:|---:|---:|---:|
| THM off | 338 | 339 | 49 °C | 60 °C | 50 °C | 35–49% |
| THM v3 active | 344 | 345 | 50 °C | 60 °C | 50 °C | 34–49% |

THM recorded no enforcement actions in the glmark2 A/B because `glmark2` is not classified as a latency/GPU-feeding workload. This confirms no regression, but it is not a strong policy test.

### 6.3 Memory benchmark coverage

There is currently **no real memory-pressure benchmark** in the tree. `bench_cpu_headroom` reads memory pressure only for context, and `bench_real_workloads.sh` exercises gcc/ffmpeg CPU arbitration. Reclaim, `memory.high`, `SIGSTOP`, and `SIGKILL` paths are covered only by unit tests, not by an end-to-end RAM-pressure run.

### 6.4 Current validation snapshot

Re-run while producing this report:

```text
./build/thm_test_runner
  TOTAL: 38/38 PASSED (100% SUCCESS)

./build/bench_cpu_headroom --compare --profile mixed --duration 8 \
    --threads 16 --bg-procs 2 --adaptive both --no-color
  VERIFICATION SCORECARD: 8/8 PASSED
  HC-CPU-1 Worker Survival: 2/2 baseline, 2/2 managed (0 killed/stopped)
  Frame Completion Max: 55.958 ms → 26.390 ms (-52.8%)
  Deadline Misses (>6.9 ms): 187 (24.8%) → 28 (2.5%) (-85.0%)
  Severe Drops (>16.7 ms): 51 → 1 (-98.0%)
  BG Compute Throughput: 87.1 → 79.0 M/s (90.7% retained)
  BG CPU Usage: 5.37/8 → 4.86/8 (3.14 cores reserved)
  CFS Throttle: 0 → 259 events (7077 ms), confirming cpu.max is active
```

These numbers are consistent with the historical task results and confirm the shipped `bb45fb3` state is still healthy.

---

## 7. Known Limitations and Open Issues

### CPU pressure

1. **System-wide signal:** `/proc/pressure/cpu` cannot identify which slice is stalled. A foreground game stall and a background compile stall look identical.
2. **Slow avg10:** even with the per-tick fast path, sustained classification still leans on a 10 s EWMA.
3. **Fixed 15-tick release:** can hold a cap ~3 s after pressure disappears when a shorter adaptive release would be safe.
4. **No per-slice PSI:** this kernel does not expose `cpu.pressure` inside the THM slices.
5. **Static hints:** `latency_workloads` and `gpu_feeders` are counts, not measured stall/GPU-fill signals. GPU-util and IO-util signals were deliberately left out of scope.
6. **Daemon overhead:** still ~7.5 ms/tick over ~285 PIDs; further profiling is possible.
7. **Synthetic jitter metrics are noisy:** benchmark docs repeatedly note that p95 wake/frame numbers on this shared host are not reliable evidence by themselves; authoritative checks are cap values, reservation counts, cgroup stats, and invariant tests.

### Memory management

1. **`memory.high` is not actually applied.** `CgroupController::set_memory_high()` exists but has no caller. `EnforcementPlane::apply()` comments promise a 75%-of-RSS throttle, but no such calculation or write exists. THROTTLE currently means slice move + OOM exposure + CPU weight cap.
2. **`AGING` has no pressure-relief downgrade.** If pressure drops, the workload remains `AGING` and still receives `THROTTLE` below HIGH.
3. **Active-dependent check is shallow.** `check_no_active_dependent()` only compares `root_pid`; it does not inspect the ownership graph despite its comment.
4. **Docs drift on reclaim sequence.** The older Typst architecture report lists a kernel root check (`ppid != 1`, `uid != 0`) that no longer exists in `reclaim()`.
5. **Signal-path inconsistency.** `ReclaimEngine` uses pidfd, but `EnforcementPlane::signal_tree()` still uses check-then-`kill()`; collateral browser protection is not consulted there.
6. **Telemetry staleness.** `TelemetrySnapshot::version` still defaults to `"3.2.0"` despite v3.3–v3.7 behavior, and `latency_cpu_weight` is never assigned in the daemon snapshot builder (JSON publishes stale `450`).
7. **OOM constants disagree with the service file comment.** Code uses `-500 / 0 / +500`; `titan-hwm.service` comments say `-200 / +300`.
8. **Swappiness is documented but unwired.** `CRITICAL` comments mention swappiness, but only an unused `HardwarePolicy` field exists.
9. **CLI pressure reason is approximate.** It explains using `mem_used_pct` and does not mirror every `compute_pressure()` branch, especially the no-PSI fallback.
10. **Cgroup failure degrades silently.** `setup_slices()` failure only warns; later writes become no-ops, leaving signal-only behavior.
11. **No real memory-pressure benchmark exists.** The benchmark suite exercises CPU arbitration only; no test or benchmark verifies actual `memory.high`, reclaim, or freeze under real RAM pressure.

### Environment / hardware

- `QT_QPA_PLATFORM=wayland;xcb` is invalid for the Superposition Qt launcher; `xcb` is required.
- Superposition Basic ignores `-resolution`, `-quality`, and `-sound`.
- OpenAL repeatedly logs `error: invalid value` from `Easy Effects Sink`; `GPUMonitorPlugin::init()` fails. Neither is THM-related.
- The hard power-off remains unexplained; treat it as a firmware/EC/power event until reproduced with full telemetry.

---

## 8. Roadmap: Stall-Aware Bandwidth Loaning

The next proposed upgrade turns the CPU engine from reactive to predictive:

1. **Latency stall signal:** sample `/proc/<pid>/schedstat` for latency/GPU-feeding PIDs; compute runqueue-wait percentage and latency-slice CPU%.
2. **Bandwidth loan controller:** when the latency slice is quiet (low runqueue delay, low CPU%, no fresh input) and CPU pressure is HIGH, lend part of the reserved headroom to BG quota.
3. **Immediate reclaim:** on wake/input/stall, drop the loan in one tick; CFS period (25 ms) bounds worst-case reclaim latency.
4. **Guardrails:** keep one whole physical core unloaned on SMT; never cap or idle the latency slice; no GPU-util or IO-util signals without explicit approval.
5. **Observability:** expose `bandwidth_loan_cores`, latency stall p95/p99, and `nr_throttled` deltas in telemetry and `titan-hwm explain`.
6. **Benchmark:** extend `bench_cpu_headroom` with a periodic latency client reporting p50/p95/p99 wake delay, background throughput, and loan timeline.

Rollout would be four commits with tests, benchmark A/B, documentation, and pushes to both branches after each task.

---

## 9. File Map

| Area | Key files |
|---|---|
| CPU pressure / PSI | `resources/pressure_level.hpp/.cpp` |
| Cgroup CPU policy | `enforcement/cgroup_controller.hpp/.cpp` |
| Enforcement plane | `enforcement/enforcement_plane.hpp/.cpp` |
| SMT isolation | `resources/smt_topology.hpp` |
| Input feed-forward | `resources/input_feedforward.hpp` |
| Core state/decision types | `core/types.hpp` |
| Workload state | `workload/workload_manager.hpp/.cpp` |
| Execution detection | `classifier/execution_detector.hpp/.cpp` |
| Policy decisions | `policy/policy_engine.hpp/.cpp` |
| Reclaim | `policy/reclaim_engine.hpp/.cpp` |
| Memory cgroups | `enforcement/cgroup_controller.cpp` (`set_memory_high`, `set_freeze`, `set_oom_score`) |
| Protection | `core/protected_registry.hpp/.cpp` |
| Workspace monitor | `ipc/workspace_monitor.hpp/.cpp` |
| Telemetry | `ipc/telemetry_publisher.hpp/.cpp` |
| Daemon loop | `daemon/daemon.cpp` |
| CLI | `cli/titan_hwm_cli.cpp` |
| Tests | `tests/test_runner.cpp` |
| Benchmarks | `benchmarks/bench_cpu_headroom.cpp`, `benchmarks/bench_real_workloads.sh` |
| Existing RFCs | `docs/thm_v3_cpu_pressure_architecture.typ`, `docs/thm_v3_architecture_report.typ` |
| Benchmark records | `docs/benchmark-results/*.md` |

---

## 10. Conclusion

THM v3 now has a mature dual-plane design: memory pressure can safely reclaim genuinely idle work, while CPU pressure is strictly limited to scheduling arbitration. The CPU engine combines PSI, per-tick stall deltas, runqueue gates, workload intent, adaptive headroom, SMT-aware cpusets, input feed-forward, and stall-aware bandwidth loaning — all without sending a single CPU-pressure kill or stop signal.

The **v3.8 bandwidth loan** completes the reservation feedback loop: after five consecutive quiet ticks with no PSI stall and no recent input, one core of an idle foreground reservation is lent to bulk work (one whole physical core on SMT hosts). Any input event, PSI stall, foreground load increase, pressure/presence change, or new latency/GPU workload restores the full reservation in the same tick.

**v3.9** makes Hyprland context auditable: `active_window_class` is matched against a root's comm/exe/argv0 and the class/title are stored on that workload root; a title alone can never bind a headless compiler to a focused editor, and an IPC gap preserves an existing binding. The next high-value step is the dependency/workload graph (IDE ↔ LSP ↔ build ↔ browser tabs) over those bound roots — I/O and GPU planes remain out of scope.
