#include "themebackend.h"

#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace {
const QColor kFallbackAccent("#89B4FA"); // Catppuccin Mocha blue
}

ThemeBackend::ThemeBackend(QObject *parent)
    : QObject(parent)
    , m_accent(kFallbackAccent)
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
    QColor next = kFallbackAccent;
    bool dark = true;

    QFile f(configPath());
    if (f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        if (doc.isObject()) {
            const QJsonObject obj = doc.object();
            const QString accentStr = obj.value("accent").toString();
            if (QColor::isValidColorName(accentStr))
                next = QColor(accentStr);
            if (obj.contains("isDark"))
                dark = obj.value("isDark").toBool(true);
        }
    }

    if (next != m_accent || dark != m_isDark) {
        m_accent = next;
        m_isDark = dark;
        emit changed();
    }

    // Re-arm the watch (atomic writes replace the inode, dropping the watch).
    const QString path = configPath();
    if (!path.isEmpty() && !m_watcher.files().contains(path))
        m_watcher.addPath(path);
}

QColor ThemeBackend::accentFg() const
{
    // Perceptual luminance: dark ink on light accents, white on dark accents.
    const double l = 0.2126 * m_accent.redF() + 0.7152 * m_accent.greenF() + 0.0722 * m_accent.blueF();
    return l > 0.6 ? QColor("#11111B") : QColor("#FFFFFF");
}
