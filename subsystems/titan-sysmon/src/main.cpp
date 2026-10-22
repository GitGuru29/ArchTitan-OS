#include <QCommandLineParser>
#include <QDateTime>
#include <QDir>
#include <QFileInfo>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSettings>
#include <QScreen>
#include <QStandardPaths>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

#include "gpumodel.hpp"
#include "ipcserver.h"
#include "sysmoncontroller.hpp"

namespace {

// ── Layout config ────────────────────────────────────────────────────────────
// ~/.config/titan-sysmon/config.ini — width + vertical insets.
QString configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
           + QStringLiteral("/titan-sysmon/config.ini");
}

void ensureDefaultConfig()
{
    const QString path = configPath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    if (QFile::exists(path))
        return;

    QSettings cfg(path, QSettings::IniFormat);
    cfg.beginGroup(QStringLiteral("layout"));
    cfg.setValue(QStringLiteral("width"),        420);
    cfg.setValue(QStringLiteral("margin_top"),     0);
    cfg.setValue(QStringLiteral("margin_bottom"),  0);
    cfg.endGroup();
    cfg.sync();
    std::cout << "[titan-sysmon] Created default config: " << path.toStdString() << "\n";
}

struct LayoutConfig { int width; int marginTop; int marginBottom; };

LayoutConfig readConfig()
{
    QSettings cfg(configPath(), QSettings::IniFormat);
    cfg.beginGroup(QStringLiteral("layout"));
    LayoutConfig lc;
    lc.width        = cfg.value(QStringLiteral("width"),        420).toInt();
    lc.marginTop    = cfg.value(QStringLiteral("margin_top"),     0).toInt();
    lc.marginBottom = cfg.value(QStringLiteral("margin_bottom"),  0).toInt();
    cfg.endGroup();
    return lc;
}

} // namespace

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Fast-path CLI dispatch — a running daemon handles these over the socket.
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
        } else if (arg == "--config") {
            ensureDefaultConfig();
            const LayoutConfig lc = readConfig();
            std::cout << "Config: " << configPath().toStdString() << "\n"
                      << "  width         = " << lc.width        << "\n"
                      << "  margin_top    = " << lc.marginTop    << "\n"
                      << "  margin_bottom = " << lc.marginBottom << "\n";
            return 0;
        }
    }

    ensureDefaultConfig();

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-sysmon"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan System Monitor"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT,  [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan System Monitor overlay"));
    parser.addHelpOption();
    parser.addVersionOption();
    QCommandLineOption daemonOption({"d", "daemon"}, QStringLiteral("Start hidden in daemon mode"));
    QCommandLineOption toggleOption({"t", "toggle"}, QStringLiteral("Toggle the overlay"));
    QCommandLineOption showOption("show", QStringLiteral("Show the overlay"));
    QCommandLineOption hideOption("hide", QStringLiteral("Hide the overlay"));
    parser.addOption(daemonOption);
    parser.addOption(toggleOption);
    parser.addOption(showOption);
    parser.addOption(hideOption);
    parser.process(app);

    const bool startHidden = parser.isSet(daemonOption);

    IpcServer ipc;
    ipc.startServer();

    GpuModel gpuModel;
    SysmonController sysmon(&gpuModel);

    QQmlApplicationEngine engine;
    auto *context = engine.rootContext();
    context->setContextProperty("sysmon",   &sysmon);
    context->setContextProperty("gpuModel", &gpuModel);

    const QUrl url(QStringLiteral("qrc:/qml/SystemMonitorWindow.qml"));
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

            auto *layerWindow = LayerShellQt::Window::get(window);
            if (layerWindow) {
                const LayoutConfig lc = readConfig();
                layerWindow->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorLeft |
                    LayerShellQt::Window::AnchorTop |
                    LayerShellQt::Window::AnchorBottom));
                layerWindow->setMargins(QMargins(0, lc.marginTop, 0, lc.marginBottom));
                layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
                layerWindow->setExclusiveZone(0);
                layerWindow->setKeyboardInteractivity(
                    LayerShellQt::Window::KeyboardInteractivityOnDemand);
                layerWindow->setScope(QStringLiteral("titan-sysmon"));
                window->setWidth(lc.width);

                std::cout << "[titan-sysmon] Surface width=" << lc.width
                          << " margins=" << lc.marginTop << "/" << lc.marginBottom << "\n";
            }

            QObject::connect(&ipc, &IpcServer::toggleRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "togglePanel");
            });
            QObject::connect(&ipc, &IpcServer::showRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "openPanel");
            });
            QObject::connect(&ipc, &IpcServer::hideRequested, window, [window]() {
                QMetaObject::invokeMethod(window, "closePanel");
            });

            // Dismiss on click-away (see titan-quicksettings for the rationale: a
            // layer surface is only focused after a click, so stamp the
            // activation and close on the first deactivation that follows, with
            // a grace period for mapping flicker).
            QObject::connect(window, &QQuickWindow::activeChanged, window, [window]() {
                constexpr qint64 graceMs = 400;
                if (window->isActive()) {
                    window->setProperty("titanFocusArmedAt", QDateTime::currentMSecsSinceEpoch());
                    return;
                }
                const qint64 armedAt = window->property("titanFocusArmedAt").toLongLong();
                if (armedAt > 0 && QDateTime::currentMSecsSinceEpoch() - armedAt >= graceMs) {
                    window->setProperty("titanFocusArmedAt", QVariant(0));
                    QMetaObject::invokeMethod(window, "closePanel");
                }
            });

            if (!startHidden)
                QMetaObject::invokeMethod(window, "openPanel");
        },
        Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
