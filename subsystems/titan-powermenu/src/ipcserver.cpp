#include "ipcserver.h"

#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <QCoreApplication>
#include <iostream>

IpcServer::IpcServer(QObject *parent)
    : QObject(parent)
{
    connect(&m_server, &QLocalServer::newConnection, this, &IpcServer::onNewConnection);
}

IpcServer::~IpcServer()
{
    m_server.close();
    QLocalServer::removeServer(socketPath());
}

QString IpcServer::socketPath()
{
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (runtimeDir.isEmpty()) {
        runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    }
    if (runtimeDir.isEmpty()) {
        runtimeDir = QStringLiteral("/tmp");
    }
    return runtimeDir + QStringLiteral("/titan-powermenu.sock");
}

bool IpcServer::startServer()
{
    const QString path = socketPath();
    QLocalServer::removeServer(path);

    if (!m_server.listen(path)) {
        std::cerr << "[titan-powermenu] Failed to bind local server: "
                  << m_server.errorString().toStdString() << "\n";
        return false;
    }
    return true;
}

bool IpcServer::sendCommand(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(200)) {
        return false;
    }

    const QByteArray payload = command.toUtf8() + '\n';
    socket.write(payload);
    socket.waitForBytesWritten(200);
    socket.disconnectFromServer();
    return true;
}

void IpcServer::onNewConnection()
{
    while (QLocalSocket *sock = m_server.nextPendingConnection()) {
        connect(sock, &QLocalSocket::readyRead, this, &IpcServer::onReadyRead);
        connect(sock, &QLocalSocket::disconnected, sock, &QLocalSocket::deleteLater);
    }
}

void IpcServer::onReadyRead()
{
    auto *sock = qobject_cast<QLocalSocket*>(sender());
    if (!sock) return;

    while (sock->canReadLine()) {
        QString line = QString::fromUtf8(sock->readLine()).trimmed().toUpper();
        if (line == QStringLiteral("TOGGLE")) {
            emit toggleRequested();
        } else if (line == QStringLiteral("SHOW")) {
            emit showRequested();
        } else if (line == QStringLiteral("HIDE")) {
            emit hideRequested();
        } else if (line == QStringLiteral("LOCK")) {
            emit lockRequested();
        } else if (line == QStringLiteral("SUSPEND")) {
            emit suspendRequested();
        } else if (line == QStringLiteral("LOGOUT")) {
            emit logoutRequested();
        } else if (line == QStringLiteral("REBOOT")) {
            emit rebootRequested();
        } else if (line == QStringLiteral("POWEROFF") || line == QStringLiteral("SHUTDOWN")) {
            emit shutdownRequested();
        }
    }
}
