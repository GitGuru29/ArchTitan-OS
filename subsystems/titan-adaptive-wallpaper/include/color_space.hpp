#pragma once

#include <cmath>
#include <cstdint>
#include <algorithm>
#include <string>

namespace taw {

struct RGB {
    float r = 0.0f; // 0.0 to 1.0
    float g = 0.0f;
    float b = 0.0f;

    static RGB from_u8(uint8_t red, uint8_t green, uint8_t blue) {
        return { red / 255.0f, green / 255.0f, blue / 255.0f };
    }

    static RGB from_hex(const std::string& hex);

    void to_u8(uint8_t& red, uint8_t& green, uint8_t& blue) const {
        red   = static_cast<uint8_t>(std::clamp(std::round(r * 255.0f), 0.0f, 255.0f));
        green = static_cast<uint8_t>(std::clamp(std::round(g * 255.0f), 0.0f, 255.0f));
        blue  = static_cast<uint8_t>(std::clamp(std::round(b * 255.0f), 0.0f, 255.0f));
    }

    std::string to_hex() const;
};

struct OKLab {
    float L = 0.0f; // Lightness [0.0, 1.0]
    float a = 0.0f; // Green-Red [-0.4, +0.4]
    float b = 0.0f; // Blue-Yellow [-0.4, +0.4]

    float chroma() const {
        return std::sqrt(a * a + b * b);
    }

    float hue() const {
        float h = std::atan2(b, a);
        return h < 0.0f ? h + 2.0f * M_PIf : h;
    }
};

// Conversions
float srgb_to_linear(float c);
float linear_to_srgb(float c);

OKLab rgb_to_oklab(const RGB& rgb);
RGB oklab_to_rgb(const OKLab& lab);

// Fast 8-bit conversions with precomputed lookup tables
OKLab rgb_u8_to_oklab(uint8_t r, uint8_t g, uint8_t b);
void oklab_to_rgb_u8(const OKLab& lab, uint8_t& out_r, uint8_t& out_g, uint8_t& out_b);

// Perceptual relative luminance (Rec. 709)
float relative_luminance(const RGB& rgb);

// Blend two OKLab colors
OKLab blend_oklab(const OKLab& c1, const OKLab& c2, float t);

} // namespace taw

