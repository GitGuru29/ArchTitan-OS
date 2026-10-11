import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "components"
import "style"

/**
 * titan-quicksettings — ArchTitan Samsung One UI 9.0 Quick Settings & Notification Center.
 *
 * Squircles, Bento-grid layout, thick pill sliders, and high-performance
 * virtualized Notification Center backed by C++ QAbstractListModel.
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
        Keys.onLeftPressed: segmentTab.currentIndex = 0
        Keys.onRightPressed: segmentTab.currentIndex = 1
    }

    // ── Drawer body ───────────────────────────────────────────────────────────
    Rectangle {
        id: card
        anchors.fill: parent
        radius: TitanTheme.radiusWindow
        color: TitanTheme.bgWindow
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true



        // Slide-in: enter from the right
        x: drawerOpen ? 0 : width + 40
        Behavior on x {
            NumberAnimation {
                duration: 280
                easing.type: Easing.OutBack
                easing.overshoot: 1.15
            }
        }

        opacity: drawerOpen ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            // 1. Samsung One UI Header (Clock, Date, Power, Settings)
            HeaderBar {}

            // 2. One UI 9.0 Segmented Tab Switcher
            OneUISegmentTab {
                id: segmentTab
                currentIndex: 0
                notifCount: (typeof notifModel !== "undefined" && notifModel) ? notifModel.totalCount : 0
            }

            // 3. Tab Views (Quick Settings vs Notification Center)
            StackLayout {
                id: viewStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: segmentTab.currentIndex

                // ── View 0: Bento Quick Settings ────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: Math.max(height, bentoContent.implicitHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: bentoContent
                            width: parent.width
                            height: Math.max(parent.height, implicitHeight)
                            spacing: 12

                            QuickToggleGrid {}

                            Item {
                                Layout.fillHeight: true
                            }

                            CalendarFooter {}
                        }
                    }
                }

                // ── View 1: Notification Center ─────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    // Quick Display Brightness Bar
                    OneUISlider {
                        iconGlyph: "\uf185" // sun
                        fillAccent: TitanTheme.yellow
                        value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                        onChanged: (v) => {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.setBrightness(v)
                        }
                    }

                    // Virtualized Notification List
                    NotificationList {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // Notification Action Footer
                    NotificationFooter {}

                    // Mini Calendar Strip
                    CalendarFooter {}
                }
            }
        }
    }
}