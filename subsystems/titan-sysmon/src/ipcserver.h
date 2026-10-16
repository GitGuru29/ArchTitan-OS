#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>

/**
 * IpcServer — single-instance command channel for titan-sysmon.
 *
 * A thin QLocalServer that accepts one-shot text commands ("TOGGLE", "SHOW",
 * "HIDE") from the hot-zone runner and re-emits them as Qt signals. The
 * `--toggle/--show/--hide` CLI flags short-circuit into sendCommand() when the
 * daemon is already running.
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
