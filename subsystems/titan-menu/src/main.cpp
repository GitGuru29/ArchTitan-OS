#include <QCommandLineParser>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

#include "ipcserver.h"
#include "menucontroller.hpp"

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    // Allow `QT_QPA_PLATFORM=offscreen titan-menu --selftest` in CI; otherwise
    // default to Wayland (layer-shell needs it).
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Fast path: a running daemon handles these over the socket, so the
    // keybind never pays for a second Qt start-up.
    for (int i = 1; i < argc; ++i) {
        const QString arg = QString::fromUtf8(argv[i]);
        if (arg == "--toggle" || arg == "-t") {
            if (IpcServer::sendCommand(QStringLiteral("TOGGLE"))) return 0;
            break;
        } else if (arg == "--show") {
            if (IpcServer::sendCommand(QStringLiteral("SHOW"))) return 0;
            break;
        } else if (arg == "--hide") {
            IpcServer::sendCommand(QStringLiteral("HIDE"));
            return 0;
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-menu"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Menu"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT,  [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan system menu"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption daemonOption({"d", "daemon"}, QStringLiteral("Start hidden in daemon mode"));
    QCommandLineOption toggleOption({"t", "toggle"}, QStringLiteral("Toggle the menu"));
    QCommandLineOption showOption("show", QStringLiteral("Show the menu"));
    QCommandLineOption hideOption("hide", QStringLiteral("Hide the menu"));
    parser.addOption(daemonOption);
    parser.addOption(toggleOption);
    parser.addOption(showOption);
    parser.addOption(hideOption);
    parser.process(app);

    const bool startHidden = parser.isSet(daemonOption);

    IpcServer ipc;
    ipc.startServer();

    MenuController menu;
    if (!menu.loadDefault())
        return 1;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("menu", &menu);

    const QUrl url(QStringLiteral("qrc:/qml/MenuWindow.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url, &ipc, startHidden](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
                return;
            }

            auto *window = qobject_cast<QQuickWindow *>(obj);
            if (!window)
                return;

            if (auto *layer = LayerShellQt::Window::get(window)) {
                // Full-screen overlay: the dim scrim catches click-away, the
                // card sits centred. Exclusive keyboard focus so typing works
                // the instant the menu opens.
                layer->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight |
                    LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom));
                layer->setLayer(LayerShellQt::Window::LayerOverlay);
                layer->setExclusiveZone(-1);
                layer->setKeyboardInteractivity(
                    LayerShellQt::Window::KeyboardInteractivityExclusive);
                layer->setScope(QStringLiteral("titan-menu"));
            }

            QObject::connect(&ipc, &IpcServer::toggleRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "toggleMenu");
            });
            QObject::connect(&ipc, &IpcServer::showRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "openMenu");
            });
            QObject::connect(&ipc, &IpcServer::hideRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "closeMenu");
            });

            if (!startHidden)
                QMetaObject::invokeMethod(window, "openMenu");
        },
        Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
