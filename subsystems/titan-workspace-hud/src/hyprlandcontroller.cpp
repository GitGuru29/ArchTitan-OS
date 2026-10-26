#include "hyprlandcontroller.h"

#include <QLocalSocket>
#include <QProcess>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QFileInfo>
#include <QDir>
#include <QIcon>
#include <QDebug>

HyprlandController::HyprlandController(QObject *parent)
    : QObject(parent)
{
    refresh();
}

QByteArray HyprlandController::queryHyprland(const QString &cmd)
{
    QString instanceSig = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (!instanceSig.isEmpty() && !runtimeDir.isEmpty()) {
        QString sockPath = runtimeDir + "/hypr/" + instanceSig + "/.socket.sock";
        QLocalSocket sock;
        sock.connectToServer(sockPath);
        if (sock.waitForConnected(150)) {
            sock.write(cmd.toUtf8());
            sock.flush();
            sock.waitForBytesWritten(150);
            QByteArray response;
            while (sock.waitForReadyRead(250)) {
                response += sock.readAll();
            }
            if (!response.isEmpty()) {
                return response;
            }
        }
    }

    // Fallback to hyprctl process
    QStringList args;
    if (cmd.startsWith("j/")) {
        args << "-j" << cmd.mid(2);
    } else {
        args = cmd.split(' ', Qt::SkipEmptyParts);
    }
    QProcess proc;
    proc.start("hyprctl", args);
    if (proc.waitForFinished(400)) {
        return proc.readAllStandardOutput();
    }
    return QByteArray();
}

void HyprlandController::dispatchHyprland(const QString &cmd)
{
    QString instanceSig = qEnvironmentVariable("HYPRLAND_INSTANCE_SIGNATURE");
    QString runtimeDir = qEnvironmentVariable("XDG_RUNTIME_DIR");
    if (!instanceSig.isEmpty() && !runtimeDir.isEmpty()) {
        QString sockPath = runtimeDir + "/hypr/" + instanceSig + "/.socket.sock";
        QLocalSocket sock;
        sock.connectToServer(sockPath);
        if (sock.waitForConnected(150)) {
            QString fullCmd = "dispatch " + cmd;
            sock.write(fullCmd.toUtf8());
            sock.flush();
            sock.waitForBytesWritten(150);
            return;
        }
    }

    QProcess::startDetached("hyprctl", QStringList{"dispatch"} << cmd.split(' ', Qt::SkipEmptyParts));
}

void HyprlandController::switchToWorkspace(int wsId)
{
    dispatchHyprland(QString("workspace %1").arg(wsId));
}

void HyprlandController::focusWindow(const QString &address)
{
    dispatchHyprland(QString("focuswindow address:%1").arg(address));
}

void HyprlandController::closeWindow(const QString &address)
{
    dispatchHyprland(QString("closewindow address:%1").arg(address));
    refresh();
}

void HyprlandController::moveWindowToWorkspace(const QString &address, int targetWs)
{
    dispatchHyprland(QString("movetoworkspacesilent %1,address:%2").arg(targetWs).arg(address));
    refresh();
}

QString HyprlandController::resolveIcon(const QString &appClass)
{
    return "image://icon/" + appClass;
}

void HyprlandController::refresh()
{
    QByteArray monData = queryHyprland("j/monitors");
    QByteArray clientData = queryHyprland("j/clients");

    int activeWs = 1;
    double monW = 1920.0;
    double monH = 1080.0;

    if (!monData.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(monData);
        if (doc.isArray()) {
            for (const QJsonValue &v : doc.array()) {
                QJsonObject m = v.toObject();
                if (m.value("focused").toBool()) {
                    activeWs = m.value("activeWorkspace").toObject().value("id").toInt(1);
                    monW = m.value("width").toDouble(1920.0);
                    monH = m.value("height").toDouble(1080.0);
                    break;
                }
            }
        }
    }
    m_activeWorkspace = activeWs;

    // Group clients by workspace (1..10)
    QMap<int, QList<QJsonObject>> clientMap;
    if (!clientData.isEmpty()) {
        QJsonDocument doc = QJsonDocument::fromJson(clientData);
        if (doc.isArray()) {
            for (const QJsonValue &v : doc.array()) {
                QJsonObject c = v.toObject();
                int ws = c.value("workspace").toObject().value("id").toInt(-1);
                if (ws >= 1 && ws <= 10) {
                    clientMap[ws].append(c);
                }
            }
        }
    }

    constexpr int cardW = 236;
    constexpr int cardH = 136;
    constexpr int usableW = cardW - 16;
    constexpr int usableH = cardH - 16;
    constexpr int offsetX = 8;
    constexpr int offsetY = 8;

    QVariantList wsList;
    for (int wsId = 1; wsId <= 10; ++wsId) {
        QVariantMap wsObj;
        wsObj["id"] = wsId;
        wsObj["active"] = (wsId == activeWs);

        QVariantList winList;
        const auto &clients = clientMap.value(wsId);
        int numWins = clients.size();

        for (int i = 0; i < numWins; ++i) {
            const QJsonObject &c = clients.at(i);
            QJsonArray atArr = c.value("at").toArray();
            QJsonArray szArr = c.value("size").toArray();

            double wx = atArr.size() >= 2 ? atArr.at(0).toDouble(0.0) : 0.0;
            double wy = atArr.size() >= 2 ? atArr.at(1).toDouble(0.0) : 0.0;
            double ww = szArr.size() >= 2 ? szArr.at(0).toDouble(100.0) : 100.0;
            double wh = szArr.size() >= 2 ? szArr.at(1).toDouble(100.0) : 100.0;

            int rx, ry, rw, rh;
            if (numWins <= 4) {
                rx = static_cast<int>((wx / monW) * usableW) + offsetX;
                ry = static_cast<int>((wy / monH) * usableH) + offsetY;
                rw = qMax(48, static_cast<int>((ww / monW) * usableW));
                rh = qMax(48, static_cast<int>((wh / monH) * usableH));
            } else {
                int subCol = i % 2;
                int subRow = (i / 2) % 2;
                rw = (usableW - 6) / 2;
                rh = (usableH - 6) / 2;
                rx = offsetX + subCol * (rw + 6);
                ry = offsetY + subRow * (rh + 6);
                if (i >= 4) break;
            }

            rx = qMax(6, qMin(rx, cardW - rw - 6));
            ry = qMax(6, qMin(ry, cardH - rh - 6));

            QString appClass = c.value("class").toString();
            QString address = c.value("address").toString();
            QString title = c.value("title").toString();

            QVariantMap winObj;
            winObj["address"] = address;
            winObj["class"] = appClass;
            winObj["title"] = title;
            winObj["icon"] = resolveIcon(appClass);
            winObj["rx"] = rx;
            winObj["ry"] = ry;
            winObj["rw"] = rw;
            winObj["rh"] = rh;

            winList.append(winObj);
        }

        wsObj["windows"] = winList;
        wsObj["windowCount"] = numWins;
        wsList.append(wsObj);
    }

    m_workspaces = wsList;
    emit stateChanged();
}
