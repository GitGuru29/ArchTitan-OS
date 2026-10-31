#pragma once

#include <QObject>
#include <QColor>
#include <QFileSystemWatcher>
#include <QHash>
#include <QQmlEngine>

/**
 * ThemeBackend — the runtime palette behind the TitanUI design system.
 *
 * Reads ~/.config/archtitan/theme.json (written by `titan-theme`) and exposes
 * the active theme's identity, mode, accent and full surface/status palette
 * to QML. The file is watched; any change re-emits `changed`, so every QML
 * surface recolours live when the theme or accent changes.
 *
 * Every key falls back to the canonical Catppuccin Mocha definition
 * (usr/share/archtitan/themes/mocha.json), so a missing or partial file
 * never leaves the UI colour-less. `info` is derived from the accent unless a
 * theme explicitly overrides it.
 */
class ThemeBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QString id READ id NOTIFY changed)
    Q_PROPERTY(QString name READ name NOTIFY changed)
    Q_PROPERTY(bool isDark READ isDark NOTIFY changed)
    Q_PROPERTY(QColor accent READ accent NOTIFY changed)
    Q_PROPERTY(QColor accentFg READ accentFg NOTIFY changed)
    Q_PROPERTY(QColor accent2 READ accent2 NOTIFY changed)
    Q_PROPERTY(QColor crust READ crust NOTIFY changed)
    Q_PROPERTY(QColor mantle READ mantle NOTIFY changed)
    Q_PROPERTY(QColor base READ base NOTIFY changed)
    Q_PROPERTY(QColor surface0 READ surface0 NOTIFY changed)
    Q_PROPERTY(QColor surface1 READ surface1 NOTIFY changed)
    Q_PROPERTY(QColor surface2 READ surface2 NOTIFY changed)
    Q_PROPERTY(QColor surface3 READ surface3 NOTIFY changed)
    Q_PROPERTY(QColor border READ border NOTIFY changed)
    Q_PROPERTY(QColor textHigh READ textHigh NOTIFY changed)
    Q_PROPERTY(QColor textMid READ textMid NOTIFY changed)
    Q_PROPERTY(QColor textLow READ textLow NOTIFY changed)
    Q_PROPERTY(QColor success READ success NOTIFY changed)
    Q_PROPERTY(QColor warning READ warning NOTIFY changed)
    Q_PROPERTY(QColor danger READ danger NOTIFY changed)
    Q_PROPERTY(QColor info READ info NOTIFY changed)
    Q_PROPERTY(QColor teal READ teal NOTIFY changed)
    Q_PROPERTY(QColor mauve READ mauve NOTIFY changed)
    Q_PROPERTY(QColor peach READ peach NOTIFY changed)
    Q_PROPERTY(QColor pink READ pink NOTIFY changed)
    Q_PROPERTY(qreal glassOpacity READ glassOpacity NOTIFY changed)
    Q_PROPERTY(qreal glassFactor READ glassFactor NOTIFY changed)

public:
    explicit ThemeBackend(QObject *parent = nullptr);

    QString id() const { return m_id; }
    QString name() const { return m_name; }
    bool isDark() const { return m_isDark; }
    qreal glassOpacity() const { return m_glassOpacity; }
    qreal glassFactor() const { return m_glassOpacity / 0.35; }
    QColor accent() const { return color("accent"); }
    QColor accentFg() const;
    QColor accent2() const { return color("accent2"); }
    QColor crust() const { return color("crust"); }
    QColor mantle() const { return color("mantle"); }
    QColor base() const { return color("base"); }
    QColor surface0() const { return color("surface0"); }
    QColor surface1() const { return color("surface1"); }
    QColor surface2() const { return color("surface2"); }
    QColor surface3() const { return color("surface3"); }
    QColor border() const { return color("border"); }
    QColor textHigh() const { return color("textHigh"); }
    QColor textMid() const { return color("textMid"); }
    QColor textLow() const { return color("textLow"); }
    QColor success() const { return color("success"); }
    QColor warning() const { return color("warning"); }
    QColor danger() const { return color("danger"); }
    QColor info() const { return color("info", m_pal.value("accent")); }
    QColor teal() const { return color("teal"); }
    QColor mauve() const { return color("mauve"); }
    QColor peach() const { return color("peach"); }
    QColor pink() const { return color("pink"); }

signals:
    void changed();

private:
    void reload();
    static QString configPath();
    QColor color(const char *key) const
    {
        return m_pal.value(QLatin1String(key));
    }
    QColor color(const char *key, const QColor &fallback) const
    {
        return m_pal.value(QLatin1String(key), fallback);
    }

    QHash<QString, QColor> m_pal; // merged Mocha defaults + theme.json palette
    QString m_id = QStringLiteral("mocha");
    QString m_name = QStringLiteral("Catppuccin Mocha");
    bool m_isDark = true;
    qreal m_glassOpacity = 0.35;
    QFileSystemWatcher m_watcher;
};
