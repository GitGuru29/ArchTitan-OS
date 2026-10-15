# titan-hotzones

Pointer **hot-zone** daemon (plus its on-screen display) for ArchTitan OS. When
the cursor dwells in one of seven screen zones, a configured command fires. It is
the interaction layer described in the ArchTitan premium-UI plan (Layer B,
part 1).

Two binaries are built:

- **`titan-hotzones`** — the daemon that tracks the pointer and fires actions.
- **`titan-zone-osd`** — a full-screen, input-transparent LayerShell overlay that
  shows which zone is activating and a ring that fills over the dwell window.

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

Corner zones are square (`corner_size`). Edge-midpoint zones are
`edge_thickness` x `edge_length`, centred on the edge. The top-centre zone is
excluded by design because it can never be reached over Waybar.

## Activation

```
 IDLE --pointer enters zone--> ARMED --dwell_ms elapsed--> FIRE
   ^                              |                          |
   |  pointer leaves before dwell  |                       LOCKED
   +------------------------------+                          |
   +-- pointer leaves exclusion box (then cooldown_ms) -------+
```

- **Dwell** prevents accidental triggers while crossing a corner at speed.
- **Exclusion box** (the "paper trail" rule) fires once per touch; the pointer
  must travel `exclusion_box` px inward to re-arm.
- **Cooldown** stops rapid re-fire during deliberate oscillation.
- **Inhibition** skips firing while a fullscreen window is focused or the
  focused window's class matches `ignore_classes`.

## Building

```sh
./build.sh          # builds and installs both binaries into airootfs/usr/local/bin
```

Requires Qt6 (Core, Gui, Quick, Qml, Network), LayerShellQt and CMake. The built
binaries are committed to `airootfs/usr/local/bin/` (matching
`titan-quicksettings`).

## Testing

```sh
titan-hotzones --check          # print effective configuration
titan-hotzones --zones          # probe monitors + cursor, report the current hit
titan-hotzones --zones --at x,y # test an arbitrary point as "x,y"
titan-hotzones --verbose        # run verbosely in the foreground
```

`--verbose` is long-only (`-v` is reserved by the version option).

`TITAN_HOTZONES_CONFIG=/path/to/hotzones.toml` overrides the config search path.

## Configuration

Loaded from the first existing path:

1. `$TITAN_HOTZONES_CONFIG`
2. `/etc/archtitan/hotzones.toml`
3. `$XDG_CONFIG_HOME/archtitan/hotzones.toml`

See `configs/hotzones.toml` for the schema. Missing keys fall back to defaults.

## Notes on Hyprland IPC

Hyprland emits no pointer-move events, so the daemon polls the compositor's
UNIX command socket directly (no `hyprctl` process spawn per tick). That socket
accepts exactly one request per connection, so each poll opens a short-lived
socket. Polling runs at ~30 Hz while the pointer is near a zone and backs off to
~5 Hz elsewhere.

The daemon also subscribes to Hyprland's **event socket** (`.socket2.sock`) to
learn when a workspace or special workspace changes. There is no per-gesture
progress event, so the resulting change is what drives touchpad-gesture feedback
on the OSD (see below). The event socket is reconnected automatically if
Hyprland restarts.

## Zone OSD (`titan-zone-osd`)

The daemon hosts a `QLocalServer` at `$XDG_RUNTIME_DIR/titan-hotzones.sock` and
broadcasts newline-delimited JSON to every connected client. Two message shapes
are emitted:

```json
{"cmd":"show","kind":"zone","zone":"top_left","progress":0.42,"screen":"eDP-1"}
{"cmd":"show","kind":"workspace","label":"Workspace 2","icon":"2","screen":""}
{"cmd":"hide"}
```

- `kind:"zone"` (default) — a hot zone is arming/armed; the OSD shows the dwell
  ring next to that zone.
- `kind:"workspace"` — a workspace or scratchpad changed (typically after a
  trackpad gesture). The OSD shows a centred pill with `label`/`icon`; the
  daemon clears it after 1.2 s. Because Hyprland's native gesture engine emits
  no gesture-progress IPC, this change-driven notice is the gesture OSD.

The OSD connects as a client and retries every 1.5 s, so daemon/OSD start order
does not matter. For zones, a frame is re-sent only when the zone changes or the
ring advances ≥ 2 %, so parking inside a zone does not flood the socket.

`titan-zone-osd` is a single **full-screen** LayerShell surface
(`LayerOverlay`, `exclusive_zone = -1`, keyboard-interactive none) that the
compositor keeps mapped across the output. The pill is positioned inside the
surface in QML rather than by re-anchoring the layer, because Hyprland does not
reposition a layer surface after it has been mapped. The surface is
input-transparent, so it never steals focus or clicks.

## Gestures

Gestures use Hyprland's native trackpad engine — no third-party plugin. As of
**Hyprland 0.55** the Lua config (`hyprland.lua`) supersedes `hyprland.conf`
entirely, so the gesture definitions live there:

| Gesture | Action |
| --- | --- |
| 3-finger left / right | workspace prev / next (native 1:1 slide) |
| 3-finger down | close active window |
| 3-finger up | overview/search (rofi — no native Expo without a plugin) |
| 4-finger up | toggle scratchpad (`special:magic`) |
| 4-finger down | show desktop (`special:showdesktop`) |

The `.conf` fallback carries the equivalent hyprlang `gesture = ...` lines for
pre-0.55 builds and is ignored on 0.56+.

