// titan-hotzones — minimal Hyprland IPC client
#include "hyprland.hpp"

#include <QByteArray>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLocalSocket>
#include <climits>
#include <unistd.h>

namespace titan {
namespace {

constexpr int kUnknownCoord = INT_MIN;

QByteArray readReply(QLocalSocket& socket, int timeoutMs) {
    QByteArray data;
    while (socket.waitForReadyRead(timeoutMs))
        data += socket.readAll();
    data += socket.readAll();
    return data;
}

} // namespace

QString hyprCommandSocketPath() {
    const QByteArray sig = qgetenv("HYPRLAND_INSTANCE_SIGNATURE");
    if (sig.isEmpty()) return {};
    QByteArray runtime = qgetenv("XDG_RUNTIME_DIR");
    if (runtime.isEmpty())
        runtime = QByteArray("/run/user/") + QByteArray::number(getuid());
    return QString::fromLocal8Bit(runtime) + "/hypr/" +
           QString::fromLocal8Bit(sig) + "/.socket.sock";
}

QString hyprSend(const QString& command, int timeoutMs) {
    const QString path = hyprCommandSocketPath();
    if (path.isEmpty() || !QFileInfo::exists(path)) return {};

    QLocalSocket socket;
    socket.connectToServer(path);
    if (!socket.waitForConnected(timeoutMs)) return {};

    socket.write(command.toUtf8());
    socket.flush();
    socket.waitForBytesWritten(timeoutMs);

    const QByteArray reply = readReply(socket, timeoutMs);
    socket.disconnectFromServer();
    return QString::fromUtf8(reply).trimmed();
}

QPoint hyprCursorPos() {
    const QString reply = hyprSend(QStringLiteral("cursorpos"));
    if (reply.isEmpty()) return {kUnknownCoord, kUnknownCoord};
    const QStringList parts = reply.split(',');
    if (parts.size() != 2) return {kUnknownCoord, kUnknownCoord};
    bool okX = false, okY = false;
    const int x = parts.at(0).trimmed().toInt(&okX);
    const int y = parts.at(1).trimmed().toInt(&okY);
    if (!okX || !okY) return {kUnknownCoord, kUnknownCoord};
    return {x, y};
}

std::vector<Monitor> hyprMonitors() {
    std::vector<Monitor> monitors;
    const QString reply = hyprSend(QStringLiteral("j/monitors"));
    if (reply.isEmpty()) return monitors;

    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(reply.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isArray()) return monitors;

    for (const QJsonValue& value : doc.array()) {
        const QJsonObject obj = value.toObject();
        Monitor m;
        m.name = obj.value(QStringLiteral("name")).toString();
        m.x = obj.value(QStringLiteral("x")).toInt();
        m.y = obj.value(QStringLiteral("y")).toInt();
        m.w = obj.value(QStringLiteral("width")).toInt();
        m.h = obj.value(QStringLiteral("height")).toInt();
        if (m.w > 0 && m.h > 0) monitors.push_back(m);
    }
    return monitors;
}

ActiveWindow hyprActiveWindow() {
    ActiveWindow aw;
    const QString reply = hyprSend(QStringLiteral("j/activewindow"));
    if (reply.isEmpty() || reply == QLatin1String("Invalid")) return aw;

    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(reply.toUtf8(), &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) return aw;

    const QJsonObject obj = doc.object();
    aw.valid = true;
    aw.windowClass = obj.value(QStringLiteral("class")).toString();
    aw.fullscreen = obj.value(QStringLiteral("fullscreen")).toInt();
    return aw;
}

} // namespace titan
