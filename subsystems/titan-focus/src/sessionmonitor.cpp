#include "sessionmonitor.h"

#include <QFileInfo>
#include <QProcessEnvironment>
#include <chrono>

namespace titan::focus {

SessionMonitor::SessionMonitor(QObject *parent)
    : QObject(parent) {
    m_lastActivitySec = monotonicNowSec();

    connect(&m_socket, &QLocalSocket::readyRead, this, &SessionMonitor::onReadyRead);
    connect(&m_socket, &QLocalSocket::disconnected, this, [this]() {
        m_reconnectTimer.start(5000);
    });
    connect(&m_socket, &QLocalSocket::errorOccurred, this, [this](QLocalSocket::LocalSocketError) {
        if (!m_reconnectTimer.isActive()) {
            m_reconnectTimer.start(5000);
        }
    });

    m_reconnectTimer.setSingleShot(true);
    connect(&m_reconnectTimer, &QTimer::timeout, this, &SessionMonitor::connectToHyprland);
}

SessionMonitor::~SessionMonitor() {
    stop();
}

int64_t SessionMonitor::monotonicNowSec() {
    using namespace std::chrono;
    return duration_cast<seconds>(steady_clock::now().time_since_epoch()).count();
}

QString SessionMonitor::resolveSocketPath() const {
    const auto env = QProcessEnvironment::systemEnvironment();
    const QString sig = env.value(QStringLiteral("HYPRLAND_INSTANCE_SIGNATURE"));
    if (sig.isEmpty()) return QString();

    const QString runtimeDir = env.value(QStringLiteral("XDG_RUNTIME_DIR"));
    if (!runtimeDir.isEmpty()) {
        const QString p = runtimeDir + QStringLiteral("/hypr/") + sig + QStringLiteral("/.socket2.sock");
        if (QFileInfo::exists(p)) return p;
    }
    const QString fallback = QStringLiteral("/tmp/hypr/") + sig + QStringLiteral("/.socket2.sock");
    if (QFileInfo::exists(fallback)) return fallback;
    return QString();
}

void SessionMonitor::start() {
    connectToHyprland();
}

void SessionMonitor::stop() {
    m_reconnectTimer.stop();
    if (m_socket.state() != QLocalSocket::UnconnectedState) {
        m_socket.abort();
    }
}

void SessionMonitor::connectToHyprland() {
    if (m_socket.state() == QLocalSocket::ConnectedState ||
        m_socket.state() == QLocalSocket::ConnectingState) {
        return;
    }
    const QString path = resolveSocketPath();
    if (path.isEmpty()) {
        m_reconnectTimer.start(5000);
        return;
    }
    m_socket.connectToServer(path, QIODevice::ReadOnly);
}

void SessionMonitor::onReadyRead() {
    m_buffer.append(m_socket.readAll());
    const int64_t now = monotonicNowSec();

    while (true) {
        const int nl = m_buffer.indexOf('\n');
        if (nl < 0) break;
        const QString line = QString::fromUtf8(m_buffer.left(nl)).trimmed();
        m_buffer.remove(0, nl + 1);
        if (!line.isEmpty()) {
            processEventLine(line, now);
        }
    }
}

void SessionMonitor::processEventLine(const QString &line, int64_t nowSec) {
    const int sep = line.indexOf(QLatin1String(">>"));
    if (sep <= 0) return;

    const QString event = line.left(sep);
    const QString data  = line.mid(sep + 2);

    if (event == QLatin1String("idle")) {
        const bool nowIdle = (data == QLatin1String("1") || data.compare(QLatin1String("true"), Qt::CaseInsensitive) == 0);
        if (nowIdle != m_isIdle) {
            m_isIdle = nowIdle;
            if (nowIdle) {
                m_idleSinceSec = nowSec;
            } else {
                m_lastActivitySec = nowSec;
                m_idleSinceSec = 0;
            }
            emit idleStateChanged(m_isIdle);
        }
        return;
    }

    // Any window or workspace activity indicates the user is active.
    if (event == QLatin1String("activewindow")) {
        m_lastActivitySec = nowSec;
        if (m_isIdle) {
            m_isIdle = false;
            m_idleSinceSec = 0;
            emit idleStateChanged(false);
        }
        const int comma = data.indexOf(QLatin1Char(','));
        const QString app = (comma >= 0) ? data.left(comma).trimmed() : data.trimmed();
        const QString title = (comma >= 0) ? data.mid(comma + 1).trimmed() : QString();
        if (app != m_activeApp || title != m_activeTitle) {
            if (!m_activeApp.isEmpty() && app != m_activeApp) {
                m_switchDelta++;
            }
            m_activeApp = app;
            m_activeTitle = title;
            emit activeWindowChanged(m_activeApp, m_activeTitle);
        }
    } else if (event == QLatin1String("workspace") || event == QLatin1String("workspacev2")) {
        m_lastActivitySec = nowSec;
        if (m_isIdle) {
            m_isIdle = false;
            m_idleSinceSec = 0;
            emit idleStateChanged(false);
        }
        m_switchDelta++;
        emit workspaceSwitched(data);
    } else if (event == QLatin1String("focusedmon") || event == QLatin1String("openwindow") || event == QLatin1String("closewindow")) {
        m_lastActivitySec = nowSec;
        if (m_isIdle) {
            m_isIdle = false;
            m_idleSinceSec = 0;
            emit idleStateChanged(false);
        }
    }
}

int64_t SessionMonitor::idleDurationSec(int64_t nowSec) const {
    if (m_isIdle && m_idleSinceSec > 0 && nowSec >= m_idleSinceSec) {
        return nowSec - m_idleSinceSec;
    }
    return 0;
}

int SessionMonitor::takeSwitchDelta() {
    const int d = m_switchDelta;
    m_switchDelta = 0;
    return d;
}

} // namespace titan::focus
