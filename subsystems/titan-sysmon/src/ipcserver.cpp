#include "ipcserver.h"

#include <QDir>
#include <QFile>
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
    if (runtimeDir.isEmpty())
        runtimeDir = QStringLiteral("/tmp");
    return runtimeDir + QStringLiteral("/titan-sysmon.sock");
}

bool IpcServer::startServer()
{
    const QString path = socketPath();
    QFile::remove(path); // clean up stale socket from a previous crash

    if (!m_server->listen(path)) {
        qWarning("titan-sysmon: failed to listen on %s: %s",
                 qPrintable(path), qPrintable(m_server->errorString()));
        return false;
    }
    return true;
}

bool IpcServer::sendCommand(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(500))
        return false;

    socket.write(command.toUtf8() + "\n");
    socket.flush();
    socket.waitForBytesWritten(500);
    socket.disconnectFromServer();
    return true;
}

void IpcServer::handleNewConnection()
{
    while (m_server->hasPendingConnections()) {
        QLocalSocket *client = m_server->nextPendingConnection();
        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            const QString cmd = QString::fromUtf8(client->readAll()).trimmed();
            if (cmd.compare(QLatin1String("TOGGLE"), Qt::CaseInsensitive) == 0)
                emit toggleRequested();
            else if (cmd.compare(QLatin1String("SHOW"), Qt::CaseInsensitive) == 0)
                emit showRequested();
            else if (cmd.compare(QLatin1String("HIDE"), Qt::CaseInsensitive) == 0)
                emit hideRequested();
            client->disconnectFromServer();
        });
        connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
    }
}
