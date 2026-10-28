#include "wallpapermanager.h"
#include <QProcess>
#include <QDir>
#include <QStandardPaths>
#include <QImage>
#include <QColor>
#include <QFile>

WallpaperManager::WallpaperManager(QObject *parent) : QObject(parent) {
    // Try to read current wallpaper from archtitan config file or swww fallback
    QProcess p;
    p.start("bash", {"-c", "sed -n '1p' ~/.config/archtitan/wallpaper 2>/dev/null || cat ~/.config/swww/current 2>/dev/null || echo ''"});
    p.waitForFinished(500);
    m_currentWallpaper = p.readAllStandardOutput().trimmed();
    calculateBrightness();
    scanWallpapers();
}

QString WallpaperManager::currentWallpaper() const { return m_currentWallpaper; }
void WallpaperManager::setCurrentWallpaper(const QString &path) {
    if (path.isEmpty()) return;
    if (m_currentWallpaper == path) return;
    m_currentWallpaper = path;
    calculateBrightness();
    // Apply with titan-set-wallpaper helper script (swaybg + persistence)
    QString bin = QStandardPaths::findExecutable("titan-set-wallpaper");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-set-wallpaper");
    QProcess::startDetached(bin, {path});
    emit currentWallpaperChanged();
    emit isDarkChanged();
}

bool WallpaperManager::isDark() const { return m_isDark; }

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

void WallpaperManager::openFilePicker() {
    // kdialog or zenity portal
    QProcess p;
    p.start("bash", {"-c", "kdialog --getopenfilename ~ 'Images (*.png *.jpg *.jpeg *.webp)' 2>/dev/null || zenity --file-selection --file-filter='Images | *.png *.jpg *.jpeg *.webp' 2>/dev/null"});
    p.waitForFinished(60000);
    QString chosen = p.readAllStandardOutput().trimmed();
    if (!chosen.isEmpty() && QFile::exists(chosen)) {
        setCurrentWallpaper(chosen);
    }
}

void WallpaperManager::launchPicker() {
    QString bin = QStandardPaths::findExecutable("titan-wallpaper-picker");
    if (bin.isEmpty()) bin = QStringLiteral("/usr/local/bin/titan-wallpaper-picker");
    QProcess::startDetached(bin, {});
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
    scanWallpapers();
}
