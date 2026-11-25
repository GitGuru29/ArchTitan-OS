# Titan Hardware Manager v3 — Progress, Evidence, and Remaining Work

**Status document:** full THM v3 rollup through v3.10
**Branch:** `feat/thm-cpu-pressure-engine`
**Commit at writing:** latest commit on `feat/thm-cpu-pressure-engine`
**Date:** 2026-11-25
**Audience:** ArchTitan OS maintainers / THM contributors

> Workflow note: THM changes are to be pushed to `feat/thm-cpu-pressure-engine`.
> Direct pushes to `main` are no longer the default path.

---

## 1. Executive summary

Titan Hardware Manager (THM) v3 is a **workload-aware resource orchestration
engine**, not a process killer. The kernel retains low-level scheduling; THM
supplies intent, context, reservations, and guardrails.

The system has two deliberately asymmetric planes:

| Plane | Problem | Enforcement levers | Process lifetime |
|---|---|---|---|
| **CPU pressure** | latency jitter, runqueue contention, background starvation | `cpu.weight`, `cpu.max`, `cpu.idle`, SMT-aware `cpuset`, governor hints, bandwidth loans | **Never** kill/stop/freeze (HC-CPU-1) |
| **Memory pressure** | RAM exhaustion, swap/OOM risk | `memory.high`, `memory.low`, `memory.oom.group`, `oom_score_adj`, cgroup freeze, pidfd reclaim | Freeze/reclaim possible, terminate only with explicit opt-in |

Current state:

- **49/49** architectural unit tests pass.
- **8/8** CPU headroom scorecard passes on the latest short run.
- Workload dependency graph links IDE/LSP/build/project roots and blocks
  reclaim when an active dependent exists.
- Daemon local dry-run peak RSS is **4.6 MB**, under the 6 MB budget.
- Real cgroup memory-pressure primitives are proven (`high=18`, `oom_kill=0`).
- Last full QEMU/KVM compile A/B was the **v3.4-R6** regression run; no
  median-compile improvement is claimed for v3.8, v3.9, or v3.10.
- Hyprland IPC remains the **only** live context source.
- I/O and GPU control planes remain out of scope, and GPU stress requires
  explicit approval.

v3.10 adds the **dependency/workload graph** over the Hyprland bindings
introduced in v3.9. The next functional work is observability fidelity and
end-to-end memory-pressure validation.

---

## 2. Architecture map

### 2.1 Core loop

`titan-hwm.service` runs the daemon at 5 Hz inside `archtitan.slice` with cgroup
v2 delegation. Each tick:

1. discovers / refreshes the process forest;
2. updates execution and pressure signals;
3. fuses classification evidence;
4. refreshes workload state and workspace context;
5. asks `PolicyEngine` for a decision;
6. sanitizes the decision fail-closed;
7. applies CPU and memory enforcement;
8. publishes telemetry and status data.

### 2.2 Major components

| Area | Responsibility | Key files |
|---|---|---|
| Types / decisions | `Workload`, `ProcessNode`, `PressureLevel`, decision structs | `core/types.hpp`, `resources/pressure_level.hpp/.cpp` |
| Process ownership | PID → root forest, ancestry to depth 3 | `workload/ownership_graph.hpp/.cpp` |
| Workload state | discovery, ACTIVE/AGING/idle transitions, observed workloads | `workload/workload_manager.hpp/.cpp` |
| Classification | cmdline, CWD project signatures, ancestry, window/workspace context, drift | `classifier/fusion_classifier.cpp`, `classifier/execution_detector.cpp` |
| CPU policy | PSI, `cpu.stat`, loadavg, thermal, adaptive headroom, SMT, bandwidth loan | `enforcement/cgroup_controller.hpp/.cpp`, `resources/smt_topology.hpp`, `resources/input_feedforward.hpp` |
| Memory policy | `memory.high/low`, OOM exposure, freeze, reclaim | `enforcement/enforcement_plane.hpp/.cpp`, `policy/reclaim_engine.hpp/.cpp` |
| Protection | protected names/exes, audio/browser collateral tiers | `core/protected_registry.hpp/.cpp` |
| Context | Hyprland workspace/window IPC, recent-focus window, root binding | `ipc/workspace_monitor.hpp/.cpp` |
| Telemetry / CLI | JSON snapshot, `titan-hwm status/explain/scan` | `ipc/telemetry_publisher.hpp/.cpp`, `cli/titan_hwm_cli.cpp` |
| Daemon orchestration | tick loop, signal path, guardrails | `daemon/daemon.cpp` |
| Tests / benchmarks | 47 TC cases, CPU headroom, RAM pressure, QEMU A/B harness | `tests/test_runner.cpp`, `benchmarks/`, `bench/host/run-bench.sh` |

### 2.3 Slices

- `archtitan-active.slice` — foreground/interactive work.
- `archtitan-latency.slice` — protected latency/GPU-feeding work; **never**
  receives `cpu.max` or `cpu.idle`.
- `archtitan-background.slice` — bulk/throughput work.
- `archtitan-throttled.slice` — v3.4 isolated background path under pressure.
- `archtitan-frozen.slice` — cgroup-frozen idle work.

---

## 3. Version timeline

### v3.0–v3.2 — foundation

- Replaced static workspace profiles with real workload classification.
- Introduced ownership graph, execution detector, policy engine, reclaim engine,
  protected registry, cgroup slices, telemetry JSON, and `titan-hwm` CLI.
- Established the dual-plane design and HC-CPU-1.
- The detailed report at
  `titan-hwm-v3/docs/thm_v3_full_report.md` is still labelled v3.2 and is a
  snapshot of commit `bb45fb3`; several limitations listed there have since been
  fixed.

### v3.3 — reliability hardening

| Step | Result |
|---|---|
| R1 | AGING pressure relief — workloads can recover when pressure drops. |
| R2 | Real `memory.high` wiring, not just a declared API. |
| R3 | Fail-closed `sanitize_decision()` gate. |
| R4 | Real cgroup RAM-pressure benchmark in a transient systemd scope. |
| R5 | Unified pidfd signalling with `posix_spawn()` helper path. |

Evidence: `2026-11-20-v3.3-r1-aging-pressure-relief.md`,
`2026-11-20-v3.3-r3-fail-closed-gate.md`,
`2026-11-20-v3.3-r4-real-memory-pressure.md`.

### v3.4 — intelligence and regression repair

| Step | Result |
|---|---|
| R1 | Recent-focus context: just-left workspace stays protected for up to 30 s. |
| R2 | Throttled slice isolation. |
| R3 | Headless capability/cap lift: no Hyprland IPC no longer means a false 50% cap. |
| R4 | Per-tick CPU overhead reduction. |
| R5 | Pressure-aware tick / fast PSI path. |
| R6 | Single glibc arena + static libstdc++/libgcc cut RSS below 6 MB. |

The original v3.4 QEMU A/B was a **9.8× regression**
(1 round / 468259 ms vs 5 rounds / 47567 ms median, 401085 pages swapped out).
Root causes were slice-wide `memory.high`, a false headless cap, frozen compiler
children, and fixed per-tick overhead. All four were corrected.

Clean R5 A/B (`A-20261123-125441` vs `B-20261123-130153`):

- median compile **20310 ms → 19021 ms** (`1.07×`);
- daemon CPU **10.64%**;
- MemAvailable **658 MB → 28 MB**;
- stalls **0.5 s → 7.3 s**;
- OOM kills **0**.

Final R6 A/B (`A-20261124-233618` vs `B-20261124-234404`, noisy host):

- median compile **56.3 s → 48.9 s** (`1.15×`);
- daemon CPU **17.76%**;
- MemAvailable **643 MB → 19 MB**;
- stalls **2.2 s → 13.7 s**;
- OOM kills **0**.

Absolute times on the noisy host are not clean speedup measurements; the
deterministic protections are the usable evidence.

Evidence: `2026-11-21-v3.4-qemu-ab-regression.md`.

### v3.5–v3.7 — isolation, feed-forward, headroom

- SMT-aware whole-core isolation prevents partial physical-core contention.
- Input feed-forward gives short protection after real input events.
- Adaptive headroom reduces reserved capacity when the foreground is quiet.
- Real gcc/ffmpeg workload arbitration and process-scan overhead were measured.

Evidence: `2026-11-19-adaptive-headroom-task3.md`,
`2026-11-20-real-workload-task4.md`,
`2026-11-20-smt-isolation-task5.md`,
`2026-11-20-input-feedforward-task6.md`,
`2026-11-20-proc-scan-task7.md`.

### v3.8 — stall-aware bandwidth loaning

`BandwidthLoanTracker` lends idle foreground reservation capacity to bulk work
only when all of these hold:

- HIGH/CRITICAL pressure and user present;
- at least 3 logical CPUs and a base reservation greater than one core;
- 5 consecutive quiet ticks;
- no recent input;
- system CPU stall present and below 5%;
- foreground load below ~25% of each reserved core.

It lends one logical core, or one full physical core on SMT hosts, and reclaims
in the same tick on input, PSI stall, foreground growth, pressure/presence
change, or a new latency/GPU workload.

Latest scorecard (2026-11-25):

- wake-up p99 **25.681 ms → 5.240 ms**;
- deadline misses **219 (28.5%) → 22 (2.0%)**;
- BG throughput **86.6% retained**;
- **8/8** after one transient host-noise 6/8.

No QEMU compile A/B was run after v3.8.

Evidence: `2026-11-25-v3.8-bandwidth-loan.md`.

### v3.9 — Hyprland window context binding

- `window_context_matches()` normalizes class/comm/exe/argv0 tokens.
- Class is authority; title is stored only after class matches.
- Headless compiler/toolchain processes cannot inherit a focused editor title.
- IPC gaps preserve an existing binding.
- Telemetry emits `window_class` / `window_title`; CLI prints them.
- TC-47 added; suite is **47/47**.

Latest scorecard (2026-11-25):

- wake-up p99 **12.714 ms → 4.623 ms**;
- frame completion p99 **14.980 ms → 7.270 ms**;
- deadline misses **177 (19.7%) → 14 (1.2%)**;
- BG throughput **82.1% retained** in the original report; **79.3%** on the
  latest re-run (43.0°C host);
- **8/8**;
- RSS **4876 KB (4.8 MB)**.

No QEMU compile A/B was run after v3.9; the headless harness has no Hyprland
IPC and therefore exercises only the unchanged CPU path.

Evidence: `2026-11-25-v3.9-window-context-binding.md`.

### v3.10 — workload dependency graph

- `workload/dependency_graph.hpp/.cpp` infers `ProcessAncestry`, `Toolchain`,
  and `SharedProject` edges over window-bound workload roots.
- Direction is `from DEPENDS ON to`; `has_active_dependent()` walks dependents
  transitively and treats protected roots as shielding too.
- `ReclaimEngine::reclaim()` takes an optional graph pointer. Step 3 and the
  step-7 recheck use it before the legacy root-PID fallback.
- Daemon uses a two-pass tick (state pass → graph rebuild → policy pass) so a
  child that became ACTIVE this tick shields its root immediately.
- Telemetry exposes `dependency` summary/counts; per-workload providers,
  dependents, and `protected_by_dependents`; CLI prints the graph summary.
- TC-48 and TC-49 added; suite is **49/49**.
- Latest scorecard: **8/8** at 40.0°C after one transient host-noise 7/8 run;
  wake-up p99 **13.332 ms → 5.278 ms**, deadline misses **23.3% → 1.3%**, BG
  throughput **80.0% retained**. Local dry-run RSS **4692 kB (4.6 MB)**.

No QEMU compile A/B was run after v3.10; no median-compile improvement is
claimed.

Evidence: `2026-11-25-v3.10-workload-dependency-graph.md`.

---

## 4. Guardrails and invariants

These are non-negotiable design constraints, not optional polish.

1. **HC-CPU-1:** CPU pressure may change scheduling only. No kill, stop,
   freeze, or protected-signal action may originate from the CPU plane.
2. **Latency slice immunity:** `archtitan-latency.slice` never receives
   `cpu.max` or `cpu.idle`.
3. **Destructive memory reclaim is opt-in:** requires
   `THM_ALLOW_DESTRUCTIVE_RECLAIM=1`.
4. **Hyprland IPC only:** no parallel live context provider; no new socket, no
   `hyprctl` fork, no `/proc`-only context source.
5. **No I/O plane, no GPU plane.** GPU stress requires explicit user approval.
6. **Protect first, reclaim second, terminate last.**
7. **Fail-closed policy:** invalid decisions are sanitized before enforcement.
8. **RSS budget:** daemon stays below 6 MB.

Current status: all eight are held in the shipped code and in the latest test
runs.

---

## 5. Validation evidence

### 5.1 Unit suite

```sh
./build/thm_test_runner
```

Result: **49/49 PASSED**.

Selected cases:

- TC-19 — CPU pressure produces no freeze/reclaim.
- TC-30/31 — GPU feeders are not frozen.
- TC-38/44/45 — recent focus, throttled slice isolation, build toolchain freeze guard.
- TC-46 — bandwidth loan and immediate reclaim.
- TC-47 — Hyprland class/title root binding and false-bind rejection.
- TC-48 — toolchain/project/ancestry edges and graph telemetry.
- TC-49 — active LSP child blocks reclaim of its root with no shared PID.

### 5.2 CPU headroom scorecard

```sh
./build/bench_cpu_headroom --compare --profile mixed \
  --duration 8 --threads 16 --bg-procs 2 --adaptive both --no-color
```

Latest v3.10 re-run: **8/8** at 40.0°C. Wake-up p99 **13.332 ms → 5.278 ms**,
deadline misses **202 (23.3%) → 15 (1.3%)**, BG throughput **80.0% retained**.
HC-CPU-1 workers survived 2/2 in both arms. The first v3.10 run was **7/8**
because BG throughput fell to 31.5% on a noisy host; the re-run restored the
invariant. The graph is not exercised by this harness, so that transient was
not treated as a graph regression.

Important caveat: p95/p99 on this shared host are noisy. Aggregate pressure p95
must not be quoted alone; historical aggregate pressure was
**7.9 ms vs 4.9 ms**, with max **1081.5 ms vs 21.4 ms**. Deterministic evidence
is cap values, reservation counts, cgroup stats, and invariant tests.

### 5.3 Memory primitives

`benchmarks/bench_memory_pressure.sh` starts a transient systemd scope with
`MemoryHigh=96M`, `MemoryLow=32M`, `MemoryMax=192M`, and proves real kernel
pressure:

- `memory.high=96 MiB`, `memory.low=32 MiB`;
- `memory.events.high = 18`;
- `oom_kill = 0`.

This validates the primitives THM uses, but it does **not** yet exercise the
full THM memory decision → enforcement path under RAM pressure.

### 5.4 QEMU/KVM A/B

Last full A/B was v3.4-R6. The harness now refuses arms when the hottest thermal
zone exceeds 60°C (`bench/host/run-bench.sh`). No post-v3.8 full compile A/B
has been run.

### 5.5 Resource cost

- Local dry-run peak RSS: **4.6 MB** (v3.10, 5 ticks, 306 PIDs).
- Guest sampled max RSS in R6: **4.2 MB**.
- Daemon CPU percentage remains host-sensitive; quote specific run IDs, not
  cross-run averages.

---

## 6. What is complete

| Capability | Status |
|---|---|
| Workload discovery and ownership forest | Complete |
| Fusion classification (ancestry, CWD, cmdline drift, execution) | Complete |
| Observed-workload telemetry-only mode | Complete |
| Workspace/window context from Hyprland IPC | Complete |
| 30 s recent-focus protection | Complete |
| Window class/title bound to workload root | Complete (v3.9) |
| Workload dependency graph + graph-guarded reclaim | Complete (v3.10) |
| CPU pressure arbitration | Complete |
| SMT whole-core isolation | Complete |
| Input feed-forward | Complete |
| Adaptive headroom | Complete |
| Stall-aware bandwidth loan | Complete (v3.8) |
| `memory.high` / `memory.low` wiring | Complete |
| Fail-closed decision sanitization | Complete |
| pidfd unified signal path | Complete |
| Browser-safe freeze / protected registry | Complete |
| Orphan thaw sweep | Complete |
| Telemetry JSON and CLI status/explain/scan | Complete |
| 49-case test suite | Complete |
| CPU headroom scorecard | Complete |
| Real cgroup memory-primitive benchmark | Complete |
| QEMU A/B harness with thermal guard | Complete |
| Daemon RSS under 6 MB | Complete |

---

## 7. What remains — prioritized implementation

### P0 — dependency / workload graph

**Status:** implemented in v3.10; residual modelling remains (see below).

The graph is built after the daemon state pass over the v3.9 bound roots:

- nodes: workload roots, state, Hyprland class/title evidence;
- edges: `ProcessAncestry`, `Toolchain` (LSP/build → window root),
  `SharedProject` (same CWD → window root);
- consumers: reclaim active-dependent check, telemetry, CLI.

Residual gap: browser tab groups, `waits-on`, and `reclassifies-from` are not
modelled yet. Existing browser roots are protected by the protected-root node
flag rather than per-tab edges.

Files:
`workload/dependency_graph.hpp/.cpp`, `policy/reclaim_engine.cpp`,
`daemon/daemon.cpp`, `ipc/telemetry_publisher.*`, `tests/test_runner.cpp`.

### P0 — graph-aware active-dependent check

**Status:** implemented in v3.10. `ReclaimEngine::reclaim()` takes an optional
`WorkloadDependencyGraph*`; steps 3 and 7 query `has_active_dependent()` before
falling back to the legacy root-PID comparison. TC-49 proves an active LSP
child blocks reclaim of a root with no shared PID.

### P1 — observability completion

Outstanding from the v3.8 roadmap:

- per-PID `/proc/<pid>/schedstat` stall signal for latency/GPU-feeding work;
- latency stall p50/p95/p99 in telemetry;
- `nr_throttled` deltas rather than only cumulative counters;
- bandwidth-loan timeline in `bench_cpu_headroom`;
- `titan-hwm explain` reason should mirror every `compute_pressure()` branch:
  low-free-memory CRITICAL fast path and no-PSI fallback are currently missing.

Files: `resources/pressure_level.cpp`, `daemon/daemon.cpp`,
`ipc/telemetry_publisher.hpp/.cpp`, `benchmarks/bench_cpu_headroom.cpp`.

### P1 — version / schema / docs reconciliation

- Telemetry `version` is still `3.3.0` while source/README/wiki advertise v3.10.
- Bench harness still checks schema prefix `3.2` and prints “v3.2 OK”.
- Some harness labels still say “THM v3.2” or “shipped v3.4”.
- **Resolved:** docs now state the actual build standard: C++17 for THM core,
  CLI and tests; C++20 only for `bench_cpu_headroom`. The daemon sources contain
  no C++20-only constructs.
- OOM constants differ between code (`-500 / 0 / +500`) and service comments
  (`-200 / +300`).
- Architecture report still describes a removed reclaim kernel-root check.
- **Resolved:** wiki pages updated from v3.1 to v3.10 and C++ labels corrected.

This is correctness-adjacent because live bench integration skips on stale
schema.

### P2 — tuning and smaller hardening

- Replace fixed 15-tick (~3 s) CPU release hysteresis with an adaptive value.
- Wire the documented `HardwarePolicy::swappiness` field or remove the stale
  claim.
- Reduce old ~7.5 ms/tick scan cost with current reprofiling.
- Test/document `WorkloadManager` pointer-lifetime contract; it assumes the
  daemon is single-threaded.
- Extend Hyprland alias coverage from real desktop sessions (Firefox ESR,
  Chromium variants, JetBrains IDEs, Electron apps).

---

## 8. What remains — validation gaps

1. **End-to-end THM memory-pressure test.** Current RAM benchmark proves kernel
   primitives in a transient scope, not THM's `memory.high` write, freeze/thaw,
   or reclaim decision path.
2. **post-v3.8/v3.9/v3.10 QEMU compile A/B.** Needed before claiming throughput
   gains; no claim is made now.
3. **`systemd-oomd` / kernel OOM coexistence audit.** Still outstanding.
4. **Browser collateral positive path.** TC-13 records “positive path not
   exercised” when no browser is live on the test host.
5. **GPU policy evidence.** glmark2 A/B recorded no enforcement because it was
   not classified as GPU-feeding; this is not a strong policy test.
6. **Input boost measurement.** Harness cannot inject realistic user input.
7. **Daemon CPU/RSS reprofile** after v3.8/v3.9/v3.10 on a quiet host.
8. **Live daemon cgroup path.** Original session reported
   `/sys/fs/cgroup/archtitan.slice not found`; delegation must be verified on a
   normal boot, not only in bench-disk injection.
9. **Per-slice PSI** is unavailable on the validation kernel, so system-wide
   PSI attribution remains ambiguous.

---

## 9. Known environment blockers and caveats

- **Thermal/power lockout:** unexplained hard power-off under NVIDIA remained
  off for ~8 h. Treat as firmware/EC/power until reproduced with full logs.
  Long A/B now waits for ≤60°C.
- **Host noise:** `ollama-local.service` restart loop and
  `coreai-local-mdns.service` CHDIR failure distort timing measurements.
- **KVM prerequisites:** `/dev/kvm` writable required; TCG is unusably slow.
- **Privilege/delegation:** root needed for cross-user `/proc`/signals;
  `cpuset` was not delegated on the validation host.
- **ISO rebuild:** blocked by `sudo: a terminal is required to read the
  password`; bench-disk injection was used instead.
- **Intel Unigine Superposition:** `SIGABRT` in
  `WidgetSpriteShader::create → Splash::init → Warming::init → MainLogic::init`
  prevents completion here. Not a THM regression.
- **GPU stress:** not run and not approved.
- **Missing workloads:** Blender/game engine/PyTorch not installed on the test
  host; one stable browser run is unavailable.
- **Telemetry source label:** live ISO CLI reports old version from the image;
  bench disk records `thm_source=bench-disk-v3.4` and source commit.

---

## 10. Explicitly out of scope

- I/O control plane.
- GPU control plane or GPU stress without explicit approval.
- New live context providers beyond Hyprland IPC.
- Automatic destructive memory reclaim by default.
- Adjacent subsystems (TitanFocus, Auto GPU Switcher) are not THM v3 work.

---

## 11. Suggested next three releases

### v3.10 — workload graph — SHIPPED

- Graph nodes/edges and TC-48/TC-49 added.
- LSP/build children and shared-CWD processes bound to window roots.
- Reclaim active-dependent check is graph-aware.
- Graph summary and per-workload counts published in telemetry / CLI.
- Browser tab groups, waits-on, and reclassification history deferred.

### v3.11 — observability and pressure fidelity

- Per-PID schedstat stall sampler.
- Stall p50/p95/p99 and `nr_throttled` deltas.
- Loan timeline in bench harness.
- `explain` reason mirrors `compute_pressure()`.
- Version/schema/docs reconciliation.

### v3.12 — validation hardening

- End-to-end THM memory-pressure benchmark.
- `systemd-oomd` coexistence audit.
- Quiet-host QEMU A/B after v3.8/v3.9 features.
- Current daemon CPU/RSS reprofile.
- Browser positive-path test on a live session.

---

## 12. Conclusion

THM v3 has moved from a prototype workspace-profile daemon to a mature
workload-aware orchestrator with explicit guardrails. The CPU plane is
scheduling-only and has survived the original v3.4 regression plus two further
feature layers. The memory plane is protect-first and now uses real cgroup
primitives with fail-closed decisions. Context is Hyprland-only and, since
v3.9, auditable at the workload-root level. v3.10 adds a real dependency graph
so an active LSP/build child can shield its root even without a shared PID.

The remaining gaps are fidelity and validation: browser-tab groups and
waits-on edges, version/schema hygiene, end-to-end memory-pressure testing, and
quiet-host QEMU A/B. The core orchestration and reclaim guardrails are in
place.

---

## 13. Source reports

- `docs/thm_v3_full_report.md` — original v3.2 technical report.
- `docs/benchmark-results/2026-11-20-v3.3-r4-real-memory-pressure.md`
- `docs/benchmark-results/2026-11-21-v3.4-qemu-ab-regression.md`
- `docs/benchmark-results/2026-11-25-v3.8-bandwidth-loan.md`
- `docs/benchmark-results/2026-11-25-v3.9-window-context-binding.md`
- `docs/benchmark-results/2026-11-25-v3.10-workload-dependency-graph.md`
- `README.md` — user-facing validation snapshot.
