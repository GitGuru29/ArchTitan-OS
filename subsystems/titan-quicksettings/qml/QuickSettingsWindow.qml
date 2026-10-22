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
    property bool showPowerMenu: false

    onShowNotificationPanelChanged: {
        rootWindow.width = showNotificationPanel ? 870 : 420;
    }

    function openDrawer() {
        drawerOpen = true;
        rootWindow.visible = true;
        rootWindow.requestActivate();
    }

    function closeDrawer() {
        drawerOpen = false;
        editMode = false;
        showPowerMenu = false;
        closeTimer.start();
    }

    function toggleDrawer() {
        if (drawerOpen) {
            closeDrawer();
        } else {
            openDrawer();
        }
    }

    // ── Keyboard navigation ─────────────────────────────────────────────────
    // The panel is fully usable without a mouse: Tab / Shift+Tab walk the
    // tiles (each is activeFocusOnTab with a visible focus ring), arrows step
    // through the same chain, and Enter / Space activate the focused tile.
    function moveFocus(forward) {
        const current = rootWindow.activeFocusItem;
        const next = current
                     ? current.nextItemInFocusChain(forward)
                     : container.nextItemInFocusChain(forward);
        if (next && next !== current) {
            next.forceActiveFocus();
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

    // ── Dual Bento Drawer Body (Slides in from right) ─────────────────────────
    Item {
        id: container
        anchors.fill: parent

        // Full keyboard operability: focus lands here when the drawer opens
        // (the tiles are activeFocusOnTab and each draws a focus ring), Tab /
        // Shift+Tab and the arrow keys step through the chain, Enter / Space
        // activate, and Esc unwinds menu → edit → close.
        focus: true
        Keys.onEscapePressed: {
            if (rootWindow.showPowerMenu) {
                rootWindow.showPowerMenu = false;
            } else if (rootWindow.editMode) {
                rootWindow.editMode = false;
            } else {
                rootWindow.closeDrawer();
            }
        }
        Keys.onRightPressed: (event) => { rootWindow.moveFocus(true);  event.accepted = true }
        Keys.onUpPressed:    (event) => { rootWindow.moveFocus(false); event.accepted = true }
        Keys.onLeftPressed:  (event) => { rootWindow.moveFocus(false); event.accepted = true }
        Keys.onDownPressed:  (event) => { rootWindow.moveFocus(true);  event.accepted = true }

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

                    // Session Header (Large Clock, Date, Greeting, Edit, Settings, Power)
                    HeaderBar {
                        showNotificationPanel: rootWindow.showNotificationPanel
                        editMode: rootWindow.editMode
                        showPowerMenu: rootWindow.showPowerMenu
                        onToggleNotificationPanel: rootWindow.showNotificationPanel = !rootWindow.showNotificationPanel
                        onToggleEditMode: {
                            rootWindow.editMode = !rootWindow.editMode;
                            if (rootWindow.editMode) rootWindow.showPowerMenu = false;
                        }
                        onTogglePowerMenu: {
                            rootWindow.showPowerMenu = !rootWindow.showPowerMenu;
                            if (rootWindow.showPowerMenu) rootWindow.editMode = false;
                        }
                    }

                    // Scrollable Bento Controls vs Edit Customizer View
                    Flickable {
                        id: bentoFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: Math.max(height, currentContent.implicitHeight)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        /**
                         * Keyboard focus follow: Tab / arrow focus can land on a
                         * control below the fold, so scroll it into view. Without
                         * this the focus ring would walk off-screen and the panel
                         * would look like it stopped responding.
                         */
                        function revealFocus() {
                            var item = rootWindow.activeFocusItem;
                            if (!item) return;

                            // Only act on items inside this flickable's content.
                            var node = item;
                            while (node && node !== contentItem) node = node.parent;
                            if (node !== contentItem) return;

                            var pad = 12;
                            var y = item.mapToItem(contentItem, 0, 0).y;
                            var h = item.height;
                            var target = contentY;
                            if (y - pad < contentY)
                                target = y - pad;
                            else if (y + h + pad > contentY + height)
                                target = y + h + pad - height;
                            var maxY = Math.max(0, contentHeight - height);
                            contentY = Math.max(0, Math.min(maxY, target));
                        }

                        Connections {
                            target: rootWindow
                            function onActiveFocusItemChanged() { bentoFlick.revealFocus() }
                        }

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

                // ── One UI Power & Session Overlay ───────────────────────
                OneUIPowerMenu {
                    id: powerMenuOverlay
                    anchors.fill: parent
                    visible: rootWindow.showPowerMenu
                    z: 99
                    onCloseRequested: rootWindow.showPowerMenu = false
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