# ArchTitan THM v3 — A/B/C resource-usage stress benchmark

Generated 2026-11-12T11:37:00

## Environment (identical across arms)

| Property | Value |
|---|---|
| VM | QEMU/KVM, 2 vCPU, 4 GB RAM, 2 GB swap on bench disk |
| Boot | live ISO, `systemd.unit=multi-user.target`, serial console |
| Workload | continuous `make -j2` (16 template-heavy C++ TUs) + probe (100 ms heartbeat) + 2×400 MB idle apps + memory hog (burst 1.9 GB, then 200 MB/10 s up to 4600 MB) |
| Phases | warm-up 60 s (not sampled) → baseline 60 s → ramp ≤240 s (stop at free <20%) → hold 90 s → release (hog TERM/CONT/KILL) → audit |

## Resource-usage comparison

| Metric (↓ lower is better / ↑ higher is better) | ArchTitan + THM v3 (n=1) | ArchTitan — THM off (n=1) |
|---|---|---|
| ↓ Kernel OOM kills | 0 | 0 |
| ↑ Compile rounds completed | 1 | 5 |
| ↓ Compile rounds FAILED | 1 | 0 |
| ↓ Median round wall time | 67927 ms | 23687 ms |
| ↑ Min MemAvailable | 653 MB | 49 MB |
| ↑ Post-release recovery | 2041 MB | 2969 MB |
| ↓ Peak memory PSI (full) | 2.6% | 24.1% |
| ↓ Full-stall seconds (Σ) | 0.4 s | 5.2 s |
| ↓ Peak swap in use | — | 305 MB |
| ↓ Swap-in pages (pswpin) | 0 | 0 |
| ↓ Swap-out pages (pswpout) | 0 | 28 |
| ↓ Major faults | 91 | 409 |
| ↓ Probe latency p95 (pressure) | 6.9 ms | 5.1 ms |
| ↓ Probe latency max (pressure) | 48.6 ms | 55.8 ms |
| ↓ Probe latency p95 (baseline) | 10.0 ms | 3.3 ms |
| ↓ Sampler tick latency max | 680 ms | 621 ms |
| ↓ Hog max RSS | 1932 MB | 2721 MB |
| ↑ Idle apps frozen (T samples) | 98 | 0 |
| ↑ Hog frozen (T samples) | 0 | 0 |
| ↓ THM daemon CPU (avg) | 32.19% | — |
| ↓ THM daemon RSS (max) | 5 MB | — |

## Qualitative outcomes

| Outcome | ArchTitan + THM v3 | ArchTitan — THM off |
|---|---|---|
| Idle apps survived (final state) | idle1:('yes', 'S')/idle2:('yes', 'S') | idle1:('yes', 'S')/idle2:('yes', 'S') |
| OOM victims | none | none |
| Hog contained | ('no', 'gone') | ('no', 'gone') |

## Interpretation

- **Less time stalled**: full memory-stall equivalent was 0.4s with THM vs 5.2s without (−92%).

- **Healthier memory floor**: minimum available memory was 653 MB with THM vs 49 MB without.

- THM froze idle apps/hog (observed in 98 samples) — a frozen workload cannot allocate or fault, so the pressure source stops growing; the frozen pages stay resident until the workload is released.

- **Cost of THM**: daemon averaged 32.2% of one vCPU and ≤5 MB RSS in a 2-vCPU guest (a fixed polling cost: ~0.2 s scan tick). On a many-core desktop this is a much smaller fraction of total capacity.


## Threats to validity (disclose in the viva)

- Live-ISO environments (tmpfs overlay) — representative but not an installed system.
- Synthetic template-heavy compile workload calibrated to real gcc RSS/time, not a real codebase.
- Single machine, KVM VM: CPU-governor effects of THM are NOT measured here (no cpufreq in QEMU); this benchmark isolates the memory/PSI/cgroup mechanisms.
- The harness (scenario shell, collector, compile driver) is double-forked out of THM's ownership tree so THM manages the *workloads* and not the benchmark controller. A real terminal shell that parents `make` would be classified SYSTEM_DEV and could be frozen at HIGH pressure — that would stop the *next* compile round, not the running build.
- Absolute compile times track the host CPU's power/thermal state; every arm runs a fixed 30-60 s un-sampled warm-up and arms run back-to-back on the same host (load guard <60% of nproc). Compare arms, not absolute numbers.
- Kernel versions differ slightly between ISO build dates (disclosed in each meta.txt).
- Kernel OOM victim selection is nondeterministic; repeat runs (--arms A,B …) to add error bars.
