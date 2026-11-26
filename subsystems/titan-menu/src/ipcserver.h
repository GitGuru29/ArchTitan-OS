#pragma once

#include <QLocalServer>
#include <QObject>

/**
 * IpcServer — single-instance command channel for titan-menu.
 *
 * Accepts one-shot text commands ("TOGGLE", "SHOW", "HIDE") on a runtime-dir
 * socket and re-emits them as signals. `titan-menu --toggle` short-circuits
 * into sendCommand() when the daemon is already running, so the keybind is
 * instant (no process start-up on the hot path).
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

private slots:
    void handleNewConnection();

private:
    QLocalServer *m_server;
};
