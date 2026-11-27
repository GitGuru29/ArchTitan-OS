#include "shellipc.h"

#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
#include <iostream>

ShellIpc::ShellIpc(QObject *parent)
    : QObject(parent)
{
    connect(&m_server, &QLocalServer::newConnection, this, &ShellIpc::handleNewConnection);
}

ShellIpc::~ShellIpc()
{
    if (m_server.isListening()) {
        m_server.close();
        QLocalServer::removeServer(socketPath());
    }
}

QString ShellIpc::socketPath()
{
    QString runtimeDir = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    if (runtimeDir.isEmpty()) {
        runtimeDir = QDir::tempPath();
    }
    return runtimeDir + QStringLiteral("/titan-shell.sock");
}

bool ShellIpc::startServer()
{
    const QString path = socketPath();
    QLocalServer::removeServer(path);

    if (!m_server.listen(path)) {
        std::cerr << "[titan-shell] Failed to listen on " << path.toStdString()
                  << ": " << m_server.errorString().toStdString() << "\n";
        return false;
    }
    std::cout << "[titan-shell] Listening on " << path.toStdString() << std::endl;

    // Create legacy socket symlinks so any process connecting to old socket names forwards to titan-shell
    const QString runtimeDir = QFileInfo(path).absolutePath();
    const QStringList legacySockets = {
        runtimeDir + QStringLiteral("/titan-spotlight.sock"),
        runtimeDir + QStringLiteral("/titan-quicksettings.sock"),
        runtimeDir + QStringLiteral("/titan-sysmon.sock"),
        runtimeDir + QStringLiteral("/titan-menu.sock"),
        runtimeDir + QStringLiteral("/titan-workspace-hud.sock")
    };
    for (const QString &legacyPath : legacySockets) {
        QFile::remove(legacyPath);
        QFile::link(path, legacyPath);
    }

    return true;
}

bool ShellIpc::sendCommand(const QString &command)
{
    QLocalSocket socket;
    socket.connectToServer(socketPath());
    if (!socket.waitForConnected(400)) {
        return false;
    }

    const QByteArray payload = command.toUtf8() + "\n";
    socket.write(payload);
    socket.flush();
    socket.waitForBytesWritten(400);
    socket.disconnectFromServer();
    return true;
}

void ShellIpc::handleNewConnection()
{
    while (m_server.hasPendingConnections()) {
        QLocalSocket *client = m_server.nextPendingConnection();
        if (!client) continue;

        connect(client, &QLocalSocket::readyRead, this, [this, client]() {
            const QByteArray raw = client->readAll();
            const QString text = QString::fromUtf8(raw);
            const QStringList lines = text.split('\n', Qt::SkipEmptyParts);
            for (const QString &line : lines) {
                const QString trimmed = line.trimmed();
                if (!trimmed.isEmpty()) {
                    dispatchCommand(trimmed);
                }
            }
        });

        connect(client, &QLocalSocket::disconnected, client, &QLocalSocket::deleteLater);
    }
}

void ShellIpc::dispatchCommand(const QString &cmd)
{
    const QString c = cmd.toLower();

    // Spotlight
    if (c == QStringLiteral("spotlight-toggle") || c == QStringLiteral("spotlight")) emit spotlightToggleRequested();
    else if (c == QStringLiteral("spotlight-show")) emit spotlightShowRequested();
    else if (c == QStringLiteral("spotlight-hide")) emit spotlightHideRequested();
    else if (c == QStringLiteral("spotlight-clipboard")) emit spotlightClipboardRequested();

    // QuickSettings
    else if (c == QStringLiteral("quicksettings-toggle") || c == QStringLiteral("quicksettings")) emit quicksettingsToggleRequested();
    else if (c == QStringLiteral("quicksettings-show")) emit quicksettingsShowRequested();
    else if (c == QStringLiteral("quicksettings-hide")) emit quicksettingsHideRequested();
    else if (c == QStringLiteral("quicksettings-wifi")) emit quicksettingsWifiRequested();
    else if (c == QStringLiteral("quicksettings-notifs")) emit quicksettingsNotifsRequested();

    // Sysmon
    else if (c == QStringLiteral("sysmon-toggle") || c == QStringLiteral("sysmon")) emit sysmonToggleRequested();
    else if (c == QStringLiteral("sysmon-show")) emit sysmonShowRequested();
    else if (c == QStringLiteral("sysmon-hide")) emit sysmonHideRequested();

    // Menu
    else if (c == QStringLiteral("menu-toggle") || c == QStringLiteral("menu")) emit menuToggleRequested();
    else if (c == QStringLiteral("menu-show")) emit menuShowRequested();
    else if (c == QStringLiteral("menu-hide")) emit menuHideRequested();

    // Workspace HUD
    else if (c == QStringLiteral("workspace-hud-toggle") || c == QStringLiteral("workspace-hud") || c == QStringLiteral("toggle")) emit workspaceHudToggleRequested();
    else if (c == QStringLiteral("workspace-hud-show") || c == QStringLiteral("show") || c == QStringLiteral("hold")) emit workspaceHudShowRequested();
    else if (c == QStringLiteral("workspace-hud-hide") || c == QStringLiteral("hide") || c == QStringLiteral("release")) emit workspaceHudHideRequested();

    else {
        std::cerr << "[titan-shell] Unknown IPC command: " << cmd.toStdString() << "\n";
    }
}
