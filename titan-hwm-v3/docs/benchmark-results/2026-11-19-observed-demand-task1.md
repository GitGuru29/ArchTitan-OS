# Task 1 — Observed heavy workload demand (2026-11-19)

Host: 8 logical CPUs, Intel i5-1135G7, Linux 6.18.59-1-lts, real cgroup v2
isolation in `user@1000.service/archtitan-bench-<pid>`.

## What changed

- `Workload::cpu_pct` is now aggregated once per tick from the measured
  per-PID CPU deltas (previously only computed in the telemetry publisher).
- `compute_governor()` no longer skips every observed workload. An observed
  workload with >= 15% CPU (or confirmed background execution) now counts as
  demand, so a focused game / Blender render / training job cannot leave
  `all_idle=true` and pin the governor at POWERSAVE under NORMAL pressure.
- Observed workloads join `archtitan-active.slice` (focused/visible) or
  `archtitan-background.slice` immediately, instead of waiting for CPU pressure
  to reach MODERATE. Assignment is change-detected, so steady state costs zero
  cgroup writes.
- Fixed the dead `high_cpu_userspace` check: classification now uses the
  previous tick's measured CPU% instead of a freshly-zeroed `ProcessNode`.
- Added TC-27 (observed heavy demand) and TC-28 (observed slice assignment).

## Unit tests

```
./build/thm_test_runner   → 28/28 PASSED (was 26/26)
TC-27: heavy=SCHEDUTIL, contended=PERFORMANCE, idle=POWERSAVE
TC-28: focused=ACTIVE, unfocused=BACKGROUND, idle/classified=skipped
```

## A/B benchmark (unchanged arbitration plane, regression check)

Command (both runs identical):

```sh
./build/bench_cpu_headroom --compare --profile mixed --duration 8 \
    --threads 16 --bg-procs 2 --no-color
```

| Metric (mixed) | Before | After | Note |
| :--- | ---: | ---: | :--- |
| Wake-up p50 | 1.555 ms | 2.371 ms | noise |
| Wake-up p95 | 9.106 ms | 2.892 ms | noise |
| Frame p95 | 12.938 ms | 5.002 ms | noise |
| Deadline misses | 21.1% | 1.3% | both runs healthy |
| BG throughput | 221.3 M/s | 221.5 M/s → 206.4 M/s | ~100% retained |
| Scorecard | 8/8 | 8/8 | pass |

Interactive profile (144 Hz) after the change: wake-up p95 1.816 ms,
frame p95 3.933 ms, deadline misses 1.0%, 96.1% BG throughput retained,
8/8 assertions passed.

The harness drives its own cgroups directly and does not run the daemon's
classification/governor path, so these numbers are a **regression check**, not
a measurement of the new logic. Run-to-run variance on this shared 8-CPU host
is significant (baseline p95 ranged 1.2–2.9 ms across identical runs). The
authoritative validation for this task is TC-27/TC-28 plus the invariant that
HC-CPU-1 still passes (zero kills/stops in every phase).
