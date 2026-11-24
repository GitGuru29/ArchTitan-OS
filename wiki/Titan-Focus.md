# TitanFocus — Developer Work Optimization Engine

**TitanFocus** (`titan-focus`) is an unprivileged, per-user, **advisory-only** developer work-optimization engine built in pure C++20 / Qt6 / QML / POSIX (zero Python runtime dependencies).

While `titan-hwm-v3` orchestrates machine resources, TitanFocus consumes the same `/proc` and Hyprland signal surface to protect developer attention, cadence, and ergonomics — without ever throttling, freezing, or signalling any user process.

---

## Architecture

1. **Layer 1 — Signal Acquisition**:
   - `SessionMonitor`: Non-blocking `QLocalSocket` reader on Hyprland's `.socket2.sock` (`activewindow>>`, `workspace>>`, `idle>>`).
   - `FocusMonitor`: Async `hyprctl -j activewindow` classifier matching `known_ides` and meeting/fullscreen-media contexts.
   - `ProcSampler`: Pure POSIX `/proc/<pid>/comm` scanner every 2 s (zero subprocesses).
   - `PressureSampler`: Pure POSIX reader for `/proc/pressure/memory`, `/proc/meminfo`, `/sys/class/thermal`, and optional `/run/archtitan/thm-state.json`.
2. **Layer 2 — Rule Engine (`RuleEngine` + `NudgeState`)**:
   - 12 declarative rules across 5 toggleable categories (`health`, `focus`, `workflow`, `system`, `summary`).
   - **Global 20-minute non-critical fatigue floor** enforced across all rules.
   - `suppress_when` gating for meetings, fullscreen media, Do Not Disturb, snooze, and active breaks.
   - `agent_done` and `uncommitted` ship disabled by default (opt-in via `~/.config/titan-focus/focus.toml`).
3. **Layer 3 — Emitter & IPC**:
   - `Notifier`: Direct `notify-send` invocation via `posix_spawn` with explicit `argv`, burst coalescing, and `waitpid(WNOHANG)` zombie reaping.
   - `IpcServer`: `$XDG_RUNTIME_DIR/titan-focus.sock` supporting `TOGGLE`, `SHOW`, `HIDE`, `SNOOZE <m>`, `BREAK <m>`, `END_BREAK`, `DISMISS`, `DND <on|off|toggle>`, `STATUS`, `WAYBAR`, and `RESET`.
4. **Layer 4 — Lazy LayerShell Overlay**:
   - `FocusPill.qml` (`AnchorTop | AnchorRight`, 8 px gap below Waybar) and `BreakOverlay.qml`, styled exclusively with `ArchTitan.TitanUI`.
   - Instantiated lazily via `Instantiator` and memory-trimmed via `malloc_trim(0)` when hidden.

---

## Usage

- **Toggle Focus Pill**: `Super + Alt + F` or click the Waybar `custom/focus-ring` pill
- **Right-click Waybar pill**: Snooze nudges for 15 minutes
- **QuickSettings Focus Card**: Toggles TitanFocus Do Not Disturb
- **CLI**:
  ```bash
  titan-focus --toggle
  titan-focus --status
  titan-focus --snooze 15
  titan-focus --break 10
  titan-focus --dnd
  ```

## Configuration

User configuration lives at `~/.config/titan-focus/focus.toml` and hot-reloads live on save.
Daily summary counters persist to `~/.local/state/titan-focus/daily.json`.
