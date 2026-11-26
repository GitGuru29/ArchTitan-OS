#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>

class IpcServer : public QObject
{
    Q_OBJECT
public:
    explicit IpcServer(QObject *parent = nullptr);
    ~IpcServer() override;

    bool startServer();
    static bool sendCommand(const QString &command);

signals:
    void toggleRequested();
    void showRequested();
    void hideRequested();
    void lockRequested();
    void suspendRequested();
    void logoutRequested();
    void rebootRequested();
    void shutdownRequested();

private slots:
    void onNewConnection();
    void onReadyRead();

private:
    QLocalServer m_server;
    static QString socketPath();
};
