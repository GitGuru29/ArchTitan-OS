#pragma once

#include <QObject>
#include <QDBusContext>
#include "notificationmodel.h"

class NotificationServer : public QObject, protected QDBusContext
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.freedesktop.Notifications")
    Q_PROPERTY(NotificationModel* model READ model CONSTANT)
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(bool dndActive READ dndActive WRITE setDndActive NOTIFY dndActiveChanged)

public:
    explicit NotificationServer(QObject *parent = nullptr);

    NotificationModel* model() const { return m_model; }
    int totalCount() const { return m_model ? m_model->totalCount() : 0; }
    bool dndActive() const { return m_dndActive; }
    void setDndActive(bool dnd);

public slots:
    void clearAll();
    void dismissAt(int index);
    void toggleDnd();
    void toggleExpanded(int index);
    void addNotification(const QString &appName, const QString &summary, const QString &body, const QString &icon = "");

    // org.freedesktop.Notifications D-Bus Methods
    uint Notify(const QString &app_name, uint replaces_id, const QString &app_icon,
                const QString &summary, const QString &body, const QStringList &actions,
                const QVariantMap &hints, int timeout);
    void CloseNotification(uint id);
    QStringList GetCapabilities();
    void GetServerInformation(QString &name, QString &vendor, QString &version, QString &spec_version);

signals:
    void totalCountChanged();
    void dndActiveChanged();
    void NotificationClosed(uint id, uint reason);
    void ActionInvoked(uint id, const QString &action_key);

private:
    NotificationModel *m_model{nullptr};
    bool m_dndActive{false};
    uint m_nextId{100};
};
