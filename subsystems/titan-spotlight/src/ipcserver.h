#pragma once

#include <QLocalServer>
#include <QObject>

/**
 * IpcServer — Single-instance command channel for titan-spotlight.
 *
 * Accepts one-shot text commands ("TOGGLE", "SHOW", "HIDE", "CLIPBOARD")
 * on $XDG_RUNTIME_DIR/titan-spotlight.sock. When the daemon is already running,
 * calling `titan-spotlight --toggle` sends a message to the socket and returns
 * immediately, achieving instant 0ms launch response when the user taps Super.
 */
class IpcServer : public QObject
{
    Q_OBJECT
public:
    explicit IpcServer(QObject *parent = nullptr);
    ~IpcServer() override;

    bool startServer();
    static bool sendCommand(const QString &command);
    static QString socketPath();

signals:
    void toggleRequested();
    void showRequested();
    void hideRequested();
    void clipboardRequested();

private slots:
    void handleNewConnection();

private:
    QLocalServer *m_server;
};
