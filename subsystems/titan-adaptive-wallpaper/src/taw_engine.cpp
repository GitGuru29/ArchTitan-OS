#include "taw_engine.hpp"
#include "wallpaper_loader.hpp"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QStandardPaths>
#include <iostream>
#include <cstdlib>

namespace taw {

TAWEngine::TAWEngine(const std::string& config_file) {
    if (!config_file.empty()) {
        m_config_path = config_file;
    } else {
        const char* xdg_config = std::getenv("XDG_CONFIG_HOME");
        if (xdg_config && *xdg_config) {
            m_config_path = std::string(xdg_config) + "/archtitan/adaptive-wallpaper.json";
        } else {
            const char* home = std::getenv("HOME");
            m_config_path = std::string(home ? home : "/tmp") + "/.config/archtitan/adaptive-wallpaper.json";
        }
    }

    ensure_config_path();
    load_config();
}

void TAWEngine::ensure_config_path() {
    QFileInfo fi(QString::fromStdString(m_config_path));
    QDir dir = fi.dir();
    if (!dir.exists()) {
        dir.mkpath(".");
    }
}

void TAWEngine::load_config() {
    QFile file(QString::fromStdString(m_config_path));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        // Fallback: deduce current wallpaper from ~/.config/archtitan/wallpaper
        const char* home = std::getenv("HOME");
        if (home) {
            std::string wp_file = std::string(home) + "/.config/archtitan/wallpaper";
            QFile wpf(QString::fromStdString(wp_file));
            if (wpf.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&wpf);
                QString line = in.readLine().trimmed();
                if (!line.isEmpty()) {
                    m_config.original_wallpaper = line.toStdString();
                }
            }
        }
        return;
    }

    QByteArray data = file.readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    if (!doc.isObject()) return;

    QJsonObject obj = doc.object();
    if (obj.contains("enabled") && obj["enabled"].isBool())
        m_config.enabled = obj["enabled"].toBool();
    if (obj.contains("autoSync") && obj["autoSync"].isBool())
        m_config.auto_sync = obj["autoSync"].toBool();
    if (obj.contains("intensity") && obj["intensity"].isDouble())
        m_config.intensity = static_cast<float>(obj["intensity"].toDouble());
    if (obj.contains("originalWallpaper") && obj["originalWallpaper"].isString())
        m_config.original_wallpaper = obj["originalWallpaper"].toString().toStdString();
    if (obj.contains("activeThemeId") && obj["activeThemeId"].isString())
        m_config.active_theme_id = obj["activeThemeId"].toString().toStdString();
    if (obj.contains("manualPaletteOverride") && obj["manualPaletteOverride"].isString())
        m_config.manual_palette_override = obj["manualPaletteOverride"].toString().toStdString();
    if (obj.contains("lastAdaptedWallpaper") && obj["lastAdaptedWallpaper"].isString())
        m_config.last_adapted_wallpaper = obj["lastAdaptedWallpaper"].toString().toStdString();
}

void TAWEngine::save_config() const {
    QJsonObject obj;
    obj["enabled"] = m_config.enabled;
    obj["autoSync"] = m_config.auto_sync;
    obj["intensity"] = static_cast<double>(m_config.intensity);
    obj["originalWallpaper"] = QString::fromStdString(m_config.original_wallpaper);
    obj["activeThemeId"] = QString::fromStdString(m_config.active_theme_id);
    obj["manualPaletteOverride"] = QString::fromStdString(m_config.manual_palette_override);
    obj["lastAdaptedWallpaper"] = QString::fromStdString(m_config.last_adapted_wallpaper);

    QJsonDocument doc(obj);
    QFile file(QString::fromStdString(m_config_path));
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        file.write(doc.toJson(QJsonDocument::Indented));
    }
}

void TAWEngine::update_config(const TAWConfig& cfg) {
    m_config = cfg;
    save_config();
}

void TAWEngine::set_enabled(bool enabled) {
    m_config.enabled = enabled;
    save_config();
}

void TAWEngine::set_auto_sync(bool auto_sync) {
    m_config.auto_sync = auto_sync;
    save_config();
}

void TAWEngine::set_intensity(float intensity) {
    m_config.intensity = std::clamp(intensity, 0.0f, 1.0f);
    save_config();
}

void TAWEngine::set_original_wallpaper(const std::string& path) {
    m_config.original_wallpaper = path;
    save_config();
}

void TAWEngine::set_manual_palette_override(const std::string& name) {
    m_config.manual_palette_override = name;
    save_config();
}

ThemePalette TAWEngine::resolve_effective_palette() const {
    if (!m_config.manual_palette_override.empty()) {
        auto opt = ThemePalette::from_preset(m_config.manual_palette_override);
        if (opt.has_value()) return *opt;

        // Try as json file path
        auto opt_file = ThemePalette::from_json_file(m_config.manual_palette_override);
        if (opt_file.has_value()) return *opt_file;
    }

    return ThemePalette::active_system_theme();
}

std::string TAWEngine::adapt(const std::string& source_path,
                             const ThemePalette& palette,
                             float intensity)
{
    if (source_path.empty() || !QFile::exists(QString::fromStdString(source_path))) {
        return source_path;
    }

    TransformOptions opts;
    opts.intensity = std::clamp(intensity, 0.0f, 1.0f);
    opts.preserve_highlights = true;
    opts.preserve_shadows = true;
    opts.amoled_black_crush = (palette.id == "amoled");

    // 1. Check cache first
    auto cached = m_cache.lookup(source_path, palette, opts);
    if (cached.has_value()) {
        return *cached;
    }

    // 2. Load source image
    QImage src = WallpaperLoader::load(source_path);
    if (src.isNull()) {
        return source_path;
    }

    // 3. Transform
    ColorTransformer transformer(palette, opts);
    QImage result = transformer.transform(src);

    // 4. Save to cache
    return m_cache.save(source_path, palette, opts, result);
}

std::string TAWEngine::adapt_current() {
    ThemePalette pal = resolve_effective_palette();
    m_config.active_theme_id = pal.id;
    return adapt(m_config.original_wallpaper, pal, m_config.intensity);
}

bool TAWEngine::sync(bool force_reapply) {
    if (m_config.original_wallpaper.empty() || !QFile::exists(QString::fromStdString(m_config.original_wallpaper))) {
        // Fallback: check ~/.config/archtitan/wallpaper or default system background
        const char* home = std::getenv("HOME");
        std::string fallback_wp;
        if (home) {
            std::string wp_file = std::string(home) + "/.config/archtitan/wallpaper";
            QFile wpf(QString::fromStdString(wp_file));
            if (wpf.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&wpf);
                QString line = in.readLine().trimmed();
                if (!line.isEmpty() && !line.contains("/archtitan/wallpapers/")) {
                    fallback_wp = line.toStdString();
                }
            }
        }
        if (fallback_wp.empty() || !QFile::exists(QString::fromStdString(fallback_wp))) {
            fallback_wp = "/usr/share/backgrounds/archtitan/wallpaper.png";
        }
        if (QFile::exists(QString::fromStdString(fallback_wp))) {
            m_config.original_wallpaper = fallback_wp;
            save_config();
        } else {
            return false;
        }
    }

    if (!m_config.enabled) {
        // Adaptive is disabled: apply the untouched original image
        return apply_to_desktop(m_config.original_wallpaper);
    }

    ThemePalette pal = resolve_effective_palette();
    m_config.active_theme_id = pal.id;

    std::string adapted_path = adapt(m_config.original_wallpaper, pal, m_config.intensity);
    if (adapted_path.empty() || !QFile::exists(QString::fromStdString(adapted_path))) {
        return false;
    }

    if (force_reapply || adapted_path != m_config.last_adapted_wallpaper) {
        m_config.last_adapted_wallpaper = adapted_path;
        save_config();
        return apply_to_desktop(adapted_path);
    }

    return true;
}

bool TAWEngine::restore_original() {
    if (m_config.original_wallpaper.empty()) return false;
    m_config.enabled = false;
    save_config();
    return apply_to_desktop(m_config.original_wallpaper);
}

bool TAWEngine::apply_to_desktop(const std::string& wallpaper_path, const std::string& mode) {
    if (wallpaper_path.empty() || !QFile::exists(QString::fromStdString(wallpaper_path))) {
        return false;
    }

    QString bin = QStandardPaths::findExecutable("titan-set-wallpaper");
    if (bin.isEmpty()) {
        bin = QStringLiteral("/usr/local/bin/titan-set-wallpaper");
    }
    if (!QFile::exists(bin)) {
        // Fallback to repo path if running in local tree
        bin = QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/local/bin/titan-set-wallpaper");
    }

    QProcess proc;
    QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    env.insert("TITAN_QUIET", "1");
    proc.setProcessEnvironment(env);
    proc.start(bin, { QString::fromStdString(wallpaper_path), QString::fromStdString(mode) });
    proc.waitForFinished(4000);
    return (proc.exitCode() == 0);
}

} // namespace taw

