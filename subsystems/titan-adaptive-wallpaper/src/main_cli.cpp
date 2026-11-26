#include "taw_engine.hpp"
#include "wallpaper_loader.hpp"
#include <iostream>
#include <string>
#include <vector>
#include <QCoreApplication>
#include <QFileSystemWatcher>
#include <QFileInfo>
#include <QDir>
#include <QThread>
#include <QTimer>

using namespace taw;

void print_help() {
    std::cout << R"(titan-adaptive-wallpaper — Native ArchTitan Adaptive Wallpaper Engine

Usage:
  titan-adaptive-wallpaper sync [--force]
      Synchronize wallpaper with the currently active desktop theme.

  titan-adaptive-wallpaper transform <input-image> [options]
      Transform an image using a specific theme palette.
      Options:
        --theme <name|file.json>   Theme preset or JSON file (default: active theme)
        --intensity <0.0-1.0>      Color adaptation intensity (default: 0.70)
        --output <destination>     Output file path (default: cached variant)

  titan-adaptive-wallpaper status
      Display current adaptive wallpaper configuration and cache metrics.

  titan-adaptive-wallpaper enable | disable
      Toggle adaptive wallpaper transformation.

  titan-adaptive-wallpaper set-intensity <0.0-1.0>
      Update the global color adaptation intensity.

  titan-adaptive-wallpaper set-wallpaper <path>
      Set a new original wallpaper and synchronize.

  titan-adaptive-wallpaper set-palette <preset|file|none>
      Set a manual palette override ('none' to follow system theme).

  titan-adaptive-wallpaper restore
      Restore the untouched original wallpaper appearance.

  titan-adaptive-wallpaper cache-clear
      Clear all cached wallpaper variants.

  titan-adaptive-wallpaper daemon
      Run as background file watcher for live theme changes.
)";
}

int main(int argc, char* argv[]) {
    QCoreApplication app(argc, argv);
    std::vector<std::string> args;
    for (int i = 1; i < argc; ++i) args.push_back(argv[i]);

    if (args.empty() || args[0] == "--help" || args[0] == "-h" || args[0] == "help") {
        print_help();
        return 0;
    }

    TAWEngine engine;
    const std::string cmd = args[0];

    if (cmd == "status") {
        const auto& cfg = engine.config();
        std::cout << "Titan Adaptive Wallpaper (TAW) Status:\n"
                  << "  Enabled:            " << (cfg.enabled ? "YES" : "NO") << "\n"
                  << "  Auto Theme Sync:    " << (cfg.auto_sync ? "YES" : "NO") << "\n"
                  << "  Intensity:          " << cfg.intensity << "\n"
                  << "  Original Wallpaper: " << cfg.original_wallpaper << "\n"
                  << "  Active Theme ID:    " << cfg.active_theme_id << "\n"
                  << "  Manual Override:    " << (cfg.manual_palette_override.empty() ? "(None — Follows Theme)" : cfg.manual_palette_override) << "\n"
                  << "  Last Adapted:       " << cfg.last_adapted_wallpaper << "\n"
                  << "  Cache Directory:    " << engine.cache().cache_dir() << "\n";
        return 0;
    }

    if (cmd == "enable") {
        engine.set_enabled(true);
        std::cout << "Adaptive wallpaper enabled. Synchronizing...\n";
        engine.sync(true);
        return 0;
    }

    if (cmd == "disable") {
        engine.set_enabled(false);
        std::cout << "Adaptive wallpaper disabled. Restoring original wallpaper...\n";
        engine.restore_original();
        return 0;
    }

    if (cmd == "set-intensity") {
        if (args.size() < 2) {
            std::cerr << "Error: intensity value required (0.0 to 1.0)\n";
            return 1;
        }
        float val = std::stof(args[1]);
        engine.set_intensity(val);
        std::cout << "Intensity set to " << val << ". Synchronizing...\n";
        engine.sync(true);
        return 0;
    }

    if (cmd == "set-wallpaper") {
        if (args.size() < 2) {
            std::cerr << "Error: wallpaper image path required\n";
            return 1;
        }
        std::string path = args[1];
        if (!WallpaperLoader::is_supported_image(path)) {
            std::cerr << "Error: file does not exist or format not supported: " << path << "\n";
            return 1;
        }
        engine.set_original_wallpaper(path);
        std::cout << "Original wallpaper updated to: " << path << "\n";
        engine.sync(true);
        return 0;
    }

    if (cmd == "set-palette") {
        if (args.size() < 2) {
            std::cerr << "Error: palette name or 'none' required\n";
            return 1;
        }
        std::string pal = args[1];
        if (pal == "none" || pal == "default") {
            engine.set_manual_palette_override("");
            std::cout << "Palette override cleared (now follows active system theme).\n";
        } else {
            engine.set_manual_palette_override(pal);
            std::cout << "Manual palette override set to: " << pal << "\n";
        }
        engine.sync(true);
        return 0;
    }

    if (cmd == "restore") {
        std::cout << "Restoring original wallpaper...\n";
        if (engine.restore_original()) {
            std::cout << "Success: " << engine.original_wallpaper() << "\n";
            return 0;
        }
        std::cerr << "Failed to restore original wallpaper.\n";
        return 1;
    }

    if (cmd == "sync") {
        bool force = (args.size() > 1 && args[1] == "--force");
        if (engine.sync(force)) {
            std::cout << "Wallpaper synchronized successfully: " << engine.config().last_adapted_wallpaper << "\n";
            return 0;
        }
        std::cerr << "Wallpaper sync skipped or failed.\n";
        return 1;
    }

    if (cmd == "cache-clear") {
        engine.cache().clear();
        std::cout << "Wallpaper cache cleared.\n";
        return 0;
    }

    if (cmd == "transform") {
        if (args.size() < 2) {
            std::cerr << "Error: input image required\n";
            return 1;
        }
        std::string input = args[1];
        std::string theme_arg = "";
        std::string output = "";
        float intensity = engine.intensity();

        for (size_t i = 2; i < args.size(); ++i) {
            if (args[i] == "--theme" && i + 1 < args.size()) {
                theme_arg = args[++i];
            } else if (args[i] == "--intensity" && i + 1 < args.size()) {
                intensity = std::stof(args[++i]);
            } else if (args[i] == "--output" && i + 1 < args.size()) {
                output = args[++i];
            }
        }

        ThemePalette pal;
        if (!theme_arg.empty()) {
            auto opt = ThemePalette::from_preset(theme_arg);
            if (opt.has_value()) {
                pal = *opt;
            } else {
                auto opt_file = ThemePalette::from_json_file(theme_arg);
                if (opt_file.has_value()) {
                    pal = *opt_file;
                } else {
                    std::cerr << "Error: unrecognized theme preset or file: " << theme_arg << "\n";
                    return 1;
                }
            }
        } else {
            pal = engine.resolve_effective_palette();
        }

        std::string result_path = engine.adapt(input, pal, intensity);
        if (result_path.empty()) {
            std::cerr << "Error: transformation failed for " << input << "\n";
            return 1;
        }

        if (!output.empty() && output != result_path) {
            QFile::remove(QString::fromStdString(output));
            if (!QFile::copy(QString::fromStdString(result_path), QString::fromStdString(output))) {
                std::cerr << "Error: could not write to output path: " << output << "\n";
                return 1;
            }
            result_path = output;
        }

        std::cout << result_path << "\n";
        return 0;
    }

    if (cmd == "daemon") {
        std::cout << "[TAW Daemon] Starting Titan Adaptive Wallpaper watcher...\n";
        QFileSystemWatcher watcher;

        const char* home = std::getenv("HOME");
        std::string cfg_dir = std::string(home ? home : "/tmp") + "/.config/archtitan";
        std::string theme_file = cfg_dir + "/theme.json";
        std::string cfg_file = cfg_dir + "/adaptive-wallpaper.json";

        if (QFile::exists(QString::fromStdString(theme_file))) {
            watcher.addPath(QString::fromStdString(theme_file));
            std::cout << "[TAW Daemon] Watching " << theme_file << "\n";
        }
        if (QFile::exists(QString::fromStdString(cfg_file))) {
            watcher.addPath(QString::fromStdString(cfg_file));
            std::cout << "[TAW Daemon] Watching " << cfg_file << "\n";
        }

        // Single-shot debounce timer so rapid events settle before syncing
        QTimer debounce_timer;
        debounce_timer.setSingleShot(true);
        // Several files change for a single theme switch (theme.json,
        // adaptive-wallpaper.json, wallpaper). Let them all settle before
        // syncing so we do not launch multiple swaybg instances in a row.
        debounce_timer.setInterval(350);

        QObject::connect(&debounce_timer, &QTimer::timeout, [&]() {
            engine.load_config();
            if (engine.is_enabled() && engine.is_auto_sync()) {
                std::cout << "[TAW Daemon] Triggering sync...\n";
                engine.sync(false);
            }
        });

        QObject::connect(&watcher, &QFileSystemWatcher::fileChanged, [&](const QString& path) {
            std::cout << "[TAW Daemon] File changed: " << path.toStdString() << "\n";
            debounce_timer.start();

            // Re-add path if atomic rename replaced the inode
            if (!watcher.files().contains(path) && QFile::exists(path)) {
                watcher.addPath(path);
            }
        });

        // Run initial sync on launch
        if (engine.is_enabled() && engine.is_auto_sync()) {
            engine.sync(false);
        }

        return app.exec();
    }

    std::cerr << "Unknown command: " << cmd << "\n";
    print_help();
    return 1;
}

