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
    width: showNotificationPanel ? 880 : 450
    height: 720

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    property bool drawerOpen: false
    property bool showNotificationPanel: false
    property bool inPlaceEditMode: false
    property alias editMode: rootWindow.inPlaceEditMode
    property bool showPowerMenu: false
    property bool showWifiPage: false

    onShowNotificationPanelChanged: {
        rootWindow.width = showNotificationPanel ? 880 : 450;
    }

    function openDrawer() {
        drawerOpen = true;
        rootWindow.visible = true;
        rootWindow.requestActivate();
    }

    function closeDrawer() {
        drawerOpen = false;
        inPlaceEditMode = false;
        showPowerMenu = false;
        showWifiPage = false;
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
            } else if (rootWindow.showWifiPage) {
                rootWindow.showWifiPage = false;
            } else if (rootWindow.inPlaceEditMode) {
                rootWindow.inPlaceEditMode = false;
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
                Layout.preferredWidth: showNotificationPanel ? 450 : 450
                Layout.fillWidth: !showNotificationPanel
                Layout.fillHeight: true
                radius: TitanTheme.radiusWindow
                border.color: TitanTheme.borderHairline
                border.width: 1
                clip: true

                // Obsidian deep graphite surface
                color: TitanTheme.bgWindow

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    // Titan Control Center Top Header
                    TitanHeader {
                        inPlaceEditMode: rootWindow.inPlaceEditMode
                        onEditRequested: {
                            rootWindow.inPlaceEditMode = !rootWindow.inPlaceEditMode;
                            if (rootWindow.inPlaceEditMode) rootWindow.showPowerMenu = false;
                        }
                        onSettingsRequested: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.openSettings();
                        }
                        onPowerRequested: {
                            rootWindow.showPowerMenu = !rootWindow.showPowerMenu;
                            if (rootWindow.showPowerMenu) rootWindow.inPlaceEditMode = false;
                        }
                    }

                    // Scrollable Bento Controls (In-Place Customization on Same UI!)
                    Flickable {
                        id: bentoFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: Math.max(height, bentoContent.implicitHeight)
                        clip: true
                        interactive: !rootWindow.inPlaceEditMode
                        boundsBehavior: Flickable.StopAtBounds
                        visible: !rootWindow.showWifiPage && !rootWindow.showPowerMenu

                        /**
                         * Keyboard focus follow: Tab / arrow focus can land on a
                         * control below the fold, so scroll it into view.
                         */
                        function revealFocus() {
                            var item = rootWindow.activeFocusItem;
                            if (!item) return;

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

                        // Normal Bento Quick Settings & In-Place Customizer on Same Screen
                        ColumnLayout {
                            id: bentoContent
                            width: parent.width
                            spacing: 8

                            QuickToggleGrid {}
                        }
                    }
                }

                // ── One UI Wi-Fi Selection Overlay ───────────────────────
                OneUIWifiPage {
                    id: wifiPageOverlay
                    anchors.fill: parent
                    visible: rootWindow.showWifiPage
                    z: 98
                    onCloseRequested: rootWindow.showWifiPage = false
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
                border.color: TitanTheme.borderGlass
                border.width: 1
                clip: true

                // Ambient vertical luminance gradient (macOS .ultraThinMaterial)
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: TitanTheme.isDark ?
                            Qt.rgba(TitanTheme.bgWindow.r + 0.06, TitanTheme.bgWindow.g + 0.06, TitanTheme.bgWindow.b + 0.08, Math.min(0.95, 0.52 * TitanTheme.glassFactor)) :
                            Qt.rgba(1.0, 1.0, 1.0, Math.min(0.95, 0.72 * TitanTheme.glassFactor))
                    }
                    GradientStop {
                        position: 0.35
                        color: TitanTheme.isDark ?
                            Qt.rgba(TitanTheme.bgWindow.r, TitanTheme.bgWindow.g, TitanTheme.bgWindow.b, Math.min(0.95, 0.46 * TitanTheme.glassFactor)) :
                            Qt.rgba(TitanTheme.bgWindow.r, TitanTheme.bgWindow.g, TitanTheme.bgWindow.b, Math.min(0.95, 0.60 * TitanTheme.glassFactor))
                    }
                    GradientStop {
                        position: 1.0
                        color: TitanTheme.isDark ?
                            Qt.rgba(TitanTheme.bgWindow.r * 0.85, TitanTheme.bgWindow.g * 0.85, TitanTheme.bgWindow.b * 0.85, Math.min(0.95, 0.40 * TitanTheme.glassFactor)) :
                            Qt.rgba(TitanTheme.bgWindow.r * 0.95, TitanTheme.bgWindow.g * 0.95, TitanTheme.bgWindow.b * 0.95, Math.min(0.95, 0.52 * TitanTheme.glassFactor))
                    }
                }

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