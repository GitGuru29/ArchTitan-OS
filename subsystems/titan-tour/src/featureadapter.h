#pragma once

#include <QElapsedTimer>
#include <QList>
#include <QObject>
#include <QPoint>
#include <QRect>
#include <QRectF>
#include <QSize>
#include <QString>
#include <QStringList>
#include <QTimer>

class QLocalSocket;
class QProcess;

/// Static description of one real ArchTitan feature the tour can drive.
struct FeatureDef
{
    QString id;               ///< tour feature id ("spotlight", "quicksettings", …)
    QString binary;           ///< executable that owns the overlay
    QString layerNamespace;   ///< Wayland layer-shell namespace (empty: not a layer overlay)
    QStringList showArgs;     ///< idempotent "show" command line (never --toggle)
    QStringList hideArgs;     ///< idempotent "hide" command line
    QString tryMode;          ///< "close" | "dwell" | "event" | "none"
    int tryDwellMs{0};        ///< dwell threshold for tryMode == "dwell"
    QRectF fallback;          ///< fractional screen rect used when geometry can't be read
};

/// One mapped layer-shell surface as reported by `hyprctl layers -j`.
struct LayerInfo
{
    QString monitor;
    QString layerNamespace;
    QRect rect;               ///< compositor-global coordinates
};

struct MonitorInfo
{
    QString name;
    QPoint origin;
    QSize size;
    bool focused{false};
};

/**
 * FeatureAdapter — one reusable seam between the tour and the *real* OS
 * components (Spotlight, Workspace HUD, QuickSettings, Media HUD, Sysmon).
 *
 * For each feature it exposes: availability, launch, state (visible + live
 * geometry), close, and interaction detection ("the user tried it"). It only
 * ever uses the idempotent `--show` / `--hide` interfaces, never `--toggle`,
 * so it cannot flip an overlay that is already open into the wrong state.
 */
class FeatureAdapter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool visible READ visible NOTIFY visibleChanged)
    Q_PROPERTY(QRectF rect READ rect NOTIFY rectChanged)
    Q_PROPERTY(bool tried READ tried NOTIFY triedChanged)
    Q_PROPERTY(bool geometryLive READ geometryLive NOTIFY rectChanged)

public:
    explicit FeatureAdapter(QObject *parent = nullptr);
    ~FeatureAdapter() override;

    static QList<FeatureDef> builtinFeatures();
    static QList<LayerInfo> parseLayers(const QByteArray &json);
    static QList<MonitorInfo> parseMonitors(const QByteArray &json);
    /// Picks the surface for `ns` on `monitor` and returns it relative to the monitor origin.
    static bool locate(const QList<LayerInfo> &layers, const MonitorInfo &monitor,
                       const QString &ns, QRectF *out);

    /// Forces every feature to report available (offscreen previews, tests).
    void setAssumeAvailable(bool on) { m_assumeAvailable = on; }
    bool hasFeature(const QString &id) const;
    FeatureDef feature(const QString &id) const;

    Q_INVOKABLE bool isAvailable(const QString &id) const;
    Q_INVOKABLE bool hasMediaPlayer() const;

    Q_INVOKABLE void open(const QString &id);
    Q_INVOKABLE void close(const QString &id);
    Q_INVOKABLE void closeAll();

    /// Starts tracking visibility/geometry/interaction for `id` on a screen of `screen` px.
    Q_INVOKABLE void watch(const QString &id, const QSize &screen);
    Q_INVOKABLE void stopWatching();

    bool visible() const { return m_visible; }
    QRectF rect() const { return m_rect; }
    bool tried() const { return m_tried; }
    bool geometryLive() const { return m_geometryLive; }

    /// Test seam: feeds one poll result in without spawning hyprctl.
    void applyLayerSnapshot(const QList<LayerInfo> &layers);
    void applyMonitors(const QList<MonitorInfo> &monitors);
    void notifyWorkspaceActivity();

signals:
    void visibleChanged();
    void rectChanged();
    void triedChanged();

private:
    void poll();
    void finishPoll(const QByteArray &out);
    void setVisible(bool v);
    void setRect(const QRectF &r, bool live);
    void setTried(bool t);
    void evaluateTried(bool wasVisible);
    void connectEvents();
    QRectF fallbackRect() const;

    QList<FeatureDef> m_defs;
    bool m_assumeAvailable{false};

    QString m_watchId;
    QSize m_screen{1920, 1080};
    MonitorInfo m_monitor;
    bool m_monitorKnown{false};
    bool m_hyprAvailable{false};

    bool m_visible{false};
    bool m_everVisible{false};
    bool m_tried{false};
    bool m_geometryLive{false};
    QRectF m_rect;
    QElapsedTimer m_visibleFor;
    qint64 m_lastVisibleMs{0};

    QTimer m_pollTimer;
    QTimer m_fallbackTimer;
    QProcess *m_proc{nullptr};
    QLocalSocket *m_events{nullptr};
    QByteArray m_eventBuf;
};

