# Unigine Superposition game-like workload benchmark (2026-11-20)

## Setup

- Host: 11th-gen laptop, 4 physical / 8 logical CPUs (`cpu0` sibling `0,4`),
  Intel Iris Xe iGPU, 15 GB RAM, Arch kernel 6.18.59-1-lts.
- App: `/opt/unigine-superposition` (Unigine Superposition 1.1, Basic edition).
- Mode: GUI launcher, **Performance** benchmark, 1080p Medium preset, OpenGL,
  fullscreen, default 3-minute run.
- Environment quirk: session sets `QT_QPA_PLATFORM=wayland;xcb`, which the Qt
  launcher cannot load. All runs used `QT_QPA_PLATFORM=xcb` (XWayland on
  `DISPLAY=:1`). The launcher ignores `-resolution/-quality/-sound` and always
  spawns `bin/superposition -preset 2 ... -video_width 1920 -video_height 1080
  -sound 1`.
- Launch was automated through AT-SPI (`Push Button "Run"`) plus an XTest click
  to raise the XWayland window first; no human input was generated during runs.
- Background contention for managed runs: two `ffmpeg libx264` encoders
  (`640x360@30`, `veryfast`) for the duration of the benchmark.

## Results

| Run | Score | FPS min | FPS avg | FPS max | Notes |
|---|---:|---:|---:|---:|---|
| Baseline, no THM, no encoders | **167** | 1.19 | **1.25** | 1.48 | Clean run, system idle otherwise |
| Managed, before fix, THM + 2 encoders | 161 | 1.10 | 1.20 | 1.42 | `superposition` unclassified; cap lifted to `max(unattended)` at CRITICAL |
| Managed, after fix, THM + 2 encoders | **162** | 1.13 | **1.21** | 1.47 | Game classified as latency intent; cap stayed at 50% + `cpu.idle` |

Interpretation: the fixed managed run retained **96.8%** of baseline score and
**96.8%** of baseline average FPS under two competing encoders. The before-fix
run retained 96.4% / 96.0%. The dominant performance problem is not THM: the
machine reports `CPU governor: powersave`, actual CPU ~1190 MHz, and even the
clean baseline only reaches ~1.25 FPS at 1080p Medium on this integrated GPU.

## THM telemetry

Before the fix (`titan-hwm scan` / `status` / `decisions`):

- `superposition` appeared under **Top unmanaged user processes** with reason
  `no classification signal`.
- At 08:29:23 pressure was CRITICAL with `bg_cap=50% +idle`, `reserved=4`.
- At 08:30:39 pressure was still CRITICAL but `bg_cap=max(unattended)`,
  `reserved=0` — the unattended escape hatch fired because no keyboard/mouse
  events arrive during an automated game, even though the game was burning a
  full core.
- No SMT/cpuset isolation was applied because demand had no latency workload.

After the fix:

- `superposition` (PID 203799) became workload **ID 21**, classified with
  latency intent (`TYPE NEUTRAL` is expected: the executable name carries the
  intent, not a classic IDE/build type).
- At CRITICAL pressure: `bg headroom cap = 50.0% + cpu.idle`, 4 logical cores
  reserved, `SMT isolation: 2 physical core(s) | latency[0,1,4,5]
  bg[2,3,6,7]`.
- No `max(unattended)` transition occurred, and no protected/kill/stop signal
  was issued (HC-CPU-1 preserved).

## Bugs identified and fixed

1. **Standalone game engine missed by intent classifier.** `Superposition`
   launches `bin/superposition` directly; it has no Steam/launcher parent and
   no matching window class, so it stayed OBSERVED and never received latency
   intent, SMT isolation, or an uncapped latency slice. Added `superposition`,
   `superposition_cli`, `unigine`, and `unigine-superposition` to
   `latency_critical_apps` (TC-37).
2. **Unattended detection was input-only.** `user_unattended()` treated >60 s
   without keyboard/mouse as "away" and lifted `cpu.max` at HIGH/CRITICAL even
   while a game/GPU feeder was active. Added
   `should_lift_unattended_cap(presence, demand)`: active `latency_workloads`
   or `gpu_feeders` suppress the lift; bulk-only work still gets it (TC-38).
3. **Zero-core reservation when the lift was suppressed.** Direct callers of
   `compute_cpu_slice_policy(raw_unattended=true, demand=game)` would skip the
   lift but still pass raw "away" to `compute_reserved_cores()`, which returns
   0. The policy now treats presence as effective (false) whenever the lift is
   suppressed, and the daemon passes the refined value to reservation,
   hysteresis, and SMT isolation.

## Bugs observed in the benchmark/environment (not THM)

- `QT_QPA_PLATFORM=wayland;xcb` is invalid for the bundled Qt launcher; must
  override to `xcb`.
- Superposition Basic ignores command-line quality/resolution/sound flags;
  `-sound 0` still produced `-sound 1`.
- OpenAL logs `error: invalid value` continuously because the default device is
  `Easy Effects Sink`. `GPUMonitorPlugin::init()` also fails. Neither affects
  scoring materially.
- CPU governor stays `powersave` with ~1190 MHz actual clock. Together with an
  iGPU this explains the ~1.2 FPS result; recommend performance governor and a
  dGPU (`GeForce MX350`) rerun for representative game numbers.
- THM daemon CPU rose to ~40-46% during the 286-process scan under contention.
  This is a follow-up profiling item, not a functional regression.

## Validation

- `./build/thm_test_runner`: **38/38 PASSED**.
- `./build/bench_cpu_headroom --compare --profile mixed --duration 8 --threads
  16 --bg-procs 2 --adaptive both --no-color`: **8/8 PASSED**, HC-CPU-1
  zero kills/stops in both phases.
