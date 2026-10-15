// titan-zone-osd — hot-zone on-screen display surface
//
// A single full-screen, input-transparent LayerShell overlay. The compositor
// keeps the surface mapped across the whole output and the QML side positions
// the pill next to the active hot zone, so we never depend on the compositor
// repositioning a layer surface after it has been mapped. State is pushed from
// `titan-hotzones` over a local socket; the OSD holds no interaction logic.
#include <QGuiApplication>
#include <QLocalSocket>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QTimer>

#include <csignal>
#include <unistd.h>

#include <LayerShellQt/window.h>

#include "osdcontroller.hpp"

namespace {

QString socketPath() {
    QByteArray runtime = qgetenv("XDG_RUNTIME_DIR");
    if (runtime.isEmpty())
        runtime = QByteArray("/run/user/") + QByteArray::number(getuid());
    return QString::fromLocal8Bit(runtime) + QStringLiteral("/titan-hotzones.sock");
}

} // namespace

int main(int argc, char** argv) {
    qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    qputenv("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1");

    QGuiApplication app(argc, argv);
    app.setApplicationName(QStringLiteral("titan-zone-osd"));
    app.setApplicationDisplayName(QStringLiteral("ArchTitan Zone OSD"));
    app.setOrganizationName(QStringLiteral("ArchTitan"));

    std::signal(SIGINT, [](int) { QGuiApplication::quit(); });
    std::signal(SIGTERM, [](int) { QGuiApplication::quit(); });

    OsdController controller;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("osd"), &controller);

    // LayerShell must be configured before the window is first shown, so we hook
    // objectCreated (queued, after the QML tree is realised) exactly as
    // titan-quicksettings does, then map the overlay.
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreated, &app,
        [](QObject* obj, const QUrl&) {
            auto* window = qobject_cast<QQuickWindow*>(obj);
            if (!window) return;
            if (auto* layer = LayerShellQt::Window::get(window)) {
                layer->setLayer(LayerShellQt::Window::LayerOverlay);
                layer->setAnchors(LayerShellQt::Window::Anchors(
                    LayerShellQt::Window::AnchorTop) |
                    LayerShellQt::Window::AnchorBottom |
                    LayerShellQt::Window::AnchorLeft |
                    LayerShellQt::Window::AnchorRight);
                // -1 => ignore other surfaces' exclusive zones, so the overlay
                // spans the full output rather than being inset by the bar.
                layer->setExclusiveZone(-1);
                layer->setKeyboardInteractivity(
                    LayerShellQt::Window::KeyboardInteractivityNone);
                layer->setScope(QStringLiteral("titan-zone-osd"));
                layer->setWantsToBeOnActiveScreen(true);
            }
            window->setVisible(true);
        },
        Qt::QueuedConnection);

    engine.load(QUrl(QStringLiteral("qrc:/qml/ZoneOsd.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    // Connect to the daemon, retrying until it appears (either may start first).
    auto* socket = new QLocalSocket(&app);
    QObject::connect(socket, &QLocalSocket::readyRead, &app, [socket, &controller] {
        while (socket->canReadLine())
            controller.apply(socket->readLine());
    });
    auto* retry = new QTimer(&app);
    retry->setInterval(1500);
    QObject::connect(retry, &QTimer::timeout, &app, [socket] {
        if (socket->state() == QLocalSocket::UnconnectedState)
            socket->connectToServer(socketPath());
    });
    retry->start();
    socket->connectToServer(socketPath());

    return app.exec();
}
