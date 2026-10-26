#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickImageProvider>
#include <QIcon>
#include <QPixmap>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

#include "ipcserver.h"
#include "hyprlandcontroller.h"

class AppIconProvider : public QQuickImageProvider
{
public:
    AppIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        int targetW = requestedSize.width() > 0 ? requestedSize.width() : 48;
        int targetH = requestedSize.height() > 0 ? requestedSize.height() : 48;

        QString name = id.toLower();
        QStringList candidates = {
            name,
            name.remove("-ide"),
            name.remove("org.kde."),
            name.remove("google-"),
            name.split('-').first(),
            name.split('.').last()
        };

        if (id.contains("chrome", Qt::CaseInsensitive)) candidates.prepend("google-chrome");
        if (id.contains("antigravity", Qt::CaseInsensitive)) candidates.prepend("antigravity-ide");
        if (id.contains("kitty", Qt::CaseInsensitive)) candidates.prepend("kitty");
        if (id.contains("dolphin", Qt::CaseInsensitive)) candidates.prepend("org.kde.dolphin");
        if (id.contains("code", Qt::CaseInsensitive)) candidates.prepend("code");
        if (id.contains("firefox", Qt::CaseInsensitive)) candidates.prepend("firefox");

        for (const QString &cand : candidates) {
            if (QIcon::hasThemeIcon(cand)) {
                QIcon icon = QIcon::fromTheme(cand);
                QPixmap pix = icon.pixmap(targetW, targetH);
                if (!pix.isNull()) {
                    if (size) *size = pix.size();
                    return pix;
                }
            }

            QStringList paths = {
                "/usr/share/pixmaps/" + cand + ".png",
                "/usr/share/pixmaps/" + cand + ".svg",
                "/usr/share/icons/hicolor/48x48/apps/" + cand + ".png",
                "/usr/share/icons/hicolor/scalable/apps/" + cand + ".svg",
                "/usr/share/icons/breeze-dark/apps/48/" + cand + ".svg"
            };

            for (const QString &p : paths) {
                if (QFile::exists(p)) {
                    QPixmap pix(p);
                    if (!pix.isNull()) {
                        QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                        if (size) *size = scaled.size();
                        return scaled;
                    }
                }
            }
        }

        QIcon fallback = QIcon::fromTheme("application-x-executable");
        QPixmap pix = fallback.pixmap(targetW, targetH);
        if (size) *size = pix.size();
        return pix;
    }
};

int main(int argc, char *argv[])
{
    // CLI handling for immediate IPC client execution
    if (argc > 1) {
        QString arg = QString::fromUtf8(argv[1]).trimmed();
        if (arg == "hold" || arg == "--hold") {
            if (IpcServer::sendCommand("HOLD")) {
                return 0;
            }
        } else if (arg == "release" || arg == "--release") {
            if (IpcServer::sendCommand("RELEASE")) {
                return 0;
            }
            return 0;
        } else if (arg == "toggle" || arg == "--toggle") {
            if (IpcServer::sendCommand("TOGGLE")) {
                return 0;
            }
        } else if (arg == "show" || arg == "--show") {
            if (IpcServer::sendCommand("SHOW")) {
                return 0;
            }
        } else if (arg == "hide" || arg == "--hide") {
            if (IpcServer::sendCommand("HIDE")) {
                return 0;
            }
            return 0;
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("titan-workspace-hud");
    app.setApplicationDisplayName("ArchTitan Workspace HUD");
    app.setOrganizationName("ArchTitan");

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    IpcServer ipc;
    if (!ipc.startServer()) {
        std::cerr << "[titan-ws-hud] Another instance may be running or failed to bind socket.\n";
    }

    HyprlandController hyprland;

    QQmlApplicationEngine engine;
    engine.addImageProvider("icon", new AppIconProvider());
    engine.rootContext()->setContextProperty("hyprland", &hyprland);

    const QUrl url(QStringLiteral("qrc:/qml/WorkspaceHudWindow.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &ipc, &hyprland, argc, argv](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

        auto window = qobject_cast<QQuickWindow*>(obj);
        if (!window) return;

        window->setWidth(1264);
        window->setHeight(320);

        auto layerWindow = LayerShellQt::Window::get(window);
        if (layerWindow) {
            layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
            layerWindow->setAnchors(LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop));
            layerWindow->setMargins(QMargins(0, 110, 0, 0));
            layerWindow->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
            layerWindow->setScope("titan-workspace-hud");
        }

        QObject::connect(&ipc, &IpcServer::showRequested, window, [&hyprland, window]() {
            hyprland.refresh();
            window->show();
            QMetaObject::invokeMethod(window, "openHud");
        });

        QObject::connect(&ipc, &IpcServer::hideRequested, window, [window]() {
            QMetaObject::invokeMethod(window, "closeHud");
        });

        QObject::connect(&ipc, &IpcServer::toggleRequested, window, [&hyprland, window]() {
            hyprland.refresh();
            if (window->isVisible()) {
                QMetaObject::invokeMethod(window, "closeHud");
            } else {
                window->show();
                QMetaObject::invokeMethod(window, "openHud");
            }
        });

        bool startHidden = true;
        if (argc > 1) {
            QString first = QString::fromUtf8(argv[1]);
            if (first == "--show" || first == "show") {
                startHidden = false;
            }
        }

        if (!startHidden) {
            hyprland.refresh();
            window->show();
            QMetaObject::invokeMethod(window, "openHud");
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
