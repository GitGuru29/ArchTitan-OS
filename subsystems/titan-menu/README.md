# ArchTitan Central Menu & Command Palette (`titan-menu`)

## Overview
`titan-menu` is a native, hardware-accelerated Wayland layer-shell command palette and system launcher for **ArchTitan OS**. Designed to bring an integrated, keyboard-first, aerospace-grade UX cohesion to the desktop, it unifies application launching, theme switching, screen capture tools, hardware toggles, desktop overlays, system settings, shortcut references, and power controls into a single frosted-glass palette accessible via **<kbd>Super</kbd>**, **<kbd>Super</kbd> + <kbd>Space</kbd>**, or **<kbd>Super</kbd> + <kbd>K</kbd>**.

---

## Key Features

- **Keyboard-First Navigation**:
  - Global fuzzy search across all titles, breadcrumbs, hints, and command names.
  - Arrow navigation (<kbd>↑</kbd>/<kbd>↓</kbd>), Tab (<kbd>Tab</kbd>/<kbd>Shift+Tab</kbd>), and Vim-style navigation (<kbd>Ctrl+N</kbd>/<kbd>Ctrl+J</kbd>, <kbd>Ctrl+P</kbd>/<kbd>Ctrl+K</kbd>).
  - <kbd>Enter</kbd> to launch or drill into subcategories; <kbd>Backspace</kbd> or <kbd>←</kbd> to step back; <kbd>Escape</kbd> to back out or dismiss.
- **Titan Design Language (TDL)**:
  - Catppuccin Mocha base palette with dynamically reactive wallpaper accents via `ArchTitan.TitanUI`.
  - Layer-shell overlay surface with compositor hardware blur (`layerrule = match:namespace titan-menu, blur on`).
  - Subtle drop shadow, rounded Bento card geometry, and micro-animated selection highlight indicators.
- **Hierarchical Menu Architecture**:
  - Defined cleanly in `data/menu.json` and compiled as a binary resource.
  - Dynamic providers (e.g. `@themes` querying `titan-theme list`).
  - Strict conditional gating with `requires`: items and empty categories automatically hide if external executables are absent.
- **Instantaneous Single-Instance Daemon**:
  - Runs in the background (`titan-menu --daemon`) with zero startup latency upon invocation.
  - IPC socket control via `$XDG_RUNTIME_DIR/titan-menu.sock` supporting `--toggle`, `--show`, and `--hide`.
  - Delay-assisted process detachment: closes the layer surface before launching external focus-stealing windows.

---

## Directory Structure

```
subsystems/titan-menu/
├── CMakeLists.txt          # Qt6 + LayerShellQt + QtTest build rules
├── build.sh                # Automated build, test, and airootfs installation script
├── resources.qrc           # QML and JSON data resource bundle
├── README.md               # Subsystem architecture and documentation
├── data/
│   └── menu.json           # Categorized tree of actions, icons, shortcuts, and triggers
├── qml/
│   ├── MenuWindow.qml      # Main LayerShellQt overlay, scrim, search input, and list view
│   └── components/
│       └── MenuRow.qml     # Interactive menu row with icon tile, labels, shortcut pill & chevron
├── src/
│   ├── main.cpp            # Entrypoint, CLI arguments parser, and layer surface geometry
│   ├── ipcserver.h / .cpp  # Single-instance UNIX domain socket IPC listener and client
│   ├── menucontroller.h / .cpp # Selection state, hierarchy navigation, search filtering & action exec
│   ├── menutree.h / .cpp   # JSON tree parser, validation schema, and executable availability checks
│   └── fuzzy.h / .cpp      # Substring scoring and ranking engine
└── tests/
    └── test_menu.cpp       # 27 unit tests covering fuzzy search, JSON schema, and navigation
```

---

## Build & Testing

### Prerequisites
- CMake ≥ 3.16, GCC / Clang with C++20 support
- Qt 6 (Core, Gui, Quick, Qml, Test)
- LayerShellQt

### Compiling and Running Tests
```bash
cd subsystems/titan-menu
./build.sh
```

To run unit tests standalone:
```bash
QT_QPA_PLATFORM=offscreen ./build/titan-menu-tests
```

### Manual Testing with Wayland Session
```bash
# Start daemon with repo's QML plugins
export QML_IMPORT_PATH="$(pwd)/../../airootfs/usr/lib/qt6/qml"
export LD_LIBRARY_PATH="$(pwd)/../../airootfs/usr/lib"
./build/titan-menu --daemon &

# Toggle menu
./build/titan-menu --toggle
```
