# Task 7 — `/proc` scan reduction (2026-11-20)

Host: 4c/8t, ~285 live PIDs during the measurement.

## What changed

Previously every 200 ms tick rebuilt the entire process graph from scratch:
directory walk plus `cmdline`, `stat`, `statm`, `stat()`, `getsid()`, `exe`
readlink and `cgroup` for every PID — and `ExecutionDetector` then opened
`/proc/<pid>/stat` a second time for CPU ticks.

- `refresh_proc_graph(graph, full_refresh)` now keeps PID nodes across ticks.
  Every tick it enumerates `/proc`, drops dead PIDs, and reads only
  `/proc/<pid>/stat` (comm, state, ppid, utime+stime) — one file read per PID.
- `cmdline`, `statm`, UID, SID, `exe` and `cgroup` are refreshed at 1 Hz
  (every 5 ticks) or immediately for newly discovered PIDs. Cmdline drift
  detection and telemetry therefore keep the same semantics.
- `ExecutionDetector::parse_cpu_ticks()` is shared by the graph refresh and the
  detector; the daemon passes the already-read ticks to `detect()`, removing the
  second per-PID `stat` open entirely.
- Shutdown logs average scan time (`[THM] /proc refresh: N us/tick ...`).
- Added TC-36 for the shared parser (comm with spaces, malformed stat).

## Unit tests

```
./build/thm_test_runner → 36/36 PASSED (was 35/35)
TC-36: "4242 (my weird proc) ... 1234 56" -> 1290 ticks; truncated -> -1
```

## Daemon A/B (pre-change commit `a046bb8` vs this change)

Both binaries run `--dry-run --ticks 30` on the same host; user+sys CPU is the
cost of the tick loop (wall includes the fixed 200 ms sleep per tick).

| run | old user | old sys | old total | new user | new sys | new total |
| :-- | --: | --: | --: | --: | --: | --: |
| 1 | 1.369 s | 1.834 s | 3.203 s | 0.480 s | 0.552 s | 1.032 s |
| 2 | 0.666 s | 0.701 s | 1.367 s | 0.499 s | 0.543 s | 1.042 s |

New daemon's own instrumentation: **7447 us/tick** and **7503 us/tick** over
~285 PIDs. The new loop's CPU cost is stable around 1.0 s/30 ticks; the old
loop varied with host conditions but was higher in both runs (up to 3.1x).
Classification, pressure evaluation, telemetry and enforcement still run every
tick — only the expensive process metadata is cached. HC-CPU-1 unchanged: no
signal path was added or removed.
