#include "themebackend.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

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
} // namespace

ThemeBackend::ThemeBackend(QObject *parent)
    : QObject(parent)
    , m_pal(kMocha)
{
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

void ThemeBackend::reload()
{
    QHash<QString, QColor> pal = kMocha;
    QString id = QStringLiteral("mocha");
    QString name = QStringLiteral("Catppuccin Mocha");
    bool dark = true;

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

    if (pal != m_pal || dark != m_isDark || id != m_id || name != m_name) {
        m_pal = pal;
        m_isDark = dark;
        m_id = id;
        m_name = name;
        emit changed();
    }

    // Re-arm the watch (atomic writes replace the inode, dropping the watch).
    const QString path = configPath();
    if (!path.isEmpty() && !m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

QColor ThemeBackend::accentFg() const
{
    // WCAG relative luminance of the accent, then the crossover where Mocha
    // crust ink (#11111B, L = 0.006) and pure white are equally legible:
    //     (L + .05) / .056  ==  1.05 / (L + .05)   ->   L = 0.1925
    // Above it (light accents — every default except Latte) use dark ink;
    // below it use white. The old gamma-space threshold (l > 0.6) put white
    // text on #89B4FA: a 2.1:1 ratio where ink gives 8.9:1.
    const auto lin = [](double v) {
        return v <= 0.04045 ? v / 12.92 : std::pow((v + 0.055) / 1.055, 2.4);
    };
    const double l = 0.2126 * lin(m_pal.value("accent").redF())
                  + 0.7152 * lin(m_pal.value("accent").greenF())
                  + 0.0722 * lin(m_pal.value("accent").blueF());
    return l > 0.1925 ? QColor("#11111B") : QColor("#FFFFFF");
}
