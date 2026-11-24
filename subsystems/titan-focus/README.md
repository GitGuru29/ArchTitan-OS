# TitanFocus — Developer Work Optimization Engine

An unprivileged, per-user, **advisory-only** developer work-optimization engine for ArchTitan OS (pure C++20 / Qt6 / QML / POSIX — zero Python).

## Architecture

1. **Layer 1 — Signal Acquisition**: Hyprland `.socket2.sock` reader (`SessionMonitor`), async `hyprctl -j activewindow` classifier (`FocusMonitor`), POSIX `/proc/*/comm` scanner (`ProcSampler`), and `/proc/pressure/*` + `/sys/class/thermal` + `/run/archtitan/thm-state.json` reader (`PressureSampler`).
2. **Layer 2 — Rule Engine**: 12 declarative rules (`hydration`, `eye_strain`, `posture`, `focus_block`, `session_cap`, `context_thrash`, `long_build`, `thermal_pressure`, `late_night`, `daily_summary`, plus opt-in `agent_done` and `uncommitted`) guarded by a strict global 20-minute non-critical notification-fatigue floor.
3. **Layer 3 — Emitter & IPC**: `notify-send` via `posix_spawn` with burst coalescing + zombie reaping (`Notifier`), and `$XDG_RUNTIME_DIR/titan-focus.sock` (`IpcServer`).
4. **Layer 4 — Lazy LayerShell Overlay**: `FocusPill.qml` and `BreakOverlay.qml` built with `ArchTitan.TitanUI`, instantiated on demand via `Instantiator` and trimmed via `malloc_trim(0)` when hidden.

## Build & Test

```bash
bash build.sh
bash tests/test-sampler.sh
```

## Keybind & CLI

- Toggle overlay: `Super + Alt + F` or `titan-focus --toggle`
- Waybar JSON: `titan-focus --waybar`
- Snooze 15 min: `titan-focus --snooze 15`
- Start 10 min break: `titan-focus --break 10`
- Toggle Do Not Disturb: `titan-focus --dnd`
