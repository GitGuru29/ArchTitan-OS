# ArchTitan.TitanUI — Titan Design Language (TDL)

The shared design system for **every** ArchTitan surface. It exists so the whole
OS — Hyprland shell configs, QML apps and Qt Widgets apps — speaks one visual
language: a **Catppuccin Mocha** base with **Samsung One UI 9.0** geometry and a
**wallpaper-adaptive accent**.

> **Rule #1:** never hardcode a colour. Use a `TitanTheme` token (QML) or a
> `TitanPalette` value (C++). The `scripts/colour-lint.py` check enforces this.

---

## 1. Using it

### QML

```qml
import ArchTitan.TitanUI

Rectangle {
    color: TitanTheme.bg2                 // translucent card
    radius: TitanTheme.radiusCard
    border.color: TitanTheme.borderSubtle
    Text {
        text: "Hello"
        color: TitanTheme.textHigh
        font.family: TitanTheme.fontFamily
        font.pixelSize: TitanTheme.sizeBody
        font.weight: TitanTheme.weightSemiBold
    }
}
```

### C++ (Qt Widgets apps: titanfetch, titanbrowser)

```cpp
#include "TitanPalette.h"   // installed at /usr/include/archtitan

QString qss = QStringLiteral("background:%1;color:%2;")
                  .arg(TitanPalette::hex(TitanPalette::base()),
                       TitanPalette::hex(TitanPalette::textHigh()));
```

`TitanPalette.h` is a header-only mirror of `TitanTheme.qml` so Widgets apps
share the exact same palette. `accent()`/`accentFg()` read
`~/.config/archtitan/theme.json` (falling back to Catppuccin blue `#89B4FA`).

---

## 2. Tokens (`TitanTheme` singleton)

| Group | Tokens |
| :-- | :-- |
| **Accent** (adaptive) | `accent`, `accentFg`, `accentSoft`, `accentSofter`, `accentEdge` |
| **Surfaces** | `crust` `mantle` `base` `surface0`…`surface3` |
| **Roles** | `bg0` deepest · `bg1` window · `bg2` card · `bg3` elevated · `bg4` hover · `bgInset` |
| **Glass** | `glass`, `glassAlt`, `glassCard` |
| **Borders** | `border`, `borderSubtle`, `borderHover`, `borderStrong` |
| **Text** | `textHigh`, `textMid`, `textLow`, `textOnAccent` |
| **Status** | `success`, `warning`, `danger`, `info`, `teal`, `peach`, `mauve`, `pink` |
| **Type** | `fontFamily` (Inter), `monoFamily` (JetBrainsMono Nerd Font), `sizeDisplay…sizeCaption`, `weightRegular…weightBold` |
| **Radii** | `radiusSm`…`radiusWindow`, `radiusCard`, `radiusControl`, `radiusSlider`, `radiusPill` |
| **Spacing** | `space1`…`space8` (4‑point grid) |
| **Motion** | `durFast` `durBase` `durSlow` `durShimmer`, `easingStandard` `easingEnter` `easingExit` `easingEmphasis`, `pressScale` |

Colour literals use **`#AARRGGBB`** (alpha first) in QML/QSS, but
**`#RRGGBBAA`** (alpha last) in GTK CSS and rofi `.rasi` files. The lint/remap
scripts branch on file type accordingly.

---

## 3. Components

| Component | Purpose |
| :-- | :-- |
| `TitanButton` | Primary/secondary/ghost/danger button (press-scale feedback) |
| `TitanCard` | Bento card container with optional title/subtitle |
| `TitanGlassPanel` | Frosted overlay surface |
| `TitanSwitch` / `TitanSlider` / `TitanProgress` | Form & value controls |
| `TitanToggleTile` | One UI quick-toggle squircle tile |
| `TitanPill` / `TitanBadge` | Status chips |
| `TitanSidebarItem` | Settings navigation row |
| `TitanIcon` | Nerd Font glyph **or** image at a fixed size |
| `TitanDivider` | Hairline separator |
| `TitanSpinner` | Indeterminate circular loader |
| `TitanSkeleton` | Shimmering placeholder block |
| `TitanEmptyState` | "Nothing here yet" placeholder (+ optional action) |
| `TitanErrorState` | Failure placeholder (+ retry action) |
| `TitanGallery` / `TitanGalleryBody` | Interactive preview of every component |

Preview the whole set:

```bash
cd titan-ui && ./build.sh
QML_IMPORT_PATH=build/qml ./build/titan-ui-gallery
```

---

## 4. Icon & font policy

- **System UI glyphs** → Nerd Font codepoints rendered with
  `font.family: TitanTheme.monoFamily`. Prefer the `TitanIcon` component.
- **Prose** → `TitanTheme.fontFamily` (Inter).
- **Brand/app/file icons** → SVG/PNG assets (`TitanIcon.source`, `:/icons/*.svg`).
- Don't mix glyph fonts. If a component renders a glyph it must use `monoFamily`.

---

## 5. Consistency tooling

All checks are pure-stdlib Python and run in CI
(`.github/workflows/ui-consistency.yml`):

```bash
python3 scripts/colour-lint.py      # every colour literal is a TDL token/value
python3 scripts/config-drift.py     # etc/skel ≡ root, live variant documented
python3 scripts/contrast-audit.py   # WCAG 2.1 contrast for token pairings
```

- **Allowlist** genuine data/artwork in `scripts/colour-allow.txt`. For a few
  deliberate lines inside an otherwise-conforming file, append an inline
  `// tdl-allow` comment on the line instead.
- `scripts/colour-remap.py` snaps off-palette literals to the nearest token
  (one-off migration helper; alpha-preserving, file-type aware).

Rendered screenshots (visual review / regression baselines):

```bash
scripts/screenshots.sh              # writes screenshots/*.png (offscreen, no GPU)
```

---

## 6. Building

```bash
./build.sh    # builds the module and installs into ../airootfs
```

Installs to `airootfs/usr/lib/qt6/qml/ArchTitan/TitanUI/` (QML module),
`airootfs/usr/lib/libTitanUI.so`, and `airootfs/usr/include/archtitan/`
(C++ palette header).
