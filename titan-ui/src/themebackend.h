#pragma once

#include <QObject>
#include <QColor>
#include <QFileSystemWatcher>
#include <QQmlEngine>

/**
 * ThemeBackend - wallpaper-adaptive accent source for the TitanUI design system.
 *
 * Reads ~/.config/archtitan/theme.json (written by titan-waybar-theme / the
 * wallpaper pipeline) and exposes the derived accent colour to QML. Watches the
 * file and re-emits on change so every QML surface recolours live when the
 * wallpaper changes. Falls back to the Catppuccin Mocha blue when no file or
 * key is present, so the UI is never colour-less.
 */
class ThemeBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QColor accent READ accent NOTIFY changed)
    Q_PROPERTY(QColor accentFg READ accentFg NOTIFY changed)
    Q_PROPERTY(bool isDark READ isDark NOTIFY changed)

public:
    explicit ThemeBackend(QObject *parent = nullptr);

    QColor accent() const { return m_accent; }
    QColor accentFg() const;
    bool isDark() const { return m_isDark; }

signals:
    void changed();

private:
    void reload();
    static QString configPath();

    QColor m_accent;
    bool m_isDark = true;
    QFileSystemWatcher m_watcher;
};
