import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * NotificationList — High-performance virtualized One UI 9.0 notification history.
 *
 * Backed by QAbstractListModel with reuseItems for minimal memory overhead and
 * 60 FPS scrolling.
 */
Item {
    id: notifListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    ListView {
        id: notifListView
        anchors.fill: parent
        spacing: 10
        clip: true
        reuseItems: true
        cacheBuffer: 120
        model: (typeof notifModel !== "undefined" && notifModel) ? notifModel : null

        delegate: OneUINotificationCard {
            width: notifListView.width
            cardIndex: index
            appNameText: model.appName
            summaryText: model.summary
            bodyText: model.body
            dateText: model.dateStr
            iconTypeVal: model.iconType
            countVal: model.itemCount
            expandedVal: model.isExpanded
            subItemsList: model.subItems
        }

        ScrollBar.vertical: ScrollBar {
            width: 4
            policy: ScrollBar.AsNeeded
            interactive: true
            anchors.right: parent.right
            anchors.rightMargin: 2

            contentItem: Rectangle {
                radius: 2
                color: control.active ? TitanTheme.accentBlue : TitanTheme.bgOneUIPill
                opacity: control.active ? 1.0 : 0.8
            }
            background: Rectangle {
                radius: 2
                color: "transparent"
            }
        }

        // Empty state
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 32
            height: 110
            radius: TitanTheme.radiusCard
            color: TitanTheme.bgOneUICard
            border.color: TitanTheme.borderGlass
            border.width: 1
            visible: notifListView.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "\uf0f3" // bell
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 24
                    color: TitanTheme.textSubtle
                }

                Text {
                    text: "You're all caught up"
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: TitanTheme.textSecondary
                }

                Text {
                    text: "No pending notifications"
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }
        }
    }
}