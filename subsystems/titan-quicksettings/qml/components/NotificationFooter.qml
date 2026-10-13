import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NotificationFooter — Samsung One UI 9.0 notification action bar.
 *
 * Left: Do Not Disturb pill button.
 * Center: Notification count.
 * Right: "Clear all" action pill.
 */
RowLayout {
    id: footerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 38
    spacing: 10

    // ── DND Toggle Pill ─────────────────────────────────────────────────────
    Rectangle {
        Layout.preferredHeight: 36
        Layout.preferredWidth: dndRow.implicitWidth + 24
        radius: 18
        color: dndActive ? TitanTheme.accentBlue : (dndMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
        border.color: dndActive ? TitanTheme.borderActive : TitanTheme.borderGlass
        border.width: 1

        property bool dndActive: (typeof notifServer !== "undefined" && notifServer) ? notifServer.dndActive : false

        Behavior on color { ColorAnimation { duration: 130 } }

        RowLayout {
            id: dndRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: footerRoot.dndActive ? "\uf1f6" : "\uf0f3"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                color: footerRoot.dndActive ? "#FFFFFF" : TitanTheme.textSubtle
            }

            Text {
                text: "DND"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: footerRoot.dndActive ? "#FFFFFF" : TitanTheme.textSecondary
            }
        }

        MouseArea {
            id: dndMa
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof notifServer !== "undefined" && notifServer)
                    notifServer.toggleDnd()
            }
        }
    }

    Item { Layout.fillWidth: true }

    // ── Clear All Action Pill ───────────────────────────────────────────────
    Rectangle {
        Layout.preferredHeight: 36
        Layout.preferredWidth: clearRow.implicitWidth + 24
        radius: 18
        color: clearMa.pressed ? TitanTheme.bgPressed : (clearMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
        border.color: clearMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
        border.width: 1

        RowLayout {
            id: clearRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "\uf1f8" // trash
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: clearMa.containsMouse ? TitanTheme.red : TitanTheme.textSubtle
            }

            Text {
                text: "Clear all"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: clearMa.containsMouse ? TitanTheme.red : TitanTheme.textSecondary
            }
        }

        MouseArea {
            id: clearMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (typeof notifServer !== "undefined" && notifServer)
                    notifServer.clearAll()
            }
        }
    }
}