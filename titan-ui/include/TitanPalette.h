#pragma once

#include <QColor>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>
#include <QString>

/**
 * TitanPalette — C++ access to the ArchTitan "Titan Design Language" tokens.
 *
 * Mirrors qml/style/TitanTheme.qml (Catppuccin Mocha base + wallpaper-adaptive
 * accent) so that Qt Widgets applications share the exact same palette as the
 * QML surfaces. Header-only: add titan-ui/include to your include path and
 *
 *     #include "TitanPalette.h"
 *
 * then use e.g. TitanPalette::textHigh() or TitanPalette::hex(TitanPalette::accent()).
 */
namespace TitanPalette {

// ── Catppuccin Mocha surfaces ──────────────────────────────────────────────
inline QColor crust()    { return QColor(0x11, 0x11, 0x1B); }
inline QColor mantle()   { return QColor(0x18, 0x18, 0x25); }
inline QColor base()     { return QColor(0x1E, 0x1E, 0x2E); }
inline QColor surface0() { return QColor(0x31, 0x32, 0x44); }
inline QColor surface1() { return QColor(0x45, 0x47, 0x5A); }
inline QColor surface2() { return QColor(0x58, 0x5B, 0x70); }
inline QColor surface3() { return QColor(0x6C, 0x70, 0x86); }

// Semantic background roles (match TitanTheme.bg0..bg4)
inline QColor bg0() { return crust(); }
inline QColor bg1() { return base(); }
inline QColor bg2() { return base(); }
inline QColor bg3() { return base(); }
inline QColor bg4() { return surface0(); }

// ── Borders ─────────────────────────────────────────────────────────────────
inline QColor border()       { return QColor(0x25, 0x28, 0x38); }
inline QColor borderSubtle() { return QColor(0xFF, 0xFF, 0xFF, 0x18); }

// ── Text ────────────────────────────────────────────────────────────────────
inline QColor textHigh() { return QColor(0xCD, 0xD6, 0xF4); }
inline QColor textMid()  { return QColor(0xA6, 0xAD, 0xC8); }
inline QColor textLow()  { return QColor(0x7F, 0x84, 0x9C); }

// ── Semantic status ─────────────────────────────────────────────────────────
inline QColor success() { return QColor(0xA6, 0xE3, 0xA1); }
inline QColor warning() { return QColor(0xF9, 0xE2, 0xAF); }
inline QColor danger()  { return QColor(0xF3, 0x8B, 0xA8); }
inline QColor info()    { return QColor(0x89, 0xB4, 0xFA); }
inline QColor teal()    { return QColor(0x94, 0xE2, 0xD5); }
inline QColor peach()   { return QColor(0xFA, 0xB3, 0x87); }
inline QColor mauve()   { return QColor(0xCB, 0xA6, 0xF7); }
inline QColor pink()    { return QColor(0xF5, 0xC2, 0xE7); }

// ── Wallpaper-adaptive accent (mirrors ThemeBackend) ────────────────────────
inline QColor accent()
{
    const QColor fallback = info(); // Catppuccin Mocha blue
    const QString configHome =
        QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (configHome.isEmpty())
        return fallback;

    QFile f(configHome + QStringLiteral("/archtitan/theme.json"));
    if (!f.open(QIODevice::ReadOnly))
        return fallback;

    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return fallback;

    const QString s = doc.object().value(QStringLiteral("accent")).toString();
    return QColor::isValidColorName(s) ? QColor(s) : fallback;
}

inline QColor accentFg()
{
    const QColor a = accent();
    const double l = 0.2126 * a.redF() + 0.7152 * a.greenF() + 0.0722 * a.blueF();
    return l > 0.6 ? crust() : QColor(0xFF, 0xFF, 0xFF);
}

// ── Helpers ─────────────────────────────────────────────────────────────────
inline QString hex(const QColor &c)  { return c.name(QColor::HexRgb); }   // "#rrggbb"
inline QString hexa(const QColor &c) { return c.name(QColor::HexArgb); }  // "#aarrggbb"
inline QColor  alpha(const QColor &c, double a) { QColor r = c; r.setAlphaF(a); return r; }

} // namespace TitanPalette
