#include "wallpaper_loader.hpp"
#include <QFileInfo>
#include <QImageReader>

namespace taw {

QImage WallpaperLoader::load(const std::string& filepath) {
    QImage img(QString::fromStdString(filepath));
    if (img.isNull()) {
        return QImage();
    }
    return img;
}

bool WallpaperLoader::save(const QImage& image, const std::string& filepath, const char* format) {
    if (image.isNull()) return false;
    return image.save(QString::fromStdString(filepath), format);
}

bool WallpaperLoader::is_supported_image(const std::string& filepath) {
    QFileInfo fi(QString::fromStdString(filepath));
    if (!fi.exists() || !fi.isFile()) return false;
    QString ext = fi.suffix().toLower();
    return (ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "webp" || ext == "bmp");
}

} // namespace taw

