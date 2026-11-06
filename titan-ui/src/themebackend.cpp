#include "themebackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

#include <algorithm>
#include <cmath>

namespace {
// Canonical Catppuccin Mocha — mirrors usr/share/archtitan/themes/mocha.json
// and the historical TitanTheme.qml literals, so a missing theme.json is
// byte-for-byte the palette the shell has always shipped.
const QHash<QString, QColor> kMocha = {
    {QStringLiteral("accent"),     QColor("#89B4FA")},
    {QStringLiteral("accent2"),    QColor("#CBA6F7")},
    {QStringLiteral("crust"),      QColor("#11111B")},
    {QStringLiteral("mantle"),     QColor("#181825")},
    {QStringLiteral("base"),       QColor("#1E1E2E")},
    {QStringLiteral("surface0"),   QColor("#313244")},
    {QStringLiteral("surface1"),   QColor("#45475A")},
    {QStringLiteral("surface2"),   QColor("#585B70")},
    {QStringLiteral("surface3"),   QColor("#6C7086")},
    {QStringLiteral("border"),     QColor("#252838")},
    {QStringLiteral("textHigh"),   QColor("#CDD6F4")},
    {QStringLiteral("textMid"),    QColor("#A6ADC8")},
    {QStringLiteral("textLow"),    QColor("#7F849C")},
    {QStringLiteral("success"),    QColor("#A6E3A1")},
    {QStringLiteral("warning"),    QColor("#F9E2AF")},
    {QStringLiteral("danger"),     QColor("#F38BA8")},
    {QStringLiteral("teal"),       QColor("#94E2D5")},
    {QStringLiteral("mauve"),      QColor("#CBA6F7")},
    {QStringLiteral("peach"),      QColor("#FAB387")},
    {QStringLiteral("pink"),       QColor("#F5C2E7")},
};

inline double linearize(double v)
{
    return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4);
}

inline double relativeLuminance(const QColor &c)
{
    return 0.2126 * linearize(c.redF())
         + 0.7152 * linearize(c.greenF())
         + 0.0722 * linearize(c.blueF());
}
} // namespace

ThemeBackend::ThemeBackend(QObject *parent)
    : QObject(parent)
    , m_pal(kMocha)
{
    computeDerivedColors();
    reload();

    const QString path = configPath();
    if (!path.isEmpty()) {
        const QString dir = QFileInfo(path).absolutePath();
        if (QDir().mkpath(dir))
            m_watcher.addPath(path);
        m_watcher.addPath(dir);
    }

    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this] { reload(); });
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, [this] { reload(); });
}

QString ThemeBackend::configPath()
{
    const QString configHome = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    if (configHome.isEmpty())
        return QString();
    return configHome + "/archtitan/theme.json";
}

void ThemeBackend::computeDerivedColors()
{
    const QColor a = accent();
    const QColor c = crust();
    const QColor b = base();
    const QColor m = mantle();
    const QColor s0 = surface0();
    const QColor d = danger();

    m_accentFg = computeAccentFg(a);

    // Derived accents
    m_accentSoft   = QColor(a.red(), a.green(), a.blue(), 46);  // 0.18
    m_accentSofter = QColor(a.red(), a.green(), a.blue(), 26);  // 0.10
    m_accentEdge   = QColor(a.red(), a.green(), a.blue(), 140); // 0.55
    m_accentHover  = lighterColor(a, 1.08);
    m_accentPressed = darkerColor(a, 1.10);

    m_dangerHover   = lighterColor(d, 1.08);
    m_dangerPressed = darkerColor(d, 1.10);

    // Semantic backgrounds
    m_bg0 = c;
    m_bg1 = m_isDark ? QColor(b.red(), b.green(), b.blue(), 179)   // base @ 0.702
                     : QColor(255, 255, 255, 215);                 // frost @ 0.84
    m_bg2 = m_isDark ? QColor(b.red(), b.green(), b.blue(), 153)   // base @ 0.60
                     : QColor(255, 255, 255, 230);                 // card @ 0.90
    m_bg3 = m_isDark ? b : QColor(255, 255, 255, 245);             // 0.96
    m_bg4 = m_isDark ? s0 : QColor(0, 0, 0, 13);                   // 0.05
    m_bgInset = m_isDark ? QColor(c.red(), c.green(), c.blue(), 128) // crust @ 0.502
                         : QColor(0, 0, 0, 15);                     // 0.06

    // Glass & overlays
    m_glass     = m_isDark ? QColor(c.red(), c.green(), c.blue(), 184)   // crust @ 0.722
                           : QColor(255, 255, 255, 215);                 // 0.84
    m_glassAlt  = m_isDark ? QColor(m.red(), m.green(), m.blue(), 112)   // mantle @ 0.439
                           : QColor(255, 255, 255, 192);                 // 0.75
    m_glassCard = m_isDark ? QColor(m.red(), m.green(), m.blue(), 102)   // mantle @ 0.40
                           : QColor(255, 255, 255, 204);                 // 0.80

    // Borders
    m_border       = m_isDark ? color("border") : QColor(0x00, 0x00, 0x00, 0x14);
    m_borderSubtle = m_isDark ? QColor(0xFF, 0xFF, 0xFF, 0x18) : QColor(0x00, 0x00, 0x00, 0x10);
    m_borderHover  = m_isDark ? QColor(0xFF, 0xFF, 0xFF, 0x40) : QColor(0x00, 0x00, 0x00, 0x24);
    m_borderStrong = m_accentEdge;

    // Interaction states
    m_stateHover    = m_isDark ? QColor(0xFF, 0xFF, 0xFF, 20) : QColor(0x00, 0x00, 0x00, 10);
    m_statePressed  = m_isDark ? QColor(0xFF, 0xFF, 0xFF, 31) : QColor(0x00, 0x00, 0x00, 20);
    m_stateSelected = m_accentSoft;
    m_focusRing     = a;
    m_scrim         = QColor(0x00, 0x00, 0x00, 140);
}

void ThemeBackend::reload()
{
    QHash<QString, QColor> pal = kMocha;
    QString id = QStringLiteral("mocha");
    QString name = QStringLiteral("Catppuccin Mocha");
    bool dark = true;
    qreal glassOpacity = 0.35;

    QFile f(configPath());
    if (f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        if (doc.isObject()) {
            const QJsonObject obj = doc.object();
            if (obj.contains("id") && obj.value("id").isString())
                id = obj.value("id").toString();
            if (obj.contains("name") && obj.value("name").isString())
                name = obj.value("name").toString();
            if (obj.contains("isDark"))
                dark = obj.value("isDark").toBool(true);
            if (obj.contains("glassOpacity")) {
                glassOpacity = obj.value("glassOpacity").toDouble(0.35);
                if (glassOpacity < 0.05) glassOpacity = 0.05;
                if (glassOpacity > 1.0) glassOpacity = 1.0;
            }

            // Accent first: an explicit palette accent still wins, but the
            // top-level keys are the ones titan-theme writes.
            for (const QString &key : {QStringLiteral("accent"), QStringLiteral("accent2")}) {
                const QString v = obj.value(key).toString();
                if (QColor::isValidColorName(v))
                    pal.insert(key, QColor(v));
            }
            const QJsonObject palette = obj.value("palette").toObject();
            for (auto it = palette.begin(); it != palette.end(); ++it) {
                const QString v = it.value().toString();
                if (QColor::isValidColorName(v))
                    pal.insert(it.key(), QColor(v));
            }
        }
    }

    if (pal != m_pal || dark != m_isDark || id != m_id || name != m_name || !qFuzzyCompare(glassOpacity, m_glassOpacity)) {
        m_pal = pal;
        m_isDark = dark;
        m_id = id;
        m_name = name;
        m_glassOpacity = glassOpacity;
        computeDerivedColors();
        emit changed();
    }

    // Re-arm the watch (atomic writes replace the inode, dropping the watch).
    const QString path = configPath();
    if (!path.isEmpty() && !m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

QColor ThemeBackend::computeAccentFg(const QColor &accentColor) const
{
    // WCAG relative luminance of the accent, then the crossover where Mocha
    // crust ink (#11111B, L = 0.006) and pure white are equally legible:
    //     (L + .05) / .056  ==  1.05 / (L + .05)   ->   L = 0.1925
    // Above it use dark ink; below it use white.
    const double l = relativeLuminance(accentColor);
    return l > 0.1925 ? QColor("#11111B") : QColor("#FFFFFF");
}

qreal ThemeBackend::contrastRatio(const QColor &fg, const QColor &bg) const
{
    // Composite fg over bg if fg has transparency
    const double a = fg.alphaF();
    const double r = fg.redF() * a + bg.redF() * (1.0 - a);
    const double g = fg.greenF() * a + bg.greenF() * (1.0 - a);
    const double b = fg.blueF() * a + bg.blueF() * (1.0 - a);

    const double l1 = 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
    const double l2 = relativeLuminance(bg);

    const double lighter = std::max(l1, l2);
    const double darker = std::min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
}

QColor ThemeBackend::alphaColor(const QColor &base, qreal a) const
{
    int alphaInt = std::clamp(static_cast<int>(std::lround(a * 255.0)), 0, 255);
    return QColor(base.red(), base.green(), base.blue(), alphaInt);
}

QColor ThemeBackend::lighterColor(const QColor &base, qreal factor) const
{
    return base.lighter(static_cast<int>(std::lround(factor * 100.0)));
}

QColor ThemeBackend::darkerColor(const QColor &base, qreal factor) const
{
    return base.darker(static_cast<int>(std::lround(factor * 100.0)));
}

bool ThemeBackend::isAccessible(const QColor &fg, const QColor &bg, qreal minRatio) const
{
    return contrastRatio(fg, bg) >= minRatio;
}
