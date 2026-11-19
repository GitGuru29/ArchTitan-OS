# ArchTitan THM v3 — A/B/C Resource-Usage Stress Benchmark

Controlled stress-test comparison proving the resource-management contribution of
the **Titan Hardware Manager v3** in **ArchTitan OS**, versus the same OS without
it, versus stock Arch Linux. Designed for the interim viva demonstration.

---

## 1. Research question & hypotheses

**RQ:** Does workload-aware resource orchestration (THM v3) measurably improve
resource usage and resilience under developer-style memory stress, compared with
the kernel's default resource-blind behaviour?

| # | Hypothesis | Metric that tests it |
|---|---|---|
| H1 | THM prevents catastrophic memory exhaustion without killing foreground/active work | OOM kills count; compile-round failures |
| H2 | THM relieves memory pressure by freezing + reclaiming *idle* workloads (targeted), not by killing whatever is biggest (blind) | MemAvailable recovery curve; frozen-state evidence; OOM victim list |
| H3 | The system stays responsive under pressure with THM | PSI full-stall seconds; interactive probe latency p95/max |
| H4 | THM's own overhead is negligible | daemon CPU% and RSS during the run |

## 2. Experimental design — the three arms

| Arm | OS image | THM v3 | What it isolates |
|---|---|---|---|
| **A** | ArchTitan OS (live ISO, `out/archtitan-*.iso`) | **running** (system service) | The full ArchTitan system under test |
| **B** | ArchTitan OS (same live ISO) | **masked** (`systemctl mask --now titan-hwm`) | THM's exact contribution — *only* variable vs arm A |
| **C** | Vanilla Arch Linux (official `archlinux-*.iso`) | does not exist there | OS-level baseline (stock kernel behaviour) |

**Controlled variables** (identical across arms):

- QEMU/KVM VM: **2 vCPU, 4 GB RAM**, virtio-blk ISO + bench disk, **2 GB swap** on the bench disk
- Boot: the ISO's own kernel + initrd + cmdline (GRUB bypassed), `systemd.unit=multi-user.target`, serial console (headless)
- Workload bits: byte-identical (shared bench disk image)
- Same scenario script, same phase timing, same 500 ms metric sampler
- Same host machine, KVM acceleration, inter-arm thermal cooldown

**Why a VM:** fixed hardware spec = reproducibility; headless serial automation =
no display overhead (thermals); memory pressure is easy to trigger in a 4 GB VM.
The CPU-governor side of THM is out of scope here (no cpufreq in QEMU) — this
benchmark isolates the **memory/PSI/cgroup mechanisms**, which are THM's core.

## 3. The workload (developer-day simulation)

| Role | Process | Resource signature | THM classification (expected) |
|---|---|---|---|
| **Protected build** | continuous `make -j2` over 16 template-heavy C++ TUs | cc1plus ~90 MB RSS each, ~5 s/TU, high CPU | `COMPILER` / executing → never frozen, never killed |
| **Interactive task** | probe: 100 ms heartbeat loop (hash 32 MB + sleep) | ~4% CPU | executing → protected |
| **Idle apps** | 2 × 400 MB allocated, then asleep | memory held, ~0% CPU | `IDLE` → frozen at HIGH pressure, resumed after |
| **Memory hog** | ramp +100 MB / 8 s up to 4.2 GB, slow rolling re-touch | memory grows, <0.5% CPU | `IDLE` → frozen (contained) at HIGH pressure |

The hog's slow re-touch is deliberate: its anonymous pages stay "hot", so the
vanilla kernel cannot silently reclaim them — only a *frozen* cgroup (which
cannot fault pages back in) lets the kernel reclaim them. That is exactly the
mechanism difference under test.

**Phases:** `baseline` 60 s → `ramp` ≤240 s (hog grows until free <20%) →
`hold` 90 s → `release` (hog SIGTERM, "user closes the app") → `audit`.

## 4. Metrics & rationale

| Metric | Source | Why it matters |
|---|---|---|
| Kernel OOM kills + victims | `journalctl -k` | Did the system destroy user work? |
| Compile rounds ok/FAIL | make exit codes | Active-work survival |
| Min MemAvailable; recovery delta | `/proc/meminfo` | How close to the wall; did freezing recover memory |
| Memory PSI some/full avg10 | `/proc/pressure/memory` | Kernel-observable stall pressure |
| Full-stall seconds (Σ) | PSI × Δt | Time-equivalent of stalls |
| pswpin / pswpout / pgmajfault | `/proc/vmstat` | Thrash evidence (frozen pages swap out once and never fault back) |
| Probe latency p95/max | tstress probe | The stalls a user feels as jank |
| Sampler tick latency | collector | Responsiveness canary |
| Idle/hog T-state samples | `/proc/*/stat` + `archtitan-frozen.slice` | Direct evidence of THM freezing |
| THM daemon CPU%/RSS | `/proc/<pid>` | H4 — cost side of the claim |

## 5. Expected result (the story the numbers should tell)

- **Arm A (THM):** as free memory crosses 25%, THM freezes the idle apps and the
  hog (SIGSTOP + `cgroup.freeze=1` + `oom_score_adj=+300`), the kernel reclaims
  their now-cold pages, MemAvailable **recovers** (V-curve), PSI drops, THM thaws
  them when pressure normalizes. Zero OOM kills, build keeps running, probe stays
  flat. Daemon overhead ~1% CPU / tens of MB.
- **Arm B (no THM):** pressure mounts unchecked → swap thrash (pswpin/pswpout,
  PSI full, probe latency spikes) → kernel OOM killer fires on RSS-blind
  heuristics (may kill cc1plus mid-build, may kill the idle app, nondeterministic).
- **Arm C (vanilla Arch):** same resource-blind behaviour as B on a stock OS —
  the OS-level comparison point.

## 6. How to run

```bash
cd bench
./host/run-bench.sh --arms A,B,C          # full runs (~8–10 min per arm)
./host/run-bench.sh --arms A,B --quick    # fast smoke test (~4 min per arm)
```

Requirements (host): `qemu-system-x86_64`, KVM access, `bsdtar`, `e2fsprogs`
(mkfs/debugfs), `python3`, `gcc`. ISOs are auto-detected (newest release date
in the filename) from `out/`, `~/Desktop/` or `~/Downloads/`; override with
`--iso-archtitan` / `--iso-vanilla`.

The VM is only as fast as the host is idle, so each arm starts behind a
**host-load guard**: it waits until 1-min load < 60% of `nproc` and
MemAvailable ≥ 5 GB (up to `--host-wait SEC`, default 600). If the host is
still busy it aborts instead of producing invalid numbers — override with
`--allow-load` for functional smoke tests only. (A concurrent ISO build at
load 14/8 turned a 5.4 s TU into 44.8 s and starved the sampler; that run was
discarded.)

Artefacts per run:

- `bench/results/<arm>-<ts>/` — `metrics.csv` (500 ms samples), `probe.csv`,
  `builds.tsv`, `survival.tsv`, `oom-events.log`, `thm-journal.log` (arm A),
  `meta.txt`, `summary.json`
- `bench/logs/<arm>-<ts>-console-transcript.log` — **full serial console
  transcript** (boot, THM service state, phase transitions, guest summary —
  the audit trail)
- `bench/results/comparison.md` + `comparison.typ` — the comparison table

Re-run any arm to add error bars (`summarize.py` aggregates all runs per arm).

## 6a. Headless-boot engineering notes (why the driver does what it does)

Two non-obvious problems solved to boot live ISOs headless over serial:

1. **plymouthd busy-loops forever in a headless VM.** With `-vga none` there is
   no DRM device, and the initramfs `plymouth` hook (ArchTitan ships plymouth;
   vanilla Arch does not) spins the CPU instead of falling through — the boot
   stalls before systemd. Fix: `disablehooks=plymouth` on the kernel cmdline
   (mkinitcpio's own mechanism — the ISO's `plymouth.enable=0` param is *not*
   honored by this plymouthd build).
2. **Serial-console terminal probes expect replies.** plymouthd/systemd/agetty
   emit `ESC[6n` ("report cursor position") and *block* waiting for the answer.
   A real terminal replies instantly; the benchmark's serial socket must too —
   the driver auto-replies `ESC[25;80R` whenever it sees the query.

The full serial transcript (`bench/logs/*-console-transcript.log`) captures
every byte of boot + scenario output as reproducibility evidence.

Two more engineering notes from the first instrumented runs:

3. **The sampler must outrank the workload.** A ~50-fork-per-tick collector
   stretched from 500 ms to 10–12 s per tick while `make -j2` saturated both
   vCPUs, so a 200 s window yielded only 20 rows. `collector.sh` now reads
   `/proc` with bash builtins (no `fork` per field), folds PSI/meminfo/vmstat
   into two `awk` passes, and `renice -n -10`s itself — a tick costs ~15 ms
   even under full compile load, keeping the 500 ms grid.
4. **Workloads must live in an attributable directory.** THM ignores a process
   whose CWD is world-writable (`[S3] Ignored CWD in world-writable path`), so
   the compile project moved from `/tmp/benchproj` to `/bench/proj` (root-owned
   0755 on the bench disk). This both lets THM classify the build and removes
   the per-scan journal spam that inflated its measured CPU overhead.

Quick mode (`--quick`) uses larger, faster hog steps (500 MB / 4 s, cap 3 GB)
so a 60 s ramp crosses THM's 25 %-free HIGH threshold and exercises the
freeze path; the full run keeps the gentle 100 MB / 8 s ramp.

## 7. Viva Q&A prep

- *"Why is the no-THM arm the same OS, not just vanilla Arch?"* — To isolate the
  variable. Arm B changes exactly one thing (THM on/off) on the identical image;
  arm C then contextualises against stock Arch.
- *"Isn't the compile workload synthetic?"* — Yes, calibrated to match real
  gcc memory/time behaviour (see `calibration.txt` in each run dir); it keeps
  the workload deterministic and reproducible, which a real codebase is not.
- *"What about THM's own cost?"* — Measured directly (H4): daemon CPU% and RSS
  are columns in the table.
- *"Why not measure CPU governor effects?"* — QEMU has no cpufreq; this VM study
  isolates the memory/PSI/cgroup mechanisms. Governor effects need bare metal.
- *"Is the kernel OOM killer's choice fair to call 'blind'?"* — It ranks by RSS +
  `oom_score_adj`. THM *informs* that ranking (`+300` on frozen junk, `-200`/`-1000`
  on protected work), which is precisely the orchestration being demonstrated.
