import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * NotificationList — scrollable grouped notification history.
 *
 * Renders NotificationCard delegates over the server model with a thin
 * styled scrollbar and a friendly empty state.
 */
Item {
    id: notifListRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    ListView {
        id: notifListView
        anchors.fill: parent
        spacing: 8
        clip: true
        model: (typeof notifServer !== "undefined" && notifServer) ? notifServer.notifications : []

        delegate: NotificationCard {
            width: notifListView.width
            modelItem: modelData
            cardIndex: index
        }

        ScrollBar.vertical: ScrollBar {
            width: 5
            policy: ScrollBar.AsNeeded
            interactive: true
            anchors.right: parent.right
            anchors.rightMargin: 1

            contentItem: Rectangle {
                radius: 2.5
                color: control.active ? TitanTheme.accent : TitanTheme.bgSurfaceAlt
                opacity: control.active ? 1.0 : 0.9
            }
            background: Rectangle {
                radius: 2.5
                color: "transparent"
            }
        }

        // Empty state
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 40
            height: 96
            radius: TitanTheme.radiusCard
            color: TitanTheme.bgSurface
            border.color: TitanTheme.borderSubtle
            border.width: 1
            visible: notifListView.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\uf0f3"   // bell
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 26
                    color: TitanTheme.textSubtle
                }
                Text {
                    text: "You're all caught up"
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeSmall
                    font.weight: Font.DemiBold
                    color: TitanTheme.textSecondary
                }
                Text {
                    text: "No new notifications"
                    Layout.alignment: Qt.AlignHCenter
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }
        }
    }
}