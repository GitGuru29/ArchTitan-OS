#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQmlPropertyMap>
#include <QSettings>
#include <QFileSystemWatcher>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QDir>
#include <csignal>
#include <iostream>
#include <malloc.h>

#include <LayerShellQt/window.h>

#include "shellipc.h"
#include "shellcontroller.h"
#include "appiconprovider.h"

// Controllers from subsystems
#include "spotlightcontroller.h"
#include "sysmoncontroller.hpp"
#include "gpumodel.hpp"
#include "menucontroller.hpp"
#include "hyprlandcontroller.h"

#include "systemcontroller.h"
#include "networkcontroller.h"
#include "bluetoothcontroller.h"
#include "audiocontroller.h"
#include "nightlightcontroller.h"
#include "notificationserver.h"
#include "mpriscontroller.h"

int main(int argc, char *argv[])
{
    // Fast-path client IPC dispatch
    for (int i = 1; i < argc; ++i) {
        const QString arg = QString::fromUtf8(argv[i]);
        if (arg == QStringLiteral("--help") || arg == QStringLiteral("-h")) {
            std::cout << "Usage: titan-shell [options]\n\n"
                      << "ArchTitan Unified Desktop Shell Daemon\n\n"
                      << "Options:\n"
                      << "  -d, --daemon          Start in background daemon mode\n"
                      << "  -s, --spotlight       Toggle spotlight launcher\n"
                      << "  -c, --clipboard       Open spotlight in clipboard mode\n"
                      << "  -q, --quicksettings   Toggle quick settings drawer\n"
                      << "  -n, --notifications   Open quick settings notifications\n"
                      << "  -m, --sysmon          Toggle system monitor sidebar\n"
                      << "  -u, --menu            Toggle application menu\n"
                      << "  -w, --workspace-hud   Toggle overview (workspace switcher)\n"
                      << "  -h, --help            Displays help on commandline options\n";
            return 0;
        } else if (arg == QStringLiteral("--spotlight") || arg == QStringLiteral("-s") || arg == QStringLiteral("--toggle-spotlight")) {
            if (ShellIpc::sendCommand(QStringLiteral("spotlight-toggle"))) return 0;
            break;
        } else if (arg == QStringLiteral("--show-spotlight")) {
            if (ShellIpc::sendCommand(QStringLiteral("spotlight-show"))) return 0;
            break;
        } else if (arg == QStringLiteral("--hide-spotlight")) {
            if (ShellIpc::sendCommand(QStringLiteral("spotlight-hide"))) return 0;
            break;
        } else if (arg == QStringLiteral("--clipboard")) {
            if (ShellIpc::sendCommand(QStringLiteral("spotlight-clipboard"))) return 0;
            break;
        } else if (arg == QStringLiteral("--quicksettings") || arg == QStringLiteral("-q") || arg == QStringLiteral("--toggle-quicksettings")) {
            if (ShellIpc::sendCommand(QStringLiteral("quicksettings-toggle"))) return 0;
            break;
        } else if (arg == QStringLiteral("--show-quicksettings")) {
            if (ShellIpc::sendCommand(QStringLiteral("quicksettings-show"))) return 0;
            break;
        } else if (arg == QStringLiteral("--hide-quicksettings")) {
            if (ShellIpc::sendCommand(QStringLiteral("quicksettings-hide"))) return 0;
            break;
        } else if (arg == QStringLiteral("--notifications") || arg == QStringLiteral("-n")) {
            if (ShellIpc::sendCommand(QStringLiteral("quicksettings-notifs"))) return 0;
            break;
        } else if (arg == QStringLiteral("--wifi")) {
            if (ShellIpc::sendCommand(QStringLiteral("quicksettings-wifi"))) return 0;
            break;
        } else if (arg == QStringLiteral("--sysmon") || arg == QStringLiteral("-m") || arg == QStringLiteral("--toggle-sysmon")) {
            if (ShellIpc::sendCommand(QStringLiteral("sysmon-toggle"))) return 0;
            break;
        } else if (arg == QStringLiteral("--show-sysmon")) {
            if (ShellIpc::sendCommand(QStringLiteral("sysmon-show"))) return 0;
            break;
        } else if (arg == QStringLiteral("--hide-sysmon")) {
            if (ShellIpc::sendCommand(QStringLiteral("sysmon-hide"))) return 0;
            break;
        } else if (arg == QStringLiteral("--menu") || arg == QStringLiteral("-u") || arg == QStringLiteral("--toggle-menu")) {
            if (ShellIpc::sendCommand(QStringLiteral("menu-toggle"))) return 0;
            break;
        } else if (arg == QStringLiteral("--show-menu")) {
            if (ShellIpc::sendCommand(QStringLiteral("menu-show"))) return 0;
            break;
        } else if (arg == QStringLiteral("--hide-menu")) {
            if (ShellIpc::sendCommand(QStringLiteral("menu-hide"))) return 0;
            break;
        } else if (arg == QStringLiteral("--workspace-hud") || arg == QStringLiteral("-w") ||
                   arg == QStringLiteral("--toggle-workspace-hud") ||
                   arg == QStringLiteral("--toggle-overview") || arg == QStringLiteral("--overview")) {
            if (ShellIpc::sendCommand(QStringLiteral("workspace-hud-toggle"))) return 0;
            break;
        } else if (arg == QStringLiteral("--show-workspace-hud")) {
            if (ShellIpc::sendCommand(QStringLiteral("workspace-hud-show"))) return 0;
            break;
        } else if (arg == QStringLiteral("--hide-workspace-hud")) {
            if (ShellIpc::sendCommand(QStringLiteral("workspace-hud-hide"))) return 0;
            break;
        }
    }

    // Set performance and memory tuning environment
    qputenv("QSG_RENDER_LOOP", "basic");
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    if (qgetenv("QT_QPA_PLATFORM").isEmpty()) {
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    }
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-shell"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Unified Desktop Shell"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT,  [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan Unified LayerShell Desktop Daemon"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption daemonOpt(QStringList() << QStringLiteral("d") << QStringLiteral("daemon"), QStringLiteral("Start in background daemon mode"));
    QCommandLineOption spotlightOpt(QStringList() << QStringLiteral("s") << QStringLiteral("spotlight"), QStringLiteral("Toggle spotlight launcher"));
    QCommandLineOption qsOpt(QStringList() << QStringLiteral("q") << QStringLiteral("quicksettings"), QStringLiteral("Toggle quick settings drawer"));
    QCommandLineOption sysmonOpt(QStringList() << QStringLiteral("m") << QStringLiteral("sysmon"), QStringLiteral("Toggle system monitor sidebar"));
    QCommandLineOption menuOpt(QStringList() << QStringLiteral("u") << QStringLiteral("menu"), QStringLiteral("Toggle menu"));
    QCommandLineOption wsOpt(QStringList() << QStringLiteral("w") << QStringLiteral("workspace-hud"), QStringLiteral("Toggle workspace HUD"));
    QCommandLineOption clipOpt(QStringList() << QStringLiteral("c") << QStringLiteral("clipboard"), QStringLiteral("Open spotlight in clipboard mode"));
    QCommandLineOption notifOpt(QStringList() << QStringLiteral("n") << QStringLiteral("notifications"), QStringLiteral("Open quick settings notifications"));

    parser.addOption(daemonOpt);
    parser.addOption(spotlightOpt);
    parser.addOption(qsOpt);
    parser.addOption(sysmonOpt);
    parser.addOption(menuOpt);
    parser.addOption(wsOpt);
    parser.addOption(clipOpt);
    parser.addOption(notifOpt);
    parser.process(app);

    ShellIpc ipc;
    if (!ipc.startServer()) {
        std::cerr << "[titan-shell] Note: Another instance may be running or failed to bind socket.\n";
    }

    ShellController shell;

    // Initialize backend controllers
    SpotlightController spotlightCtrl;
    GpuModel gpuModel;
    SysmonController sysmonCtrl(&gpuModel);
    MenuController menuCtrl;
    menuCtrl.loadDefault();
    HyprlandController hyprlandCtrl;

    SystemController systemCtrl;
    NetworkController networkCtrl;
    BluetoothController bluetoothCtrl;
    AudioController audioCtrl;
    NightLightController nightLightCtrl;
    NotificationServer notifServer;
    MprisController mprisCtrl;

    // Connect IPC signals to shell controller
    QObject::connect(&ipc, &ShellIpc::spotlightToggleRequested, &shell, [&shell, &spotlightCtrl]() {
        spotlightCtrl.reset();
        spotlightCtrl.setClipboardMode(false);
        shell.toggleSpotlight();
    });
    QObject::connect(&ipc, &ShellIpc::spotlightShowRequested, &shell, [&shell, &spotlightCtrl]() {
        spotlightCtrl.reset();
        spotlightCtrl.setClipboardMode(false);
        shell.showSpotlight();
    });
    QObject::connect(&ipc, &ShellIpc::spotlightHideRequested, &shell, &ShellController::hideSpotlight);
    QObject::connect(&ipc, &ShellIpc::spotlightClipboardRequested, &shell, [&shell, &spotlightCtrl]() {
        spotlightCtrl.reset();
        spotlightCtrl.setClipboardMode(true);
        shell.showSpotlightClipboard();
    });

    QObject::connect(&ipc, &ShellIpc::quicksettingsToggleRequested, &shell, &ShellController::toggleQuicksettings);
    QObject::connect(&ipc, &ShellIpc::quicksettingsShowRequested,   &shell, &ShellController::showQuicksettings);
    QObject::connect(&ipc, &ShellIpc::quicksettingsHideRequested,   &shell, &ShellController::hideQuicksettings);
    QObject::connect(&ipc, &ShellIpc::quicksettingsWifiRequested,   &shell, &ShellController::showQuicksettingsWifi);
    QObject::connect(&ipc, &ShellIpc::quicksettingsNotifsRequested, &shell, &ShellController::showQuicksettingsNotifs);

    QObject::connect(&ipc, &ShellIpc::sysmonToggleRequested, &shell, &ShellController::toggleSysmon);
    QObject::connect(&ipc, &ShellIpc::sysmonShowRequested,   &shell, &ShellController::showSysmon);
    QObject::connect(&ipc, &ShellIpc::sysmonHideRequested,   &shell, &ShellController::hideSysmon);

    QObject::connect(&ipc, &ShellIpc::menuToggleRequested, &shell, &ShellController::toggleMenu);
    QObject::connect(&ipc, &ShellIpc::menuShowRequested,   &shell, &ShellController::showMenu);
    QObject::connect(&ipc, &ShellIpc::menuHideRequested,   &shell, &ShellController::hideMenu);

    QObject::connect(&ipc, &ShellIpc::workspaceHudToggleRequested, &shell, [&shell, &hyprlandCtrl]() {
        hyprlandCtrl.refresh();
        shell.toggleWorkspaceHud();
    });
    QObject::connect(&ipc, &ShellIpc::workspaceHudShowRequested, &shell, [&shell, &hyprlandCtrl]() {
        hyprlandCtrl.refresh();
        shell.showWorkspaceHud();
    });
    QObject::connect(&ipc, &ShellIpc::workspaceHudHideRequested, &shell, &ShellController::hideWorkspaceHud);

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/local/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("qrc:/quicksettings/qml"));
    engine.addImportPath(QStringLiteral("qrc:/spotlight/qml"));
    engine.addImportPath(QStringLiteral("qrc:/sysmon/qml"));
    engine.addImportPath(QStringLiteral("qrc:/menu/qml"));
    engine.addImportPath(QStringLiteral("qrc:/workspacehud/qml"));

    const QString devQml = QDir::currentPath() + QStringLiteral("/titan-ui/build/qml");
    if (QDir(devQml).exists()) engine.addImportPath(devQml);
    const QString airootQml = QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml");
    if (QDir(airootQml).exists()) engine.addImportPath(airootQml);

    engine.addImageProvider(QStringLiteral("icon"), new AppIconProvider());

    auto *ctx = engine.rootContext();
    ctx->setContextProperty(QStringLiteral("shell"),          &shell);
    ctx->setContextProperty(QStringLiteral("spotlight"),      &spotlightCtrl);
    ctx->setContextProperty(QStringLiteral("sysmon"),         &sysmonCtrl);
    ctx->setContextProperty(QStringLiteral("gpuModel"),       &gpuModel);
    ctx->setContextProperty(QStringLiteral("menu"),           &menuCtrl);
    ctx->setContextProperty(QStringLiteral("hyprland"),       &hyprlandCtrl);

    ctx->setContextProperty(QStringLiteral("systemCtrl"),     &systemCtrl);
    ctx->setContextProperty(QStringLiteral("networkCtrl"),    &networkCtrl);
    ctx->setContextProperty(QStringLiteral("bluetoothCtrl"),  &bluetoothCtrl);
    ctx->setContextProperty(QStringLiteral("btCtrl"),         &bluetoothCtrl);
    ctx->setContextProperty(QStringLiteral("audioCtrl"),      &audioCtrl);
    ctx->setContextProperty(QStringLiteral("nightLightCtrl"),  &nightLightCtrl);
    ctx->setContextProperty(QStringLiteral("mprisCtrl"),       &mprisCtrl);
    ctx->setContextProperty(QStringLiteral("notifServer"),     &notifServer);
    ctx->setContextProperty(QStringLiteral("notifModel"),      notifServer.model());

    // Mirror Settings > Appearance > Glassmorphism into QML
    auto *appearance = QQmlPropertyMap::create(&app);
    auto refreshGlass = [appearance]() {
        QSettings settings(QStringLiteral("ArchTitan"), QStringLiteral("archtitan-settings"));
        appearance->insert(QStringLiteral("glassmorphism"),
                           settings.value(QStringLiteral("appearance/glassmorphism"), true).toBool());
    };
    refreshGlass();
    ctx->setContextProperty(QStringLiteral("AppearanceSettings"), appearance);

    const QString settingsFile = QSettings(QStringLiteral("ArchTitan"),
                                           QStringLiteral("archtitan-settings")).fileName();
    auto *settingsWatcher = new QFileSystemWatcher(&app);
    settingsWatcher->addPath(QFileInfo(settingsFile).absolutePath());
    QObject::connect(settingsWatcher, &QFileSystemWatcher::directoryChanged,
                     &app, refreshGlass);

    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const auto &w : warnings) {
            std::cerr << "[titan-shell-qml] " << w.toString().toStdString() << "\n";
        }
    });

    const QUrl url(QStringLiteral("qrc:/qml/ShellRoot.qml"));
    engine.load(url);

    // Initial trigger if started with specific flags
    if (parser.isSet(clipOpt)) shell.showSpotlightClipboard();
    else if (parser.isSet(notifOpt)) shell.showQuicksettingsNotifs();
    else if (parser.isSet(spotlightOpt)) shell.toggleSpotlight();
    else if (parser.isSet(qsOpt)) shell.toggleQuicksettings();
    else if (parser.isSet(sysmonOpt)) shell.toggleSysmon();
    else if (parser.isSet(menuOpt)) shell.toggleMenu();
    else if (parser.isSet(wsOpt)) shell.toggleWorkspaceHud();

    malloc_trim(0);
    return app.exec();
}
