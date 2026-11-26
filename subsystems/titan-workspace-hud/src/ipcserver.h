#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QTimer>

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
    void showRequested();
    void hideRequested();
    void toggleRequested();

private slots:
    void handleNewConnection();
    void onHoldTimeout();

private:
    QLocalServer *m_server;
    QTimer *m_holdTimer;
};
