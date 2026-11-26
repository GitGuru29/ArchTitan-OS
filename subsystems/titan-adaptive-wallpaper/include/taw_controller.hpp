#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QQmlEngine>
#include "taw_engine.hpp"

namespace taw {

class TAWController : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool autoSync READ autoSync WRITE setAutoSync NOTIFY autoSyncChanged)
    Q_PROPERTY(qreal intensity READ intensity WRITE setIntensity NOTIFY intensityChanged)
    Q_PROPERTY(QString originalWallpaper READ originalWallpaper WRITE setOriginalWallpaper NOTIFY originalWallpaperChanged)
    Q_PROPERTY(QString adaptedWallpaper READ adaptedWallpaper NOTIFY adaptedWallpaperChanged)
    Q_PROPERTY(QString activeThemeId READ activeThemeId NOTIFY activeThemeIdChanged)
    Q_PROPERTY(QString manualPaletteOverride READ manualPaletteOverride WRITE setManualPaletteOverride NOTIFY manualPaletteOverrideChanged)
    Q_PROPERTY(QStringList availablePalettes READ availablePalettes CONSTANT)

public:
    explicit TAWController(QObject* parent = nullptr);

    bool enabled() const { return m_engine.is_enabled(); }
    void setEnabled(bool v);

    bool autoSync() const { return m_engine.is_auto_sync(); }
    void setAutoSync(bool v);

    qreal intensity() const { return m_engine.intensity(); }
    void setIntensity(qreal v);

    QString originalWallpaper() const { return QString::fromStdString(m_engine.original_wallpaper()); }
    void setOriginalWallpaper(const QString& path);

    QString adaptedWallpaper() const { return QString::fromStdString(m_engine.config().last_adapted_wallpaper); }
    QString activeThemeId() const { return QString::fromStdString(m_engine.config().active_theme_id); }

    QString manualPaletteOverride() const { return QString::fromStdString(m_engine.manual_palette_override()); }
    void setManualPaletteOverride(const QString& name);

    QStringList availablePalettes() const;

    Q_INVOKABLE void sync();
    Q_INVOKABLE void restoreOriginal();
    Q_INVOKABLE QString previewAdaptation(const QString& imagePath, const QString& paletteName, qreal intensity);
    Q_INVOKABLE void reload();

signals:
    void enabledChanged();
    void autoSyncChanged();
    void intensityChanged();
    void originalWallpaperChanged();
    void adaptedWallpaperChanged();
    void activeThemeIdChanged();
    void manualPaletteOverrideChanged();
    void previewReady(const QString& previewPath);

private:
    TAWEngine m_engine;
};

} // namespace taw

