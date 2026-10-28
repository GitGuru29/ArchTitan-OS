#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QQuickImageProvider>
#include <QCommandLineParser>
#include <QCommandLineOption>
#include <QDateTime>
#include <QIcon>
#include <QPixmap>
#include <QFile>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

#include "ipcserver.h"
#include "spotlightcontroller.h"

class AppIconProvider : public QQuickImageProvider
{
public:
    AppIconProvider() : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override
    {
        int targetW = requestedSize.width() > 0 ? requestedSize.width() : 48;
        int targetH = requestedSize.height() > 0 ? requestedSize.height() : 48;

        if (id.startsWith(QLatin1Char('/')) && QFile::exists(id)) {
            QPixmap pix(id);
            if (!pix.isNull()) {
                QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                if (size) *size = scaled.size();
                return scaled;
            }
        }

        QString name = id.toLower();
        QStringList candidates = {
            name,
            name.remove(QStringLiteral("-ide")),
            name.remove(QStringLiteral("org.kde.")),
            name.remove(QStringLiteral("google-")),
            name.split(QLatin1Char('-')).first(),
            name.split(QLatin1Char('.')).last()
        };

        if (id.contains(QStringLiteral("chrome"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("google-chrome"));
        if (id.contains(QStringLiteral("antigravity"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("antigravity-ide"));
        if (id.contains(QStringLiteral("kitty"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("kitty"));
        if (id.contains(QStringLiteral("code"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("code"));
        if (id.contains(QStringLiteral("firefox"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("firefox"));
        if (id.contains(QStringLiteral("terminal"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("utilities-terminal"));
        if (id.contains(QStringLiteral("settings"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("preferences-system"));
        if (id.contains(QStringLiteral("calculator"), Qt::CaseInsensitive)) candidates.prepend(QStringLiteral("accessories-calculator"));

        static const QStringList baseDirs = {
            QStringLiteral("/usr/share/icons/hicolor/scalable/apps/"),
            QStringLiteral("/usr/share/icons/hicolor/48x48/apps/"),
            QStringLiteral("/usr/share/icons/breeze-dark/apps/48/"),
            QStringLiteral("/usr/share/icons/breeze/apps/48/"),
            QStringLiteral("/usr/share/pixmaps/")
        };

        for (const QString &cand : candidates) {
            for (const QString &dir : baseDirs) {
                QString png = dir + cand + QStringLiteral(".png");
                if (QFile::exists(png)) {
                    QPixmap pix(png);
                    if (!pix.isNull()) {
                        QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                        if (size) *size = scaled.size();
                        return scaled;
                    }
                }
                QString svg = dir + cand + QStringLiteral(".svg");
                if (QFile::exists(svg)) {
                    QPixmap pix(svg);
                    if (!pix.isNull()) {
                        QPixmap scaled = pix.scaled(targetW, targetH, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                        if (size) *size = scaled.size();
                        return scaled;
                    }
                }
            }
        }

        QPixmap fallback(targetW, targetH);
        fallback.fill(Qt::transparent);
        if (size) *size = fallback.size();
        return fallback;
    }
};

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    if (qgetenv("QT_QPA_PLATFORM").isEmpty())
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // CLI handling for immediate IPC client execution:
    if (argc > 1) {
        QString first = QString::fromUtf8(argv[1]).trimmed();
        if (first == QStringLiteral("-t") || first == QStringLiteral("--toggle") || first == QStringLiteral("toggle")) {
            if (IpcServer::sendCommand(QStringLiteral("TOGGLE"))) {
                return 0;
            }
        } else if (first == QStringLiteral("--show") || first == QStringLiteral("show")) {
            if (IpcServer::sendCommand(QStringLiteral("SHOW"))) {
                return 0;
            }
        } else if (first == QStringLiteral("--hide") || first == QStringLiteral("hide")) {
            if (IpcServer::sendCommand(QStringLiteral("HIDE"))) {
                return 0;
            }
            return 0;
        } else if (first == QStringLiteral("-c") || first == QStringLiteral("--clipboard") || first == QStringLiteral("clipboard")) {
            if (IpcServer::sendCommand(QStringLiteral("CLIPBOARD"))) {
                return 0;
            }
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-spotlight"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Spotlight"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan OS Native macOS-style Spotlight Launcher"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption daemonOption({QStringLiteral("d"), QStringLiteral("daemon")}, QStringLiteral("Start hidden as background daemon"));
    QCommandLineOption toggleOption({QStringLiteral("t"), QStringLiteral("toggle")}, QStringLiteral("Toggle Spotlight"));
    QCommandLineOption showOption(QStringLiteral("show"), QStringLiteral("Show Spotlight"));
    QCommandLineOption hideOption(QStringLiteral("hide"), QStringLiteral("Hide Spotlight"));
    QCommandLineOption clipboardOption({QStringLiteral("c"), QStringLiteral("clipboard")}, QStringLiteral("Open in clipboard mode"));
    parser.addOption(daemonOption);
    parser.addOption(toggleOption);
    parser.addOption(showOption);
    parser.addOption(hideOption);
    parser.addOption(clipboardOption);
    parser.process(app);

    const bool startHidden = parser.isSet(daemonOption);
    const bool startClipboard = parser.isSet(clipboardOption);

    IpcServer ipc;
    if (!ipc.startServer()) {
        std::cerr << "[titan-spotlight] Note: Another instance may be active or listening.\n";
    }

    SpotlightController controller;
    if (startClipboard) {
        controller.setClipboardMode(true);
    }

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImageProvider(QStringLiteral("icon"), new AppIconProvider());
    engine.rootContext()->setContextProperty(QStringLiteral("spotlight"), &controller);

    const QUrl url(QStringLiteral("qrc:/qml/SpotlightWindow.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &ipc, &controller, startHidden, startClipboard](QObject *obj, const QUrl &objUrl) {
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
            layer->setScope(QStringLiteral("titan-spotlight"));
        }

        auto openWindow = [window, &controller, layer](bool clipboardMode = false) {
            controller.reset();
            if (clipboardMode) {
                controller.setClipboardMode(true);
            }
            if (layer) {
                layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
            }
            QMetaObject::invokeMethod(window, "openSpotlight");
        };

        auto closeWindow = [window, layer]() {
            if (layer) {
                layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityNone);
            }
            QMetaObject::invokeMethod(window, "closeSpotlight");
        };

        QObject::connect(&ipc, &IpcServer::toggleRequested, window, [window, openWindow, closeWindow]() {
            bool isOpen = window->property("spotlightOpen").toBool();
            if (isOpen) {
                closeWindow();
            } else {
                openWindow(false);
            }
        });

        QObject::connect(&ipc, &IpcServer::showRequested, window, [openWindow]() {
            openWindow(false);
        });

        QObject::connect(&ipc, &IpcServer::hideRequested, window, [closeWindow]() {
            closeWindow();
        });

        QObject::connect(&ipc, &IpcServer::clipboardRequested, window, [openWindow]() {
            openWindow(true);
        });

        QObject::connect(&controller, &SpotlightController::closeRequested, window, [closeWindow]() {
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
            openWindow(startClipboard);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
