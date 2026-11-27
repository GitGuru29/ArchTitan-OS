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
    QStringList list{QStringLiteral("Auto (Active Theme)")};

    for (const std::string& preset : ThemePalette::available_presets()) {
        const QString id = QString::fromStdString(preset);
        if (id == QLatin1String("mocha")) list << QStringLiteral("Catppuccin Mocha");
        else if (id == QLatin1String("latte")) list << QStringLiteral("Catppuccin Latte");
        else if (id == QLatin1String("tokyonight")) list << QStringLiteral("Tokyo Night");
        else if (id == QLatin1String("rosepine")) list << QStringLiteral("Rosé Pine");
        else if (id == QLatin1String("amoled")) list << QStringLiteral("AMOLED");
        else {
            QString pretty = id;
            if (!pretty.isEmpty()) pretty[0] = pretty[0].toUpper();
            list << pretty;
        }
    }

    list.removeDuplicates();
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
        const std::string requested = paletteName.toStdString();
        auto preset = ThemePalette::from_preset(requested);
        if (preset.has_value()) {
            pal = *preset;
        } else {
            auto from_file = ThemePalette::from_json_file(requested);
            pal = from_file.value_or(m_engine.resolve_effective_palette());
        }
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

