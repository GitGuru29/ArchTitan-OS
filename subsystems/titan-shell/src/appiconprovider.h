#pragma once

#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>
#include <QFile>
#include <QFileInfo>
#include <QDir>

class AppIconProvider : public QQuickImageProvider
{
public:
    AppIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        int targetW = requestedSize.width() > 0 ? requestedSize.width() : 48;
        int targetH = requestedSize.height() > 0 ? requestedSize.height() : 48;

        if (id.startsWith(QLatin1Char('/')) && QFile::exists(id)) {
            QPixmap pix(id);
            if (!pix.isNull()) {
                QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                if (size) *size = scaled.size();
                return scaled;
            }
        }

        QString name = id.toLower();
        QStringList candidates = {
            name,
            name.remove(QStringLiteral("-ide")),
            name.remove(QStringLiteral("org.kde.")),
            name.remove(QStringLiteral("google-")),
            name.split(QLatin1Char('-')).first(),
            name.split(QLatin1Char('.')).last()
        };

        if (id.contains(QStringLiteral("chrome"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("google-chrome"));
        if (id.contains(QStringLiteral("antigravity"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("antigravity-ide"));
        if (id.contains(QStringLiteral("kitty"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("kitty"));
        if (id.contains(QStringLiteral("code"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("code"));
        if (id.contains(QStringLiteral("firefox"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("firefox"));
        if (id.contains(QStringLiteral("terminal"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("utilities-terminal"));
        if (id.contains(QStringLiteral("settings"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("preferences-system"));
        if (id.contains(QStringLiteral("calculator"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("accessories-calculator"));

        for (const QString &cand : candidates) {
            if (QIcon::hasThemeIcon(cand)) {
                QIcon icon = QIcon::fromTheme(cand);
                QPixmap pix = icon.pixmap(targetW, targetH);
                if (!pix.isNull()) {
                    if (size) *size = pix.size();
                    return pix;
                }
            }
        }

        static const QStringList baseDirs = {
            QStringLiteral("/usr/share/icons/hicolor/scalable/apps/"),
            QStringLiteral("/usr/share/icons/hicolor/48x48/apps/"),
            QStringLiteral("/usr/share/icons/Papirus/48x48/apps/"),
            QStringLiteral("/usr/share/pixmaps/")
        };

        for (const QString &cand : candidates) {
            for (const QString &dir : baseDirs) {
                QString png = dir + cand + QStringLiteral(".png");
                if (QFile::exists(png)) {
                    QPixmap pix(png);
                    if (!pix.isNull()) {
                        QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                        if (size) *size = scaled.size();
                        return scaled;
                    }
                }
                QString svg = dir + cand + QStringLiteral(".svg");
                if (QFile::exists(svg)) {
                    QPixmap pix(svg);
                    if (!pix.isNull()) {
                        QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                        if (size) *size = scaled.size();
                        return scaled;
                    }
                }
            }
        }

        QPixmap fallback(targetW, targetH);
        fallback.fill(Qt::transparent);
        if (size) *size = fallback.size();
        return fallback;
    }
};
