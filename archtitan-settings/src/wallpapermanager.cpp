#include "wallpapermanager.h"
#include <QProcess>
#include <QDir>
#include <QStandardPaths>
#include <QImage>
#include <QColor>
#include <QFile>
#include <QSaveFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <algorithm>

WallpaperManager::WallpaperManager(QObject *parent) : QObject(parent) {
    loadAdaptiveConfig();

    // Try to read current wallpaper from archtitan config file or swww fallback
    QProcess p;
    p.start("bash", {"-c", "sed -n '1p' ~/.config/archtitan/wallpaper 2>/dev/null || cat ~/.config/swww/current 2>/dev/null || echo ''"});
    p.waitForFinished(500);
    m_currentWallpaper = p.readAllStandardOutput().trimmed();

    if (m_originalWallpaper.isEmpty()) {
        m_originalWallpaper = m_currentWallpaper;
    }

    calculateBrightness();
    scanWallpapers();
}

QString WallpaperManager::currentWallpaper() const { return m_currentWallpaper; }
QString WallpaperManager::originalWallpaper() const { return m_originalWallpaper; }

void WallpaperManager::setCurrentWallpaper(const QString &path) {
    if (path.isEmpty()) return;

    m_originalWallpaper = path;
    emit originalWallpaperChanged();

    if (m_adaptiveEnabled) {
        // Update adaptive config original wallpaper
        saveAdaptiveConfig();
        // Invoke adaptive sync
        syncAdaptive();
    } else {
        if (m_currentWallpaper == path) return;
        m_currentWallpaper = path;
        calculateBrightness();

        QString bin = QStandardPaths::findExecutable("titan-set-wallpaper");
        if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-set-wallpaper");
        QProcess::startDetached(bin, {path});

        emit currentWallpaperChanged();
        emit isDarkChanged();
    }
}

bool WallpaperManager::isDark() const { return m_isDark; }

bool WallpaperManager::adaptiveEnabled() const { return m_adaptiveEnabled; }
void WallpaperManager::setAdaptiveEnabled(bool enabled) {
    if (m_adaptiveEnabled != enabled) {
        m_adaptiveEnabled = enabled;
        saveAdaptiveConfig();
        emit adaptiveEnabledChanged();
        if (enabled) {
            syncAdaptive();
        } else {
            restoreOriginal();
        }
    }
}

bool WallpaperManager::adaptiveAutoSync() const { return m_adaptiveAutoSync; }
void WallpaperManager::setAdaptiveAutoSync(bool autoSync) {
    if (m_adaptiveAutoSync != autoSync) {
        m_adaptiveAutoSync = autoSync;
        saveAdaptiveConfig();
        emit adaptiveAutoSyncChanged();
    }
}

qreal WallpaperManager::adaptiveIntensity() const { return m_adaptiveIntensity; }
void WallpaperManager::setAdaptiveIntensity(qreal intensity) {
    qreal clamped = std::clamp(intensity, 0.0, 1.0);
    if (std::abs(m_adaptiveIntensity - clamped) > 0.001) {
        m_adaptiveIntensity = clamped;
        saveAdaptiveConfig();
        emit adaptiveIntensityChanged();
    }
}

QString WallpaperManager::adaptivePalette() const { return m_adaptivePalette; }
void WallpaperManager::setAdaptivePalette(const QString &palette) {
    if (m_adaptivePalette != palette) {
        m_adaptivePalette = palette;
        saveAdaptiveConfig();
        emit adaptivePaletteChanged();
        if (m_adaptiveEnabled) {
            syncAdaptive();
        }
    }
}

QStringList WallpaperManager::paletteList() const {
    return {
        "Auto (Active Theme)",
        "Catppuccin Mocha",
        "Nord",
        "Tokyo Night",
        "Dracula",
        "Gruvbox",
        "Everforest",
        "Rosé Pine",
        "AMOLED"
    };
}

void WallpaperManager::calculateBrightness() {
    if (m_currentWallpaper.isEmpty() || !QFile::exists(m_currentWallpaper)) {
        m_isDark = true;
        return;
    }
    QImage img(m_currentWallpaper);
    if (img.isNull()) {
        m_isDark = true;
        return;
    }
    QImage scaled = img.scaled(1, 1, Qt::IgnoreAspectRatio, Qt::FastTransformation);
    QColor avgColor = scaled.pixelColor(0, 0);
    double luminance = 0.299 * avgColor.red() + 0.587 * avgColor.green() + 0.114 * avgColor.blue();
    m_isDark = luminance < 128.0;
}

QStringList WallpaperManager::wallpaperList() const { return m_wallpaperList; }

void WallpaperManager::scanWallpapers() {
    m_wallpaperList.clear();
    QStringList searchDirs = {
        "/usr/share/backgrounds/archtitan",
        QDir::currentPath() + "/airootfs/usr/share/backgrounds/archtitan",
        "/usr/share/wallpapers",
        QDir::homePath() + "/.local/share/backgrounds",
        QDir::homePath() + "/Pictures/Wallpapers",
        QDir::homePath() + "/Pictures"
    };

    QStringList exts = {"*.jpg","*.jpeg","*.png","*.webp"};
    for (const QString &dir : searchDirs) {
        QDir d(dir);
        if (!d.exists()) continue;
        for (const QString &f : d.entryList(exts, QDir::Files)) {
            const QString fullPath = d.absoluteFilePath(f);
            if (!m_wallpaperList.contains(fullPath))
                m_wallpaperList.append(fullPath);
        }
    }
    emit wallpaperListChanged();
}

void WallpaperManager::launchPicker() {
    QString bin = QStandardPaths::findExecutable("titan-wallpaper-picker");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-wallpaper-picker");
    QProcess::startDetached(bin, {});
}

void WallpaperManager::syncAdaptive() {
    QString bin = QStandardPaths::findExecutable("titan-adaptive-wallpaper");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-adaptive-wallpaper");
    if (!QFile::exists(bin)) {
        bin = QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/local/bin/titan-adaptive-wallpaper");
    }

    QProcess p;
    p.start(bin, {"sync", "--force"});
    // A cold palette transform can take >10s. Killing it mid-apply was a
    // direct cause of missing/blank wallpapers.
    p.waitForFinished(30000);
    refresh();
}

void WallpaperManager::restoreOriginal() {
    QString bin = QStandardPaths::findExecutable("titan-adaptive-wallpaper");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-adaptive-wallpaper");
    if (!QFile::exists(bin)) {
        bin = QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/local/bin/titan-adaptive-wallpaper");
    }

    QProcess p;
    p.start(bin, {"restore"});
    p.waitForFinished(10000);
    refresh();
}

QString WallpaperManager::previewAdaptive(const QString &path, const QString &palette, qreal intensity) {
    if (path.isEmpty()) return QString();

    QString bin = QStandardPaths::findExecutable("titan-adaptive-wallpaper");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-adaptive-wallpaper");
    if (!QFile::exists(bin)) {
        bin = QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/local/bin/titan-adaptive-wallpaper");
    }

    QString palArg = palette;
    if (palArg.contains("Auto", Qt::CaseInsensitive)) {
        palArg = "";
    } else {
        palArg = palArg.toLower().remove(" ").remove("-");
        if (palArg.contains("rose")) palArg = "rosepine";
        if (palArg.contains("tokyo")) palArg = "tokyonight";
    }

    QStringList args = {"transform", path, "--intensity", QString::number(intensity, 'f', 2)};
    if (!palArg.isEmpty()) {
        args << "--theme" << palArg;
    }

    QProcess p;
    p.start(bin, args);
    p.waitForFinished(30000);
    return QString::fromUtf8(p.readAllStandardOutput()).trimmed();
}

void WallpaperManager::loadAdaptiveConfig() {
    QString configPath = QDir::homePath() + "/.config/archtitan/adaptive-wallpaper.json";
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) return;

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();
    if (obj.contains("enabled")) m_adaptiveEnabled = obj["enabled"].toBool();
    if (obj.contains("autoSync")) m_adaptiveAutoSync = obj["autoSync"].toBool();
    if (obj.contains("intensity")) m_adaptiveIntensity = obj["intensity"].toDouble();
    if (obj.contains("originalWallpaper")) m_originalWallpaper = obj["originalWallpaper"].toString();
    if (obj.contains("manualPaletteOverride")) {
        QString p = obj["manualPaletteOverride"].toString();
        m_adaptivePalette = p.isEmpty() ? "Auto (Active Theme)" : p;
    }
}

void WallpaperManager::saveAdaptiveConfig() {
    QString configPath = QDir::homePath() + "/.config/archtitan/adaptive-wallpaper.json";
    QDir().mkpath(QFileInfo(configPath).dir().path());

    // Preserve engine-owned fields (lastAdaptedWallpaper / activeThemeId).
    // Dropping them on every slider change forced TAW to re-apply the
    // wallpaper repeatedly and made rapid palette changes churn swaybg.
    QJsonObject obj;
    QFile existing(configPath);
    if (existing.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QJsonDocument oldDoc = QJsonDocument::fromJson(existing.readAll());
        if (oldDoc.isObject()) obj = oldDoc.object();
    }

    obj["enabled"] = m_adaptiveEnabled;
    obj["autoSync"] = m_adaptiveAutoSync;
    obj["intensity"] = m_adaptiveIntensity;
    obj["originalWallpaper"] = m_originalWallpaper;
    obj["manualPaletteOverride"] = (m_adaptivePalette == "Auto (Active Theme)") ? "" : m_adaptivePalette;

    // Atomic replace: the TAW daemon watches this file and must never see a
    // half-written JSON document.
    QSaveFile file(configPath);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
        file.commit();
    }
}

void WallpaperManager::refresh() {
    QProcess p;
    p.start("bash", {"-c", "sed -n '1p' ~/.config/archtitan/wallpaper 2>/dev/null || echo ''"});
    p.waitForFinished(500);
    QString wp = p.readAllStandardOutput().trimmed();
    if (!wp.isEmpty() && wp != m_currentWallpaper) {
        m_currentWallpaper = wp;
        calculateBrightness();
        emit currentWallpaperChanged();
        emit isDarkChanged();
    }
    loadAdaptiveConfig();
    emit adaptiveEnabledChanged();
    emit adaptiveAutoSyncChanged();
    emit adaptiveIntensityChanged();
    emit adaptivePaletteChanged();
    scanWallpapers();
}
