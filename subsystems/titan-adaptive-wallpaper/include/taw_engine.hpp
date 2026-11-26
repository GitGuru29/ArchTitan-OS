#pragma once

#include "theme_palette.hpp"
#include "color_transformer.hpp"
#include "cache_manager.hpp"
#include <string>
#include <memory>

namespace taw {

struct TAWConfig {
    bool enabled = true;
    bool auto_sync = true;
    float intensity = 0.70f;
    std::string original_wallpaper = "/usr/share/backgrounds/archtitan/wallpaper.png";
    std::string active_theme_id = "mocha";
    std::string manual_palette_override = ""; // Empty means follow system theme
    std::string last_adapted_wallpaper = "";
};

class TAWEngine {
public:
    explicit TAWEngine(const std::string& config_file = "");

    const TAWConfig& config() const { return m_config; }
    void update_config(const TAWConfig& cfg);

    bool is_enabled() const { return m_config.enabled; }
    void set_enabled(bool enabled);

    bool is_auto_sync() const { return m_config.auto_sync; }
    void set_auto_sync(bool auto_sync);

    float intensity() const { return m_config.intensity; }
    void set_intensity(float intensity);

    std::string original_wallpaper() const { return m_config.original_wallpaper; }
    void set_original_wallpaper(const std::string& path);

    std::string manual_palette_override() const { return m_config.manual_palette_override; }
    void set_manual_palette_override(const std::string& name);

    // Resolves active palette (either manual override or active system theme)
    ThemePalette resolve_effective_palette() const;

    // Adapts an image using given or effective palette, returning the path to the transformed image
    std::string adapt(const std::string& source_path,
                      const ThemePalette& palette,
                      float intensity);

    // Adapts the current original wallpaper to the current effective palette
    std::string adapt_current();

    // Synchronizes wallpaper with current system theme / settings
    bool sync(bool force_reapply = false);

    // Restores the original wallpaper without any adaptive coloring
    bool restore_original();

    // Applies a wallpaper to the desktop via titan-set-wallpaper
    static bool apply_to_desktop(const std::string& wallpaper_path, const std::string& mode = "fill");

    // Cache access
    CacheManager& cache() { return m_cache; }

    void load_config();
    void save_config() const;

private:
    std::string m_config_path;
    TAWConfig m_config;
    CacheManager m_cache;

    void ensure_config_path();
};

} // namespace taw

