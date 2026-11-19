#include <cstdio>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlError>
#include <QQmlContext>
#include <QQuickStyle>
#include <QFontDatabase>
#include <QIcon>
#include <QFile>
#include <QDir>
#include <QSurfaceFormat>

#include "settingsbackend.h"
#include "systeminfo.h"
#include "networkmanager.h"
#include "displaymanager.h"
#include "audiobackend.h"
#include "wallpapermanager.h"

int main(int argc, char *argv[]) {
    // ── Enable Wayland Alpha/Transparency ────────────────────────
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QGuiApplication app(argc, argv);

    app.setApplicationName("ArchTitan Settings");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("ArchTitan");
    app.setOrganizationDomain("archtitan.os");
    app.setDesktopFileName(QStringLiteral("archtitan-settings"));

    QQuickStyle::setStyle("Basic");

    // ── Load Inter font if available ─────────────────────────────
    // Try multiple common font paths on Arch Linux
    QStringList fontDirs = {
        "/usr/share/fonts/inter",
        "/usr/share/fonts/TTF",
        "/usr/share/fonts/truetype/inter"
    };
    QStringList fontWeights = {"Regular", "Medium", "SemiBold", "Bold"};
    for (const QString &dir : fontDirs) {
        for (const QString &w : fontWeights) {
            QFontDatabase::addApplicationFont(dir + "/Inter-" + w + ".otf");
            QFontDatabase::addApplicationFont(dir + "/Inter-" + w + ".ttf");
        }
    }

    QQmlApplicationEngine engine;

    SettingsBackend settingsBackend;
    SystemInfo      systemInfo;
    NetworkManager  networkManager;
    DisplayManager  displayManager;
    AudioBackend    audioBackend;
    WallpaperManager wallpaperManager;

    engine.rootContext()->setContextProperty("SettingsBackend",   &settingsBackend);
    engine.rootContext()->setContextProperty("SystemInfo",        &systemInfo);
    engine.rootContext()->setContextProperty("NetworkManager",    &networkManager);
    engine.rootContext()->setContextProperty("DisplayManager",    &displayManager);
    engine.rootContext()->setContextProperty("AudioBackend",      &audioBackend);
    engine.rootContext()->setContextProperty("WallpaperManager",  &wallpaperManager);

    // ── QML URL: filesystem (dev) or embedded resource ────────────
    using namespace Qt::StringLiterals;

    engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/usr/local/lib/qt6/qml"));
    engine.addImportPath(QDir::homePath() + QStringLiteral("/.local/lib/qt6/qml"));

    // Check for dev-mode override via QML_SOURCE_DIR env variable
    QString qmlSourceDir = qEnvironmentVariable("QML_SOURCE_DIR");
    QUrl url;
    if (!qmlSourceDir.isEmpty() && QFile::exists(qmlSourceDir + "/Main.qml")) {
        url = QUrl::fromLocalFile(qmlSourceDir + "/Main.qml");
        engine.addImportPath(qmlSourceDir);
        engine.addImportPath(qmlSourceDir + "/..");
    } else {
        // The module's qmldir lives at qrc:/ArchTitanSettings/qmldir, so the
        // import path must be the resource root. Adding "qrc:/ArchTitanSettings"
        // here makes QML look for qrc:/ArchTitanSettings/ArchTitanSettings/qmldir,
        // which does not exist; the module then resolves via its auto-registration
        // stub (which registers no QML-only types) and pages fail with
        // "X is not a type" on startup.
        engine.addImportPath(u"qrc:/"_s);
        url = QUrl(u"qrc:/ArchTitanSettings/qml/Main.qml"_s);
    }

    // Keep QML diagnostics around so a startup failure is actionable. Many Qt
    // builds ship with warning output compiled out, so print explicitly.
    QList<QQmlError> qmlDiagnostics;
    QObject::connect(&engine, &QQmlEngine::warnings, &app,
                     [&qmlDiagnostics](const QList<QQmlError> &warnings) {
        qmlDiagnostics.append(warnings);
    });

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url, &qmlDiagnostics](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            for (const QQmlError &e : qmlDiagnostics)
                fprintf(stderr, "[archtitan-settings] QML: %s\n", qPrintable(e.toString()));
            fprintf(stderr, "[archtitan-settings] FATAL: QML failed to load root object for %s\n",
                    qPrintable(objUrl.toString()));
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
