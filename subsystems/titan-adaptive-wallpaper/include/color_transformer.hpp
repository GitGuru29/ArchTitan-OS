#pragma once

#include "color_space.hpp"
#include "theme_palette.hpp"
#include <QImage>

namespace taw {

struct TransformOptions {
    float intensity = 0.70f;              // 0.0 (original) to 1.0 (full adaptation)
    bool preserve_highlights = true;      // Keep pure whites/specular highlights clean
    bool preserve_shadows = true;         // Keep pure blacks deep and unwashed
    float contrast_boost = 1.05f;         // Subtle S-curve contrast refinement
    bool amoled_black_crush = false;      // If true (for AMOLED), crushes deep shadows to #000000
};

class ColorTransformer {
public:
    explicit ColorTransformer(const ThemePalette& palette, const TransformOptions& options = {});

    void set_palette(const ThemePalette& palette);
    void set_options(const TransformOptions& options);

    const ThemePalette& palette() const { return m_palette; }
    const TransformOptions& options() const { return m_options; }

    // Transform in-place or return a new QImage
    QImage transform(const QImage& source) const;

    // Fast single pixel transformation
    RGB transform_pixel(const RGB& src) const;

private:
    ThemePalette m_palette;
    TransformOptions m_options;

    // Precomputed anchor points along luminance curve
    struct Anchor {
        float L_in;
        OKLab lab;
    };
    std::vector<Anchor> m_anchors;

    void update_anchors();
    OKLab sample_anchor_curve(float luminance) const;
};

} // namespace taw

