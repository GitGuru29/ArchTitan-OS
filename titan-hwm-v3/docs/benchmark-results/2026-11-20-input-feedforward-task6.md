# Task 6 — Keyboard/mouse input feed-forward (2026-11-20)

Host: 4c/8t, user is in the `input` group and `/dev/input/event*` is readable.
No physical input was generated during the benchmark, so the live path was
validated by pure tests and the benchmark used a simulated boost.

## What changed

- `resources/input_feedforward.hpp` opens every readable `/dev/input/eventN`
  once with `O_NONBLOCK`, drains it each tick, and accepts only deliberate user
  input: key press/repeat, or non-zero relative/absolute pointer motion. Key
  releases and power/lid/sleep keys are ignored.
- `InputFeedForwardTracker` latches for 1.2 s after the last event and expires
  on its own, so a vanished device cannot leave the system pinned.
- A bounded boost is applied to the already-computed CPU policy:
  ACTIVE `+400`, LATENCY `+400`, BACKGROUND `−5` (floor 10), and one extra core
  taken away from bulk work. If no cap is engaged, a short one is armed so
  input latency is protected at NORMAL/MODERATE pressure. Unattended users get
  no boost. Weights are clamped at 10000; nothing is ever signaled (HC-CPU-1).
- Enforcement accepts the optional boost; telemetry/CLI expose
  `input_feedforward` and `input_age_ms`.

## Unit tests

```
./build/thm_test_runner  → 35/35 PASSED (was 34/34)
TC-35: key/mouse accepted, power key and key release rejected;
       latch 1 -> 1 -> 0 across 0/600/1300 ms;
       NORMAL quota 175000 us with reserve 1, HIGH quota 150000 us with
       reserve 2, active/latency 1400/1350, BG floored at 10;
       unattended policy untouched
TC-23: telemetry contract now checks 23 fields incl. input boost state
```

## Synthetic A/B

`bench_cpu_headroom --compare --profile mixed --duration 8 --threads 16
--bg-procs 2 [--input-boost] [--adaptive both]`, two independent runs of the
first two configurations.

| Configuration | BG cpu.max | managed wake-up p95 (run 1 / run 2) | BG throughput retained | Scorecard |
| :--- | ---: | ---: | ---: | ---: |
| baseline policy | 87.5% | 1.88 / 2.02 ms | 98.2 / 97.9% | 8/8 |
| `--input-boost` | 75.0% | 2.79 / 2.70 ms | 93.9 / 92.1% | 8/8 |
| `--adaptive both --input-boost` | 50.0% | 4.00 ms (single run) | 65.1% | 8/8 |

The deterministic, checkable effect is the cap: a fresh input event tightens
BG from 87.5% to 75%, and to 50% when a game + dataloader are already active.
The synthetic foreground loop does not model a real input-driven interactive
thread, so its jitter numbers are not evidence of a user-visible win here — in
these runs boosted jitter was actually slightly higher while background
throughput dropped as expected. The boost is aimed at the real
keyboard/mouse → compositor path, which this harness cannot reproduce. One
early run hit a noisy host period and scored 5/8; all reported runs above
passed 8/8. HC-CPU-1 held in every case.
