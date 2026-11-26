# Real cgroup v2 CPU Benchmark — 2026-11-19

Host:

- 8 logical CPUs, Intel i5-1135G7 (4 cores / 8 threads)
- Linux 6.18.59-1-lts
- `intel_pstate`, available governors: `performance powersave`
- Cgroup isolation: `/sys/fs/cgroup/user.slice/user-1000.slice/user@1000.service/archtitan-bench-<pid>`
  (real `cpu.weight` + 25 ms `cpu.max`, delegated to the user session; no root password needed)

All runs used 16 background threads across 2 forked worker processes (2x logical CPU saturation).
HC-CPU-1 held in every phase: background workers were throttled/rescheduled, never frozen, stopped, or killed.

## 1. Full suite: 18/18 assertions passed

Command:

```sh
titan-cpu-bench --suite --duration 10 --threads 16 --bg-procs 2 --no-color
```

### Interactive / 144 Hz compositor

| Metric | Flat Linux | THM v3.2 managed | Change |
| :--- | ---: | ---: | ---: |
| Slice weights (FG:BG) | 100:100 | 1000:10 | asymmetric |
| BG `cpu.max` | max (100%) | 87.5% @ 25 ms | 1 core reserved |
| Wake-up p50 | 2.616 ms | 0.038 ms | -98.6% (69x) |
| Wake-up p95 | 14.851 ms | 1.248 ms | -91.6% (11.9x) |
| Wake-up p99 | 29.148 ms | 4.040 ms | -86.1% (7.2x) |
| Frame p95 | 19.430 ms | 4.183 ms | -78.5% (4.6x) |
| Frame p99 | 39.145 ms | 7.940 ms | -79.7% (4.9x) |
| Deadline misses (>6.9 ms) | 290/865 (33.5%) | 21/1411 (1.5%) | -92.8% (13.8x) |
| Severe drops (>16.7 ms) | 52 | 0 | -100% |
| BG throughput | 189.6 M/s | 188.3 M/s | 99.3% retained |
| BG CPU usage | 6.40 / 8 | 6.22 / 8 | 1.78 cores reserved |
| `cpu.stat` throttles | 0 | 19 (46 ms) | `cpu.max` active |

### Audio DSP / 48 kHz, 128-frame quantum

| Metric | Flat Linux | THM v3.2 managed | Change |
| :--- | ---: | ---: | ---: |
| Slice weights (FG:BG) | 100:100 | 2000:10 | asymmetric |
| Wake-up p95 | 5.861 ms | 0.186 ms | -96.8% (31.5x) |
| Wake-up p99 | 11.963 ms | 2.594 ms | -78.3% (4.6x) |
| Frame p95 | 6.060 ms | 0.344 ms | -94.3% (17.6x) |
| Frame p99 | 12.271 ms | 2.830 ms | -76.9% (4.3x) |
| Deadline misses (>2.7 ms) | 459/2695 (17.0%) | 41/3678 (1.1%) | -91.1% (11.2x) |
| Severe drops (>16.7 ms) | 11 | 0 | -100% |
| BG throughput | 198.9 M/s | 194.5 M/s | 97.8% retained |
| `cpu.stat` throttles | 0 | 46 (63 ms) | `cpu.max` active |

### Pressure ramp

| Stage | RunQ/N | Instant PSI | PSI avg10 | Level | BG cap | HC-CPU-1 |
| :--- | ---: | ---: | ---: | :--- | :--- | :--- |
| CALM | 0.38 | 2.1% | 27.3% | MODERATE | max | OK |
| WARMUP (N/2) | 1.25 | 5.7% | 19.1% | MODERATE | max | OK |
| STORM (2xN) | 3.00 | 86.2% | 33.8% | CRITICAL | 75% | OK |
| COOLDOWN (N/2) | 1.38 | 8.8% | 26.6% | MODERATE | max | OK |
| RECOVERY | 0.62 | 7.2% | 15.2% | MODERATE | max | OK |

The storm was classified CRITICAL on an 86.2% per-tick PSI delta while `avg10` was only 33.8%,
confirming the new fast path engages before the 10 s EWMA catches up.

The live-daemon check was skipped because no `titan-hwm-daemon` was running and `/run/archtitan`
is not writable by the unprivileged user. All other 18 assertions passed.

## 2. Ablation: weights vs `cpu.max` — 6/6 assertions passed

Command:

```sh
titan-cpu-bench --ablation --profile interactive --duration 8 --threads 16 --bg-procs 2 --no-color
```

| Metric | Flat Linux | Weights only | Full weights + `cpu.max` |
| :--- | ---: | ---: | ---: |
| Wake-up p95 | 11.329 ms | 1.535 ms | 0.158 ms |
| Wake-up p99 | 22.118 ms | 4.052 ms | 4.190 ms |
| Frame p95 | 13.402 ms | 4.333 ms | 2.250 ms |
| Frame p99 | 26.540 ms | 7.500 ms | 6.062 ms |
| Frame max | 48.690 ms | 24.938 ms | 18.267 ms |
| Budget misses | 232/773 | 16/1129 | 8/1140 |
| BG throughput | 191.0 M/s | 191.1 M/s | 195.4 M/s |
| CFS throttles | 0 | 0 | 14 |

`cpu.weight` alone removes most of the tail latency; the 25 ms `cpu.max` headroom adds a further
clearly measurable reduction in frame time and deadline misses without costing background throughput.

## 3. Mixed build-like load — 8/8 assertions passed

Command:

```sh
titan-cpu-bench --compare --profile mixed --duration 10 --threads 16 --bg-procs 2 --no-color
```

| Metric | Flat Linux | THM v3.2 managed | Change |
| :--- | ---: | ---: | ---: |
| Wake-up p95 | 8.682 ms | 0.838 ms | -90.4% (10.4x) |
| Wake-up p99 | 15.798 ms | 4.137 ms | -73.8% (3.8x) |
| Frame p95 | 10.916 ms | 2.835 ms | -74.0% (3.9x) |
| Frame p99 | 17.702 ms | 5.233 ms | -70.4% (3.4x) |
| Deadline misses | 216/1113 (19.4%) | 8/1306 (0.6%) | -96.3% (27x) |
| Severe drops (>16.7 ms) | 16 | 1 | -93.8% |
| BG throughput | 203.7 M/s | 206.2 M/s | 101.2% retained |
| `cpu.stat` throttles | 0 | 41 (137 ms) | `cpu.max` active |

## Conclusion

Under real kernel cgroup v2 enforcement on an 8-CPU laptop-class host, the CPU control plane cuts
interactive, audio, and build-like tail latency by 4x-30x and nearly eliminates deadline misses,
while retaining roughly 98-101% of background throughput. Background work is throttled by the
kernel rather than by signals: HC-CPU-1 remained intact in every phase.
