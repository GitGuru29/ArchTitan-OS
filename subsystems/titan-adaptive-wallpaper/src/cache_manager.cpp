#include "cache_manager.hpp"
#include <QCryptographicHash>
#include <QFileInfo>
#include <QDir>
#include <QDateTime>
#include <QImageReader>
#include <QUuid>
#include <cstdlib>

namespace taw {

CacheManager::CacheManager(const std::string& cache_dir) {
    if (!cache_dir.empty()) {
        m_cache_dir = cache_dir;
    } else {
        const char* xdg_cache = std::getenv("XDG_CACHE_HOME");
        if (xdg_cache && *xdg_cache) {
            m_cache_dir = std::string(xdg_cache) + "/archtitan/wallpapers";
        } else {
            const char* home = std::getenv("HOME");
            m_cache_dir = std::string(home ? home : "/tmp") + "/.cache/archtitan/wallpapers";
        }
    }
    ensure_cache_dir();
}

void CacheManager::ensure_cache_dir() const {
    QDir dir(QString::fromStdString(m_cache_dir));
    if (!dir.exists()) {
        dir.mkpath(".");
    }
}

std::string CacheManager::compute_key(const std::string& original_path,
                                      const ThemePalette& palette,
                                      const TransformOptions& options) const
{
    QCryptographicHash hasher(QCryptographicHash::Sha256);

    // 1. Source file path + size + mtime
    QFileInfo fi(QString::fromStdString(original_path));
    hasher.addData(fi.canonicalFilePath().toUtf8());
    hasher.addData(QByteArray::number(fi.size()));
    hasher.addData(QByteArray::number(fi.lastModified().toSecsSinceEpoch()));

    // 2. Palette identity and key colors
    hasher.addData(QByteArrayView(palette.id.c_str(), palette.id.size()));
    std::string acc = palette.accent.to_hex();
    hasher.addData(QByteArrayView(acc.c_str(), acc.size()));
    std::string acc2 = palette.accent2.to_hex();
    hasher.addData(QByteArrayView(acc2.c_str(), acc2.size()));
    std::string crust = palette.crust.to_hex();
    hasher.addData(QByteArrayView(crust.c_str(), crust.size()));
    std::string base = palette.base.to_hex();
    hasher.addData(QByteArrayView(base.c_str(), base.size()));
    std::string surf1 = palette.surface1.to_hex();
    hasher.addData(QByteArrayView(surf1.c_str(), surf1.size()));
    std::string txt = palette.textHigh.to_hex();
    hasher.addData(QByteArrayView(txt.c_str(), txt.size()));

    // 3. Transformation parameters
    int int_discrete = static_cast<int>(std::round(options.intensity * 100.0f));
    hasher.addData(QByteArray::number(int_discrete));
    hasher.addData(QByteArrayView(options.preserve_highlights ? "PH1" : "PH0", 3));
    hasher.addData(QByteArrayView(options.preserve_shadows ? "PS1" : "PS0", 3));
    hasher.addData(QByteArrayView(options.amoled_black_crush ? "AM1" : "AM0", 3));

    return hasher.result().toHex().toStdString();
}

std::optional<std::string> CacheManager::lookup(const std::string& original_path,
                                                const ThemePalette& palette,
                                                const TransformOptions& options) const
{
    ensure_cache_dir();
    std::string key = compute_key(original_path, palette, options);
    std::string target_path = m_cache_dir + "/" + key + ".png";

    QFileInfo fi(QString::fromStdString(target_path));
    if (fi.exists() && fi.size() > 0) {
        // A truncated PNG passes the size check but renders as a black screen.
        // Reading just the header is cheap enough for the cache-hit path.
        QImageReader reader(QString::fromStdString(target_path));
        if (reader.canRead() && reader.size().isValid() &&
            reader.size().width() > 0 && reader.size().height() > 0) {
            return target_path;
        }
    }
    return std::nullopt;
}

std::string CacheManager::save(const std::string& original_path,
                               const ThemePalette& palette,
                               const TransformOptions& options,
                               const QImage& transformed_image) const
{
    ensure_cache_dir();
    std::string key = compute_key(original_path, palette, options);
    std::string target_path = m_cache_dir + "/" + key + ".png";

    // Unique temp name: several TAW processes can miss the cache for the same
    // key at once (theme spam / slider). A timestamp-only name let them clobber
    // each other's temp file and leave no usable wallpaper behind.
    const QString target = QString::fromStdString(target_path);
    const QString tmp_path = target + ".tmp." +
                             QString::number(QDateTime::currentMSecsSinceEpoch()) +
                             "." + QUuid::createUuid().toString(QUuid::WithoutBraces);

    if (transformed_image.isNull() || !transformed_image.save(tmp_path, "PNG")) {
        QFile::remove(tmp_path);
        return {};
    }

    // rename(2) replaces the old target atomically on Linux. Never leave a
    // window where the path exists but points at a half-written image.
    if (!QFile::rename(tmp_path, target)) {
        QFile::remove(target);
        if (!QFile::rename(tmp_path, target)) {
            QFile::remove(tmp_path);
            return {};
        }
    }

    return target_path;
}

void CacheManager::clear() {
    QDir dir(QString::fromStdString(m_cache_dir));
    if (dir.exists()) {
        dir.removeRecursively();
    }
    ensure_cache_dir();
}

void CacheManager::prune(size_t max_count) {
    QDir dir(QString::fromStdString(m_cache_dir));
    if (!dir.exists()) return;

    QFileInfoList list = dir.entryInfoList(QStringList() << "*.png", QDir::Files, QDir::Time);
    if (static_cast<size_t>(list.size()) > max_count) {
        for (int i = max_count; i < list.size(); ++i) {
            QFile::remove(list[i].absoluteFilePath());
        }
    }
}

} // namespace taw
