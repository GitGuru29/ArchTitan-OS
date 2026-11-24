#pragma once

#include <QObject>
#include <QLocalServer>
#include <QLocalSocket>
#include <QString>

class ShellIpc : public QObject
{
    Q_OBJECT
public:
    explicit ShellIpc(QObject *parent = nullptr);
    ~ShellIpc() override;

    bool startServer();
    static bool sendCommand(const QString &command);

signals:
    // Spotlight
    void spotlightToggleRequested();
    void spotlightShowRequested();
    void spotlightHideRequested();
    void spotlightClipboardRequested();

    // QuickSettings
    void quicksettingsToggleRequested();
    void quicksettingsShowRequested();
    void quicksettingsHideRequested();
    void quicksettingsWifiRequested();
    void quicksettingsNotifsRequested();

    // Sysmon
    void sysmonToggleRequested();
    void sysmonShowRequested();
    void sysmonHideRequested();

    // Menu
    void menuToggleRequested();
    void menuShowRequested();
    void menuHideRequested();

    // Workspace HUD
    void workspaceHudToggleRequested();
    void workspaceHudShowRequested();
    void workspaceHudHideRequested();

private slots:
    void handleNewConnection();

private:
    void dispatchCommand(const QString &cmd);
    static QString socketPath();

    QLocalServer m_server;
};
