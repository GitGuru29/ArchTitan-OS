#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QDateTime>
#include <QSettings>
#include <QDir>
#include <QStandardPaths>
#include <csignal>
#include <iostream>

#include <LayerShellQt/window.h>

// ── Config helpers ────────────────────────────────────────────────────────────
// Edit ~/.config/titan-quicksettings/config.ini to adjust layout without
// recompiling. Restart the daemon after saving.
static QString configPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
           + "/titan-quicksettings/config.ini";
}

static void ensureDefaultConfig()
{
    QString path = configPath();
    QDir().mkpath(QFileInfo(path).absolutePath());
    if (!QFile::exists(path)) {
        QSettings cfg(path, QSettings::IniFormat);
        cfg.beginGroup("layout");
        // Layout metrics:
        //   top_margin:        px below bar surface (4 snaps cleanly below waybar)
        //   bottom_margin:     px from screen foot / workspace bottom edge (default 8)
        //   right_margin:      px from right screen edge (default 8)
        //   panel_width:       drawer width in px (default 420)
        //   panel_height:      fallback height in px (used if stretch_to_bottom=false)
        //   stretch_to_bottom: stretch drawer from bar to workspace foot (default true)
        cfg.setValue("top_margin",        4);
        cfg.setValue("bottom_margin",      8);
        cfg.setValue("right_margin",       8);
        cfg.setValue("panel_width",      420);
        cfg.setValue("panel_height",     860);
        cfg.setValue("stretch_to_bottom", true);
        cfg.endGroup();
        cfg.sync();
        std::cout << "[titan-qs] Created default config: "
                  << path.toStdString() << "\n";
    }
}

struct LayoutConfig {
    int topMargin;
    int bottomMargin;
    int rightMargin;
    int panelWidth;
    int panelHeight;
    bool stretchToBottom;
};

static LayoutConfig readConfig()
{
    QSettings cfg(configPath(), QSettings::IniFormat);
    cfg.beginGroup("layout");
    LayoutConfig lc;
    lc.topMargin        = cfg.value("top_margin",        4).toInt();
    lc.bottomMargin     = cfg.value("bottom_margin",      8).toInt();
    lc.rightMargin      = cfg.value("right_margin",       8).toInt();
    lc.panelWidth       = cfg.value("panel_width",      420).toInt();
    lc.panelHeight      = cfg.value("panel_height",     860).toInt();
    lc.stretchToBottom  = cfg.value("stretch_to_bottom", true).toBool();
    cfg.endGroup();
    return lc;
}

#include "ipcserver.h"
#include "systemcontroller.h"
#include "networkcontroller.h"
#include "bluetoothcontroller.h"
#include <malloc.h>
#include "audiocontroller.h"
#include "nightlightcontroller.h"
#include "notificationserver.h"

int main(int argc, char *argv[])
{
    // Wayland configuration & GPU rendering (software backend can be set via env var if needed)
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    // Pre-check CLI arguments for fast socket command dispatch
    for (int i = 1; i < argc; ++i) {
        QString arg = QString::fromUtf8(argv[i]);
        if (arg == "--toggle" || arg == "-t") {
            if (IpcServer::sendCommand("TOGGLE")) {
                return 0;
            }
            break;
        } else if (arg == "--show") {
            if (IpcServer::sendCommand("SHOW")) {
                return 0;
            }
            break;
        } else if (arg == "--hide") {
            if (IpcServer::sendCommand("HIDE")) {
                return 0;
            }
            return 0;
        } else if (arg == "--set-margin" && i + 1 < argc) {
            // Quick CLI override: titan-quicksettings --set-margin top=N
            // Writes to config.ini so it persists on next daemon restart.
            QString kv = QString::fromUtf8(argv[++i]);
            QStringList parts = kv.split('=');
            if (parts.size() == 2) {
                ensureDefaultConfig();
                QSettings cfg(configPath(), QSettings::IniFormat);
                cfg.beginGroup("layout");
                QString key = parts[0].trimmed();
                int val = parts[1].trimmed().toInt();
                if (key == "top")    cfg.setValue("top_margin",        val);
                if (key == "bottom") cfg.setValue("bottom_margin",     val);
                if (key == "right")  cfg.setValue("right_margin",      val);
                if (key == "width")  cfg.setValue("panel_width",       val);
                if (key == "height") cfg.setValue("panel_height",      val);
                if (key == "stretch")cfg.setValue("stretch_to_bottom", (val != 0));
                cfg.endGroup(); cfg.sync();
                std::cout << "[titan-qs] Set " << key.toStdString()
                          << " = " << val << " in " << configPath().toStdString()
                          << ". Restart the daemon to apply.\n";
            }
            return 0;
        } else if (arg == "--config") {
            ensureDefaultConfig();
            std::cout << "Config: " << configPath().toStdString() << "\n";
            auto lc = readConfig();
            std::cout << "  top_margin        = " << lc.topMargin       << "\n"
                      << "  bottom_margin     = " << lc.bottomMargin    << "\n"
                      << "  right_margin      = " << lc.rightMargin     << "\n"
                      << "  panel_width       = " << lc.panelWidth      << "\n"
                      << "  panel_height      = " << lc.panelHeight     << "\n"
                      << "  stretch_to_bottom = " << (lc.stretchToBottom ? "true" : "false") << "\n";
            return 0;
        }
    }

    ensureDefaultConfig();

    QGuiApplication app(argc, argv);
    app.setApplicationName("titan-quicksettings");
    app.setApplicationDisplayName("ArchTitan Quick Settings");
    app.setOrganizationName("ArchTitan");

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription("ArchTitan Quick Settings & Notification Center");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption daemonOption({"d", "daemon"}, "Start in background daemon mode (hidden)");
    QCommandLineOption toggleOption({"t", "toggle"}, "Toggle visibility of the quick settings drawer");
    QCommandLineOption showOption("show", "Show the quick settings drawer");
    QCommandLineOption hideOption("hide", "Hide the quick settings drawer");

    parser.addOption(daemonOption);
    parser.addOption(toggleOption);
    parser.addOption(showOption);
    parser.addOption(hideOption);
    parser.process(app);

    bool startHidden = parser.isSet(daemonOption);

    // Initialize backend controllers
    IpcServer ipc;
    ipc.startServer();

    SystemController systemCtrl;
    NetworkController netCtrl;
    BluetoothController btCtrl;
    AudioController audioCtrl;
    NightLightController nightCtrl;
    NotificationServer notifServer;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/lib/qt6/qml"));
    auto *context = engine.rootContext();
    context->setContextProperty("systemCtrl", &systemCtrl);
    context->setContextProperty("networkCtrl", &netCtrl);
    context->setContextProperty("bluetoothCtrl", &btCtrl);
    context->setContextProperty("audioCtrl", &audioCtrl);
    context->setContextProperty("nightLightCtrl", &nightCtrl);
    context->setContextProperty("notifServer", &notifServer);
    context->setContextProperty("notifModel", notifServer.model());

    const QUrl url(QStringLiteral("qrc:/qml/QuickSettingsWindow.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &ipc, startHidden](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
            return;
        }

        QQuickWindow *window = qobject_cast<QQuickWindow *>(obj);
        if (!window) return;

        // Configure LayerShell on root window
        auto *layerWindow = LayerShellQt::Window::get(window);
        if (layerWindow) {
            auto lc = readConfig();

            int screenHeight = QGuiApplication::primaryScreen()
                                   ? QGuiApplication::primaryScreen()->geometry().height()
                                   : 1080;
            int availHeight = QGuiApplication::primaryScreen()
                                  ? QGuiApplication::primaryScreen()->availableGeometry().height()
                                  : screenHeight;

            int targetHeight = lc.panelHeight;
            if (lc.stretchToBottom) {
                // Stretch to foot of desktop workspace:
                // Anchor Top + Right + Bottom so Hyprland pins both edges.
                // Distance to workspace foot is availableGeometry height minus margins.
                targetHeight = qMax(480, availHeight - lc.topMargin - lc.bottomMargin);

                layerWindow->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorTop |
                    LayerShellQt::Window::AnchorRight |
                    LayerShellQt::Window::AnchorBottom
                ));
                layerWindow->setMargins(QMargins(0, lc.topMargin, lc.rightMargin, lc.bottomMargin));
            } else {
                targetHeight = qMax(460, qMin(lc.panelHeight, availHeight - 56));

                layerWindow->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorTop |
                    LayerShellQt::Window::AnchorRight
                ));
                layerWindow->setMargins(QMargins(0, lc.topMargin, lc.rightMargin, 0));
            }

            layerWindow->setLayer(LayerShellQt::Window::LayerOverlay);
            layerWindow->setExclusiveZone(0); // 0 = don't claim space, still respect bar
            layerWindow->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
            layerWindow->setScope("titan-quicksettings");

            window->setWidth(lc.panelWidth);
            window->setHeight(targetHeight);

            std::cout << "[titan-qs] Layout: top=" << lc.topMargin
                      << " bottom=" << (lc.stretchToBottom ? lc.bottomMargin : 0)
                      << " right=" << lc.rightMargin
                      << " size=" << lc.panelWidth << "x" << targetHeight
                      << " (stretchToBottom=" << (lc.stretchToBottom ? "true" : "false") << ")\n";
        }

        QObject::connect(&ipc, &IpcServer::toggleRequested, window, [window]() {
            QMetaObject::invokeMethod(window, "toggleDrawer");
        });
        QObject::connect(&ipc, &IpcServer::showRequested, window, [window]() {
            QMetaObject::invokeMethod(window, "openDrawer");
        });
        QObject::connect(&ipc, &IpcServer::hideRequested, window, [window]() {
            QMetaObject::invokeMethod(window, "closeDrawer");
        });

        // Dismiss on click-away: a layer-shell surface only receives keyboard
        // focus once the user clicks it, so stamp the activation time and close
        // on the first deactivation that follows. The grace period swallows the
        // activate/deactivate flicker some compositors emit while mapping, and a
        // panel that was never activated keeps its Esc / hotkey dismissal.
        QObject::connect(window, &QQuickWindow::activeChanged, window, [window]() {
            constexpr qint64 graceMs = 400;
            if (window->isActive()) {
                window->setProperty("titanFocusArmedAt", QDateTime::currentMSecsSinceEpoch());
                return;
            }
            const qint64 armedAt = window->property("titanFocusArmedAt").toLongLong();
            if (armedAt > 0 && QDateTime::currentMSecsSinceEpoch() - armedAt >= graceMs) {
                window->setProperty("titanFocusArmedAt", QVariant(0));
                QMetaObject::invokeMethod(window, "closeDrawer");
            }
        });

        if (!startHidden) {
            QMetaObject::invokeMethod(window, "openDrawer");
        }
    }, Qt::QueuedConnection);

    engine.load(url);
    malloc_trim(0);

    return app.exec();
}
