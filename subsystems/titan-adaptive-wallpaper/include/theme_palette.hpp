#pragma once

#include "color_space.hpp"
#include <string>
#include <vector>
#include <optional>

namespace taw {

struct ThemePalette {
    std::string id;
    std::string name;
    bool isDark = true;

    // Core accents
    RGB accent;
    RGB accent2;

    // Surfaces & background
    RGB crust;
    RGB mantle;
    RGB base;
    RGB surface0;
    RGB surface1;
    RGB surface2;
    RGB surface3;

    // Highlights & tones
    RGB textHigh;
    RGB textMid;
    RGB textLow;
    RGB teal;
    RGB mauve;
    RGB peach;
    RGB pink;

    // Precomputed OKLab anchors
    OKLab oklab_crust;
    OKLab oklab_mantle;
    OKLab oklab_base;
    OKLab oklab_surface1;
    OKLab oklab_accent;
    OKLab oklab_accent2;
    OKLab oklab_textHigh;

    void compute_oklab_anchors();

    // Built-in presets
    static ThemePalette mocha();
    static ThemePalette nord();
    static ThemePalette tokyonight();
    static ThemePalette dracula();
    static ThemePalette gruvbox();
    static ThemePalette everforest();
    static ThemePalette rosepine();
    static ThemePalette amoled();

    static std::vector<std::string> available_presets();
    static std::optional<ThemePalette> from_preset(const std::string& name);
    static std::optional<ThemePalette> from_json_file(const std::string& filepath);
    static std::optional<ThemePalette> from_json_string(const std::string& json_str);
    static ThemePalette active_system_theme();
};

} // namespace taw

