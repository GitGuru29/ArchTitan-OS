# Titan Hotzones & Zone OSD

**Titan Hotzones** (`titan-hotzones`) is an intelligent pointer dwell-gesture daemon and Wayland LayerShell on-screen display (`titan-zone-osd`) designed for ArchTitan OS. It allows users to trigger system menus, monitor panels, and workspace actions simply by resting their mouse cursor at screen edges or corners.

---

## Architecture Overview

```mermaid
graph TD
    subgraph Pointer["Pointer Input & Compositor"]
        HYPR[Hyprland Compositor]
        SOCK_CMD["Hyprland Command Socket (/tmp/hypr/.../.socket.sock)"]
        SOCK_EVT["Hyprland Event Socket (.../.socket2.sock)"]
    end

    subgraph HotzonesDaemon["titan-hotzones Daemon"]
        POLL[Adaptive Socket Poller (5Hz - 30Hz)]
        FSM[Zone Dwell Finite State Machine]
        CONF[/etc/archtitan/hotzones.toml]
        IPC_SRV[QLocalServer: $XDG_RUNTIME_DIR/titan-hotzones.sock]
    end

    subgraph OSD["Visual Feedback Overlay"]
        ZONE_OSD[titan-zone-osd LayerShell Process]
        RING[Arc Progress Indicator & Zone Pills]
    end

    subgraph Actions["Dispatched Commands"]
        SYSMON[titan-sysmon --toggle]
        MENU[titan-menu --toggle]
        QUICK[titan-quicksettings --toggle]
        WS[Workspace Switchers]
    end

    HYPR --- SOCK_CMD
    HYPR --- SOCK_EVT
    SOCK_CMD --> POLL
    SOCK_EVT --> FSM
    CONF --> FSM
    POLL --> FSM
    FSM -->|Broadcast JSON| IPC_SRV
    IPC_SRV --> ZONE_OSD
    ZONE_OSD --> RING
    FSM -->|Dwell Elapsed| Actions
```

The subsystem consists of two lightweight C++/Qt6 binaries:

1. **`titan-hotzones`** — The background daemon that samples cursor positions, enforces dwell timings, tracks exclusion boxes, and dispatches configured shell commands.
2. **`titan-zone-osd`** — A full-screen, click-through (`LayerShellQt`) Wayland overlay that provides real-time visual feedback: an expanding ring that fills over the dwell period and zone pills.

---

## 7 Screen Dwell Zones

Hotzones divides the monitor perimeter into 7 precision trigger zones:

```
                       TOP EDGE
        +--[TL]-----(top-centre: omitted)-----[TR]--+
        |     corner   (Waybar occupies)    corner   |
  [LC]  ( )                                        ( )  [RC]
  left  |                                          |  right
 centre |                                          | centre
        +--[BL]--------[bottom-centre]--------[BR]--+
                     BOTTOM EDGE
```

| Zone Identifier | Location | Default Geometry | Default Action |
| :--- | :--- | :--- | :--- |
| **`top_left` (`TL`)** | Top-Left Corner | `32x32 px` square | Open **Titan Menu** (`titan-menu --toggle`) |
| **`top_right` (`TR`)** | Top-Right Corner | `32x32 px` square | Open **Titan Quick Settings** (`titan-quicksettings --toggle`) |
| **`left_centre` (`LC`)** | Left Edge Midpoint | `8x160 px` vertical pill | Toggle **Titan System Monitor** (`titan-sysmon --toggle`) |
| **`right_centre` (`RC`)** | Right Edge Midpoint | `8x160 px` vertical pill | Open **Spotlight / Media HUD** (`titan-media-hud --toggle`) |
| **`bottom_left` (`BL`)** | Bottom-Left Corner | `32x32 px` square | Switch to Workspace 1 |
| **`bottom_centre` (`BC`)**| Bottom Edge Midpoint | `160x8 px` horizontal pill| Toggle **Titan Workspace HUD** (`titan-workspace-hud --toggle`) |
| **`bottom_right` (`BR`)**| Bottom-Right Corner| `32x32 px` square | Toggle Scratchpad / Special Workspace |

> [!NOTE]
> The **top-centre** zone is deliberately omitted from the hotzone schema because Waybar occupies the top screen edge.

---

## Activation State Machine & Hysteresis

To prevent false triggers when moving the mouse across the screen at normal working speeds, `titan-hotzones` enforces a strict 4-stage state machine:

```
 IDLE --pointer enters zone--> ARMED --dwell_ms elapsed--> FIRE
   ^                              |                          |
   |  pointer leaves before dwell  |                       LOCKED
   +------------------------------+                          |
   +-- pointer leaves exclusion box (then cooldown_ms) -------+
```

1. **Idle**: The cursor is elsewhere on the desktop. Polling runs at low power (~5 Hz).
2. **Armed**: The cursor enters a hotzone bounding box. Polling accelerates to 30 Hz. The dwell timer starts (default: `250 ms`), and the daemon signals `titan-zone-osd` to begin drawing the filling arc ring.
3. **Fire**: If the cursor remains in the zone for the full `dwell_ms` duration, the configured action is executed via `fork`/`exec`.
4. **Locked & Exclusion Box**: Once fired, the zone locks. To re-arm, the cursor must travel inwards past the **exclusion box** (e.g., 60 px into the screen). This "paper trail" rule guarantees that resting the mouse at the screen edge fires an action exactly once, without rapid re-triggering.
5. **Cooldown**: After leaving the exclusion box, an optional `cooldown_ms` (default: `300 ms`) prevents accidental double triggers.

---

## Hyprland IPC Architecture

Because Wayland compositors do not expose global pointer coordinates to unprivileged clients, `titan-hotzones` interfaces directly with Hyprland's UNIX sockets:

- **Command Socket (`.socket.sock`)**: Polled via raw UNIX socket connections with `j/cursorpos` queries to fetch live `(x, y)` coordinates without spawning `hyprctl` child processes.
- **Event Socket (`.socket2.sock`)**: Subscribes to compositor events (`workspace>>`, `activespecial>>`, `focusedmon>>`) to automatically adapt when monitors are plugged/unplugged or when fullscreen windows request inhibition.
- **Inhibition Awareness**: If a fullscreen window is active (`fullscreen = true`) or the focused window matches `ignore_classes` (e.g. games, VMs, video players), hotzones automatically suspend.

---

## Configuration (`hotzones.toml`)

The configuration is read from:
1. `$TITAN_HOTZONES_CONFIG` (if exported)
2. `/etc/archtitan/hotzones.toml` (system default)
3. `~/.config/archtitan/hotzones.toml` (user override)

### Sample Configuration

```toml
[general]
dwell_ms = 250
cooldown_ms = 350
exclusion_box = 60
corner_size = 32
edge_thickness = 8
edge_length = 160
ignore_classes = ["steam_app_.*", "gamescope", "qemu-system-.*"]

[zones.top_left]
enabled = true
command = "titan-menu --toggle"
label = "ArchTitan Menu"

[zones.left_centre]
enabled = true
command = "titan-sysmon --toggle"
label = "System Monitor"

[zones.top_right]
enabled = true
command = "titan-quicksettings --toggle"
label = "Quick Settings"

[zones.bottom_centre]
enabled = true
command = "titan-workspace-hud --toggle"
label = "Workspaces"
```

---

## Testing & Diagnostic Commands

The `titan-hotzones` binary includes built-in diagnostic and probe flags:

```bash
# Print active configuration and calculated bounding boxes
titan-hotzones --check

# Probe connected monitors and report current cursor coordinates & active zone hit
titan-hotzones --zones

# Test whether an arbitrary (x, y) coordinate falls within a zone
titan-hotzones --zones --at 0,540

# Run daemon verbosely in foreground (shows socket events, dwell progress, and state transitions)
titan-hotzones --verbose
```
