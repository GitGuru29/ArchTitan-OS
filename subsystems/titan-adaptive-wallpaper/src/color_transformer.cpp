#include "color_transformer.hpp"
#include <algorithm>
#include <cmath>
#include <vector>

namespace taw {

ColorTransformer::ColorTransformer(const ThemePalette& palette, const TransformOptions& options)
    : m_palette(palette), m_options(options)
{
    update_anchors();
}

void ColorTransformer::set_palette(const ThemePalette& palette) {
    m_palette = palette;
    update_anchors();
}

void ColorTransformer::set_options(const TransformOptions& options) {
    m_options = options;
    update_anchors();
}

void ColorTransformer::update_anchors() {
    m_anchors.clear();

    // Setup 6 distinct anchors across the 0.0 -> 1.0 luminance spectrum
    // Ordered strictly by input luminance
    m_anchors.push_back({ 0.00f, m_palette.oklab_crust });
    m_anchors.push_back({ 0.18f, m_palette.oklab_base });
    m_anchors.push_back({ 0.40f, m_palette.oklab_surface1 });
    m_anchors.push_back({ 0.65f, m_palette.oklab_accent2 });
    m_anchors.push_back({ 0.85f, m_palette.oklab_accent });
    m_anchors.push_back({ 1.00f, m_palette.oklab_textHigh });

    // Precompute 1024-entry anchor curve lookup table for ultra-fast per-pixel sampling
    for (int i = 0; i < 1024; ++i) {
        float lum = i / 1023.0f;
        m_curve_lut[i] = sample_anchor_curve(lum);
    }
}

OKLab ColorTransformer::sample_anchor_curve(float lum) const {
    lum = std::clamp(lum, 0.0f, 1.0f);
    if (m_anchors.empty()) return { lum, 0.0f, 0.0f };
    if (lum <= m_anchors.front().L_in) return m_anchors.front().lab;
    if (lum >= m_anchors.back().L_in)  return m_anchors.back().lab;

    // Linear search across anchors (only 6 elements)
    for (size_t i = 0; i < m_anchors.size() - 1; ++i) {
        if (lum >= m_anchors[i].L_in && lum <= m_anchors[i+1].L_in) {
            float span = m_anchors[i+1].L_in - m_anchors[i].L_in;
            float t = (span > 0.0001f) ? (lum - m_anchors[i].L_in) / span : 0.0f;
            // Smooth hermite interpolation t * t * (3 - 2 * t)
            float smooth_t = t * t * (3.0f - 2.0f * t);
            return blend_oklab(m_anchors[i].lab, m_anchors[i+1].lab, smooth_t);
        }
    }
    return m_anchors.back().lab;
}

RGB ColorTransformer::transform_pixel(const RGB& src) const {
    if (m_options.intensity <= 0.001f) {
        return src;
    }

    OKLab in_lab = rgb_to_oklab(src);
    float in_L = in_lab.L;

    // AMOLED special crush
    if (m_options.amoled_black_crush && in_L < 0.06f) {
        return { 0.0f, 0.0f, 0.0f };
    }

    // Sample theme chromatic anchor at input luminance
    OKLab target_lab = sample_anchor_curve(in_L);

    // Dynamic contrast S-curve on Lightness
    float out_L = in_L;
    if (std::abs(m_options.contrast_boost - 1.0f) > 0.01f) {
        // Subtle sigmoid contrast refinement
        float centered = in_L - 0.5f;
        out_L = 0.5f + centered * m_options.contrast_boost;
        out_L = std::clamp(out_L, 0.0f, 1.0f);
    }

    float in_chroma = in_lab.chroma();

    // Atmospheric adaptation:
    // Blend the pixel's chromaticity towards the target theme palette anchor
    // Desaturated/neutral regions take on theme tint readily;
    // High-chroma objects retain vibrant personality while shifting towards the palette.
    float target_a = target_lab.a;
    float target_b = target_lab.b;

    // Weight factor: how much to preserve existing hue vs adopting theme anchor
    float adopt_weight = 0.75f;
    if (in_chroma > 0.12f) {
        // High chroma region: soften adoption so bold colors still show through
        adopt_weight = 0.45f;
    }

    float adapted_a = in_lab.a * (1.0f - adopt_weight) + target_a * adopt_weight;
    float adapted_b = in_lab.b * (1.0f - adopt_weight) + target_b * adopt_weight;

    // Apply overall intensity slider
    float eff_intensity = std::clamp(m_options.intensity, 0.0f, 1.0f);
    float final_a = in_lab.a * (1.0f - eff_intensity) + adapted_a * eff_intensity;
    float final_b = in_lab.b * (1.0f - eff_intensity) + adapted_b * eff_intensity;

    // Highlight protection: preserve pure specular whites from color cast
    if (m_options.preserve_highlights && in_L > 0.92f) {
        float white_fade = (1.0f - in_L) / (1.0f - 0.92f); // 1.0 at 0.92 -> 0.0 at 1.0
        final_a *= white_fade;
        final_b *= white_fade;
    }

    // Shadow protection: preserve deep rich blacks from muddy grey tinting
    if (m_options.preserve_shadows && in_L < 0.08f) {
        float black_fade = in_L / 0.08f; // 0.0 at 0.0 -> 1.0 at 0.08
        final_a *= black_fade;
        final_b *= black_fade;
    }

    OKLab out_lab { out_L, final_a, final_b };
    return oklab_to_rgb(out_lab);
}

QImage ColorTransformer::transform(const QImage& source) const {
    if (source.isNull()) return source;
    if (m_options.intensity <= 0.001f) return source;

    QImage img = source.convertToFormat(QImage::Format_ARGB32);
    const int width = img.width();
    const int height = img.height();

    const float eff_intensity = std::clamp(m_options.intensity, 0.0f, 1.0f);
    const bool has_contrast_boost = (std::abs(m_options.contrast_boost - 1.0f) > 0.01f);
    const float contrast_boost = m_options.contrast_boost;
    const bool amoled_crush = m_options.amoled_black_crush;
    const bool preserve_highlights = m_options.preserve_highlights;
    const bool preserve_shadows = m_options.preserve_shadows;

    #pragma omp parallel for schedule(dynamic, 64) if(height > 64)
    for (int y = 0; y < height; ++y) {
        auto* scanline = reinterpret_cast<uint32_t*>(img.scanLine(y));
        for (int x = 0; x < width; ++x) {
            uint32_t pixel = scanline[x];
            uint8_t a = (pixel >> 24) & 0xFF;
            uint8_t r = (pixel >> 16) & 0xFF;
            uint8_t g = (pixel >> 8) & 0xFF;
            uint8_t b = pixel & 0xFF;

            OKLab in_lab = rgb_u8_to_oklab(r, g, b);
            float in_L = in_lab.L;

            if (amoled_crush && in_L < 0.06f) {
                scanline[x] = (static_cast<uint32_t>(a) << 24);
                continue;
            }

            int lut_idx = std::clamp(static_cast<int>(in_L * 1023.0f + 0.5f), 0, 1023);
            const OKLab& target_lab = m_curve_lut[lut_idx];

            float out_L = in_L;
            if (has_contrast_boost) {
                out_L = std::clamp(0.5f + (in_L - 0.5f) * contrast_boost, 0.0f, 1.0f);
            }

            float in_chroma = in_lab.chroma();
            float adopt_weight = (in_chroma > 0.12f) ? 0.45f : 0.75f;

            float adapted_a = in_lab.a * (1.0f - adopt_weight) + target_lab.a * adopt_weight;
            float adapted_b = in_lab.b * (1.0f - adopt_weight) + target_lab.b * adopt_weight;

            float final_a = in_lab.a * (1.0f - eff_intensity) + adapted_a * eff_intensity;
            float final_b = in_lab.b * (1.0f - eff_intensity) + adapted_b * eff_intensity;

            if (preserve_highlights && in_L > 0.92f) {
                float white_fade = (1.0f - in_L) * (1.0f / 0.08f);
                final_a *= white_fade;
                final_b *= white_fade;
            }

            if (preserve_shadows && in_L < 0.08f) {
                float black_fade = in_L * (1.0f / 0.08f);
                final_a *= black_fade;
                final_b *= black_fade;
            }

            OKLab out_lab { out_L, final_a, final_b };
            uint8_t out_r, out_g, out_b;
            oklab_to_rgb_u8(out_lab, out_r, out_g, out_b);

            scanline[x] = (static_cast<uint32_t>(a) << 24) |
                          (static_cast<uint32_t>(out_r) << 16) |
                          (static_cast<uint32_t>(out_g) << 8) |
                          static_cast<uint32_t>(out_b);
        }
    }

    return img;
}

} // namespace taw

