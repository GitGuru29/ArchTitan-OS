# Titan Menu (`titan-menu`)

The **ArchTitan Central Menu & Command Palette** (`titan-menu`) is a hardware-accelerated Wayland layer-shell application providing an integrated, keyboard-first desktop hub for ArchTitan OS. It brings unified, Omarchy-level UX cohesion across application launching, wallpaper management, system toggles, desktop HUD overlays, system settings, and interactive keyboard shortcut references.

Triggered via **<kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Space</kbd>** or **<kbd>Super</kbd> + <kbd>K</kbd>**.

---

## Visual Architecture & UI

- **Layer-Shell Surface**: Centered floating frosted-glass card rendered in the upper third of the display.
- **Titan Design Language (TDL)**: Uses Catppuccin Mocha surface tokens (`mantle`, `base`, `surface0`) with dynamically adaptive wallpaper accents via `ArchTitan.TitanUI`.
- **Compositor Hardware Blur**: Enhanced with dual-cavity blur via Hyprland layer rules (`match:namespace titan-menu, blur on`).
- **Interactive Scrim**: Translucent backdrop catching click-away events to dismiss smoothly.

```
┌─────────────────────────────────────────────────────────────┐
│ 🔍 Search everything, or pick a category...                 │
├─────────────────────────────────────────────────────────────┤
│ [ ▦ ] Apps                   Launch an app    [Super+Space] │
│ [ 🗔 ] Windows                Switch open windows            │
│ [ 🎨 ] Theme                  Theme engine & cycling     [>] │
│ [ 🖼 ] Wallpaper              Pick a background     [Super+\]│
│ [ 📷 ] Capture                Screenshots & colors       [>] │
│ [ ⚙ ] Toggles                Night light, game mode     [>] │
│ [ 🎛 ] Panels                 Quick settings, sysmon     [>] │
│ [ 🔧 ] Settings               System, audio, network     [>] │
│ [ ⌨ ] Shortcuts              Keyboard cheat sheet       [>] │
│ [ ⏻ ] System                 Lock, sleep, update, power [>] │
├─────────────────────────────────────────────────────────────┤
│ ↑↓ navigate    ↵ select    ← back    esc close              │
└─────────────────────────────────────────────────────────────┘
```

---

## Core Capabilities

### 1. Global Ranked Fuzzy Search
- Real-time scoring and ranking across item titles, hints, categories, and command targets.
- Exact and prefix matches are prioritized.
- Drill-down items display full breadcrumb paths (e.g. `Capture › Region to clipboard`).

### 2. Category Hierarchy & Extensibility
Defined cleanly in `data/menu.json` and compiled directly into the binary:
- **Apps**: Dispatches Rofi Application Search.
- **Windows**: Dispatches interactive window switcher.
- **Theme**: Integrates dynamically with `titan-theme` via the `@themes` provider, providing instant theme previews, selection, and Next/Prev/Random cycling.
- **Wallpaper**: Launches `titan-wallpaper-picker`.
- **Capture**: Quick screenshot triggers (region to clipboard, region to file, full-screen to file), color picker, and clipboard history.
- **Toggles**: Night light (hyprsunset), Caffeine (hypridle), Game mode (compositor effects toggle), and power profile cycling.
- **Panels**: Toggles Quick Settings, Media Island HUD, and System Monitor.
- **Settings**: Direct access to ArchTitan Settings, Pavucontrol Audio Mixer, and NetworkManager TUI.
- **Shortcuts**: Interactive in-palette keyboard cheat sheet where selecting any keybind immediately launches the corresponding application or executes the action.
- **System**: Screen lock, sleep, reboot/power off, Hyprland reload, and terminal system updates (`sudo pacman -Syu`).

### 3. Conditional Gating (`requires`)
Items requiring specific external binaries (such as `titan-theme`, `cliphist`, `hyprpicker`, `pavucontrol`) declare a `"requires"` attribute. If the binary is absent from PATH, the item—and any group that becomes empty as a result—is automatically hidden without breaking layout or search.

### 4. Zero-Latency Daemon & IPC
`titan-menu` autostarts at session boot (`titan-menu --daemon`). It listens on a UNIX domain socket at `$XDG_RUNTIME_DIR/titan-menu.sock`:
- `--toggle`: Toggles visibility instantaneously.
- `--show`: Displays and focuses search input.
- `--hide`: Dismisses smoothly.

---

## Keybindings & Navigation

| Key | Action |
| :--- | :--- |
| <kbd>Super</kbd> + <kbd>Alt</kbd> + <kbd>Space</kbd> | Toggle Central Menu & Command Palette |
| <kbd>Super</kbd> + <kbd>K</kbd> | Toggle Menu / Shortcuts Reference |
| <kbd>↑</kbd> / <kbd>↓</kbd> or <kbd>Ctrl+P</kbd> / <kbd>Ctrl+N</kbd> | Move row selection |
| <kbd>Tab</kbd> / <kbd>Shift+Tab</kbd> | Cycle forward / backward |
| <kbd>Return</kbd> / <kbd>Enter</kbd> | Activate item or drill down into subcategory |
| <kbd>Backspace</kbd> / <kbd>←</kbd> | Step back from subcategory when search field is empty |
| <kbd>Escape</kbd> | Step back or dismiss menu |
| Click outside card | Dismiss menu |

---

## Source & Build

- **Source Code**: [`subsystems/titan-menu/`](file:///home/msfvenom/custom-os-build/subsystems/titan-menu)
- **Binary Location**: `/usr/local/bin/titan-menu`
- **Permissions**: `0:0:755` (configured in `profiledef.sh`)
- **Unit Tests**: 27 unit tests (`test_menu.cpp`) validating fuzzy ranking, JSON parsing, navigation stack, and dynamic provider handling.
