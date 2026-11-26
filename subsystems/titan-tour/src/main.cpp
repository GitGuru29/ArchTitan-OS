#include <QCommandLineOption>
#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QImage>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickWindow>
#include <QTimer>
#include <csignal>

#ifdef HAVE_LAYERSHELLQT
#include <LayerShellQt/Window>
#endif

#include "tourcontroller.h"

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        if (!qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
            qputenv("QT_QPA_PLATFORM", "wayland");
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-tour"));
    app.setApplicationDisplayName(QStringLiteral("RISE, TITAN. — ArchTitan Tour"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));
    app.setApplicationVersion(QStringLiteral("3.0.0"));

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription(
        QStringLiteral("ArchTitan OS — Cinematic First-Run Experience & Live Feature Guide"));
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption modeOption(
        QStringLiteral("mode"),
        QStringLiteral("Tour mode: welcome | whats-new | replay"),
        QStringLiteral("mode"));
    QCommandLineOption stepOption(
        QStringLiteral("step"),
        QStringLiteral("Jump directly to a feature/step id (e.g. spotlight, workspace, quicksettings)"),
        QStringLiteral("step"));
    QCommandLineOption autostartOption(
        QStringLiteral("autostart"),
        QStringLiteral("Run in login autostart mode (shows Welcome on first run, What's New after update)"));
    QCommandLineOption forceOption(
        QStringLiteral("force"),
        QStringLiteral("Force showing the full tour even if already completed"));
    QCommandLineOption layerOption(
        QStringLiteral("layer-shell"),
        QStringLiteral("Attach as a full-screen Wayland LayerShell surface"));
    QCommandLineOption dumpOption(
        QStringLiteral("dump-slides"),
        QStringLiteral("Render all tour scenes to PNG images in <dir> and exit"),
        QStringLiteral("dir"));

    parser.addOption(modeOption);
    parser.addOption(stepOption);
    parser.addOption(autostartOption);
    parser.addOption(forceOption);
    parser.addOption(layerOption);
    parser.addOption(dumpOption);
    parser.process(app);

    const QString requestedMode = parser.value(modeOption);
    const QString requestedStep = parser.value(stepOption);
    const bool isAutostart = parser.isSet(autostartOption);
    const bool isForce = parser.isSet(forceOption);
    const bool useLayerShell = parser.isSet(layerOption);
    const QString dumpDir = parser.value(dumpOption);

    TourController tourCtrl;
    if (!dumpDir.isEmpty()) {
        tourCtrl.setSoundFxEnabled(false);
        tourCtrl.setReducedMotion(true);
        tourCtrl.adapter()->setAssumeAvailable(true);
    }

    if (dumpDir.isEmpty()) {
        if (!tourCtrl.configureSession(requestedMode, requestedStep, isAutostart, isForce)) {
            return 0;
        }
    } else {
        tourCtrl.configureSession(
            requestedMode.isEmpty() ? QStringLiteral("welcome") : requestedMode,
            requestedStep, false, true);
    }

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/titan-ui/build/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() +
                         QStringLiteral("/../../../airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QCoreApplication::applicationDirPath() +
                         QStringLiteral("/../../airootfs/usr/lib/qt6/qml"));

    engine.rootContext()->setContextProperty(QStringLiteral("tourCtrl"), &tourCtrl);

    const QUrl url(QStringLiteral("qrc:/qml/Main.qml"));
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [url](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl) {
                QCoreApplication::exit(-1);
            }
        },
        Qt::QueuedConnection);

    engine.load(url);
    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (!window) {
        return -1;
    }

#ifdef HAVE_LAYERSHELLQT
    if (useLayerShell && dumpDir.isEmpty() &&
        QGuiApplication::platformName().contains(QLatin1String("wayland"), Qt::CaseInsensitive)) {
        if (auto *layer = LayerShellQt::Window::get(window)) {
            layer->setAnchors(LayerShellQt::Window::Anchors(
                LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom |
                LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight));
            layer->setLayer(LayerShellQt::Window::LayerTop);
            layer->setExclusiveZone(-1);
            layer->setKeyboardInteractivity(
                LayerShellQt::Window::KeyboardInteractivityOnDemand);
            layer->setScope(QStringLiteral("titan-tour"));
        }
    }
#endif

    window->show();

    if (!dumpDir.isEmpty()) {
        QDir().mkpath(dumpDir);
        window->setProperty("entryProgress", 1.0);
        const int total = tourCtrl.totalSteps();

        auto *stepTimer = new QTimer(window);
        stepTimer->setSingleShot(true);
        int *currentIdx = new int(0);
        QObject::connect(stepTimer, &QTimer::timeout, window,
                         [window, &tourCtrl, dumpDir, total, currentIdx, stepTimer]() {
            if (*currentIdx < total) {
                QMetaObject::invokeMethod(window, "goToSlide", Q_ARG(QVariant, *currentIdx));
                window->setProperty("entryProgress", 1.0);
                window->update();
                const int idxSnap = *currentIdx;
                QTimer::singleShot(220, window, [window, dumpDir, idxSnap, currentIdx, stepTimer]() {
                    const QImage img = window->grabWindow();
                    img.save(QStringLiteral("%1/step_%2.png")
                                 .arg(dumpDir)
                                 .arg(idxSnap + 1, 2, 10, QLatin1Char('0')));
                    (*currentIdx)++;
                    stepTimer->start(80);
                });
                return;
            }
            if (*currentIdx == total) {
                tourCtrl.goToStepId(QStringLiteral("quicksettings"));
                tourCtrl.activateLiveFeature();
                window->update();
                QTimer::singleShot(220, window, [window, &tourCtrl, dumpDir, currentIdx, stepTimer]() {
                    const QImage img = window->grabWindow();
                    img.save(QStringLiteral("%1/live_spotlight_quicksettings.png").arg(dumpDir));
                    tourCtrl.dismissLiveFeature();
                    (*currentIdx)++;
                    stepTimer->start(80);
                });
                return;
            }
            if (*currentIdx == total + 1) {
                tourCtrl.setMode(QStringLiteral("whats-new"));
                window->update();
                QTimer::singleShot(220, window, [window, dumpDir, currentIdx]() {
                    const QImage img = window->grabWindow();
                    img.save(QStringLiteral("%1/whats_new.png").arg(dumpDir));
                    delete currentIdx;
                    QGuiApplication::quit();
                });
                return;
            }
        });
        stepTimer->start(120);
    }

    return app.exec();
}
