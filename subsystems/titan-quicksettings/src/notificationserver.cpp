#include "notificationserver.h"
#include <QDBusConnection>
#include <QDebug>

NotificationServer::NotificationServer(QObject *parent)
    : QObject(parent)
    , m_model(new NotificationModel(this))
{
    connect(m_model, &NotificationModel::totalCountChanged, this, &NotificationServer::totalCountChanged);

    // Register on session bus for desktop notification specification
    QDBusConnection bus = QDBusConnection::sessionBus();
    if (bus.registerService("org.freedesktop.Notifications")) {
        bus.registerObject("/org/freedesktop/Notifications", this,
                           QDBusConnection::ExportAllSlots | QDBusConnection::ExportAllSignals);
        qInfo() << "[titan-qs] Registered org.freedesktop.Notifications D-Bus service.";
    } else {
        qDebug() << "[titan-qs] Could not acquire org.freedesktop.Notifications (another daemon may be running).";
    }
}

void NotificationServer::clearAll()
{
    if (m_model) {
        m_model->clearAll();
    }
}

void NotificationServer::dismissAt(int index)
{
    if (m_model) {
        m_model->dismissGroup(index);
    }
}

void NotificationServer::toggleExpanded(int index)
{
    if (m_model) {
        m_model->toggleExpanded(index);
    }
}

void NotificationServer::setDndActive(bool dnd)
{
    if (m_dndActive != dnd) {
        m_dndActive = dnd;
        emit dndActiveChanged();
    }
}

void NotificationServer::toggleDnd()
{
    setDndActive(!m_dndActive);
}

void NotificationServer::addNotification(const QString &appName, const QString &summary,
                                         const QString &body, const QString &icon)
{
    if (m_dndActive) {
        return; // Suppressed by Do Not Disturb
    }

    uint id = ++m_nextId;
    if (m_model) {
        m_model->addNotification(id, appName, summary, body, icon);
    }
}

uint NotificationServer::Notify(const QString &app_name, uint replaces_id, const QString &app_icon,
                                const QString &summary, const QString &body, const QStringList &actions,
                                const QVariantMap &hints, int timeout)
{
    Q_UNUSED(replaces_id);
    Q_UNUSED(actions);
    Q_UNUSED(hints);
    Q_UNUSED(timeout);

    addNotification(app_name, summary, body, app_icon);
    return m_nextId;
}

void NotificationServer::CloseNotification(uint id)
{
    emit NotificationClosed(id, 3); // 3 = closed by call
}

QStringList NotificationServer::GetCapabilities()
{
    return {"actions", "body", "body-markup", "icon-static", "persistence"};
}

void NotificationServer::GetServerInformation(QString &name, QString &vendor, QString &version, QString &spec_version)
{
    name = "ArchTitan One UI Notification Center";
    vendor = "ArchTitan";
    version = "1.0.0";
    spec_version = "1.2";
}
