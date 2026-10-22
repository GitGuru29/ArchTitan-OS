#pragma once

#include <QColor>
#include <QEasingCurve>
#include <QFile>
#include <QHash>
#include <QJsonDocument>
#include <QJsonObject>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QString>

#include <cmath>

/**
 * TitanPalette — C++ access to the "Titan Design Language" (TDL) tokens.
 *
 * Full mirror of titan-ui/qml/style/TitanTheme.qml so that Qt Widgets apps
 * (titanfetch, titanbrowser, …) share the exact palette of the QML shell.
 * Colours resolve against ~/.config/archtitan/theme.json (written by
 * `titan-theme`) merged over the canonical Catppuccin Mocha fallback, so a
 * theme or wallpaper-accent change recolours the Widgets apps on their next
 * launch — the same source of truth the QML surfaces bind to at runtime.
 *
 * Header-only: add titan-ui/include to the include path,
 *
 *     #include "TitanPalette.h"
 *
 * then use e.g. TitanPalette::textHigh(), TitanPalette::hex(TitanPalette::accent())
 * or TitanPalette::qss(css) for stylesheet token substitution. The token set is
 * kept honest against TitanTheme.qml by scripts/palette-parity.py.
 *
 * The palette is resolved once per process: a Widgets app is a short-lived
 * consumer of the shell theme, not a live client of it (the QML surfaces are).
 */
namespace TitanPalette {
namespace detail {

// ── Canonical fallbacks (mirror of usr/share/archtitan/themes/mocha.json) ──
inline const QHash<QString, QColor> &mocha()
{
    static const QHash<QString, QColor> kMocha = {
        {QStringLiteral("accent"),   QColor(0x89, 0xB4, 0xFA)},
        {QStringLiteral("accent2"),  QColor(0xCB, 0xA6, 0xF7)},
        {QStringLiteral("crust"),    QColor(0x11, 0x11, 0x1B)},
        {QStringLiteral("mantle"),   QColor(0x18, 0x18, 0x25)},
        {QStringLiteral("base"),     QColor(0x1E, 0x1E, 0x2E)},
        {QStringLiteral("surface0"), QColor(0x31, 0x32, 0x44)},
        {QStringLiteral("surface1"), QColor(0x45, 0x47, 0x5A)},
        {QStringLiteral("surface2"), QColor(0x58, 0x5B, 0x70)},
        {QStringLiteral("surface3"), QColor(0x6C, 0x70, 0x86)},
        {QStringLiteral("border"),   QColor(0x25, 0x28, 0x38)},
        {QStringLiteral("textHigh"), QColor(0xCD, 0xD6, 0xF4)},
        {QStringLiteral("textMid"),  QColor(0xA6, 0xAD, 0xC8)},
        {QStringLiteral("textLow"),  QColor(0x7F, 0x84, 0x9C)},
        {QStringLiteral("success"),  QColor(0xA6, 0xE3, 0xA1)},
        {QStringLiteral("warning"),  QColor(0xF9, 0xE2, 0xAF)},
        {QStringLiteral("danger"),   QColor(0xF3, 0x8B, 0xA8)},
        {QStringLiteral("teal"),     QColor(0x94, 0xE2, 0xD5)},
        {QStringLiteral("mauve"),    QColor(0xCB, 0xA6, 0xF7)},
        {QStringLiteral("peach"),    QColor(0xFA, 0xB3, 0x87)},
        {QStringLiteral("pink"),     QColor(0xF5, 0xC2, 0xE7)},
    };
    return kMocha;
}

struct Snapshot {
    QHash<QString, QColor> pal;
    bool dark = true;
    QString id = QStringLiteral("mocha");
    QString name = QStringLiteral("Catppuccin Mocha");
};

// Mirrors ThemeBackend::reload(): the top-level accent/accent2 keys win, then
// the "palette" object is merged over the Mocha fallback.
inline Snapshot load()
{
    Snapshot s;
    s.pal = mocha();

    const QString home = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (home.isEmpty())
        return s;

    QFile f(home + QStringLiteral("/archtitan/theme.json"));
    if (!f.open(QIODevice::ReadOnly))
        return s;

    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return s;

    const QJsonObject obj = doc.object();
    if (obj.value(QStringLiteral("id")).isString())
        s.id = obj.value(QStringLiteral("id")).toString();
    if (obj.value(QStringLiteral("name")).isString())
        s.name = obj.value(QStringLiteral("name")).toString();
    if (obj.contains(QStringLiteral("isDark")))
        s.dark = obj.value(QStringLiteral("isDark")).toBool(true);

    for (const QString &key : {QStringLiteral("accent"), QStringLiteral("accent2")}) {
        const QString v = obj.value(key).toString();
        if (QColor::isValidColorName(v))
            s.pal.insert(key, QColor(v));
    }
    const QJsonObject palette = obj.value(QStringLiteral("palette")).toObject();
    for (auto it = palette.begin(); it != palette.end(); ++it) {
        const QString v = it.value().toString();
        if (QColor::isValidColorName(v))
            s.pal.insert(it.key(), QColor(v));
    }
    return s;
}

inline const Snapshot &snap()
{
    static const Snapshot s = load();
    return s;
}

inline QColor raw(const char *key)
{
    return snap().pal.value(QLatin1String(key));
}

} // namespace detail

// ── Mode / identity ────────────────────────────────────────────────────────
inline bool isDark()       { return detail::snap().dark; }
inline QString id()        { return detail::snap().id; }
inline QString name()      { return detail::snap().name; }

// ── Catppuccin Mocha surfaces ──────────────────────────────────────────────
inline QColor crust()    { return detail::raw("crust"); }
inline QColor mantle()   { return detail::raw("mantle"); }
inline QColor base()     { return detail::raw("base"); }
inline QColor surface0() { return detail::raw("surface0"); }
inline QColor surface1() { return detail::raw("surface1"); }
inline QColor surface2() { return detail::raw("surface2"); }
inline QColor surface3() { return detail::raw("surface3"); }

// ── Semantic background roles (mirror TitanTheme.bg0…bg4 + bgInset) ─────────
inline QColor bg0()     { return crust(); }
inline QColor bg1()     { return isDark() ? QColor(base().red(), base().green(), base().blue(), 179)
                                          : QColor(255, 255, 255, 215); } // base @ 0.702 vs crisp white frost @ 0.84
inline QColor bg2()     { return isDark() ? QColor(base().red(), base().green(), base().blue(), 153)
                                          : QColor(255, 255, 255, 230); } // card @ 0.90
inline QColor bg3()     { return isDark() ? base() : QColor(255, 255, 255, 245); }
inline QColor bg4()     { return isDark() ? surface0() : QColor(0, 0, 0, 13); } // hover / pill @ 0.05
inline QColor bgInset() { return isDark() ? QColor(crust().red(), crust().green(), crust().blue(), 128)
                                          : QColor(0, 0, 0, 15); } // recessed track @ 0.06

// ── Frosted glass / overlay ─────────────────────────────────────────────────
inline QColor glass()     { return isDark() ? QColor(crust().red(), crust().green(), crust().blue(), 184)
                                            : QColor(255, 255, 255, 215); }  // crust @ 0.722 vs 0.84
inline QColor glassAlt()  { return isDark() ? QColor(mantle().red(), mantle().green(), mantle().blue(), 112)
                                            : QColor(255, 255, 255, 192); } // mantle @ 0.439 vs 0.75
inline QColor glassCard() { return isDark() ? QColor(mantle().red(), mantle().green(), mantle().blue(), 102)
                                            : QColor(255, 255, 255, 204); } // mantle @ 0.400 vs 0.80

// ── Borders ────────────────────────────────────────────────────────────────
inline QColor border()       { return isDark() ? detail::raw("border") : QColor(0x00, 0x00, 0x00, 0x14); }
inline QColor borderSubtle() { return isDark() ? QColor(0xFF, 0xFF, 0xFF, 0x18)
                                               : QColor(0x00, 0x00, 0x00, 0x10); }
inline QColor borderHover()  { return isDark() ? QColor(0xFF, 0xFF, 0xFF, 0x40)
                                               : QColor(0x00, 0x00, 0x00, 0x24); }

// ── Text ───────────────────────────────────────────────────────────────────
inline QColor textHigh() { return detail::raw("textHigh"); }
inline QColor textMid()  { return detail::raw("textMid"); }
inline QColor textLow()  { return detail::raw("textLow"); }

// ── Semantic status ────────────────────────────────────────────────────────
inline QColor success() { return detail::raw("success"); }
inline QColor warning() { return detail::raw("warning"); }
inline QColor danger()  { return detail::raw("danger"); }
inline QColor teal()    { return detail::raw("teal"); }
inline QColor peach()   { return detail::raw("peach"); }
inline QColor mauve()   { return detail::raw("mauve"); }
inline QColor pink()    { return detail::raw("pink"); }

// ── Accent (theme / wallpaper-adaptive) ────────────────────────────────────
inline QColor accent()  { return detail::raw("accent"); }
inline QColor accent2() { return detail::raw("accent2"); }

// `info` is derived from the accent unless the theme overrides it, exactly as
// ThemeBackend::info() does.
inline QColor info()
{
    const QColor c = detail::raw("info");
    return c.isValid() ? c : accent();
}

inline QColor accentFg()
{
    // WCAG relative luminance of the accent, then the crossover where Mocha
    // crust ink and pure white are equally legible (L = 0.1925 — derivation in
    // ThemeBackend::accentFg). The old gamma-space `l > 0.6` rule put white
    // text on #89B4FA: 2.1:1 where ink gives 8.9:1.
    const QColor a = accent();
    const auto lin = [](double v) {
        return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4);
    };
    const double l = 0.2126 * lin(a.redF())
                   + 0.7152 * lin(a.greenF())
                   + 0.0722 * lin(a.blueF());
    return l > 0.1925 ? crust() : QColor(0xFF, 0xFF, 0xFF);
}

inline QColor accentSoft()   { const QColor a = accent(); return QColor(a.red(), a.green(), a.blue(), 46); }  // 0.18
inline QColor accentSofter() { const QColor a = accent(); return QColor(a.red(), a.green(), a.blue(), 26); }  // 0.10
inline QColor accentEdge()   { const QColor a = accent(); return QColor(a.red(), a.green(), a.blue(), 140); } // 0.55

inline QColor borderStrong()  { return accentEdge(); }
inline QColor textOnAccent()  { return accentFg(); }

// ── Typography ─────────────────────────────────────────────────────────────
inline QString fontFamily() { return QStringLiteral("Inter"); }
inline QString monoFamily() { return QStringLiteral("JetBrainsMono Nerd Font"); }
inline int sizeDisplay() { return 22; }
inline int sizeTitle()   { return 15; }
inline int sizeBody()    { return 13; }
inline int sizeLabel()   { return 11; }
inline int sizeCaption() { return 9; }
inline int weightRegular()  { return 400; }
inline int weightMedium()   { return 500; }
inline int weightSemiBold() { return 600; }
inline int weightBold()     { return 700; }

// ── Radii (One UI 9.0 squircles) ───────────────────────────────────────────
inline int radiusSm()      { return 8; }
inline int radiusMd()      { return 12; }
inline int radiusLg()      { return 16; }
inline int radiusXl()      { return 20; }
inline int radiusBento()   { return 24; }
inline int radiusWindow()  { return 28; }
inline int radiusCard()    { return 20; }
inline int radiusControl() { return 16; }
inline int radiusSlider()  { return 26; }
inline int radiusPill()    { return 999; }

// ── Spacing (4-point grid) ─────────────────────────────────────────────────
inline int space1() { return 4; }
inline int space2() { return 8; }
inline int space3() { return 12; }
inline int space4() { return 16; }
inline int space6() { return 24; }
inline int space8() { return 32; }

// ── Motion ─────────────────────────────────────────────────────────────────
inline int durFast()    { return 120; }
inline int durBase()    { return 200; }
inline int durSlow()    { return 320; }
inline int durShimmer() { return 1400; }
// QML `Easing.*` shares QEasingCurve::Type's values.
inline int easingStandard() { return QEasingCurve::OutCubic; }
inline int easingEnter()    { return QEasingCurve::OutCubic; }
inline int easingExit()     { return QEasingCurve::InCubic; }
inline int easingEmphasis() { return QEasingCurve::OutQuart; }
inline double pressScale() { return 0.97; }

// ── Helpers ────────────────────────────────────────────────────────────────
inline QString hex(const QColor &c)  { return c.name(QColor::HexRgb); }
inline QString hexa(const QColor &c) { return c.name(QColor::HexArgb); }
inline QColor alpha(const QColor &c, double a) { return QColor(c.red(), c.green(), c.blue(), int(std::lround(a * 255.0))); }

// ── Stylesheet token substitution ──────────────────────────────────────────
// Widgets apps can write QSS against `@token` placeholders instead of literal
// colours; qss() swaps them for the resolved TDL values. `@tokenRGB` expands
// to "r, g, b" for use inside rgba(). Unknown placeholders are left untouched,
// so `@media`-style text (or literal @handles) passes through unharmed.
inline QColor token(const QString &name)
{
    static const QHash<QString, QColor> map = {
        {QStringLiteral("accent"), accent()},
        {QStringLiteral("accent2"), accent2()},
        {QStringLiteral("accentFg"), accentFg()},
        {QStringLiteral("accentSoft"), accentSoft()},
        {QStringLiteral("accentSofter"), accentSofter()},
        {QStringLiteral("accentEdge"), accentEdge()},
        {QStringLiteral("crust"), crust()},
        {QStringLiteral("mantle"), mantle()},
        {QStringLiteral("base"), base()},
        {QStringLiteral("surface0"), surface0()},
        {QStringLiteral("surface1"), surface1()},
        {QStringLiteral("surface2"), surface2()},
        {QStringLiteral("surface3"), surface3()},
        {QStringLiteral("bg0"), bg0()},
        {QStringLiteral("bg1"), bg1()},
        {QStringLiteral("bg2"), bg2()},
        {QStringLiteral("bg3"), bg3()},
        {QStringLiteral("bg4"), bg4()},
        {QStringLiteral("bgInset"), bgInset()},
        {QStringLiteral("glass"), glass()},
        {QStringLiteral("glassAlt"), glassAlt()},
        {QStringLiteral("glassCard"), glassCard()},
        {QStringLiteral("border"), border()},
        {QStringLiteral("borderSubtle"), borderSubtle()},
        {QStringLiteral("borderHover"), borderHover()},
        {QStringLiteral("borderStrong"), borderStrong()},
        {QStringLiteral("textHigh"), textHigh()},
        {QStringLiteral("textMid"), textMid()},
        {QStringLiteral("textLow"), textLow()},
        {QStringLiteral("textOnAccent"), textOnAccent()},
        {QStringLiteral("success"), success()},
        {QStringLiteral("warning"), warning()},
        {QStringLiteral("danger"), danger()},
        {QStringLiteral("info"), info()},
        {QStringLiteral("teal"), teal()},
        {QStringLiteral("peach"), peach()},
        {QStringLiteral("mauve"), mauve()},
        {QStringLiteral("pink"), pink()},
    };
    return map.value(name);
}

inline QString qss(const QString &css)
{
    static const QRegularExpression re(QStringLiteral("@([A-Za-z][A-Za-z0-9_]*)"));
    QString out;
    out.reserve(css.size());

    qsizetype last = 0;
    auto it = re.globalMatch(css);
    while (it.hasNext()) {
        const QRegularExpressionMatch m = it.next();
        const QString name = m.captured(1);

        QString value;
        if (name.endsWith(QStringLiteral("RGB"))) {
            const QColor c = token(name.chopped(3));
            if (c.isValid())
                value = QStringLiteral("%1, %2, %3").arg(c.red()).arg(c.green()).arg(c.blue());
        } else {
            const QColor c = token(name);
            if (c.isValid())
                value = c.alpha() == 255 ? hex(c) : hexa(c);
        }

        if (value.isEmpty())
            continue; // leave the unknown placeholder in place

        out += css.mid(last, m.capturedStart() - last);
        out += value;
        last = m.capturedEnd();
    }
    out += css.mid(last);
    return out;
}

} // namespace TitanPalette
