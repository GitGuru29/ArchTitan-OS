#pragma once

#include <QAbstractListModel>
#include <QDateTime>
#include <QList>
#include <QString>
#include <QVariantMap>

struct NotificationItem {
    uint id{0};
    QString appName;
    QString summary;
    QString body;
    QString iconType;
    QDateTime timestamp;
    QString dateStr;
};

struct NotificationGroup {
    QString appName;
    QString iconType;
    QList<NotificationItem> items;
    bool expanded{false};
    QDateTime latestTimestamp;
};

class NotificationModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int totalCount READ totalCount NOTIFY totalCountChanged)
    Q_PROPERTY(int groupCount READ rowCount NOTIFY totalCountChanged)

public:
    enum NotificationRoles {
        IdRole = Qt::UserRole + 1,
        AppNameRole,
        SummaryRole,
        BodyRole,
        DateStrRole,
        IconTypeRole,
        CountRole,
        ExpandedRole,
        ItemsRole
    };
    Q_ENUM(NotificationRoles)

    explicit NotificationModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    int totalCount() const;

public slots:
    void clearAll();
    void dismissGroup(int index);
    void dismissItem(int groupIndex, int itemIndex);
    void toggleExpanded(int index);
    void addNotification(uint id, const QString &appName, const QString &summary,
                         const QString &body, const QString &icon);

signals:
    void totalCountChanged();
    void notificationDismissed(uint id);

private:
    void initSampleNotifications();
    static QString formatRelativeTime(const QDateTime &dt);

    QList<NotificationGroup> m_groups;
};
