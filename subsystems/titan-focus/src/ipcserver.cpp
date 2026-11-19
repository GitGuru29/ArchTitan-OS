#include "ipcserver.h"

#include <QDir>
#include <QLocalSocket>
#include <QStandardPaths>
#include <iostream>

namespace titan::focus {

IpcServer::IpcServer(QObject *parent)
    : QObject(parent) {
    connect(&m_server, &QLocalServer::newConnection, this, &IpcServer::onNewConnection);
}

IpcServer::~IpcServer() {
    if (m_server.isListening()) {
        m_server.close();
        QLocalServer::removeServer(socketPath());
    }
}

QString IpcServer::socketPath() {
    QString runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (runtimeDir.isEmpty()) {
        runtimeDir = QDir::tempPath();
    }
    return runtimeDir + QStringLiteral("/titan-focus.sock");
}

bool IpcServer::startServer() {
    const QString path = socketPath();
    QLocalServer::removeServer(path);
    if (!m_server.listen(path)) {
        std::cerr << "[titan-focus] Failed to listen on " << path.toStdString()
                  << ": " << m_server.errorString().toStdString() << "\n";
        return false;
    }
    return true;
}

bool IpcServer::sendCommand(const QString &command, QString *replyOut, int timeoutMs) {
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(timeoutMs)) {
        return false;
    }

    const QByteArray payload = command.toUtf8() + '\n';
    socket.write(payload);
    socket.flush();
    if (socket.bytesToWrite() > 0 && !socket.waitForBytesWritten(timeoutMs)) {
        return false;
    }

    if (replyOut) {
        QByteArray response;
        while (socket.waitForReadyRead(timeoutMs)) {
            response.append(socket.readAll());
            if (response.contains('\n')) break;
        }
        *replyOut = QString::fromUtf8(response).trimmed();
    }

    socket.disconnectFromServer();
    return true;
}

void IpcServer::onNewConnection() {
    while (m_server.hasPendingConnections()) {
        QLocalSocket *client = m_server.nextPendingConnection();
        if (!client) continue;

        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            const QString raw = QString::fromUtf8(client->readAll());
            const QStringList lines = raw.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
            for (const QString &line : lines) {
                const QString trimmed = line.trimmed();
                if (trimmed.isEmpty()) continue;
                const QString reply = m_handler ? m_handler(trimmed) : QStringLiteral("OK");
                client->write(reply.toUtf8() + '\n');
                client->flush();
            }
        });
        connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
    }
}

} // namespace titan::focus
