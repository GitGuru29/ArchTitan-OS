#pragma once

#include "theme_palette.hpp"
#include "color_transformer.hpp"
#include <string>
#include <optional>
#include <QImage>

namespace taw {

class CacheManager {
public:
    explicit CacheManager(const std::string& cache_dir = "");

    std::string cache_dir() const { return m_cache_dir; }

    // Generates a deterministic unique key based on image metadata + theme + intensity
    std::string compute_key(const std::string& original_path,
                            const ThemePalette& palette,
                            const TransformOptions& options) const;

    // Returns path to cached file if it exists and is valid
    std::optional<std::string> lookup(const std::string& original_path,
                                      const ThemePalette& palette,
                                      const TransformOptions& options) const;

    // Saves transformed image to cache
    std::string save(const std::string& original_path,
                     const ThemePalette& palette,
                     const TransformOptions& options,
                     const QImage& transformed_image) const;

    // Clear all cached wallpapers
    void clear();

    // Prune oldest files if cache exceeds max_count
    void prune(size_t max_count = 64);

private:
    std::string m_cache_dir;

    void ensure_cache_dir() const;
};

} // namespace taw

