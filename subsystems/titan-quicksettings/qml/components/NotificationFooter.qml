import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NotificationFooter — DND toggle, running total and clear-all.
 *
 * Slim status bar under the list: gives destructive and mute actions a
 * fixed, always-reachable home.
 */
RowLayout {
    id: footerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 36
    spacing: 8

    // DND toggle
    IconButton {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        source: "\uf1f6"   // bell-slash
        tip: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
             ? "Do Not Disturb: on" : "Do Not Disturb: off"
        active: (typeof notifServer !== "undefined" && notifServer) ? notifServer.dndActive : false
        activeColor: TitanTheme.red
        activeTint: TitanTheme.accentText
        onClicked: if (typeof notifServer !== "undefined" && notifServer) notifServer.toggleDnd()
    }

    // Total pill
    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        radius: 18
        color: TitanTheme.bgSurfaceAlt
        border.color: TitanTheme.borderSubtle
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: "\uf0f3"   // bell
                font.family: TitanTheme.fontFamily
                font.pixelSize: 13
                color: (typeof notifServer !== "undefined" && notifServer && notifServer.dndActive)
                       ? TitanTheme.textSubtle : TitanTheme.textMuted
            }
            Text {
                text: (typeof notifServer !== "undefined" && notifServer)
                      ? notifServer.totalCount.toLocaleString() + " notifications"
                      : "0 notifications"
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeSmall
                font.weight: Font.DemiBold
                color: TitanTheme.textMuted
            }
        }
    }

    // Clear all
    IconButton {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        source: "\uf1f8"   // trash
        tip: "Clear all notifications"
        destructive: true
        onClicked: if (typeof notifServer !== "undefined" && notifServer) notifServer.clearAll()
    }
}