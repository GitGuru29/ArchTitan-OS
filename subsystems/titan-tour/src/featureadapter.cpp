#include "featureadapter.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <QProcess>
#include <QStandardPaths>

FeatureAdapter::FeatureAdapter(QObject *parent)
    : QObject(parent)
    , m_defs(builtinFeatures())
{
    m_monitor.name = QStringLiteral("default");
    m_monitor.origin = QPoint(0, 0);
    m_monitor.size = QSize(1920, 1080);
    m_monitor.focused = true;

    const QString his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    const QString xdg = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (!his.isEmpty() && !xdg.isEmpty()) {
        const QString sockDir = xdg + QStringLiteral("/hypr/") + his;
        m_hyprAvailable = QFile::exists(sockDir + QStringLiteral("/.socket.sock"));
    }

    m_pollTimer.setInterval(220);
    connect(&m_pollTimer, &QTimer::timeout, this, &FeatureAdapter::poll);

    m_fallbackTimer.setSingleShot(true);
    connect(&m_fallbackTimer, &QTimer::timeout, this, [this]() {
        if (!m_watchId.isEmpty() && !m_visible) {
            setRect(fallbackRect(), false);
            setVisible(true);
        }
    });

    if (m_hyprAvailable) {
        connectEvents();
    }
}

FeatureAdapter::~FeatureAdapter()
{
    stopWatching();
    if (m_proc) {
        m_proc->kill();
        m_proc->deleteLater();
        m_proc = nullptr;
    }
}

QList<FeatureDef> FeatureAdapter::builtinFeatures()
{
    return {
        FeatureDef{
            QStringLiteral("desktop"),
            QStringLiteral("waybar"),
            QStringLiteral("waybar"),
            {},
            {},
            QStringLiteral("dwell"),
            1000,
            QRectF(0.01, 0.006, 0.98, 0.044)
        },
        FeatureDef{
            QStringLiteral("spotlight"),
            QStringLiteral("titan-spotlight"),
            QStringLiteral("titan-spotlight"),
            {QStringLiteral("--show")},
            {QStringLiteral("--hide")},
            QStringLiteral("dwell"),
            900,
            QRectF(0.24, 0.16, 0.52, 0.44)
        },
        FeatureDef{
            QStringLiteral("workspace"),
            QStringLiteral("titan-workspace-hud"),
            QStringLiteral("titan-workspace-hud"),
            {QStringLiteral("--show")},
            {QStringLiteral("--hide")},
            QStringLiteral("dwell"),
            1000,
            QRectF(0.14, 0.08, 0.72, 0.34)
        },
        FeatureDef{
            QStringLiteral("quicksettings"),
            QStringLiteral("titan-quicksettings"),
            QStringLiteral("titan-quicksettings"),
            {QStringLiteral("--show")},
            {QStringLiteral("--hide")},
            QStringLiteral("dwell"),
            1000,
            QRectF(0.68, 0.055, 0.30, 0.88)
        },
        FeatureDef{
            QStringLiteral("media"),
            QStringLiteral("titan-media-hud"),
            QStringLiteral("titan-media-island"),
            {QStringLiteral("--show")},
            {QStringLiteral("--hide")},
            QStringLiteral("dwell"),
            900,
            QRectF(0.32, 0.045, 0.36, 0.22)
        },
        FeatureDef{
            QStringLiteral("sysmon"),
            QStringLiteral("titan-sysmon"),
            QStringLiteral("titan-sysmon"),
            {QStringLiteral("--show")},
            {QStringLiteral("--hide")},
            QStringLiteral("dwell"),
            1000,
            QRectF(0.012, 0.055, 0.26, 0.88)
        },
        FeatureDef{
            QStringLiteral("security"),
            QStringLiteral("titan-sandboxd"),
            QString(),
            {},
            {},
            QStringLiteral("none"),
            0,
            QRectF(0.16, 0.14, 0.68, 0.56)
        },
        FeatureDef{
            QStringLiteral("personalize"),
            QStringLiteral("archtitan-settings"),
            QString(),
            {},
            {},
            QStringLiteral("none"),
            0,
            QRectF(0.14, 0.12, 0.72, 0.62)
        }
    };
}

QList<LayerInfo> FeatureAdapter::parseLayers(const QByteArray &json)
{
    QList<LayerInfo> out;
    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(json, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) return out;

    const QJsonObject root = doc.object();
    for (auto it = root.begin(); it != root.end(); ++it) {
        const QString monitorName = it.key();
        const QJsonObject levels = it.value().toObject().value(QStringLiteral("levels")).toObject();
        for (auto lit = levels.begin(); lit != levels.end(); ++lit) {
            const QJsonArray arr = lit.value().toArray();
            for (const QJsonValue &v : arr) {
                const QJsonObject lo = v.toObject();
                LayerInfo info;
                info.monitor = monitorName;
                info.layerNamespace = lo.value(QStringLiteral("namespace")).toString();
                info.rect = QRect(
                    lo.value(QStringLiteral("x")).toInt(),
                    lo.value(QStringLiteral("y")).toInt(),
                    lo.value(QStringLiteral("w")).toInt(),
                    lo.value(QStringLiteral("h")).toInt());
                if (!info.layerNamespace.isEmpty() && info.rect.width() > 0 && info.rect.height() > 0) {
                    out << info;
                }
            }
        }
    }
    return out;
}

QList<MonitorInfo> FeatureAdapter::parseMonitors(const QByteArray &json)
{
    QList<MonitorInfo> out;
    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(json, &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) return out;

    for (const QJsonValue &v : doc.array()) {
        const QJsonObject mo = v.toObject();
        MonitorInfo info;
        info.name = mo.value(QStringLiteral("name")).toString();
        info.origin = QPoint(mo.value(QStringLiteral("x")).toInt(),
                             mo.value(QStringLiteral("y")).toInt());
        info.size = QSize(mo.value(QStringLiteral("width")).toInt(1920),
                          mo.value(QStringLiteral("height")).toInt(1080));
        info.focused = mo.value(QStringLiteral("focused")).toBool(false);
        out << info;
    }
    return out;
}

bool FeatureAdapter::locate(const QList<LayerInfo> &layers, const MonitorInfo &monitor,
                            const QString &ns, QRectF *out)
{
    if (ns.isEmpty() || !out) return false;

    const LayerInfo *best = nullptr;
    for (const LayerInfo &l : layers) {
        if (l.layerNamespace != ns) continue;
        if (!monitor.name.isEmpty() && l.monitor == monitor.name) {
            best = &l;
            break;
        }
        if (!best) best = &l;
    }
    if (!best) return false;

    *out = QRectF(best->rect.x() - monitor.origin.x(),
                  best->rect.y() - monitor.origin.y(),
                  best->rect.width(),
                  best->rect.height());
    return true;
}

bool FeatureAdapter::hasFeature(const QString &id) const
{
    for (const FeatureDef &d : m_defs) {
        if (d.id == id) return true;
    }
    return false;
}

FeatureDef FeatureAdapter::feature(const QString &id) const
{
    for (const FeatureDef &d : m_defs) {
        if (d.id == id) return d;
    }
    return FeatureDef{};
}

static QString findTitanBinary(const QString &binary)
{
    if (binary.isEmpty()) return QString();
    const QString sys = QStandardPaths::findExecutable(binary);
    if (!sys.isEmpty()) return sys;

    const QStringList candidates = {
        QStringLiteral("/usr/local/bin/") + binary,
        QStringLiteral("/usr/bin/") + binary,
        QDir::currentPath() + QStringLiteral("/airootfs/usr/local/bin/") + binary,
        QDir::currentPath() + QStringLiteral("/airootfs/usr/bin/") + binary
    };
    for (const QString &c : candidates) {
        if (QFileInfo::exists(c)) return c;
    }
    return QString();
}

bool FeatureAdapter::isAvailable(const QString &id) const
{
    if (m_assumeAvailable) return hasFeature(id);
    const FeatureDef d = feature(id);
    if (d.id.isEmpty()) return false;
    return !findTitanBinary(d.binary).isEmpty();
}

bool FeatureAdapter::hasMediaPlayer() const
{
    const QString playerctl = QStandardPaths::findExecutable(QStringLiteral("playerctl"));
    if (playerctl.isEmpty()) return false;
    QProcess p;
    p.start(playerctl, {QStringLiteral("-l")});
    if (!p.waitForFinished(350)) return false;
    return !QString::fromUtf8(p.readAllStandardOutput()).trimmed().isEmpty();
}

void FeatureAdapter::open(const QString &id)
{
    if (m_assumeAvailable) return;
    const FeatureDef d = feature(id);
    if (d.id.isEmpty() || d.showArgs.isEmpty()) return;

    const QString bin = findTitanBinary(d.binary);
    if (bin.isEmpty()) return;

    QProcess::startDetached(bin, d.showArgs);
}

void FeatureAdapter::close(const QString &id)
{
    if (m_assumeAvailable) return;
    const FeatureDef d = feature(id);
    if (d.id.isEmpty() || d.hideArgs.isEmpty()) return;

    const QString bin = findTitanBinary(d.binary);
    if (bin.isEmpty()) return;

    QProcess::startDetached(bin, d.hideArgs);
}

void FeatureAdapter::closeAll()
{
    if (m_assumeAvailable) return;
    for (const FeatureDef &d : m_defs) {
        if (!d.hideArgs.isEmpty()) {
            const QString bin = findTitanBinary(d.binary);
            if (!bin.isEmpty()) {
                QProcess::startDetached(bin, d.hideArgs);
            }
        }
    }
}

QRectF FeatureAdapter::fallbackRect() const
{
    const FeatureDef d = feature(m_watchId);
    const QRectF f = d.fallback.isValid() ? d.fallback : QRectF(0.25, 0.20, 0.50, 0.45);
    const double w = m_screen.width() > 0 ? m_screen.width() : 1920.0;
    const double h = m_screen.height() > 0 ? m_screen.height() : 1080.0;
    return QRectF(f.x() * w, f.y() * h, f.width() * w, f.height() * h);
}

void FeatureAdapter::watch(const QString &id, const QSize &screen)
{
    stopWatching();
    m_watchId = id;
    if (screen.width() > 0 && screen.height() > 0) {
        m_screen = screen;
    }

    m_everVisible = false;
    m_lastVisibleMs = 0;
    setTried(false);
    setRect(fallbackRect(), false);

    const FeatureDef d = feature(id);
    if (d.layerNamespace.isEmpty()) {
        setVisible(true);
        return;
    }

    // Immediate optimistic fallback so the spotlight frame animates smoothly right away,
    // then snaps to live compositor coordinates if hyprctl responds.
    if (m_assumeAvailable || !m_hyprAvailable) {
        setVisible(true);
        return;
    }
    m_fallbackTimer.start(120);
    poll();
    m_pollTimer.start();
}

void FeatureAdapter::stopWatching()
{
    m_pollTimer.stop();
    m_fallbackTimer.stop();
    if (m_proc) {
        m_proc->disconnect(this);
        m_proc->kill();
        m_proc->waitForFinished(80);
        m_proc->deleteLater();
        m_proc = nullptr;
    }
    m_watchId.clear();
    setVisible(false);
}

void FeatureAdapter::applyMonitors(const QList<MonitorInfo> &monitors)
{
    if (monitors.isEmpty()) return;
    for (const MonitorInfo &m : monitors) {
        if (m.focused) {
            m_monitor = m;
            m_monitorKnown = true;
            return;
        }
    }
    m_monitor = monitors.first();
    m_monitorKnown = true;
}

void FeatureAdapter::applyLayerSnapshot(const QList<LayerInfo> &layers)
{
    if (m_watchId.isEmpty()) return;
    const FeatureDef d = feature(m_watchId);
    if (d.layerNamespace.isEmpty()) return;

    const bool wasVisible = m_visible;
    QRectF found;
    if (locate(layers, m_monitor, d.layerNamespace, &found)) {
        // Guard against full-screen scrim layers: if a layer fills >92% of the screen
        // (e.g. titan-spotlight's backdrop window), use the centered card fallback rect
        // for the spotlight cutout while still marking the live surface as visible.
        const double screenArea = double(m_screen.width()) * double(m_screen.height());
        const double layerArea = found.width() * found.height();
        if (screenArea > 0 && (layerArea / screenArea) > 0.90) {
            setRect(fallbackRect(), true);
        } else {
            setRect(found, true);
        }
        setVisible(true);
    } else {
        if (m_everVisible) {
            setVisible(false);
        }
    }
    evaluateTried(wasVisible);
}

void FeatureAdapter::notifyWorkspaceActivity()
{
    if (m_watchId == QLatin1String("workspace")) {
        setTried(true);
    }
}

void FeatureAdapter::poll()
{
    if (m_watchId.isEmpty() || !m_hyprAvailable || m_proc) return;
    const QString hyprctl = QStandardPaths::findExecutable(QStringLiteral("hyprctl"));
    if (hyprctl.isEmpty()) return;

    m_proc = new QProcess(this);
    connect(m_proc, qOverload<int, QProcess::ExitStatus>(&QProcess::finished),
            this, [this](int code, QProcess::ExitStatus status) {
        const QByteArray out = (code == 0 && status == QProcess::NormalExit && m_proc)
            ? m_proc->readAllStandardOutput()
            : QByteArray();
        if (m_proc) {
            m_proc->deleteLater();
            m_proc = nullptr;
        }
        if (!out.isEmpty()) finishPoll(out);
    });
    m_proc->start(hyprctl, {QStringLiteral("layers"), QStringLiteral("-j")});
}

void FeatureAdapter::finishPoll(const QByteArray &out)
{
    applyLayerSnapshot(parseLayers(out));
}

void FeatureAdapter::setVisible(bool v)
{
    if (m_visible == v) {
        if (v && m_visibleFor.isValid()) {
            m_lastVisibleMs = m_visibleFor.elapsed();
        }
        return;
    }
    if (!v && m_visible && m_visibleFor.isValid()) {
        m_lastVisibleMs = m_visibleFor.elapsed();
    }
    m_visible = v;
    if (v) {
        m_everVisible = true;
        m_visibleFor.restart();
    }
    emit visibleChanged();
}

void FeatureAdapter::setRect(const QRectF &r, bool live)
{
    if (m_rect == r && m_geometryLive == live) return;
    m_rect = r;
    m_geometryLive = live;
    emit rectChanged();
}

void FeatureAdapter::setTried(bool t)
{
    if (m_tried == t) return;
    m_tried = t;
    emit triedChanged();
}

void FeatureAdapter::evaluateTried(bool wasVisible)
{
    if (m_tried || m_watchId.isEmpty()) return;
    const FeatureDef d = feature(m_watchId);

    if (d.tryMode == QLatin1String("close")) {
        if (wasVisible && !m_visible && m_lastVisibleMs >= 200) {
            setTried(true);
        }
    } else if (d.tryMode == QLatin1String("dwell")) {
        const qint64 elapsed = m_visible && m_visibleFor.isValid()
            ? m_visibleFor.elapsed()
            : m_lastVisibleMs;
        if (m_everVisible && elapsed >= d.tryDwellMs) {
            setTried(true);
        }
    }
}

void FeatureAdapter::connectEvents()
{
    const QString his = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    const QString xdg = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (his.isEmpty() || xdg.isEmpty()) return;

    const QString sock2 = xdg + QStringLiteral("/hypr/") + his + QStringLiteral("/.socket2.sock");
    if (!QFile::exists(sock2)) return;

    m_events = new QLocalSocket(this);
    connect(m_events, &QLocalSocket::readyRead, this, [this]() {
        m_eventBuf.append(m_events->readAll());
        int nl = -1;
        while ((nl = m_eventBuf.indexOf('\n')) != -1) {
            const QByteArray line = m_eventBuf.left(nl);
            m_eventBuf.remove(0, nl + 1);
            if (line.startsWith("workspace>>") || line.startsWith("movewindow>>") ||
                line.startsWith("activewindow>>")) {
                notifyWorkspaceActivity();
            }
        }
    });
    m_events->connectToServer(sock2, QIODevice::ReadOnly);
}
