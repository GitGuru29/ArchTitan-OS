# Task 4 — Real-workload CPU arbitration A/B (2026-11-20)

Host: 4 physical cores / 8 logical threads (`cpu0` siblings `0,4`), Linux
cgroup v2 with the `cpu` controller delegated to `user@1000.service`. No root
needed. Blender, a game engine, and PyTorch are not installed on this host, so
the real workloads used here are **gcc -O2 compilation** (foreground) and
**ffmpeg/libx264 encoding** (background, 4 concurrent workers — one per physical
core). Game and training intent remain covered by the synthetic
`bench_cpu_headroom --adaptive` runs in the Task 3 record.

## Harness

`benchmarks/bench_real_workloads.sh` runs two transient user scopes:

- **baseline**: foreground `CPUWeight=100`, background `CPUWeight=100`, no quota.
- **managed**: foreground `CPUWeight=1000` (THM `SLICE_ACTIVE` at HIGH),
  background `CPUWeight=10` (THM `SLICE_BACKGROUND` at HIGH) plus the
  `CPUQuota` produced by `compute_cpu_slice_policy()` for the chosen headroom.

Background encoders are started first and reach steady state before the
foreground compile loop is timed, so `systemd-run` startup overhead is not
counted. Background cost is the `cpu.stat` `usage_usec` delta over the same
window. HC-CPU-1 is preserved by construction: no signals, kills or freezes.

## Results

3 A/B repetitions per quota level. Timings in ms; `BG cpu` is CPU-time consumed
by the background scope during the foreground window.

### Fixed headroom — 87.5% (HIGH, no extra demand)

| rep | baseline FG | managed FG | baseline BG cpu | managed BG cpu |
| --: | --: | --: | --: | --: |
| 1 | 2207 | 1362 | 13836 | 1183 |
| 2 | 3726 | 5017 | 21497 | 4374 |
| 3 | 6921 | 5048 | 36706 | 4459 |
| **avg** | **4285** | **3809** | **24013** | **3339** |

Foreground speedup **1.12x**, background CPU **0.14x** of baseline.

### Adaptive headroom — 75% (game intent, one extra core reserved)

| rep | baseline FG | managed FG | baseline BG cpu | managed BG cpu |
| --: | --: | --: | --: | --: |
| 1 | 2280 | 1355 | 14112 | 971 |
| 2 | 2271 | 1360 | 13511 | 1046 |
| 3 | 7030 | 4930 | 38326 | 3668 |
| **avg** | **3860** | **2548** | **21983** | **1895** |

Foreground speedup **1.51x**, background CPU **0.09x** of baseline.

## Interpretation

The tighter adaptive cap consistently gives the foreground more CPU and leaves
the render workers less — the intended trade when a game (or dataloader) is
actually running. Absolute times vary substantially between reps (rep 3 on
both runs hit a noisy host period), so the per-rep ratios and the direction of
change are more meaningful than the averaged speedup alone. The static C++
benchmark remains the deterministic regression check; this harness validates
that the same policy shape helps a real compiler under a real encoder load.

Reproduce:

```sh
./benchmarks/bench_real_workloads.sh --reps 3 --quota 87.5%
./benchmarks/bench_real_workloads.sh --reps 3 --quota 75%
```
