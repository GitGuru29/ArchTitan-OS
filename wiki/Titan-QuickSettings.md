# Titan Quick Settings & Notification Center (`titan-quicksettings`)

The **ArchTitan Quick Settings & Notification Center** (`titan-quicksettings`) is a native C++/Qt6 Wayland layer-shell subsystem providing a hardware-accelerated, obsidian glassmorphic control drawer. Sliding in smoothly from the right edge of the screen upon pressing **<kbd>Super</kbd> + <kbd>N</kbd>**, it unifies hardware control toggles, system telemetry, and a full desktop notification center into a single cohesive interface.

---

## Visual & Functional Layout

```
┌────────────────────────────────────────────────────────────┐
│ [▲ ArchTitan] Up 42m                    [✎] [↻] [⚙] [⏻]   │  <- Header (/proc/uptime, Settings, Power)
├────────────────────────────────────────────────────────────┤
│  [ (•) Internet         ] [ ᛒ Bluetooth       ] [ ☕ ]     │  <- Primary Toggles (Network, BlueZ, Caffeine)
│       Home_Wi-Fi                Connected                  │
│  [ 🎙 Mute ] [ 🔊 Audio: 75%  ] [ 🌙 Night Light: On ]     │  <- Audio & Display (WirePlumber, Hyprsunset)
│  [ ◐ ]   [ ılı ]   [ ≈ ]   [ ☁🔒 ]   [ 🎮 ]                │  <- Quick Grid (Theme, Visualizer, VPN, Game)
│  [ ⛶ ]   [ 💉 ]   [ ⌨ ]   [ 🔔 ]    [ 🎵 ]                │  <- Quick Grid (Grim, Hyprpicker, DND, MPRIS)
├────────────────────────────────────────────────────────────┤
│ ╭────────────────────────────────────────────────────────╮ │
│ │ (•) Network Management         Just now        [2 ▾]   │ │  <- Grouped Notifications (NetworkManager)
│ │     Wi-Fi Connected         Connected to Home_Wi-Fi    │ │
│ ╰────────────────────────────────────────────────────────╯ │
│ ╭────────────────────────────────────────────────────────╮ │
│ │ [💬] notify-send               10m ago         [1 ▾]   │ │  <- Desktop Notifications Spec
│ │     THM Telemetry           Workload profile: DEV      │ │
│ ╰────────────────────────────────────────────────────────╯ │
├────────────────────────────────────────────────────────────┤
│ [ 🔕 ]                 3 notifications                [ 🗑 ] │  <- DND Toggle, Counter, Clear All
├────────────────────────────────────────────────────────────┤
│ ▲  Wednesday, October 21 • 0 tasks                         │  <- Calendar & Task Bar
└────────────────────────────────────────────────────────────┘
```

---

## Core Capabilities

### 1. Hardware & System Toggles
- **NetworkManager D-Bus (`NetworkController`)**: Real-time wireless connection state, SSID display, signal strength, and Wi-Fi toggle.
- **BlueZ D-Bus (`BluetoothController`)**: Controller power state, connected device identification, and Bluetooth toggle.
- **PipeWire / WirePlumber (`AudioController`)**: Default audio sink and microphone volume monitoring and mute toggling.
- **Night Light (`NightLightController`)**: Controls color temperature warmth via `hyprsunset` / `gammastep`.
- **Caffeine & Game Mode**: Toggles idle inhibition (`hypridle`) and disables compositor animations/blur for high-framerate gaming.

### 2. Grouped Notification Center
- Implements the FreeDesktop Notification Specification (`org.freedesktop.Notifications`).
- Groups notifications hierarchically by application name.
- Badges show collapsed notification counts (`[2 ▾]`, `[441 ▾]`) with expandable inline cards.
- Provides Do Not Disturb (DND) mode and "Clear All" actions.

### 3. Layer-Shell Windowing & Styling
- **Anchoring**: Anchored to the **Right**, **Top**, and **Bottom** screen edges on the primary Wayland output.
- **Glassmorphism**: Catppuccin Mocha obsidian surface (`#E611111B`) with 1px subtle cyan/electric blue border (`#2E89B4FA`) and compositor blur.
- **Click-Away & Focus Dismiss**: Clicking outside the drawer or pressing <kbd>Escape</kbd> immediately hides the panel.

### 4. Single-Instance IPC Daemon
- Launches at login via `titan-quicksettings --daemon`.
- Listens on UNIX domain socket at `$XDG_RUNTIME_DIR/titan-quicksettings.sock`.
- Instantaneous visibility toggle on `Super+N` via `titan-quicksettings --toggle` without process startup overhead.

---

## Keybindings & Triggers

| Trigger | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>N</kbd> | Toggle Quick Settings & Notification Center |
| Waybar Bell Icon | Click to toggle Quick Settings drawer |
| <kbd>Escape</kbd> / Click outside | Dismiss drawer |

---

## Directory & File Locations

- **Source Code**: [`subsystems/titan-quicksettings/`](file:///home/msfvenom/custom-os-build/subsystems/titan-quicksettings)
- **Binary**: `/usr/local/bin/titan-quicksettings`
- **Toggle Helper**: `/usr/local/bin/titan-quicksettings-toggle`
- **Permissions**: `0:0:755` (in `profiledef.sh`)
