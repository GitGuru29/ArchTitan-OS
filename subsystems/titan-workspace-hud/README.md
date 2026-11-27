# Titan Workspace HUD (`titan-workspace-hud`)

**ArchTitan OS — Interactive Mission Control Workspace Grid & Window Relocator**

## Overview
`titan-workspace-hud` is a native C++20 / Qt6 QML Wayland overlay subsystem that provides the ArchTitan equivalent of the host shell's **Super+Tab** workspace overview: a 2×5 matrix of live workspaces and window thumbnails with drag-to-relocate, positioned beneath the Waybar HUD. It replaces the legacy Python HUD with instant, zero-cold-start native performance.

## Design Philosophy
> **"Visual clarity at the speed of thought."**

- **Single Chord:** <kbd>Super</kbd>+<kbd>Tab</kbd> toggles the 2×5 overview; no bare-Super binding is needed.
- **Instant Toggle:** Opening and closing the matrix is handled over a local UNIX socket, with zero cold-start cost.
- **Direct Focus:** Clicking a workspace or window tile switches focus and dismisses the overlay immediately.

## Features
- **2×5 Workspace Matrix:** Scaled 1264×320px frosted glass container with 236×136px workspace cards matching Titan Design Language (TDL).
- **Proportional Mini Window Tiles:** Accurately renders active windows per workspace with document scanline textures and centered application icons (`image://icon/<class>`).
- **Drag-and-Drop Window Relocation:** Grab any mini window tile and drag it into another workspace card to dispatch immediate Hyprland `movetoworkspacesilent`.
- **Interactive Window Management:** Directly close windows from inside the HUD with the mini tile `✕` button, or click any tile to focus and switch.
- **Direct Shortcut Badging:** Each card displays its direct navigation shortcut pill (<kbd>󰘳 1</kbd> .. <kbd>󰘳 0</kbd>).
- **Density Badging:** Busy workspaces ($\ge 3$ windows) display clean count badges (`N wins`).
- **Empty Workspaces:** Graceful empty states with large 52px bold centered numerals.
- **Host-style Focus Ring:** An accent outline slides between cells to mark the active workspace, matching the host overview.
- **Liquid Glass:** Frosted sheet, specular sheen, themed cards and tiles follow the Settings `glassmorphism` toggle live.
- **Direct Hyprland IPC:** Bypasses shell execution overhead by querying `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket.sock` directly in C++.
- **LayerShellQt Integration:** Native Wayland overlay anchoring to `AnchorTop` with margin 110px.

## Architecture
```
Qt6 Quick / QML (WindowTile, WorkspaceCard, WorkspaceGrid)
                         │
HyprlandController (C++) ┴ IpcServer (UNIX Socket Server)
          │                                  │
Direct Hyprland Socket             $XDG_RUNTIME_DIR/titan-workspace-hud.sock
(.socket.sock: j/monitors, j/clients)         (HOLD, RELEASE, SHOW, HIDE)
```

## Build & Install
```bash
./build.sh
```
The binary compiles with GCC 16 / CMake and installs directly to `airootfs/usr/local/bin/titan-workspace-hud`.
