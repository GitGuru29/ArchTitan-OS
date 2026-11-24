# Task 3 — Adaptive CPU headroom (2026-11-19)

Host: 8 logical CPUs, Linux 6.18.59-1-lts, real cgroup v2 isolation.

## What changed

- `CpuDemandHint` carries descriptive demand signals from the live workload
  tree: active latency-critical workloads, GPU dataloaders, bulk jobs, summed
  foreground CPU%, temperature, and SMT topology.
- `compute_reserved_cores()` extends the fixed 1-core HIGH / 2-core CRITICAL
  rule with demand (game +1, dataloader +1, saturated foreground +1), SMT
  sibling doubling, thermal clawback above 80 °C, and hard caps (never more
  than half the machine, never an empty BG slice).
- `AdaptiveHeadroomTracker` requires 3 consecutive ticks before changing
  `cpu.max`; pressure/away transitions apply immediately. No signal path is
  involved — this path only writes cgroup scheduling files (HC-CPU-1).
- Reservation is exposed in telemetry (`cpu.reserved_cores`) and CLI output.
- Benchmark harness gained `--adaptive none|game|train|both` so the cgroup
  effect of the hint can be measured directly.

## Unit tests

```
./build/thm_test_runner   → 33/33 PASSED (was 31/31)
TC-32: legacy=1/2, game=2, game+train=3, SMT=4, hot=2, saturated=2;
       quota 175000us -> 150000us (87.5% -> 75%)
TC-33: 1,1,1,2 with aborted rise restored; pressure transition immediate
TC-23: telemetry now checks 17 fields incl. reserved_cores
```

## A/B benchmark — headroom curve

Identical load (mixed profile, 8 s/phase, 16 BG threads, 2 processes). Only the
managed phase's demand hint changed:

```sh
./build/bench_cpu_headroom --compare --profile mixed --duration 8 \
    --threads 16 --bg-procs 2 --adaptive <none|game|both> --no-color
```

| Hint | BG cpu.max | Cores reserved (cpu.stat) | BG throughput retained | Scorecard |
| :--- | ---: | ---: | ---: | ---: |
| none (fixed) | 87.5% | 1.66 | 99.3% | 8/8 |
| game | 75.0% | 2.08 | 93.8% | 8/8 |
| game + train | 62.5% | 3.00 | 81.8% | 8/8 |

This is the intended trade: a running game / dataloader takes real capacity
away from bulk work. Foreground jitter numbers in these runs (p95 1.9–2.9 ms)
are dominated by host noise and the synthetic foreground worker does not model
a real game loop, so they are not evidence of a foreground win by themselves.
The authoritative checks are the reserved-core counts, the cpu.max values, and
TC-32/TC-33; HC-CPU-1 remained intact in every phase (0 kills/stops).
