# TitanBrowser

A minimal, fast, and ArchTitan-branded web browser built on Qt6 WebEngine.

## Features
- 🌑 Dark glassmorphism UI — matches the ArchTitan desktop theme
- 📑 Multi-tab browsing (Ctrl+T / Ctrl+W)
- 🔍 Smart address bar — URL detection, autocomplete from history/bookmarks, and search aliases (`gh`, `yt`, `wiki`, `g`, `ddg`, `b`, `bing`). Google is the default engine; DuckDuckGo, Brave, Bing, Kagi, Ecosia and Yahoo are supported.
- ⌨️ Keyboard shortcuts: `Ctrl+L` focus bar, `Ctrl+R` reload, `Alt+←/→` navigate — press `Ctrl+/` for the full in-app cheat sheet (`F11` fullscreen, `Ctrl+\` toggle toolbar, `Ctrl+K` command palette, `Ctrl+Shift+K` AI panel)
- 🎨 2px animated progress accent line
- 🖥️ Wayland-native via Qt6 Ozone/EGL

## Build

```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(nproc)
sudo cmake --install .
```

## Dependencies
- `qt6-webengine`
- `qt6-base`
- `qt6-declarative`
- `qt6-webchannel`

All available in the Arch repos and already pulled by the ArchTitan ISO.

## Why not Chromium / Firefox?
Chromium installs at ~389 MB. TitanBrowser reuses `qt6-webengine` (already a shared dep)
and its own binary compiles to ~2–3 MB, saving significant ISO space while keeping
the same Blink rendering engine under the hood.
