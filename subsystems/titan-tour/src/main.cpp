#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QCommandLineParser>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QTimer>
#include <QImage>
#include <QQuickItem>
#include <csignal>
#include <iostream>

#include "tourcontroller.h"

int main(int argc, char *argv[])
{
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM")) {
        if (!qEnvironmentVariableIsEmpty("WAYLAND_DISPLAY")) {
            qputenv("QT_QPA_PLATFORM", "wayland");
        }
    }

    QGuiApplication app(argc, argv);
    app.setApplicationName("titan-tour");
    app.setApplicationDisplayName("Welcome to ArchTitan");
    app.setOrganizationName("ArchTitan");

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    QCommandLineParser parser;
    parser.setApplicationDescription("ArchTitan macOS-Style Onboarding & System Guide");
    parser.addHelpOption();
    parser.addVersionOption();

    QCommandLineOption autostartOption("autostart", "Run in autostart mode (respects .tour-done on installed systems)");
    QCommandLineOption forceOption("force", "Force showing tour even if already completed");
    QCommandLineOption dumpOption("dump-slides", "Render all slides to PNG images in <dir> and exit", "dir");
    parser.addOption(autostartOption);
    parser.addOption(forceOption);
    parser.addOption(dumpOption);
    parser.process(app);

    bool isAutostart = parser.isSet(autostartOption);
    bool isForce = parser.isSet(forceOption);
    QString dumpDir = parser.value(dumpOption);

    if (isAutostart && !isForce && dumpDir.isEmpty()) {
        bool isLive = QFile::exists("/run/archiso");
        if (!isLive) {
            QString doneFlag = QDir::homePath() + "/.config/archtitan/.tour-done";
            if (QFile::exists(doneFlag)) {
                return 0;
            }
        }
    }

    TourController tourCtrl;
    if (!dumpDir.isEmpty()) {
        tourCtrl.setSoundFxEnabled(false);
    }

    // Library paths
    QStringList libDirs = {
        QStringLiteral("/usr/lib"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/lib"),
        QDir::currentPath() + QStringLiteral("/titan-ui/build"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/lib"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/lib")
    };
    QString existingLd = qEnvironmentVariable("LD_LIBRARY_PATH");
    if (!existingLd.isEmpty()) libDirs.prepend(existingLd);
    qputenv("LD_LIBRARY_PATH", libDirs.join(QLatin1Char(':')).toUtf8());

    QQmlApplicationEngine engine;
    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/airootfs/usr/lib/qt6/qml"));
    engine.addImportPath(QDir::currentPath() + QStringLiteral("/titan-ui/build/qml"));
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

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

    auto *window = qobject_cast<QQuickWindow *>(engine.rootObjects().first());
    if (window) {
        window->show();

        if (!dumpDir.isEmpty()) {
            QDir().mkpath(dumpDir);
            window->setProperty("entryProgress", 1.0);
            int total = window->property("totalSlides").toInt();
            if (total <= 0) total = 5;

            auto *stepTimer = new QTimer(window);
            int *currentIdx = new int(0);
            QObject::connect(stepTimer, &QTimer::timeout, window, [window, dumpDir, total, currentIdx, stepTimer]() {
                if (*currentIdx >= total) {
                    stepTimer->stop();
                    delete currentIdx;
                    QGuiApplication::quit();
                    return;
                }
                window->setProperty("currentSlide", *currentIdx);
                window->setProperty("entryProgress", 1.0);
                QTimer::singleShot(180, window, [window, dumpDir, currentIdx]() {
                    QImage img = window->grabWindow();
                    QString outPath = QStringLiteral("%1/slide_%2.png").arg(dumpDir).arg(*currentIdx + 1);
                    img.save(outPath);
                    (*currentIdx)++;
                });
            });
            stepTimer->start(350);
        }
    }

    return app.exec();
}
