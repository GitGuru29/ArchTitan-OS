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
 * Performance-first architecture:
 * All derived colors (alphas, semantic background roles, glass depths, hover/press
 * states, and borders) are precalculated in C++ once on reload, eliminating
 * repetitive runtime JavaScript Qt.rgba() evaluations in QML bindings.
 */
class ThemeBackend : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Identity & mode
    Q_PROPERTY(QString id READ id NOTIFY changed)
    Q_PROPERTY(QString name READ name NOTIFY changed)
    Q_PROPERTY(bool isDark READ isDark NOTIFY changed)

    // Primary & adaptive accents
    Q_PROPERTY(QColor accent READ accent NOTIFY changed)
    Q_PROPERTY(QColor accentFg READ accentFg NOTIFY changed)
    Q_PROPERTY(QColor accent2 READ accent2 NOTIFY changed)
    Q_PROPERTY(QColor accentSoft READ accentSoft NOTIFY changed)
    Q_PROPERTY(QColor accentSofter READ accentSofter NOTIFY changed)
    Q_PROPERTY(QColor accentEdge READ accentEdge NOTIFY changed)
    Q_PROPERTY(QColor accentHover READ accentHover NOTIFY changed)
    Q_PROPERTY(QColor accentPressed READ accentPressed NOTIFY changed)

    // Base surfaces (Catppuccin compatible)
    Q_PROPERTY(QColor crust READ crust NOTIFY changed)
    Q_PROPERTY(QColor mantle READ mantle NOTIFY changed)
    Q_PROPERTY(QColor base READ base NOTIFY changed)
    Q_PROPERTY(QColor surface0 READ surface0 NOTIFY changed)
    Q_PROPERTY(QColor surface1 READ surface1 NOTIFY changed)
    Q_PROPERTY(QColor surface2 READ surface2 NOTIFY changed)
    Q_PROPERTY(QColor surface3 READ surface3 NOTIFY changed)

    // Precomputed semantic background roles
    Q_PROPERTY(QColor bg0 READ bg0 NOTIFY changed)
    Q_PROPERTY(QColor bg1 READ bg1 NOTIFY changed)
    Q_PROPERTY(QColor bg2 READ bg2 NOTIFY changed)
    Q_PROPERTY(QColor bg3 READ bg3 NOTIFY changed)
    Q_PROPERTY(QColor bg4 READ bg4 NOTIFY changed)
    Q_PROPERTY(QColor bgInset READ bgInset NOTIFY changed)

    // Glass & overlays
    Q_PROPERTY(qreal glassOpacity READ glassOpacity NOTIFY changed)
    Q_PROPERTY(qreal glassFactor READ glassFactor NOTIFY changed)
    Q_PROPERTY(QColor glass READ glass NOTIFY changed)
    Q_PROPERTY(QColor glassAlt READ glassAlt NOTIFY changed)
    Q_PROPERTY(QColor glassCard READ glassCard NOTIFY changed)

    // Borders
    Q_PROPERTY(QColor border READ border NOTIFY changed)
    Q_PROPERTY(QColor borderSubtle READ borderSubtle NOTIFY changed)
    Q_PROPERTY(QColor borderHover READ borderHover NOTIFY changed)
    Q_PROPERTY(QColor borderStrong READ borderStrong NOTIFY changed)

    // Text & status
    Q_PROPERTY(QColor textHigh READ textHigh NOTIFY changed)
    Q_PROPERTY(QColor textMid READ textMid NOTIFY changed)
    Q_PROPERTY(QColor textLow READ textLow NOTIFY changed)
    Q_PROPERTY(QColor success READ success NOTIFY changed)
    Q_PROPERTY(QColor warning READ warning NOTIFY changed)
    Q_PROPERTY(QColor danger READ danger NOTIFY changed)
    Q_PROPERTY(QColor dangerHover READ dangerHover NOTIFY changed)
    Q_PROPERTY(QColor dangerPressed READ dangerPressed NOTIFY changed)
    Q_PROPERTY(QColor info READ info NOTIFY changed)
    Q_PROPERTY(QColor teal READ teal NOTIFY changed)
    Q_PROPERTY(QColor mauve READ mauve NOTIFY changed)
    Q_PROPERTY(QColor peach READ peach NOTIFY changed)
    Q_PROPERTY(QColor pink READ pink NOTIFY changed)

    // Interaction states
    Q_PROPERTY(QColor stateHover READ stateHover NOTIFY changed)
    Q_PROPERTY(QColor statePressed READ statePressed NOTIFY changed)
    Q_PROPERTY(QColor stateSelected READ stateSelected NOTIFY changed)
    Q_PROPERTY(QColor focusRing READ focusRing NOTIFY changed)
    Q_PROPERTY(QColor scrim READ scrim NOTIFY changed)

public:
    explicit ThemeBackend(QObject *parent = nullptr);

    // Getters
    QString id() const { return m_id; }
    QString name() const { return m_name; }
    bool isDark() const { return m_isDark; }
    qreal glassOpacity() const { return m_glassOpacity; }
    qreal glassFactor() const { return m_glassOpacity / 0.35; }

    QColor accent() const { return color("accent"); }
    QColor accentFg() const { return m_accentFg; }
    QColor accent2() const { return color("accent2"); }
    QColor accentSoft() const { return m_accentSoft; }
    QColor accentSofter() const { return m_accentSofter; }
    QColor accentEdge() const { return m_accentEdge; }
    QColor accentHover() const { return m_accentHover; }
    QColor accentPressed() const { return m_accentPressed; }

    QColor crust() const { return color("crust"); }
    QColor mantle() const { return color("mantle"); }
    QColor base() const { return color("base"); }
    QColor surface0() const { return color("surface0"); }
    QColor surface1() const { return color("surface1"); }
    QColor surface2() const { return color("surface2"); }
    QColor surface3() const { return color("surface3"); }

    QColor bg0() const { return m_bg0; }
    QColor bg1() const { return m_bg1; }
    QColor bg2() const { return m_bg2; }
    QColor bg3() const { return m_bg3; }
    QColor bg4() const { return m_bg4; }
    QColor bgInset() const { return m_bgInset; }

    QColor glass() const { return m_glass; }
    QColor glassAlt() const { return m_glassAlt; }
    QColor glassCard() const { return m_glassCard; }

    QColor border() const { return m_border; }
    QColor borderSubtle() const { return m_borderSubtle; }
    QColor borderHover() const { return m_borderHover; }
    QColor borderStrong() const { return m_borderStrong; }

    QColor textHigh() const { return color("textHigh"); }
    QColor textMid() const { return color("textMid"); }
    QColor textLow() const { return color("textLow"); }
    QColor success() const { return color("success"); }
    QColor warning() const { return color("warning"); }
    QColor danger() const { return color("danger"); }
    QColor dangerHover() const { return m_dangerHover; }
    QColor dangerPressed() const { return m_dangerPressed; }
    QColor info() const { return color("info", m_pal.value("accent")); }
    QColor teal() const { return color("teal"); }
    QColor mauve() const { return color("mauve"); }
    QColor peach() const { return color("peach"); }
    QColor pink() const { return color("pink"); }

    QColor stateHover() const { return m_stateHover; }
    QColor statePressed() const { return m_statePressed; }
    QColor stateSelected() const { return m_stateSelected; }
    QColor focusRing() const { return m_focusRing; }
    QColor scrim() const { return m_scrim; }

    // Fast C++ math & contrast helpers callable from QML
    Q_INVOKABLE qreal contrastRatio(const QColor &fg, const QColor &bg) const;
    Q_INVOKABLE QColor alphaColor(const QColor &base, qreal a) const;
    Q_INVOKABLE QColor lighterColor(const QColor &base, qreal factor = 1.08) const;
    Q_INVOKABLE QColor darkerColor(const QColor &base, qreal factor = 1.10) const;
    Q_INVOKABLE bool isAccessible(const QColor &fg, const QColor &bg, qreal minRatio = 4.5) const;

signals:
    void changed();

private:
    void reload();
    void computeDerivedColors();
    static QString configPath();
    QColor computeAccentFg(const QColor &accentColor) const;

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

    // Precomputed cached colors
    QColor m_accentFg;
    QColor m_accentSoft;
    QColor m_accentSofter;
    QColor m_accentEdge;
    QColor m_accentHover;
    QColor m_accentPressed;
    QColor m_dangerHover;
    QColor m_dangerPressed;

    QColor m_bg0;
    QColor m_bg1;
    QColor m_bg2;
    QColor m_bg3;
    QColor m_bg4;
    QColor m_bgInset;

    QColor m_glass;
    QColor m_glassAlt;
    QColor m_glassCard;

    QColor m_border;
    QColor m_borderSubtle;
    QColor m_borderHover;
    QColor m_borderStrong;

    QColor m_stateHover;
    QColor m_statePressed;
    QColor m_stateSelected;
    QColor m_focusRing;
    QColor m_scrim;
};
