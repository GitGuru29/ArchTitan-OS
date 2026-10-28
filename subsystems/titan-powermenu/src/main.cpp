#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QDateTime>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

#include "ipcserver.h"
#include "powermenucontroller.h"

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Fast-path CLI IPC dispatch:
    if (argc > 1) {
        QString first = QString::fromUtf8(argv[1]).trimmed().toLower();
        if (first == QStringLiteral("-t") || first == QStringLiteral("--toggle") || first == QStringLiteral("toggle")) {
            if (IpcServer::sendCommand(QStringLiteral("TOGGLE"))) return 0;
        } else if (first == QStringLiteral("--show") || first == QStringLiteral("show")) {
            if (IpcServer::sendCommand(QStringLiteral("SHOW"))) return 0;
        } else if (first == QStringLiteral("--hide") || first == QStringLiteral("hide")) {
            if (IpcServer::sendCommand(QStringLiteral("HIDE"))) return 0;
            return 0;
        } else if (first == QStringLiteral("-l") || first == QStringLiteral("--lock") || first == QStringLiteral("lock")) {
            if (IpcServer::sendCommand(QStringLiteral("LOCK"))) return 0;
        } else if (first == QStringLiteral("-s") || first == QStringLiteral("--suspend") || first == QStringLiteral("suspend") || first == QStringLiteral("sleep")) {
            if (IpcServer::sendCommand(QStringLiteral("SUSPEND"))) return 0;
        } else if (first == QStringLiteral("-e") || first == QStringLiteral("--logout") || first == QStringLiteral("logout") || first == QStringLiteral("exit")) {
            if (IpcServer::sendCommand(QStringLiteral("LOGOUT"))) return 0;
        } else if (first == QStringLiteral("-r") || first == QStringLiteral("--reboot") || first == QStringLiteral("reboot") || first == QStringLiteral("restart")) {
            if (IpcServer::sendCommand(QStringLiteral("REBOOT"))) return 0;
        } else if (first == QStringLiteral("-p") || first == QStringLiteral("--shutdown") || first == QStringLiteral("shutdown") || first == QStringLiteral("poweroff")) {
            if (IpcServer::sendCommand(QStringLiteral("POWEROFF"))) return 0;
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-powermenu"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Power Menu"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan OS Native Glass Power & Session Menu"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption daemonOption({QStringLiteral("d"), QStringLiteral("daemon")}, QStringLiteral("Start hidden in background daemon mode"));
    QCommandLineOption toggleOption({QStringLiteral("t"), QStringLiteral("toggle")}, QStringLiteral("Toggle Power Menu"));
    QCommandLineOption showOption(QStringLiteral("show"), QStringLiteral("Show Power Menu"));
    QCommandLineOption hideOption(QStringLiteral("hide"), QStringLiteral("Hide Power Menu"));
    QCommandLineOption lockOption({QStringLiteral("l"), QStringLiteral("lock")}, QStringLiteral("Lock screen directly"));
    QCommandLineOption suspendOption({QStringLiteral("s"), QStringLiteral("suspend")}, QStringLiteral("Suspend directly"));
    QCommandLineOption logoutOption({QStringLiteral("e"), QStringLiteral("logout")}, QStringLiteral("Logout directly"));
    QCommandLineOption rebootOption({QStringLiteral("r"), QStringLiteral("reboot")}, QStringLiteral("Reboot directly"));
    QCommandLineOption shutdownOption({QStringLiteral("p"), QStringLiteral("shutdown")}, QStringLiteral("Shutdown directly"));

    parser.addOption(daemonOption);
    parser.addOption(toggleOption);
    parser.addOption(showOption);
    parser.addOption(hideOption);
    parser.addOption(lockOption);
    parser.addOption(suspendOption);
    parser.addOption(logoutOption);
    parser.addOption(rebootOption);
    parser.addOption(shutdownOption);
    parser.process(app);

    PowerMenuController controller;

    if (parser.isSet(lockOption)) {
        controller.lockSession();
        return 0;
    }
    if (parser.isSet(suspendOption)) {
        controller.suspendSession();
        return 0;
    }
    if (parser.isSet(logoutOption)) {
        controller.logoutSession();
        return 0;
    }
    if (parser.isSet(rebootOption)) {
        controller.rebootSystem();
        return 0;
    }
    if (parser.isSet(shutdownOption)) {
        controller.shutdownSystem();
        return 0;
    }

    const bool startHidden = parser.isSet(daemonOption);

    IpcServer ipc;
    if (!ipc.startServer()) {
        std::cerr << "[titan-powermenu] Note: Another instance may be active.\n";
    }

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.rootContext()->setContextProperty(QStringLiteral("powerMenu"), &controller);

    const QUrl url(QStringLiteral("qrc:/qml/PowerMenuWindow.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &ipc, &controller, startHidden](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

        auto window = qobject_cast<QQuickWindow*>(obj);
        if (!window) return;

        LayerShellQt::Window *layer = LayerShellQt::Window::get(window);
        if (layer) {
            layer->setAnchors(LayerShellQt::Window::Anchors(
                LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight |
                LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom));
            layer->setLayer(LayerShellQt::Window::LayerOverlay);
            layer->setExclusiveZone(-1);
            layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
            layer->setScope(QStringLiteral("titan-powermenu"));
        }

        auto openWindow = [window, &controller, layer]() {
            controller.refreshStats();
            controller.setSelectedIndex(0); // Focus lock by default
            if (layer) {
                layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
            }
            QMetaObject::invokeMethod(window, "openPowerMenu");
        };

        auto closeWindow = [window, layer]() {
            if (layer) {
                layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
            }
            QMetaObject::invokeMethod(window, "closePowerMenu");
        };

        QObject::connect(&ipc, &IpcServer::toggleRequested, window, [window, openWindow, closeWindow]() {
            bool isOpen = window->property("powerMenuOpen").toBool();
            if (isOpen) {
                closeWindow();
            } else {
                openWindow();
            }
        });

        QObject::connect(&ipc, &IpcServer::showRequested, window, [openWindow]() {
            openWindow();
        });

        QObject::connect(&ipc, &IpcServer::hideRequested, window, [closeWindow]() {
            closeWindow();
        });

        QObject::connect(&ipc, &IpcServer::lockRequested, &controller, &PowerMenuController::lockSession);
        QObject::connect(&ipc, &IpcServer::suspendRequested, &controller, &PowerMenuController::suspendSession);
        QObject::connect(&ipc, &IpcServer::logoutRequested, &controller, &PowerMenuController::logoutSession);
        QObject::connect(&ipc, &IpcServer::rebootRequested, &controller, &PowerMenuController::rebootSystem);
        QObject::connect(&ipc, &IpcServer::shutdownRequested, &controller, &PowerMenuController::shutdownSystem);

        QObject::connect(&controller, &PowerMenuController::closeRequested, window, [closeWindow]() {
            closeWindow();
        });

        // Click-away / focus loss dismissal
        QObject::connect(window, &QQuickWindow::activeChanged, window, [window, closeWindow]() {
            constexpr qint64 graceMs = 400;
            if (window->isActive()) {
                window->setProperty("titanFocusArmedAt", QDateTime::currentMSecsSinceEpoch());
                return;
            }
            const qint64 armedAt = window->property("titanFocusArmedAt").toLongLong();
            if (armedAt > 0 && QDateTime::currentMSecsSinceEpoch() - armedAt >= graceMs) {
                window->setProperty("titanFocusArmedAt", QVariant(0));
                closeWindow();
            }
        });

        if (!startHidden) {
            openWindow();
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
