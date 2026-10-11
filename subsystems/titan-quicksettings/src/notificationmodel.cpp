#include "notificationmodel.h"
#include <QDebug>

NotificationModel::NotificationModel(QObject *parent)
    : QAbstractListModel(parent)
{
    initSampleNotifications();
}

int NotificationModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_groups.size();
}

QVariant NotificationModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_groups.size())
        return QVariant();

    const NotificationGroup &group = m_groups.at(index.row());
    if (group.items.isEmpty())
        return QVariant();

    const NotificationItem &topItem = group.items.first();

    switch (role) {
    case IdRole:
        return topItem.id;
    case AppNameRole:
        return group.appName;
    case SummaryRole:
        return topItem.summary;
    case BodyRole:
        return topItem.body;
    case DateStrRole:
        return topItem.dateStr.isEmpty() ? formatRelativeTime(topItem.timestamp) : topItem.dateStr;
    case IconTypeRole:
        return group.iconType;
    case CountRole:
        return group.items.size();
    case ExpandedRole:
        return group.expanded;
    case ItemsRole: {
        QVariantList list;
        for (const auto &item : group.items) {
            QVariantMap map;
            map["id"] = item.id;
            map["summary"] = item.summary;
            map["body"] = item.body;
            map["dateStr"] = item.dateStr.isEmpty() ? formatRelativeTime(item.timestamp) : item.dateStr;
            list.append(map);
        }
        return list;
    }
    default:
        break;
    }

    return QVariant();
}

QHash<int, QByteArray> NotificationModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[IdRole] = "notifId";
    roles[AppNameRole] = "appName";
    roles[SummaryRole] = "summary";
    roles[BodyRole] = "body";
    roles[DateStrRole] = "dateStr";
    roles[IconTypeRole] = "iconType";
    roles[CountRole] = "itemCount";
    roles[ExpandedRole] = "isExpanded";
    roles[ItemsRole] = "subItems";
    return roles;
}

int NotificationModel::totalCount() const
{
    int total = 0;
    for (const auto &group : m_groups) {
        total += group.items.size();
    }
    return total;
}

void NotificationModel::clearAll()
{
    if (m_groups.isEmpty())
        return;

    beginResetModel();
    m_groups.clear();
    endResetModel();
    emit totalCountChanged();
}

void NotificationModel::dismissGroup(int index)
{
    if (index < 0 || index >= m_groups.size())
        return;

    beginRemoveRows(QModelIndex(), index, index);
    m_groups.removeAt(index);
    endRemoveRows();
    emit totalCountChanged();
}

void NotificationModel::dismissItem(int groupIndex, int itemIndex)
{
    if (groupIndex < 0 || groupIndex >= m_groups.size())
        return;

    auto &group = m_groups[groupIndex];
    if (itemIndex < 0 || itemIndex >= group.items.size())
        return;

    group.items.removeAt(itemIndex);

    if (group.items.isEmpty()) {
        beginRemoveRows(QModelIndex(), groupIndex, groupIndex);
        m_groups.removeAt(groupIndex);
        endRemoveRows();
    } else {
        emit dataChanged(index(groupIndex, 0), index(groupIndex, 0),
                          {SummaryRole, BodyRole, CountRole, ItemsRole, DateStrRole});
    }
    emit totalCountChanged();
}

void NotificationModel::toggleExpanded(int groupIndex)
{
    if (groupIndex < 0 || groupIndex >= m_groups.size())
        return;

    m_groups[groupIndex].expanded = !m_groups[groupIndex].expanded;
    emit dataChanged(index(groupIndex, 0), index(groupIndex, 0), {ExpandedRole});
}

void NotificationModel::addNotification(uint id, const QString &appName, const QString &summary,
                                        const QString &body, const QString &icon)
{
    QString safeApp = appName.trimmed().isEmpty() ? QStringLiteral("System") : appName.trimmed();
    QString safeIcon = icon.trimmed().isEmpty() ? QStringLiteral("message") : icon.trimmed();

    NotificationItem item;
    item.id = id;
    item.appName = safeApp;
    item.summary = summary;
    item.body = body;
    item.iconType = safeIcon;
    item.timestamp = QDateTime::currentDateTime();
    item.dateStr = QStringLiteral("Just now");

    // Check if an existing group matches this app
    int foundIndex = -1;
    for (int i = 0; i < m_groups.size(); ++i) {
        if (m_groups[i].appName.compare(safeApp, Qt::CaseInsensitive) == 0) {
            foundIndex = i;
            break;
        }
    }

    if (foundIndex >= 0) {
        // Prepend into existing group
        m_groups[foundIndex].items.prepend(item);
        m_groups[foundIndex].latestTimestamp = item.timestamp;
        if (!safeIcon.isEmpty()) {
            m_groups[foundIndex].iconType = safeIcon;
        }

        if (foundIndex > 0) {
            // Move updated group to top of list
            beginMoveRows(QModelIndex(), foundIndex, foundIndex, QModelIndex(), 0);
            auto movedGroup = m_groups.takeAt(foundIndex);
            m_groups.prepend(movedGroup);
            endMoveRows();
            emit dataChanged(index(0, 0), index(0, 0));
        } else {
            emit dataChanged(index(0, 0), index(0, 0),
                              {SummaryRole, BodyRole, DateStrRole, CountRole, ItemsRole, IdRole});
        }
    } else {
        // Create new group at top
        NotificationGroup newGroup;
        newGroup.appName = safeApp;
        newGroup.iconType = safeIcon;
        newGroup.latestTimestamp = item.timestamp;
        newGroup.items.append(item);

        beginInsertRows(QModelIndex(), 0, 0);
        m_groups.prepend(newGroup);
        endInsertRows();
    }

    emit totalCountChanged();
}

QString NotificationModel::formatRelativeTime(const QDateTime &dt)
{
    qint64 secs = dt.secsTo(QDateTime::currentDateTime());
    if (secs < 60)
        return QStringLiteral("Just now");
    if (secs < 3600)
        return QString("%1m ago").arg(secs / 60);
    if (secs < 86400)
        return QString("%1h ago").arg(secs / 3600);
    return dt.toString("MMM d");
}

void NotificationModel::initSampleNotifications()
{
    // Seed initial app groups
    NotificationGroup g1;
    g1.appName = "Antigravity IDE";
    g1.iconType = "antigravity";
    NotificationItem g1_item;
    g1_item.id = 1;
    g1_item.appName = g1.appName;
    g1_item.summary = "Antigravity IDE Project Status Inquiry";
    g1_item.body = "Requesting your permission in Terminal: Command execution requested";
    g1_item.iconType = g1.iconType;
    g1_item.dateStr = "Just now";
    g1_item.timestamp = QDateTime::currentDateTime();
    g1.items.append(g1_item);
    m_groups.append(g1);

    NotificationGroup g2;
    g2.appName = "Network Management";
    g2.iconType = "wifi";
    NotificationItem g2_item;
    g2_item.id = 2;
    g2_item.appName = g2.appName;
    g2_item.summary = "Connected to Wi-Fi Network";
    g2_item.body = "moto g24 power connection established with 5 GHz link";
    g2_item.iconType = g2.iconType;
    g2_item.dateStr = "10m ago";
    g2_item.timestamp = QDateTime::currentDateTime().addSecs(-600);
    g2.items.append(g2_item);
    m_groups.append(g2);

    NotificationGroup g3;
    g3.appName = "Hyprland";
    g3.iconType = "terminal";
    NotificationItem g3_item;
    g3_item.id = 3;
    g3_item.appName = g3.appName;
    g3_item.summary = "Display Configuration Applied";
    g3_item.body = "Output eDP-1 set to 1920x1080 @ 60Hz";
    g3_item.iconType = g3.iconType;
    g3_item.dateStr = "1h ago";
    g3_item.timestamp = QDateTime::currentDateTime().addSecs(-3600);
    g3.items.append(g3_item);
    m_groups.append(g3);
}
