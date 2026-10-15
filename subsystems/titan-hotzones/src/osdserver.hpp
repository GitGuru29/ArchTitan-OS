// titan-hotzones — tiny broadcast server used to drive the zone OSD.
//
// The daemon hosts a UNIX-domain socket; any connected `titan-zone-osd` client
// receives newline-delimited JSON state messages. This keeps the OSD fully
// decoupled (it can be absent, restart, or run per-screen) and the daemon
// never blocks on it.
#pragma once

#include <QJsonObject>
#include <QLocalServer>
#include <QList>

class QLocalSocket;

class OsdServer {
public:
    bool start();
    bool hasClients() const { return !clients_.isEmpty(); }
    void broadcast(const QJsonObject& message);

    static QString socketPath();

private:
    QLocalServer server_;
    QList<QLocalSocket*> clients_;
};
