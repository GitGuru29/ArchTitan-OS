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
            //  PANEL 1: macOS Control Center Popover — Liquid Frosted Glass
            // ═════════════════════════════════════════════════════════════════
            Item {
                Layout.preferredWidth: showNotificationPanel ? 430 : 430
                Layout.fillWidth: !showNotificationPanel
                Layout.fillHeight: true

                // Click-away area below the floating popover
                MouseArea {
                    anchors.fill: parent
                    onClicked: rootWindow.closeDrawer()
                }

                Item {
                    id: leftCard
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: (rootWindow.showWifiPage || rootWindow.showPowerMenu)
                            ? Math.min(parent.height, 560)
                            : Math.min(parent.height, bentoContent.implicitHeight + bottleneckDock.implicitHeight + 36)
                    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    readonly property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0
                    readonly property string actionGridMode: {
                        var rev = revision;
                        return (typeof systemCtrl !== "undefined" && systemCtrl)
                               ? systemCtrl.getWidgetSize("actionGrid", "compact")
                               : "compact";
                    }

                    // Stepped Bottleneck Geometry (matches archtitan_control_center_mockup)
                    readonly property bool bottleneckActive: !rootWindow.showWifiPage && !rootWindow.showPowerMenu && (actionGridMode === "compact")
                    readonly property real stepX: bottleneckActive ? 114 : 0
                    readonly property real stepY: Math.max(120, height - bottleneckDock.implicitHeight - 18)

                    onWidthChanged: glassSilhouetteCanvas.requestPaint()
                    onHeightChanged: glassSilhouetteCanvas.requestPaint()
                    onStepXChanged: glassSilhouetteCanvas.requestPaint()
                    onStepYChanged: glassSilhouetteCanvas.requestPaint()

                    // ── Stepped Bottleneck Frosted Glass Silhouette (Canvas) ──
                    Canvas {
                        id: glassSilhouetteCanvas
                        anchors.fill: parent
                        antialiasing: true

                        property color bgCol: TitanTheme.bgWindow
                        property color borderCol: TitanTheme.borderGlass
                        onBgColChanged: requestPaint()
                        onBorderColChanged: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            var W = width - 1;
                            var H = height - 1;
                            var x0 = 0.5;
                            var y0 = 0.5;
                            var r = TitanTheme.radiusWindow;
                            var sx = leftCard.stepX;
                            var sy = Math.min(H - 40, Math.max(80, leftCard.stepY));
                            var rBot = 18;
                            var rInner = 16;

                            ctx.beginPath();
                            if (sx <= 1) {
                                // Standard Full Rounded Rectangle (when Wi-Fi, Power, or Wide Grid active)
                                ctx.moveTo(x0 + r, y0);
                                ctx.lineTo(W - r, y0);
                                ctx.arcTo(W, y0, W, y0 + r, r);
                                ctx.lineTo(W, H - r);
                                ctx.arcTo(W, H, W - r, H, r);
                                ctx.lineTo(x0 + r, H);
                                ctx.arcTo(x0, H, x0, H - r, r);
                                ctx.lineTo(x0, y0 + r);
                                ctx.arcTo(x0, y0, x0 + r, y0, r);
                            } else {
                                // Asymmetric Stepped "Bottleneck" Silhouette with Concave Fillet at (sx, sy)
                                ctx.moveTo(x0 + r, y0);
                                // Top edge -> Top-Right corner
                                ctx.lineTo(W - r, y0);
                                ctx.arcTo(W, y0, W, y0 + r, r);
                                // Right edge -> Bottom-Right corner
                                ctx.lineTo(W, H - r);
                                ctx.arcTo(W, H, W - r, H, r);
                                // Bottleneck bottom edge -> Bottleneck Bottom-Left corner (sx, H)
                                ctx.lineTo(sx + rBot, H);
                                ctx.arcTo(sx, H, sx, H - rBot, rBot);
                                // Bottleneck left vertical wall up to Concave Inner Fillet (sx, sy)
                                ctx.lineTo(sx, sy + rInner);
                                ctx.arcTo(sx, sy, sx - rInner, sy, rInner);
                                // Upper body bottom-left overhang -> Upper Body Bottom-Left corner (x0, sy)
                                ctx.lineTo(x0 + r, sy);
                                ctx.arcTo(x0, sy, x0, sy - r, r);
                                // Left edge back up to Top-Left corner
                                ctx.lineTo(x0, y0 + r);
                                ctx.arcTo(x0, y0, x0 + r, y0, r);
                            }
                            ctx.closePath();

                            ctx.fillStyle = bgCol;
                            ctx.fill();

                            ctx.lineWidth = 1.2;
                            ctx.strokeStyle = borderCol;
                            ctx.stroke();
                        }
                    }

                    // Absorb clicks inside the upper body
                    MouseArea {
                        x: 0
                        y: 0
                        width: parent.width
                        height: leftCard.stepY
                    }

                    // Absorb clicks inside the right-aligned bottleneck dock
                    MouseArea {
                        x: leftCard.stepX
                        y: leftCard.stepY
                        width: parent.width - leftCard.stepX
                        height: parent.height - leftCard.stepY
                    }

                    // Main Upper Body + Stepped Bottleneck Layout
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        // 1. Upper 2-Column Bento Body (Connectivity, Focus, Sliders, Media, Pulse)
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

                            ColumnLayout {
                                id: bentoContent
                                width: parent.width
                                spacing: 8

                                QuickToggleGrid {}
                            }
                        }

                        // 2. Stepped Bottom-Right Bottleneck Dock (5 Icon Squircles + Thin Separator + Status Footer)
                        ColumnLayout {
                            id: bottleneckDock
                            visible: !rootWindow.showWifiPage && !rootWindow.showPowerMenu
                            Layout.fillWidth: true
                            Layout.leftMargin: leftCard.bottleneckActive ? leftCard.stepX : 0
                            spacing: 8

                            // Utility Squircles Row inside the Bottleneck
                            TitanActionGrid {
                                Layout.fillWidth: true
                            }

                            // Subtle 1px Glass Separator Line inside the Bottleneck
                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Qt.rgba(1, 1, 1, 0.08)
                            }

                            // macOS Bottom Status & Controls Strip (Battery | Edit Controls | Settings & Power)
                            TitanFooterBar {
                                id: footerBar
                                Layout.fillWidth: true
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
                        }
                    }

                    // ── Inline Wi-Fi Network Picker Overlay ──────────────────
                    OneUIWifiPage {
                        id: wifiPageOverlay
                        anchors.fill: parent
                        visible: rootWindow.showWifiPage
                        z: 98
                        onCloseRequested: rootWindow.showWifiPage = false
                    }

                    // ── Inline Power & Session Overlay ───────────────────────
                    OneUIPowerMenu {
                        id: powerMenuOverlay
                        anchors.fill: parent
                        visible: rootWindow.showPowerMenu
                        z: 99
                        onCloseRequested: rootWindow.showPowerMenu = false
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