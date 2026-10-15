// titan-hotzones — broadcast server for the zone OSD
#include "osdserver.hpp"

#include <QByteArray>
#include <QJsonDocument>
#include <QLocalSocket>
#include <unistd.h>

QString OsdServer::socketPath() {
    QByteArray runtime = qgetenv("XDG_RUNTIME_DIR");
    if (runtime.isEmpty())
        runtime = QByteArray("/run/user/") + QByteArray::number(getuid());
    return QString::fromLocal8Bit(runtime) + QStringLiteral("/titan-hotzones.sock");
}

bool OsdServer::start() {
    const QString path = socketPath();
    // A stale socket from a crashed instance would block listen(); clear it.
    QLocalServer::removeServer(path);

    server_.setSocketOptions(QLocalServer::UserAccessOption);
    if (!server_.listen(path))
        return false;

    QObject::connect(&server_, &QLocalServer::newConnection, &server_, [this] {
        while (QLocalSocket* client = server_.nextPendingConnection()) {
            clients_.append(client);
            QObject::connect(client, &QLocalSocket::disconnected, &server_,
                             [this, client] {
                                 clients_.removeAll(client);
                                 client->deleteLater();
                             });
        }
    });
    return true;
}

void OsdServer::broadcast(const QJsonObject& message) {
    if (clients_.isEmpty()) return;
    const QByteArray line =
        QJsonDocument(message).toJson(QJsonDocument::Compact) + '\n';
    for (QLocalSocket* client : clients_) {
        if (client->state() == QLocalSocket::ConnectedState) {
            client->write(line);
            client->flush();
        }
    }
}
