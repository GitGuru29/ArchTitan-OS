# Task 5 — SMT / cpuset whole-core isolation (2026-11-20)

Host: 4 physical cores / 8 logical threads. `cpu0` sibling list is `0,4`, so the
pairs are `0/4`, `1/5`, `2/6`, `3/7`.

## What changed

- New pure module `resources/smt_topology.hpp`: parses sysfs `core_id` and
  `thread_siblings_list`, groups logical CPUs by physical core, and plans a
  cpuset split. No kernel writes in the planner.
- `plan_smt_isolation()` gives latency work **whole physical cores** (both
  siblings), and removes *all* siblings of those cores from the background
  slice. A game alone reserves one physical core; a game plus GPU feeder
  reserves two (half the machine on 4c/8t). At least two physical cores always
  remain with background work. An unattended user disables isolation.
- Intent alone engages it, at any pressure: a background compile on a game's
  SMT sibling steals execution units long before PSI reaches HIGH. `cpu.max`
  and weights remain pressure-driven (`compute_cpu_slice_policy`).
- `CgroupController::set_cpuset()` enables the `cpuset` controller in
  `archtitan.slice`, inherits `cpuset.mems` from the parent, and is a best-effort
  no-op where cpuset is unavailable. `EnforcementPlane::apply_smt_isolation()`
  writes ACTIVE and LATENCY to the reserved set and BACKGROUND to the complement,
  change-detected (zero writes in steady state). Only cgroup files are touched —
  HC-CPU-1 still forbids any signal from this path.
- Telemetry/CLI expose `smt_isolation`, `isolated_cores`, `latency_cpuset` and
  `background_cpuset`.

## Unit tests

```
./build/thm_test_runner  → 34/34 PASSED (was 33/33)
TC-34: parse "0-1,4,7"; 4 sibling pairs; 1 job -> latency[0,4] bg[1,2,3,5,6,7];
       2 jobs -> latency[0,1,4,5] bg[2,3,6,7]; MODERATE still engages;
       unattended disables
TC-23: telemetry contract now checks 21 fields incl. both cpusets
```

## Real-workload A/B

`benchmarks/bench_real_workloads.sh --reps 3 --smt-isolate` adds two modes:
`smt-only` (equal weights, no quota, affinity split) to isolate the physical-core
effect, and `managed-smt` (production HIGH weights + quota + split). cpuset is
not delegated to `user@.service` on this host, so the benchmark uses `taskset`
to apply the same CPU sets. Split used: FG `[0,4,1,5]`, BG `[2,6,3,7]`.

| mode | avg compile | median compile | avg BG CPU |
| :--- | ---: | ---: | ---: |
| baseline (equal weights) | 5931 ms | 6933 ms | 31827 ms |
| smt-only (affinity split) | 5839 ms | 5800 ms | 22471 ms |
| managed (1000/10 + 87.5%) | 5007 ms | 5017 ms | 4399 ms |
| managed-smt | 5102 ms | 5091 ms | 4507 ms |

Interpretation: with equal weights, keeping the compiler off the encoder's SMT
siblings cut background CPU consumption by ~29% and improved the median compile
time by ~16% (6933 -> 5800 ms). With THM's HIGH-pressure weights the background
slice is already starved (`weight=10`), so the weight/quota effect dominates and
cpuset adds little in this particular mix — its value is protecting latency work
at NORMAL/MODERATE pressure, where those brakes are not engaged. Rep 1 was an
unusually quiet period for the first pair, so medians are more trustworthy than
averages here. Zero kills/stops in every mode (HC-CPU-1).

## Deterministic regression

```
./build/bench_cpu_headroom --compare --profile mixed --duration 8 \
    --threads 16 --bg-procs 2 --adaptive both --no-color
→ BG cap 62.5%, jitter p95 7.319 -> 3.684 ms (-49.7%), BG throughput 80.6%,
  8/8 scorecard passed
```
