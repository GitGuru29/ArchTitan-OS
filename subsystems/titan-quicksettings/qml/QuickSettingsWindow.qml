import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "components"
import "style"

/**
 * titan-quicksettings — ArchTitan Samsung One UI 9.0 Dual-Panel Bento Center.
 *
 * Side-by-side Bento architecture:
 * Left: Quick Settings cluster (Clock, connectivity, 4-toggles, sliders, 8 actions, device pills)
 * Right: Notification & Media Hub (Notifications, live media player, clear all)
 */
Window {
    id: rootWindow
    title: "titan-quicksettings"
    width: showNotificationPanel ? 870 : 420
    height: 990

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    property bool drawerOpen: false
    property bool showNotificationPanel: false
    property bool editMode: false

    onShowNotificationPanelChanged: {
        rootWindow.width = showNotificationPanel ? 870 : 420;
    }

    Binding {
        target: TitanTheme
        property: "isDark"
        value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
    }

    function openDrawer() {
        drawerOpen = true;
        rootWindow.visible = true;
        rootWindow.requestActivate();
    }

    function closeDrawer() {
        drawerOpen = false;
        editMode = false;
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

    // ── Dual Bento Drawer Body (Slides in from right) ─────────────────────────
    Item {
        id: container
        anchors.fill: parent

        // Slide-in animation from the right
        x: drawerOpen ? 0 : width + 50
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.12
            }
        }

        opacity: drawerOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            // ═════════════════════════════════════════════════════════════════
            //  PANEL 1: Quick Settings (Left) — Liquid Frosted Glass
            // ═════════════════════════════════════════════════════════════════
            Rectangle {
                id: leftCard
                Layout.preferredWidth: showNotificationPanel ? 416 : 420
                Layout.fillWidth: !showNotificationPanel
                Layout.fillHeight: true
                radius: TitanTheme.radiusWindow
                color: TitanTheme.bgWindow
                border.color: TitanTheme.borderGlass
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Session Header (Large Clock, Date, Greeting, Edit, Settings)
                    HeaderBar {
                        showNotificationPanel: rootWindow.showNotificationPanel
                        editMode: rootWindow.editMode
                        onToggleNotificationPanel: rootWindow.showNotificationPanel = !rootWindow.showNotificationPanel
                        onToggleEditMode: rootWindow.editMode = !rootWindow.editMode
                    }

                    // Scrollable Bento Controls vs Edit Customizer View
                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: Math.max(height, currentContent.implicitHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Item {
                            id: currentContent
                            width: parent.width
                            implicitHeight: rootWindow.editMode ? customizerView.implicitHeight : bentoContent.implicitHeight

                            // Normal Bento Quick Settings
                            ColumnLayout {
                                id: bentoContent
                                width: parent.width
                                visible: !rootWindow.editMode
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                spacing: 12

                                QuickToggleGrid {}

                                Item {
                                    Layout.fillHeight: true
                                }

                                CalendarFooter {}
                            }

                            // One UI 9 Edit Quick Panel Customizer View
                            QuickSettingsCustomizer {
                                id: customizerView
                                width: parent.width
                                visible: rootWindow.editMode
                                opacity: visible ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                                onDoneRequested: rootWindow.editMode = false
                            }
                        }
                    }
                }
            }

            // ═════════════════════════════════════════════════════════════════
            //  PANEL 2: Notifications & Media Hub (Right) — Liquid Glass
            // ═════════════════════════════════════════════════════════════════
            Rectangle {
                id: rightCard
                visible: showNotificationPanel
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: TitanTheme.radiusWindow
                color: TitanTheme.bgWindow
                border.color: TitanTheme.borderGlass
                border.width: 1
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Notification Center & Embedded Media Player
                    NotificationList {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}