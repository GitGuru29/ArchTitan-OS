import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "components"
import "style"

/**
 * titan-quicksettings — ArchTitan Quick Settings & Notification Center.
 *
 * A glassmorphic layer-shell drawer that slides in from the right edge.
 * All surfaces, type and accents delegate to TitanTheme so the whole panel
 * changes together when the design system is tuned.
 */
Window {
    id: rootWindow
    title: "titan-quicksettings"
    width: 420
    // Fallback height — main.cpp clamps this to the available work area.
    height: 860

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    property bool drawerOpen: false

    function openDrawer() {
        drawerOpen = true;
        rootWindow.visible = true;
        rootWindow.requestActivate();
    }

    function closeDrawer() {
        drawerOpen = false;
        closeTimer.start();
    }

    function toggleDrawer() {
        if (drawerOpen) {
            closeDrawer();
        } else {
            openDrawer();
        }
    }

    Timer {
        id: closeTimer
        interval: 280
        onTriggered: {
            if (!drawerOpen) {
                rootWindow.visible = false;
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: closeDrawer()
    }

    // ── Drawer body ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        radius: TitanTheme.radiusWindow
        color: TitanTheme.bgWindow
        border.color: TitanTheme.borderActive
        border.width: 1
        clip: true

        // Frosted edge highlight (hairline inside the top edge)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: TitanTheme.borderGlass
        }

        // Slide-in: enter from the right, over-shoot like the OS panel
        x: drawerOpen ? 0 : width + 40
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        // Subtle fade with the slide
        opacity: drawerOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // 1. Session header
            HeaderBar {}

            // 2. Quick controls (connectivity, volume/brightness, tool grid)
            QuickToggleGrid {}

            // 3. Notifications section label
            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle { width: 3; height: 12; radius: 1.5; color: TitanTheme.accent }
                Text {
                    text: "NOTIFICATIONS"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeCaption
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: TitanTheme.textSubtle
                }
                Item { Layout.fillWidth: true }
            }

            // 4. Notification history
            NotificationList {}

            // 5. Notification footer (DND / count / clear)
            NotificationFooter {}

            // 6. Calendar & tasks
            CalendarFooter {}
        }
    }
}