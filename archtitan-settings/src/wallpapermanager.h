#pragma once
#include <QObject>
#include <QStringList>

class WallpaperManager : public QObject {
    Q_OBJECT

    Q_PROPERTY(QString currentWallpaper READ currentWallpaper WRITE setCurrentWallpaper NOTIFY currentWallpaperChanged)
    Q_PROPERTY(QString originalWallpaper READ originalWallpaper NOTIFY originalWallpaperChanged)
    Q_PROPERTY(QStringList wallpaperList READ wallpaperList NOTIFY wallpaperListChanged)
    Q_PROPERTY(bool isDark READ isDark NOTIFY isDarkChanged)

    // Titan Adaptive Wallpaper (TAW) properties
    Q_PROPERTY(bool adaptiveEnabled READ adaptiveEnabled WRITE setAdaptiveEnabled NOTIFY adaptiveEnabledChanged)
    Q_PROPERTY(bool adaptiveAutoSync READ adaptiveAutoSync WRITE setAdaptiveAutoSync NOTIFY adaptiveAutoSyncChanged)
    Q_PROPERTY(qreal adaptiveIntensity READ adaptiveIntensity WRITE setAdaptiveIntensity NOTIFY adaptiveIntensityChanged)
    Q_PROPERTY(QString adaptivePalette READ adaptivePalette WRITE setAdaptivePalette NOTIFY adaptivePaletteChanged)
    Q_PROPERTY(QStringList paletteList READ paletteList CONSTANT)

public:
    explicit WallpaperManager(QObject *parent = nullptr);

    QString currentWallpaper() const;
    void setCurrentWallpaper(const QString &path);
    QString originalWallpaper() const;
    QStringList wallpaperList() const;
    bool isDark() const;

    bool adaptiveEnabled() const;
    void setAdaptiveEnabled(bool enabled);

    bool adaptiveAutoSync() const;
    void setAdaptiveAutoSync(bool autoSync);

    qreal adaptiveIntensity() const;
    void setAdaptiveIntensity(qreal intensity);

    QString adaptivePalette() const;
    void setAdaptivePalette(const QString &palette);

    QStringList paletteList() const;

    Q_INVOKABLE void scanWallpapers();
    Q_INVOKABLE void launchPicker();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void syncAdaptive();
    Q_INVOKABLE void restoreOriginal();
    Q_INVOKABLE QString previewAdaptive(const QString &path, const QString &palette, qreal intensity);

signals:
    void currentWallpaperChanged();
    void originalWallpaperChanged();
    void wallpaperListChanged();
    void isDarkChanged();
    void adaptiveEnabledChanged();
    void adaptiveAutoSyncChanged();
    void adaptiveIntensityChanged();
    void adaptivePaletteChanged();

private:
    QString m_currentWallpaper;
    QString m_originalWallpaper;
    QStringList m_wallpaperList;
    bool m_isDark = true;

    bool m_adaptiveEnabled = true;
    bool m_adaptiveAutoSync = true;
    qreal m_adaptiveIntensity = 0.70;
    QString m_adaptivePalette = "Auto (Active Theme)";

    void calculateBrightness();
    void loadAdaptiveConfig();
    void saveAdaptiveConfig();
};
