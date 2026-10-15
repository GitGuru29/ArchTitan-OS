// TitanUI component gallery — dev preview.
// Build:  cmake --build build
// Run:    QML_IMPORT_PATH=<build>/qml ./build/titan-ui-gallery
#include <QGuiApplication>
#include <QQmlApplicationEngine>

int main(int argc, char *argv[])
{
    // Some environments suppress Qt's default stderr logging; force it on so
    // QML errors are visible while developing the design system.
    qputenv("QT_FORCE_STDERR_LOGGING", "1");

    QGuiApplication app(argc, argv);
    app.setApplicationName("titan-ui-gallery");
    app.setOrganizationName("ArchTitan");

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app,
                     [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule("ArchTitan.TitanUI", "TitanGallery");

    return app.exec();
}
