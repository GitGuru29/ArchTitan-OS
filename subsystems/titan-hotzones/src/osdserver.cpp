// titan-hotzones — broadcast/control server for the zone OSD
#include "osdserver.hpp"

#include <QByteArray>
#include <QJsonDocument>
#include <QLocalSocket>
#include <unistd.h>

QString OsdServer::socketPath() {
  QByteArray runtime = qgetenv("XDG_RUNTIME_DIR");
  if (runtime.isEmpty())
    runtime = QByteArray("/run/user/") + QByteArray::number(getuid());
  return QString::fromLocal8Bit(runtime) +
         QStringLiteral("/titan-hotzones.sock");
}

OsdServer::OsdServer(QObject *parent) : QObject(parent) {
  connect(&server_, &QLocalServer::newConnection, this,
          &OsdServer::handleNewConnection);
}

bool OsdServer::start() {
  const QString path = socketPath();
  QLocalServer::removeServer(path);
  server_.setSocketOptions(QLocalServer::UserAccessOption);
  if (!server_.listen(path))
    return false;
  return true;
}

void OsdServer::broadcast(const QJsonObject &message) {
  if (clients_.isEmpty())
    return;
  const QByteArray line =
      QJsonDocument(message).toJson(QJsonDocument::Compact) + '\n';
  for (QLocalSocket *client : clients_) {
    if (client->state() == QLocalSocket::ConnectedState) {
      client->write(line);
      client->flush();
    }
  }
}

void OsdServer::handleNewConnection() {
  while (QLocalSocket *client = server_.nextPendingConnection()) {
    clients_.append(client);
    connect(client, &QLocalSocket::disconnected, this, [this, client] {
      clients_.removeAll(client);
      client->deleteLater();
    });
    connect(client, &QLocalSocket::readyRead, this, [this, client] {
      QByteArray raw = client->readAll();
      QString cmd = QString::fromUtf8(raw).trimmed().toUpper();
      if (cmd == "ENABLE")
        emit enableRequested();
      else if (cmd == "DISABLE")
        emit disableRequested();
      else if (cmd == "TOGGLE")
        emit toggleRequested();
      else if (cmd == "STATUS") {
        client->write("OK\n");
        client->flush();
      }
      client->disconnectFromServer();
    });
    emit clientConnected();
  }
}
