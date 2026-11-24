# Task 2 — Workload intent + latency slice (2026-11-19)

Host: 8 logical CPUs, Linux 6.18.59-1-lts, real cgroup v2 isolation in
`user@1000.service/archtitan-bench-<pid>`.

## What changed

- `Workload` / `ClassificationResult` gained three descriptive intent flags:
  `latency_critical` (games / real-time apps), `throughput_bulk` (render /
  compile), `gpu_feeding` (training dataloaders).
- `FusionClassifier::detect_intent` recognises Steam/Proton/Wine/gamescope,
  Blender/Cycles/Inkscape/Handbrake, and python-family processes whose full
  command line contains torch/train.py/tensorflow/dataloader markers.
  Intent alone promotes a workload out of observation mode — headless games and
  trainers have no window title and would otherwise stay unclassified.
- `PolicyEngine`: games return `KEEP_FULL` even when their workspace is not
  focused; GPU feeders are never frozen or reclaimed and are only memory-
  throttled at CRITICAL pressure.
- New `archtitan-latency.slice`: weighted like foreground (450→1000 by CPU
  pressure) but **never** given `cpu.max` or `cpu.idle`. Bulk work keeps the
  capped background slice. Games/dataloaders route to the latency slice.
- Governor boosts for active bulk work and for background games/dataloaders.
- Telemetry exposes all three intent flags and the latency slice weight.

## Unit tests

```
./build/thm_test_runner   → 31/31 PASSED (was 28/28)
TC-29: game=LATENCY, render=BULK, train=GPU_FEED, plain python=none
TC-30: game@CRITICAL=KEEP_FULL, train@HIGH=KEEP_BACKGROUND, train@CRITICAL=THROTTLE
TC-31: game/train=archtitan-latency.slice, bulk=background, L(HIGH)=950
TC-23: telemetry contract now checks 16 fields incl. latency_weight
```

## A/B benchmark (regression check)

Command (identical for both profiles and both tasks):

```sh
./build/bench_cpu_headroom --compare --profile <mixed|interactive> \
    --duration 8 --threads 16 --bg-procs 2 --no-color
```

| Metric (mixed) | Before (Task 1) | After (Task 2) |
| :--- | ---: | ---: |
| Wake-up p95 | 2.892 ms | 0.656 ms |
| Frame p95 | 5.002 ms | 2.946 ms |
| Deadline misses | 1.3% | 0.5% |
| BG throughput retained | 100.4% | 102.7% |
| Scorecard | 8/8 | 8/8 |

Interactive (144 Hz) after the change: wake-up p95 0.259 ms, frame p95 2.217 ms,
deadline misses 0.3%, 8/8 assertions passed. One run showed 81.0% BG throughput
retained; an immediate re-run of the identical command showed 95.1% with 1.22
cores still reserved — run-to-run variance on this shared host is high. Both
runs passed the 8/8 scorecard and HC-CPU-1 remained intact (no kills/stops).

The synthetic harness drives its own cgroups directly and does not instantiate
the classifier or policy engine, so these numbers are a **regression check** on
the arbitration plane; TC-29..TC-31 validate the new intent logic.
