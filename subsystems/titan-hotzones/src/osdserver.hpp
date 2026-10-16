// titan-hotzones — tiny broadcast/control server used to drive the zone OSD.
//
// The daemon hosts a UNIX-domain socket; any connected `titan-zone-osd` client
// receives newline-delimited JSON state messages. Also accepts control commands
// (ENABLE, DISABLE, TOGGLE, STATUS) from clients (e.g., Quick Settings).
#pragma once

#include <QJsonObject>
#include <QList>
#include <QLocalServer>

class QLocalSocket;

class OsdServer : public QObject {
  Q_OBJECT
public:
  explicit OsdServer(QObject *parent = nullptr);
  bool start();
  bool hasClients() const { return !clients_.isEmpty(); }
  void broadcast(const QJsonObject &message);

  static QString socketPath();

signals:
  void enableRequested();
  void disableRequested();
  void toggleRequested();
  void clientConnected();

private:
  QLocalServer server_;
  QList<QLocalSocket *> clients_;

private slots:
  void handleNewConnection();
};
