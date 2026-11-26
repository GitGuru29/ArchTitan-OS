#include "color_space.hpp"
#include "theme_palette.hpp"
#include "color_transformer.hpp"
#include "cache_manager.hpp"
#include "wallpaper_loader.hpp"
#include "taw_engine.hpp"

#include <iostream>
#include <cassert>
#include <QCoreApplication>
#include <QFileInfo>
#include <QDir>
#include <QColor>
#include <chrono>

using namespace taw;

void test_color_space() {
    std::cout << "[TEST] 1. Color Space & OKLab Conversions...\n";

    RGB pure_red { 1.0f, 0.0f, 0.0f };
    OKLab lab_red = rgb_to_oklab(pure_red);
    RGB back_red = oklab_to_rgb(lab_red);

    assert(std::abs(pure_red.r - back_red.r) < 0.01f);
    assert(std::abs(pure_red.g - back_red.g) < 0.01f);
    assert(std::abs(pure_red.b - back_red.b) < 0.01f);

    RGB hex_color = RGB::from_hex("#89B4FA");
    assert(hex_color.to_hex() == "#89B4FA");

    std::cout << "  ✓ OKLab roundtrip precision verified.\n";
    std::cout << "  ✓ Hex color encoding/decoding verified.\n";
}

void test_palette_loading() {
    std::cout << "[TEST] 2. Theme Palette Loading & Anchors...\n";

    ThemePalette mocha = ThemePalette::mocha();
    assert(mocha.id == "mocha");
    assert(mocha.accent.to_hex() == "#89B4FA");

    ThemePalette nord = ThemePalette::nord();
    assert(nord.id == "nord");
    assert(nord.accent.to_hex() == "#88C0D0");

    ThemePalette everforest = ThemePalette::everforest();
    assert(everforest.id == "everforest");

    // Test JSON parser on real system file if present
    std::string test_json = R"({
        "id": "test_theme",
        "name": "Test Theme",
        "isDark": true,
        "accent": "#00E5FF",
        "accent2": "#A855F7",
        "palette": {
            "crust": "#0B0F19",
            "base": "#141C2E",
            "surface1": "#24314A",
            "textHigh": "#F8FAFC"
        }
    })";

    auto parsed = ThemePalette::from_json_string(test_json);
    assert(parsed.has_value());
    assert(parsed->id == "test_theme");
    assert(parsed->accent.to_hex() == "#00E5FF");
    assert(parsed->accent2.to_hex() == "#A855F7");

    std::cout << "  ✓ Built-in palettes (Mocha, Nord, Everforest, etc.) verified.\n";
    std::cout << "  ✓ Arbitrary JSON palette parser verified.\n";
}

void test_milestone_1_transformation() {
    std::cout << "[TEST] 3. Milestone 1: Transforming Wallpaper with 3 Distinct Palettes...\n";

    // Use a real wallpaper from the repo
    std::string wp_path = "/home/msfvenom/custom-os-build/airootfs/usr/share/backgrounds/archtitan/wallpaper.png";
    if (!QFile::exists(QString::fromStdString(wp_path))) {
        wp_path = "/usr/share/backgrounds/archtitan/wallpaper.png";
    }

    QImage src;
    if (QFile::exists(QString::fromStdString(wp_path))) {
        src = WallpaperLoader::load(wp_path);
        std::cout << "  Loaded real wallpaper: " << wp_path << " (" << src.width() << "x" << src.height() << ")\n";
    } else {
        // Create synthetic high-res gradient test image
        src = QImage(1920, 1080, QImage::Format_ARGB32);
        for (int y = 0; y < 1080; ++y) {
            for (int x = 0; x < 1920; ++x) {
                int r = (x * 255) / 1920;
                int g = (y * 255) / 1080;
                int b = 128;
                src.setPixelColor(x, y, QColor(r, g, b));
            }
        }
        std::cout << "  Created synthetic test canvas (1920x1080)\n";
    }

    // Palette 1: Catppuccin Mocha (Lavender/Purple atmosphere)
    auto t0 = std::chrono::high_resolution_clock::now();
    ColorTransformer transformer_mocha(ThemePalette::mocha(), { 0.75f, true, true, 1.05f });
    QImage res_mocha = transformer_mocha.transform(src);
    auto t1 = std::chrono::high_resolution_clock::now();
    double ms_mocha = std::chrono::duration<double, std::milli>(t1 - t0).count();

    // Palette 2: Nord (Arctic blue/cyan atmosphere)
    ColorTransformer transformer_nord(ThemePalette::nord(), { 0.75f, true, true, 1.05f });
    QImage res_nord = transformer_nord.transform(src);

    // Palette 3: Everforest (Green forest atmosphere)
    ColorTransformer transformer_everforest(ThemePalette::everforest(), { 0.75f, true, true, 1.05f });
    QImage res_everforest = transformer_everforest.transform(src);

    assert(!res_mocha.isNull());
    assert(!res_nord.isNull());
    assert(!res_everforest.isNull());

    std::cout << "  ✓ Transformed to Catppuccin Mocha in " << ms_mocha << " ms.\n";
    std::cout << "  ✓ Transformed to Nord.\n";
    std::cout << "  ✓ Transformed to Everforest.\n";
}

void test_caching_and_engine() {
    std::cout << "[TEST] 4. Milestone 4: Image Caching & Hash Determinism...\n";

    std::string temp_cache = "/tmp/archtitan_taw_test_cache";
    TAWEngine engine("/tmp/archtitan_taw_test_config.json");
    engine.cache().clear();

    std::string test_img = "/home/msfvenom/custom-os-build/airootfs/usr/share/backgrounds/archtitan/wallpaper.png";
    if (!QFile::exists(QString::fromStdString(test_img))) {
        test_img = "/tmp/test_src.png";
        QImage dummy(200, 200, QImage::Format_ARGB32);
        dummy.fill(Qt::blue);
        dummy.save(QString::fromStdString(test_img));
    }

    ThemePalette pal = ThemePalette::nord();

    // 1st run: Cache Miss -> Generates and saves
    auto t0 = std::chrono::high_resolution_clock::now();
    std::string path1 = engine.adapt(test_img, pal, 0.70f);
    auto t1 = std::chrono::high_resolution_clock::now();
    double ms_miss = std::chrono::duration<double, std::milli>(t1 - t0).count();

    assert(!path1.empty());
    assert(QFile::exists(QString::fromStdString(path1)));

    // 2nd run: Cache Hit -> Instantaneous return
    auto t2 = std::chrono::high_resolution_clock::now();
    std::string path2 = engine.adapt(test_img, pal, 0.70f);
    auto t3 = std::chrono::high_resolution_clock::now();
    double ms_hit = std::chrono::duration<double, std::milli>(t3 - t2).count();

    assert(path1 == path2);
    assert(ms_hit < 5.0); // should be < 5ms on cache hit

    std::cout << "  ✓ Cache Miss execution: " << ms_miss << " ms (processed & cached)\n";
    std::cout << "  ✓ Cache Hit execution:  " << ms_hit << " ms (instantaneous lookup)\n";
}

void test_palette_robustness() {
    std::cout << "[TEST] 5. Malformed theme plates & UI palette labels...\n";

    RGB color;
    assert(RGB::from_hex_checked("#1E66F5FF", color));   // #RRGGBBAA from a theme plate
    assert(color.to_hex() == "#1E66F5");
    assert(!RGB::from_hex_checked("#GGHHII", color));

    // A bad swatch must keep the baseline instead of turning every anchor
    // black (which rendered the desktop as a black screen).
    auto parsed = ThemePalette::from_json_string(R"({
        "id": "broken",
        "accent": "not-a-colour",
        "palette": { "crust": "#GGHHII", "textHigh": "#FFFFFFFF" }
    })");
    assert(parsed.has_value());
    assert(parsed->accent.to_hex() == ThemePalette::mocha().accent.to_hex());
    assert(parsed->crust.to_hex() == ThemePalette::mocha().crust.to_hex());
    assert(parsed->textHigh.to_hex() == "#FFFFFF");

    assert(ThemePalette::from_preset("Catppuccin Mocha")->id == "mocha");
    assert(ThemePalette::from_preset("AMOLED")->id == "amoled");
    assert(ThemePalette::from_preset("Rose Pine")->id == "rosepine");

    std::cout << "  ✓ Invalid swatches fall back safely; palette pills resolve.\n";
}

void test_cache_integrity() {
    std::cout << "[TEST] 6. Cache integrity & atomic replacement...\n";

    CacheManager cache("/tmp/opencode/taw_test_cache_integrity");
    cache.clear();

    ThemePalette pal = ThemePalette::nord();
    TransformOptions opts { 0.70f, true, true, 1.0f, false };
    QImage img(64, 64, QImage::Format_ARGB32);
    img.fill(QColor(40, 90, 140, 255));

    assert(cache.save("virtual-source", pal, opts, QImage()).empty());
    std::string path = cache.save("virtual-source", pal, opts, img);
    assert(!path.empty() && QFile::exists(QString::fromStdString(path)));
    assert(cache.lookup("virtual-source", pal, opts).value_or("") == path);

    // A truncated/ corrupt cache entry must never be applied to swaybg.
    QFile broken(QString::fromStdString(path));
    assert(broken.open(QIODevice::WriteOnly));
    broken.write("not a png");
    broken.close();
    assert(!cache.lookup("virtual-source", pal, opts).has_value());

    assert(!cache.save("virtual-source", pal, opts, img).empty());
    assert(cache.lookup("virtual-source", pal, opts).has_value());

    std::cout << "  ✓ Failed saves and corrupt entries are rejected.\n";
}

void test_amoled_crush() {
    std::cout << "[TEST] 7. AMOLED crush does not blank the wallpaper...\n";

    QImage src(32, 32, QImage::Format_ARGB32);
    for (int y = 0; y < src.height(); ++y) {
        for (int x = 0; x < src.width(); ++x) {
            src.setPixelColor(x, y, x < 8 ? QColor(0, 0, 0, 128) : QColor(210, 210, 210, 128));
        }
    }

    TransformOptions opts;
    opts.intensity = 1.0f;
    opts.contrast_boost = 1.0f;
    opts.amoled_black_crush = true;
    QImage out = ColorTransformer(ThemePalette::amoled(), opts).transform(src);

    for (int y = 0; y < out.height(); ++y) {
        for (int x = 0; x < out.width(); ++x) {
            assert(qAlpha(out.pixel(x, y)) == 128);
            if (x >= 8) assert(qGreen(out.pixel(x, y)) > 20);
        }
    }

    std::cout << "  ✓ Alpha preserved; only true near-blacks are crushed.\n";
}

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);
    std::cout << "═══════════════════════════════════════════════════════════\n"
              << " Titan Adaptive Wallpaper (TAW) Verification Suite\n"
              << "═══════════════════════════════════════════════════════════\n";

    test_color_space();
    test_palette_loading();
    test_milestone_1_transformation();
    test_caching_and_engine();
    test_palette_robustness();
    test_cache_integrity();
    test_amoled_crush();

    std::cout << "═══════════════════════════════════════════════════════════\n"
              << " ALL TAW UNIT TESTS & MILESTONES PASSED (100% SUCCESS)\n"
              << "═══════════════════════════════════════════════════════════\n";
    return 0;
}

