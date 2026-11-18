#pragma once

#include <QObject>
#include <QLocalSocket>
#include <QTimer>
#include <QString>
#include <cstdint>

namespace titan::focus {

/**
 * SessionMonitor — Layer 1 Hyprland event-socket consumer.
 *
 * Connects to $XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock
 * (fallback /tmp/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock) and parses:
 *   - activewindow>><class>,<title>
 *   - workspace>><name>
 *   - focusedmon>><mon>,<ws>
 *   - idle>><0|1> (when emitted by compositor / idle notifier)
 */
class SessionMonitor : public QObject {
    Q_OBJECT

public:
    explicit SessionMonitor(QObject *parent = nullptr);
    ~SessionMonitor() override;

    void start();
    void stop();

    bool    isConnected() const { return m_socket.state() == QLocalSocket::ConnectedState; }
    bool    isIdle() const { return m_isIdle; }
    int64_t idleDurationSec(int64_t nowSec) const;
    QString activeApp() const { return m_activeApp; }
    QString activeTitle() const { return m_activeTitle; }
    int     takeSwitchDelta();

    // Test / synthetic feed helper
    void processEventLine(const QString &line, int64_t nowSec);

signals:
    void activeWindowChanged(const QString &appClass, const QString &title);
    void workspaceSwitched(const QString &workspace);
    void idleStateChanged(bool idle);

private:
    QString resolveSocketPath() const;
    void connectToHyprland();
    void onReadyRead();
    static int64_t monotonicNowSec();

    QLocalSocket m_socket;
    QTimer       m_reconnectTimer;
    QByteArray   m_buffer;

    QString m_activeApp;
    QString m_activeTitle;
    bool    m_isIdle = false;
    int64_t m_idleSinceSec = 0;
    int64_t m_lastActivitySec = 0;
    int     m_switchDelta = 0;
};

} // namespace titan::focus
