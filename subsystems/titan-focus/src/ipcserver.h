#pragma once

#include <QObject>
#include <QLocalServer>
#include <QString>
#include <functional>

namespace titan::focus {

/**
 * IpcServer — QLocalServer at $XDG_RUNTIME_DIR/titan-focus.sock.
 *
 * Supports request/reply verbs:
 *   TOGGLE, SHOW, HIDE, SNOOZE <mins>, BREAK <mins>, END_BREAK,
 *   DISMISS, DND <on|off|toggle>, STATUS, WAYBAR, RESET
 */
class IpcServer : public QObject {
    Q_OBJECT

public:
    using CommandHandler = std::function<QString(const QString &cmd)>;

    explicit IpcServer(QObject *parent = nullptr);
    ~IpcServer() override;

    static QString socketPath();
    static bool sendCommand(const QString &command, QString *replyOut = nullptr, int timeoutMs = 400);

    bool startServer();
    void setHandler(CommandHandler handler) { m_handler = std::move(handler); }

private slots:
    void onNewConnection();

private:
    QLocalServer   m_server;
    CommandHandler m_handler;
};

} // namespace titan::focus
