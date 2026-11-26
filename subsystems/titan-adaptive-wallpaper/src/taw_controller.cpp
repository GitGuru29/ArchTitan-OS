#include "taw_controller.hpp"

namespace taw {

TAWController::TAWController(QObject* parent) : QObject(parent) {
    m_engine.load_config();
}

void TAWController::setEnabled(bool v) {
    if (m_engine.is_enabled() != v) {
        m_engine.set_enabled(v);
        emit enabledChanged();
        if (v) {
            sync();
        } else {
            restoreOriginal();
        }
    }
}

void TAWController::setAutoSync(bool v) {
    if (m_engine.is_auto_sync() != v) {
        m_engine.set_auto_sync(v);
        emit autoSyncChanged();
    }
}

void TAWController::setIntensity(qreal v) {
    float clamped = std::clamp(static_cast<float>(v), 0.0f, 1.0f);
    if (std::abs(m_engine.intensity() - clamped) > 0.001f) {
        m_engine.set_intensity(clamped);
        emit intensityChanged();
    }
}

void TAWController::setOriginalWallpaper(const QString& path) {
    std::string s = path.toStdString();
    if (m_engine.original_wallpaper() != s) {
        m_engine.set_original_wallpaper(s);
        emit originalWallpaperChanged();
        if (m_engine.is_enabled() && m_engine.is_auto_sync()) {
            sync();
        }
    }
}

void TAWController::setManualPaletteOverride(const QString& name) {
    std::string s = name.toStdString();
    if (m_engine.manual_palette_override() != s) {
        m_engine.set_manual_palette_override(s);
        emit manualPaletteOverrideChanged();
        if (m_engine.is_enabled()) {
            sync();
        }
    }
}

QStringList TAWController::availablePalettes() const {
    QStringList list;
    list << "Auto (Active Theme)"
         << "Catppuccin Mocha"
         << "Nord"
         << "Tokyo Night"
         << "Dracula"
         << "Gruvbox"
         << "Everforest"
         << "Rosé Pine"
         << "AMOLED";
    return list;
}

void TAWController::sync() {
    m_engine.sync(true);
    emit adaptedWallpaperChanged();
    emit activeThemeIdChanged();
}

void TAWController::restoreOriginal() {
    m_engine.restore_original();
    emit adaptedWallpaperChanged();
}

QString TAWController::previewAdaptation(const QString& imagePath, const QString& paletteName, qreal intensity) {
    std::string path = imagePath.toStdString();
    ThemePalette pal;

    if (paletteName.isEmpty() || paletteName.contains("Auto", Qt::CaseInsensitive)) {
        pal = m_engine.resolve_effective_palette();
    } else {
        std::string lower = paletteName.toLower().replace(" ", "").replace("-", "").toStdString();
        if (lower.find("mocha") != std::string::npos || lower.find("catppuccin") != std::string::npos) pal = ThemePalette::mocha();
        else if (lower.find("nord") != std::string::npos) pal = ThemePalette::nord();
        else if (lower.find("tokyo") != std::string::npos) pal = ThemePalette::tokyonight();
        else if (lower.find("dracula") != std::string::npos) pal = ThemePalette::dracula();
        else if (lower.find("gruvbox") != std::string::npos) pal = ThemePalette::gruvbox();
        else if (lower.find("everforest") != std::string::npos) pal = ThemePalette::everforest();
        else if (lower.find("rose") != std::string::npos) pal = ThemePalette::rosepine();
        else if (lower.find("amoled") != std::string::npos) pal = ThemePalette::amoled();
        else pal = m_engine.resolve_effective_palette();
    }

    std::string res = m_engine.adapt(path, pal, static_cast<float>(intensity));
    QString qres = QString::fromStdString(res);
    emit previewReady(qres);
    return qres;
}

void TAWController::reload() {
    m_engine.load_config();
    emit enabledChanged();
    emit autoSyncChanged();
    emit intensityChanged();
    emit originalWallpaperChanged();
    emit adaptedWallpaperChanged();
    emit activeThemeIdChanged();
    emit manualPaletteOverrideChanged();
}

} // namespace taw

