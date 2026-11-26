#pragma once

#include <string>
#include <QImage>

namespace taw {

class WallpaperLoader {
public:
    static QImage load(const std::string& filepath);
    static bool save(const QImage& image, const std::string& filepath, const char* format = "PNG");
    static bool is_supported_image(const std::string& filepath);
};

} // namespace taw

