# ArchTitan Spotlight (`titan-spotlight`)

**macOS-style High Performance Native Spotlight Search & Launcher for ArchTitan OS**

## Overview
`titan-spotlight` is a native C++20 / Qt6 LayerShellQt subsystem providing a hardware-accelerated, keyboard-first Spotlight search modal for **ArchTitan OS**. Inspired by macOS Spotlight and Raycast, it replaces `rofi` with instant 0ms zero-overhead invocation directly bound to the single tap of the **<kbd>Super</kbd>** key.

---

## Key Features

1. **Native macOS Spotlight Experience**:
   - Centered obsidian frosted glass card with Catppuccin Mocha palette and dynamic wallpaper-adaptive luminance.
   - Smooth LayerShellQt overlay surface with compositor hardware blur (`layerrule = blur, titan-spotlight`).
   - Open animation: subtle scale and spring curve.
   - Instant search with live results as you type.

2. **Instant Mathematical Evaluation (Mac Spotlight Calculator)**:
   - Type math expressions (`42 * 10`, `sqrt(144)`, `2^8`, `15% of 80`, `sin(45)`, etc.) and get immediate results.
   - Press <kbd>Enter</kbd> to copy the formatted answer directly to your clipboard via `wl-copy`.

3. **Applications & XDG Desktop Indexer**:
   - Parses system and user `.desktop` applications from `/usr/share/applications`, `/usr/local/share/applications`, and `~/.local/share/applications`.
   - Fuzzy prefix and substring ranking.
   - Renders native vector and raster desktop application icons.
   - Launches apps sandboxed through `titan-exec-hook` to preserve ArchTitan security policies and Titan Hardware Manager (THM) profiles.

4. **Terminal Commands & Shell Runner**:
   - Type `> <command>` to run commands in Kitty terminal with interactive pause on completion.

5. **Quick System Actions**:
   - Direct access to Lock Screen, Sleep/Suspend, Restart, Power Off, ArchTitan Settings, Area Screenshot, Task Manager (btop), File Manager (ranger), and Audio Mixer (pavucontrol).

6. **Clipboard Integration (`--clipboard`)**:
   - Pre-filtered clipboard history via `cliphist`.
   - Bound to **<kbd>Super</kbd> + <kbd>V</kbd>**.

7. **Zero-Latency Daemon Architecture**:
   - Runs in background (`titan-spotlight --daemon`).
   - Single-instance UNIX socket IPC (`$XDG_RUNTIME_DIR/titan-spotlight.sock`) responds to `--toggle`, `--show`, `--hide`, `--clipboard`.

---

## Build & Install
```bash
./build.sh
```
Compiles with GCC / CMake and installs directly to `airootfs/usr/local/bin/titan-spotlight`.
