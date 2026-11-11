#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <csignal>
#include <iostream>

#include "tourcontroller.h"

int main(int argc, char *argv[])
{
    // Force Wayland by default under Wayland compositors
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        if (!qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
            qputenv("QT_QPA_PLATFORM", "wayland");
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("titan-tour");
    app.setApplicationDisplayName("ArchTitan Virtual Tour");
    app.setOrganizationName("ArchTitan");

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription("ArchTitan Cinematic Virtual Tour & Onboarding");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption autostartOption("autostart", "Run in autostart mode (respects .tour-done on installed systems)");
    QCommandLineOption forceOption("force", "Force showing tour even if already completed");
    parser.addOption(autostartOption);
    parser.addOption(forceOption);
    parser.process(app);

    bool isAutostart = parser.isSet(autostartOption);
    bool isForce = parser.isSet(forceOption);

    // If running in autostart mode on an installed system and already marked done, exit early
    if (isAutostart && !isForce) {
        bool isLive = QFile::exists("/run/archiso");
        if (!isLive) {
            QString doneFlag = QDir::homePath() + "/.config/archtitan/.tour-done";
            if (QFile::exists(doneFlag)) {
                return 0;
            }
        }
    }

    TourController tourCtrl;

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/lib/qt6/qml"));

    auto *context = engine.rootContext();
    context->setContextProperty("tourCtrl", &tourCtrl);

    const QUrl url(QStringLiteral("qrc:/qml/TourWindow.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}

