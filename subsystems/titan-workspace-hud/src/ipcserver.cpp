#include "ipcserver.h"
#include <QStandardPaths>
#include <QFile>
#include <QDebug>

IpcServer::IpcServer(QObject *parent)
    : QObject(parent)
    , m_server(new QLocalServer(this))
    , m_holdTimer(new QTimer(this))
{
    m_holdTimer->setSingleShot(true);
    m_holdTimer->setInterval(280); // 280ms hysteresis threshold
    connect(m_holdTimer, &QTimer::timeout, this, &IpcServer::onHoldTimeout);
    connect(m_server, &QLocalServer::newConnection, this, &IpcServer::handleNewConnection);
}

IpcServer::~IpcServer()
{
    if (m_server && m_server->isListening()) {
        m_server->close();
        QFile::remove(socketPath());
    }
}

QString IpcServer::socketPath()
{
    QString runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (runtimeDir.isEmpty()) {
        runtimeDir = "/tmp";
    }
    return runtimeDir + "/titan-workspace-hud.sock";
}

bool IpcServer::startServer()
{
    QString path = socketPath();
    QFile::remove(path); // Clean up stale socket

    if (!m_server->listen(path)) {
        qWarning() << "[titan-ws-hud] Failed to start IPC server at" << path << ":" << m_server->errorString();
        return false;
    }
    return true;
}

bool IpcServer::sendCommand(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(300)) {
        return false;
    }

    QByteArray data = command.toUtf8() + "\n";
    socket.write(data);
    socket.flush();
    socket.waitForBytesWritten(300);
    socket.disconnectFromServer();
    return true;
}

void IpcServer::handleNewConnection()
{
    while (m_server->hasPendingConnections()) {
        QLocalSocket *client = m_server->nextPendingConnection();
        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            QByteArray raw = client->readAll();
            QString cmd = QString::fromUtf8(raw).trimmed();

            if (cmd.compare("HOLD", Qt::CaseInsensitive) == 0) {
                // Key hold started: begin 280ms timer
                if (!m_holdTimer->isActive()) {
                    m_holdTimer->start();
                }
            } else if (cmd.compare("RELEASE", Qt::CaseInsensitive) == 0) {
                // Key released: if hold timer is still running (<280ms), cancel it!
                if (m_holdTimer->isActive()) {
                    m_holdTimer->stop();
                } else {
                    emit hideRequested();
                }
            } else if (cmd.compare("TOGGLE", Qt::CaseInsensitive) == 0) {
                emit toggleRequested();
            } else if (cmd.compare("SHOW", Qt::CaseInsensitive) == 0) {
                emit showRequested();
            } else if (cmd.compare("HIDE", Qt::CaseInsensitive) == 0) {
                if (m_holdTimer->isActive()) {
                    m_holdTimer->stop();
                }
                emit hideRequested();
            }
        });
        connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
    }
}

void IpcServer::onHoldTimeout()
{
    emit showRequested();
}
