#include <QDir>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QString>
#include <csignal>
#include <iostream>
#include <malloc.h>

#include "focuscontroller.h"
#include "ipcserver.h"

namespace {

void printUsage() {
    std::cout << "Usage: titan-focus [options]\n\n"
              << "ArchTitan OS — TitanFocus Developer Work Optimization Engine\n"
              << "(Advisory only; never throttles or signals processes.)\n\n"
              << "Options:\n"
              << "  -d, --daemon           Start background daemon\n"
              << "  -t, --toggle           Toggle focus pill overlay\n"
              << "      --show             Show focus pill overlay\n"
              << "      --hide             Hide focus pill overlay\n"
              << "      --snooze <mins>    Snooze nudges for <mins> (default 15)\n"
              << "      --break <mins>     Start break timer for <mins> (default 10)\n"
              << "      --end-break        End active break early\n"
              << "      --dismiss          Dismiss latest nudge\n"
              << "      --dnd [on|off]     Toggle or set Do Not Disturb\n"
              << "      --status           Print daemon JSON status\n"
              << "      --waybar           Print Waybar custom module JSON\n"
              << "      --reset            Reset session timers\n"
              << "  -h, --help             Show this help\n";
}

} // namespace

int main(int argc, char *argv[]) {
    using titan::focus::IpcServer;

    // ── Fast-path CLI dispatch before QGuiApplication construction (< 5 ms) ──
    bool startDaemon = false;
    bool openOverlayOnStart = false;

    for (int i = 1; i < argc; ++i) {
        const QString arg = QString::fromUtf8(argv[i]);
        if (arg == QLatin1String("-h") || arg == QLatin1String("--help")) {
            printUsage();
            return 0;
        }
        if (arg == QLatin1String("-d") || arg == QLatin1String("--daemon")) {
            startDaemon = true;
            continue;
        }

        QString ipcCmd;
        bool printReply = false;

        if (arg == QLatin1String("-t") || arg == QLatin1String("--toggle")) {
            ipcCmd = QStringLiteral("TOGGLE");
            openOverlayOnStart = true;
        } else if (arg == QLatin1String("--show")) {
            ipcCmd = QStringLiteral("SHOW");
            openOverlayOnStart = true;
        } else if (arg == QLatin1String("--hide")) {
            ipcCmd = QStringLiteral("HIDE");
        } else if (arg == QLatin1String("--snooze")) {
            const QString mins = (i + 1 < argc) ? QString::fromUtf8(argv[++i]) : QStringLiteral("15");
            ipcCmd = QStringLiteral("SNOOZE ") + mins;
        } else if (arg == QLatin1String("--break")) {
            const QString mins = (i + 1 < argc) ? QString::fromUtf8(argv[++i]) : QStringLiteral("10");
            ipcCmd = QStringLiteral("BREAK ") + mins;
        } else if (arg == QLatin1String("--end-break")) {
            ipcCmd = QStringLiteral("END_BREAK");
        } else if (arg == QLatin1String("--dismiss")) {
            ipcCmd = QStringLiteral("DISMISS");
        } else if (arg == QLatin1String("--dnd")) {
            QString mode = QStringLiteral("toggle");
            if (i + 1 < argc && !QString::fromUtf8(argv[i + 1]).startsWith(QLatin1Char('-'))) {
                mode = QString::fromUtf8(argv[++i]);
            }
            ipcCmd = QStringLiteral("DND ") + mode;
            printReply = true;
        } else if (arg == QLatin1String("--status")) {
            ipcCmd = QStringLiteral("STATUS");
            printReply = true;
        } else if (arg == QLatin1String("--waybar")) {
            ipcCmd = QStringLiteral("WAYBAR");
            printReply = true;
        } else if (arg == QLatin1String("--reset")) {
            ipcCmd = QStringLiteral("RESET");
        }

        if (!ipcCmd.isEmpty()) {
            QString reply;
            if (IpcServer::sendCommand(ipcCmd, printReply ? &reply : nullptr)) {
                if (printReply && !reply.isEmpty()) {
                    std::cout << reply.toStdString() << "\n";
                }
                return 0;
            }
            // Waybar fallback when daemon is not yet running
            if (ipcCmd == QLatin1String("WAYBAR")) {
                std::cout << "{\"text\":\"󰔟 --\",\"tooltip\":\"TitanFocus daemon offline (click to start)\",\"class\":\"offline\"}\n";
                return 0;
            }
            if (!openOverlayOnStart) {
                std::cerr << "[titan-focus] Daemon not running.\n";
                return 1;
            }
            break; // Start daemon & open requested view
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-focus"));
    app.setApplicationVersion(QStringLiteral("1.0.0"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));
    app.setQuitOnLastWindowClosed(false);

    std::signal(SIGINT,  [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    IpcServer ipc;
    if (!ipc.startServer()) {
        // Another instance owns the socket; forward toggle if requested
        if (openOverlayOnStart) {
            IpcServer::sendCommand(QStringLiteral("TOGGLE"));
            return 0;
        }
        return 1;
    }

    titan::focus::FocusController controller;
    ipc.setHandler([&controller](const QString &cmd) {
        return controller.handleIpcCommand(cmd);
    });

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/local/lib/qt6/qml"));
    const QString devQml = QDir::currentPath() + QStringLiteral("/titan-ui/build/qml");
    if (QDir(devQml).exists()) engine.addImportPath(devQml);
    const QString airootQml = QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml");
    if (QDir(airootQml).exists()) engine.addImportPath(airootQml);

    engine.rootContext()->setContextProperty(QStringLiteral("focusCtrl"), &controller);

    QObject::connect(&engine, &QQmlApplicationEngine::warnings, [](const QList<QQmlError> &warnings) {
        for (const auto &w : warnings) {
            std::cerr << "[titan-focus-qml] " << w.toString().toStdString() << "\n";
        }
    });

    engine.load(QUrl(QStringLiteral("qrc:/qml/FocusRoot.qml")));
    controller.start();

    if (openOverlayOnStart && !startDaemon) {
        controller.showPill();
    }

    malloc_trim(0);
    return app.exec();
}
