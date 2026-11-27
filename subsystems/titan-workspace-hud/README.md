# Titan Overview (`titan-workspace-hud`)

**ArchTitan OS — host-style "Toggle overview" workspace switcher**

## Overview
`titan-workspace-hud` is a native C++20 / Qt6 QML Wayland overlay that implements the ArchTitan equivalent of the host shell's **Super+Tab → Shell: Toggle overview** action. It renders a full-screen, dimmed overview with a centred liquid-glass sheet, a 2×5 workspace matrix, live window tiles, search, and drag-to-relocate — with zero cold-start cost.

## Design Philosophy
> **"Visual clarity at the speed of thought."**

- **Single Chord:** <kbd>Super</kbd>+<kbd>Tab</kbd> toggles the overview; no bare-Super binding is needed.
- **Instant Toggle:** `titan-workspace-hud --toggle-overview` (aliases: `--toggle`, `--overview`) is handled over a local UNIX socket.
- **Direct Focus:** Click a workspace or window tile to focus and dismiss the overview. Number keys <kbd>1</kbd>–<kbd>0</kbd> jump directly; <kbd>Esc</kbd> or clicking the scrim closes it.

## Features
- **Full-screen Overview:** All four LayerShell anchors, a dimmed scrim, and a centred glass sheet sized to the available desktop instead of a fixed 1264×320 panel.
- **2×5 Adaptive Workspace Matrix:** Cell size is derived from the current screen, so the overview scales correctly on any monitor.
- **Live Window Tiles:** Window rectangles are normalised in C++ and scaled in QML, preserving each window's position and size inside its workspace.
- **Search:** Filter the overview by window title, class, or workspace number, matching the host overview's search field.
- **Drag-and-Drop Relocation:** Drag any tile into another workspace card to dispatch Hyprland `movetoworkspacesilent`.
- **Window Controls:** Close windows from the tile's `✕` button or click a tile to focus it.
- **Host-style Focus Ring:** An accent outline slides between cells to mark the active workspace.
- **Liquid Glass:** Frosted sheet, travelling specular highlight, bright refraction lips and translucent cards/tiles. The scrim lightens so Hyprland's backdrop blur shows through. Every surface follows the Settings → Appearance → Glassmorphism toggle live; disabled mode uses solid theme surfaces.
- **Direct Hyprland IPC:** Queries `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock` directly in C++.

## Architecture
```
QML (Overview window, WorkspaceGrid, WorkspaceCard, WindowTile)
                         │
HyprlandController (C++) ┴ IpcServer (UNIX socket)
          │                                  │
Direct Hyprland socket             $XDG_RUNTIME_DIR/titan-workspace-hud.sock
```

## Build & Install
```bash
./build.sh
```
The binary compiles with GCC 16 / CMake and installs to `airootfs/usr/local/bin/titan-workspace-hud`.
