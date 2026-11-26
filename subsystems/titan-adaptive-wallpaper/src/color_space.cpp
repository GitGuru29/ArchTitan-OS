#include "color_space.hpp"
#include <cstdio>
#include <sstream>
#include <iomanip>
#include <array>

namespace taw {

static const auto g_srgb_to_linear_u8 = [] {
    std::array<float, 256> table{};
    for (int i = 0; i < 256; ++i) {
        float c = i / 255.0f;
        table[i] = (c <= 0.04045f) ? (c / 12.92f) : std::pow((c + 0.055f) / 1.055f, 2.4f);
    }
    return table;
}();

static const auto g_linear_to_srgb_u8 = [] {
    std::array<uint8_t, 4096> table{};
    for (int i = 0; i < 4096; ++i) {
        float c = i / 4095.0f;
        float s = (c <= 0.0031308f) ? (12.92f * c) : (1.055f * std::pow(c, 1.0f / 2.4f) - 0.055f);
        int val = static_cast<int>(std::round(s * 255.0f));
        table[i] = static_cast<uint8_t>(std::clamp(val, 0, 255));
    }
    return table;
}();

static inline uint8_t fast_linear_to_u8(float c) {
    if (c <= 0.0f) return 0;
    if (c >= 1.0f) return 255;
    int idx = static_cast<int>(c * 4095.0f + 0.5f);
    return g_linear_to_srgb_u8[idx];
}

static int hex_digit(char c) {
    if (c >= '0' && c <= '9') return c - '0';
    if (c >= 'a' && c <= 'f') return c - 'a' + 10;
    if (c >= 'A' && c <= 'F') return c - 'A' + 10;
    return -1;
}

bool RGB::from_hex_checked(const std::string& hex, RGB& out) {
    if (hex.empty()) return false;
    std::string s = hex;
    if (s[0] == '#') s = s.substr(1);

    // Expand shorthand (#RGB / #RGBA) to the full form.
    if (s.size() == 3 || s.size() == 4) {
        std::string expanded;
        expanded.reserve(s.size() * 2);
        for (char c : s) {
            if (hex_digit(c) < 0) return false;
            expanded += c;
            expanded += c;
        }
        s = expanded;
    }
    if (s.size() != 6 && s.size() != 8) return false;

    // Only the first six nibbles matter — theme plates sometimes carry an
    // alpha channel, but wallpaper anchors are always opaque.
    int r = -1, g = -1, b = -1;
    for (int i = 0; i < 6; ++i) {
        if (hex_digit(s[i]) < 0) return false;
    }
    r = (hex_digit(s[0]) << 4) | hex_digit(s[1]);
    g = (hex_digit(s[2]) << 4) | hex_digit(s[3]);
    b = (hex_digit(s[4]) << 4) | hex_digit(s[5]);
    if (s.size() == 8) {
        for (int i = 6; i < 8; ++i) {
            if (hex_digit(s[i]) < 0) return false;
        }
    }

    out = { r / 255.0f, g / 255.0f, b / 255.0f };
    return true;
}

RGB RGB::from_hex(const std::string& hex) {
    RGB out;
    return RGB::from_hex_checked(hex, out) ? out : RGB { 0.0f, 0.0f, 0.0f };
}

std::string RGB::to_hex() const {
    uint8_t red, green, blue;
    to_u8(red, green, blue);
    std::ostringstream ss;
    ss << "#"
       << std::hex << std::setfill('0') << std::uppercase
       << std::setw(2) << static_cast<int>(red)
       << std::setw(2) << static_cast<int>(green)
       << std::setw(2) << static_cast<int>(blue);
    return ss.str();
}

float srgb_to_linear(float c) {
    c = std::clamp(c, 0.0f, 1.0f);
    if (c <= 0.04045f) {
        return c / 12.92f;
    }
    return std::pow((c + 0.055f) / 1.055f, 2.4f);
}

float linear_to_srgb(float c) {
    c = std::clamp(c, 0.0f, 1.0f);
    if (c <= 0.0031308f) {
        return 12.92f * c;
    }
    return 1.055f * std::pow(c, 1.0f / 2.4f) - 0.055f;
}

OKLab rgb_to_oklab(const RGB& rgb) {
    float r = srgb_to_linear(rgb.r);
    float g = srgb_to_linear(rgb.g);
    float b = srgb_to_linear(rgb.b);

    float l = 0.4122214708f * r + 0.5363325363f * g + 0.0514459929f * b;
    float m = 0.2119034982f * r + 0.6806995451f * g + 0.1073969566f * b;
    float s = 0.0883024619f * r + 0.2817188376f * g + 0.6299787005f * b;

    float l_ = std::cbrtf(l);
    float m_ = std::cbrtf(m);
    float s_ = std::cbrtf(s);

    OKLab lab;
    lab.L = 0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_;
    lab.a = 1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_;
    lab.b = 0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_;
    return lab;
}

RGB oklab_to_rgb(const OKLab& lab) {
    float l_ = lab.L + 0.3963377774f * lab.a + 0.2158037573f * lab.b;
    float m_ = lab.L - 0.1055613458f * lab.a - 0.0638541728f * lab.b;
    float s_ = lab.L - 0.0894841775f * lab.a - 1.2914855480f * lab.b;

    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;

    float r = +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s;
    float g = -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s;
    float b = -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s;

    RGB out;
    out.r = linear_to_srgb(r);
    out.g = linear_to_srgb(g);
    out.b = linear_to_srgb(b);
    return out;
}

OKLab rgb_u8_to_oklab(uint8_t red, uint8_t green, uint8_t blue) {
    float r = g_srgb_to_linear_u8[red];
    float g = g_srgb_to_linear_u8[green];
    float b = g_srgb_to_linear_u8[blue];

    float l = 0.4122214708f * r + 0.5363325363f * g + 0.0514459929f * b;
    float m = 0.2119034982f * r + 0.6806995451f * g + 0.1073969566f * b;
    float s = 0.0883024619f * r + 0.2817188376f * g + 0.6299787005f * b;

    float l_ = std::cbrtf(l);
    float m_ = std::cbrtf(m);
    float s_ = std::cbrtf(s);

    OKLab lab;
    lab.L = 0.2104542553f * l_ + 0.7936177850f * m_ - 0.0040720468f * s_;
    lab.a = 1.9779984951f * l_ - 2.4285922050f * m_ + 0.4505937099f * s_;
    lab.b = 0.0259040371f * l_ + 0.7827717662f * m_ - 0.8086757660f * s_;
    return lab;
}

void oklab_to_rgb_u8(const OKLab& lab, uint8_t& out_r, uint8_t& out_g, uint8_t& out_b) {
    float l_ = lab.L + 0.3963377774f * lab.a + 0.2158037573f * lab.b;
    float m_ = lab.L - 0.1055613458f * lab.a - 0.0638541728f * lab.b;
    float s_ = lab.L - 0.0894841775f * lab.a - 1.2914855480f * lab.b;

    float l = l_ * l_ * l_;
    float m = m_ * m_ * m_;
    float s = s_ * s_ * s_;

    float r = +4.0767416621f * l - 3.3077115913f * m + 0.2309699292f * s;
    float g = -1.2684380046f * l + 2.6097574011f * m - 0.3413193965f * s;
    float b = -0.0041960863f * l - 0.7034186147f * m + 1.7076147010f * s;

    out_r = fast_linear_to_u8(r);
    out_g = fast_linear_to_u8(g);
    out_b = fast_linear_to_u8(b);
}

float relative_luminance(const RGB& rgb) {
    float r = srgb_to_linear(rgb.r);
    float g = srgb_to_linear(rgb.g);
    float b = srgb_to_linear(rgb.b);
    return 0.2126f * r + 0.7152f * g + 0.0722f * b;
}

OKLab blend_oklab(const OKLab& c1, const OKLab& c2, float t) {
    t = std::clamp(t, 0.0f, 1.0f);
    return {
        c1.L * (1.0f - t) + c2.L * t,
        c1.a * (1.0f - t) + c2.a * t,
        c1.b * (1.0f - t) + c2.b * t
    };
}

} // namespace taw

