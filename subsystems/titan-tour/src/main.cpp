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

#include <LayerShellQt/Window>

#include "tourcontroller.h"

int main(int argc, char *argv[])
{
    qputenv("QML_DISABLE_DISK_CACHE", "1");
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    }
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-tour"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Virtual Tour"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT,  [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("ArchTitan Cinematic Virtual Tour & Spatial Onboarding"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption autostartOption(QStringLiteral("autostart"), QStringLiteral("Run in autostart mode (respects .tour-done on installed systems)"));
    QCommandLineOption forceOption(QStringLiteral("force"), QStringLiteral("Force showing tour even if already completed"));
    parser.addOption(autostartOption);
    parser.addOption(forceOption);
    parser.process(app);

    const bool isAutostart = parser.isSet(autostartOption);
    const bool isForce = parser.isSet(forceOption);

    if (isAutostart && !isForce) {
        const bool isLive = QFile::exists(QStringLiteral("/run/archiso"));
        if (!isLive) {
            const QString doneFlag = QDir::homePath() + QStringLiteral("/.config/archtitan/.tour-done");
            if (QFile::exists(doneFlag)) {
                return 0;
            }
        }
    }

    TourController tourCtrl;

    // Ensure child processes (titan-quicksettings, titan-sysmon, titan-spotlight, etc.)
    // can always resolve libTitanUI.so and ArchTitan.TitanUI QML module
    QStringList libDirs = {
        QStringLiteral("/usr/lib"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/lib"),
        QDir::currentPath() + QStringLiteral("/titan-ui/build"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/lib"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/lib")
    };
    const QString existingLd = qEnvironmentVariable("LD_LIBRARY_PATH");
    if (!existingLd.isEmpty()) libDirs.prepend(existingLd);
    qputenv("LD_LIBRARY_PATH", libDirs.join(QLatin1Char(':')).toUtf8());

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/local/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/titan-ui/build/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/lib/qt6/qml"));

    auto *context = engine.rootContext();
    context->setContextProperty(QStringLiteral("tourCtrl"), &tourCtrl);

    const QUrl url(QStringLiteral("qrc:/qml/TourWindow.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
                return;
            }

            auto *window = qobject_cast<QQuickWindow *>(obj);
            if (!window)
                return;

            if (auto *layer = LayerShellQt::Window::get(window)) {
                layer->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorLeft |
                    LayerShellQt::Window::AnchorRight |
                    LayerShellQt::Window::AnchorTop |
                    LayerShellQt::Window::AnchorBottom));
                layer->setLayer(LayerShellQt::Window::LayerOverlay);
                layer->setExclusiveZone(-1);
                layer->setKeyboardInteractivity(
                    LayerShellQt::Window::KeyboardInteractivityExclusive);
                layer->setScope(QStringLiteral("titan-tour"));
            }

            QMetaObject::invokeMethod(window, "openTour");
        },
        Qt::QueuedConnection);

    engine.load(url);
    return app.exec();
}
