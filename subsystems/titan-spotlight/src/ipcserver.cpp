#include "ipcserver.h"

#include <QFile>
#include <QLocalSocket>
#include <QStandardPaths>

IpcServer::IpcServer(QObject *parent)
    : QObject(parent)
    , m_server(new QLocalServer(this))
{
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
        runtimeDir = QStringLiteral("/tmp");
    }
    return runtimeDir + QStringLiteral("/titan-spotlight.sock");
}

bool IpcServer::startServer()
{
    const QString path = socketPath();
    QFile::remove(path); // Clean stale socket
    return m_server->listen(path);
}

bool IpcServer::sendCommand(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(200)) {
        return false;
    }
    const QByteArray payload = command.toUtf8() + "\n";
    socket.write(payload);
    socket.flush();
    socket.waitForBytesWritten(200);
    socket.disconnectFromServer();
    return true;
}

void IpcServer::handleNewConnection()
{
    while (m_server->hasPendingConnections()) {
        QLocalSocket *client = m_server->nextPendingConnection();
        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            const QByteArray raw = client->readAll();
            const QString cmd = QString::fromUtf8(raw).trimmed().toUpper();
            if (cmd == QStringLiteral("TOGGLE")) {
                emit toggleRequested();
            } else if (cmd == QStringLiteral("SHOW")) {
                emit showRequested();
            } else if (cmd == QStringLiteral("HIDE")) {
                emit hideRequested();
            } else if (cmd == QStringLiteral("CLIPBOARD")) {
                emit clipboardRequested();
            }
        });
        connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
    }
}
