# ArchTitan Power & Session Menu (`titan-powermenu`)

`titan-powermenu` is the native C++20 / Qt6 / LayerShellQt session and power management overlay for ArchTitan OS. It provides an obsidian glass HUD for locking the session, suspending to RAM, logging out of Hyprland, rebooting, and shutting down.

## Features
- **Wayland Native**: Utilizes `LayerShellQt` overlay layer for composited blur, smooth spring animations, and instant keyboard interactivity.
- **IPC Architecture**: Prewarmable background daemon listening on `$XDG_RUNTIME_DIR/titan-powermenu.sock` for sub-millisecond invocation.
- **Glass Bento Cards**: 5 themed glass cards (Lock, Suspend, Log Out, Restart, Shut Down) with specular hover glow and Catppuccin Mocha accent coloring.
- **System Telemetry Badge**: Displays real-time user `@` hostname, uptime, and battery percentage with charging indicators.
- **Full Keyboard Navigation**:
  - <kbd>L</kbd>: Lock session (`hyprlock`)
  - <kbd>S</kbd>: Suspend system to RAM (`systemctl suspend`)
  - <kbd>E</kbd> / <kbd>U</kbd>: Log out of Hyprland (`hyprctl dispatch exit`)
  - <kbd>R</kbd>: Reboot system (`systemctl reboot`)
  - <kbd>P</kbd> / <kbd>X</kbd>: Shut down device (`systemctl poweroff`)
  - <kbd>Left</kbd> / <kbd>Right</kbd>: Cycle card selection
  - <kbd>Enter</kbd> / <kbd>Space</kbd>: Execute selected action
  - <kbd>Esc</kbd>: Cancel / Dismiss

## CLI Usage
```bash
titan-powermenu             # Show power menu (or dispatch IPC to running daemon)
titan-powermenu --toggle    # Toggle power menu on/off
titan-powermenu --daemon    # Run in background daemon mode
titan-powermenu --lock      # Directly lock session
titan-powermenu --suspend   # Directly suspend
titan-powermenu --logout    # Directly logout
titan-powermenu --reboot    # Directly reboot
titan-powermenu --shutdown  # Directly power off
```

## Build & Install
```bash
./build.sh
```
Binary installs to `/usr/local/bin/titan-powermenu` and `/usr/bin/titan-powermenu`.
