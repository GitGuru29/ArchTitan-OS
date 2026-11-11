import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI
import "slides"

Window {
    id: window
    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    visible: false
    color: "transparent"
    title: "titan-tour"
    flags: Qt.FramelessWindowHint

    property bool tourOpen: false
    property int currentSlide: 0
    readonly property int totalSlides: 6

    function openTour() {
        tourOpen = true;
        visible = true;
        requestActivate();
        tourCtrl.playSound("startup");
        Qt.callLater(function() {
            keyHandler.forceActiveFocus();
            beaconCanvas.requestPaint();
        });
    }

    function goToSlide(idx) {
        if (idx < 0 || idx >= totalSlides || idx === currentSlide) return;
        currentSlide = idx;
        beaconCanvas.requestPaint();
    }

    function nextSlide() {
        if (currentSlide < totalSlides - 1) {
            tourCtrl.playSound("step");
            goToSlide(currentSlide + 1);
        }
    }

    function prevSlide() {
        if (currentSlide > 0) {
            tourCtrl.playSound("step");
            goToSlide(currentSlide - 1);
        }
    }

    function finishAndClose() {
        tourOpen = false;
        tourCtrl.finishTour(!tourCtrl.showOnStartup);
    }

    // Global Keyboard Navigation
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                if (window.currentSlide < window.totalSlides - 1) window.nextSlide();
                else window.finishAndClose();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) {
                window.prevSlide();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                window.finishAndClose();
                event.accepted = true;
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_6) {
                tourCtrl.playSound("step");
                window.goToSlide(event.key - Qt.Key_1);
                event.accepted = true;
            }
        }
    }

    // 1. Subtle ArchTitan Liquid Glass Scrim (Matches titan-menu so desktop & Waybar remain visible)
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.06, 0.34)
        opacity: window.tourOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durSlow; easing.type: Easing.OutCubic } }
    }

    // 2. Signature ArchTitan Hot-Zone Workspace Boundary Frame (Matches ZoneOsd.qml)
    Item {
        anchors.fill: parent
        opacity: window.tourOpen ? (window.currentSlide === 1 ? 0.95 : 0.45) : 0.0
        Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: TitanTheme.accent }
                GradientStop { position: 1.0; color: TitanTheme.mauve }
            }
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: TitanTheme.mauve }
                GradientStop { position: 1.0; color: TitanTheme.accent }
            }
        }
        Rectangle {
            anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
            width: 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: TitanTheme.accent }
                GradientStop { position: 1.0; color: TitanTheme.mauve }
            }
        }
        Rectangle {
            anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
            width: 2
            gradient: Gradient {
                GradientStop { position: 0.0; color: TitanTheme.mauve }
                GradientStop { position: 1.0; color: TitanTheme.accent }
            }
        }
    }

    // 3. Vector Targeting Lines Connecting Real Screen Hot-Zones to Central Stage
    Canvas {
        id: beaconCanvas
        anchors.fill: parent
        opacity: window.tourOpen ? (window.currentSlide === 1 ? 0.85 : 0.25) : 0.0
        Behavior on opacity { NumberAnimation { duration: 280 } }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;

            var targets = [
                { x: 140, y: 78,  tx: cx - 360, ty: cy - 270, col: "rgba(99, 102, 241, 0.50)" },
                { x: cx,  y: 78,  tx: cx,       ty: cy - 270, col: "rgba(167, 139, 250, 0.50)" },
                { x: width - 140, y: 78, tx: cx + 360, ty: cy - 270, col: "rgba(56, 189, 248, 0.55)" },
                { x: 130, y: cy,  tx: cx - 510, ty: cy,       col: "rgba(52, 211, 153, 0.50)" },
                { x: width - 130, y: cy, tx: cx + 510, ty: cy, col: "rgba(45, 212, 191, 0.50)" },
                { x: width - 140, y: height - 42, tx: cx + 360, ty: cy + 270, col: "rgba(251, 191, 36, 0.50)" }
            ];

            ctx.lineWidth = 1.2;
            ctx.setLineDash([4, 4]);

            for (var i = 0; i < targets.length; i++) {
                var t = targets[i];
                ctx.strokeStyle = t.col;
                ctx.beginPath();
                ctx.moveTo(t.x, t.y);
                ctx.lineTo(t.tx, t.ty);
                ctx.stroke();
            }
        }
    }

    // 4. Peripheral Screen-Edge Dwell Beacons (Matches ZoneOsd.qml & hotzones.toml)
    // Placed at topInset: 52 so they never overlap Waybar at the top edge!
    Item {
        anchors.fill: parent
        opacity: window.tourOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durSlow } }

        readonly property var edgeBeacons: [
            {
                zone: "top_left",
                title: "Titan Spotlight",
                sub: "180ms Corner Dwell • Super",
                icon: "\uf002",
                col: TitanTheme.accent,
                bx: 14, by: 52,
                act: function() { tourCtrl.toggleSpotlight(); }
            },
            {
                zone: "top_center",
                title: "Dynamic Media Island",
                sub: "Super + M • Live MPRIS2 HUD",
                icon: "\uf001",
                col: TitanTheme.mauve,
                bx: (window.width - 236) / 2, by: 52,
                act: function() { tourCtrl.toggleMediaHud(); }
            },
            {
                zone: "top_right",
                title: "Control Center",
                sub: "180ms Corner Dwell • Super+N",
                icon: "\uf1de",
                col: TitanTheme.info,
                bx: window.width - 236 - 14, by: 52,
                act: function() { tourCtrl.toggleControlCenter(); }
            },
            {
                zone: "left_center",
                title: "System Monitor",
                sub: "180ms Left-Edge Dwell",
                icon: "\uf080",
                col: TitanTheme.success,
                bx: 14, by: (window.height - 54) / 2,
                act: function() { tourCtrl.toggleSysmon(); }
            },
            {
                zone: "right_center",
                title: "10-Workspace HUD",
                sub: "Super + Tab • Right-Edge Dwell",
                icon: "\uf009",
                col: TitanTheme.teal,
                bx: window.width - 236 - 14, by: (window.height - 54) / 2,
                act: function() { tourCtrl.toggleWorkspaceHud(); }
            },
            {
                zone: "bottom_right",
                title: "Notification Hub",
                sub: "180ms Bottom-Right Dwell",
                icon: "\uf0f3",
                col: TitanTheme.warning,
                bx: window.width - 236 - 14, by: window.height - 54 - 14,
                act: function() { tourCtrl.openNotifications(); }
            }
        ]

        Repeater {
            model: parent.edgeBeacons

            delegate: Rectangle {
                required property var modelData
                x: modelData.bx
                y: modelData.by
                width: 236
                height: 54
                radius: 18
                color: bMouse.containsMouse
                    ? Qt.rgba(TitanTheme.surface1.r, TitanTheme.surface1.g, TitanTheme.surface1.b, 0.94)
                    : Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.88)
                border.width: (window.currentSlide === 1 || bMouse.containsMouse) ? 1.5 : 1
                border.color: (window.currentSlide === 1 || bMouse.containsMouse)
                    ? modelData.col
                    : Qt.rgba(modelData.col.r, modelData.col.g, modelData.col.b, 0.42)

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 12
                    spacing: 10

                    // ZoneOsd-style Dwell Progress Ring + Icon
                    Item {
                        width: 36
                        height: 36

                        TitanArcItem {
                            anchors.fill: parent
                            color: modelData.col
                            trackColor: Qt.rgba(1, 1, 1, 0.10)
                            lineWidth: 3
                            startAngle: -90.0
                            sweepAngle: bMouse.containsMouse ? 360.0 : 275.0
                            showTrack: true
                            roundCaps: true
                            Behavior on sweepAngle { NumberAnimation { duration: 180 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            color: modelData.col
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 13
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 12
                            font.weight: TitanTheme.weightBold
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.sub
                            color: modelData.col
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: bMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.act()
                }
            }
        }
    }

    // 5. Central 3-Island Liquid Glass Bento Stage (1040 x 690)
    Item {
        id: centralStage
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 16
        width: 1040
        height: 690
        opacity: window.tourOpen ? 1.0 : 0.0
        scale: window.tourOpen ? 1.0 : 0.96
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durSlow; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: TitanTheme.durSlow; easing.type: Easing.OutQuart } }

        ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Island 1: Top Floating Command Capsule
            TourHeader {
                Layout.fillWidth: true
                currentSlide: window.currentSlide
                totalSlides: window.totalSlides
                onSlideRequested: function(idx) { window.goToSlide(idx); }
                onCloseClicked: window.finishAndClose()
            }

            // Island 2: Main Liquid Glass Bento Stage (Matches titan-menu & titan-sysmon)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    id: stageCard
                    anchors.fill: parent
                    radius: 26
                    border.width: 1.5
                    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.44)
                    clip: true

                    // Liquid Glass Translucent Gradient (Lets Hyprland Dual-Kawase blur shine through)
                    gradient: Gradient {
                        GradientStop {
                            position: 0.0
                            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b,
                                           Math.min(0.94, 0.86 * TitanTheme.glassFactor))
                        }
                        GradientStop {
                            position: 1.0
                            color: Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b,
                                           Math.min(0.92, 0.82 * TitanTheme.glassFactor))
                        }
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.78)
                        shadowBlur: 0.95
                        shadowVerticalOffset: 14
                        autoPaddingEnabled: true
                    }

                    // 3D Glass Specular Sheen (Curved top-light wash from MenuWindow.qml)
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 190
                        radius: stageCard.radius
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                            GradientStop { position: 0.40; color: Qt.rgba(1, 1, 1, 0.025) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Inner Hairline Border
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 25
                        color: "transparent"
                        border.width: 1
                        border.color: TitanTheme.borderSubtle
                    }

                    // Top Specular Horizon Glint
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 56
                        height: 1.5
                        radius: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, 0.22) }
                            GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.62) }
                            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.22) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Left & Right Glowing Accent Side-Rims
                    Rectangle {
                        anchors.left: parent.left
                        anchors.leftMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 160
                        radius: 1
                        color: TitanTheme.accent
                        opacity: 0.65
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 160
                        radius: 1
                        color: TitanTheme.info
                        opacity: 0.65
                    }

                    // Corner Targeting Reticle
                    TitanReticle {
                        anchors.fill: parent
                        anchors.margins: 12
                        color: TitanTheme.accent
                        bracketLength: 16
                        bracketThickness: 2
                        pulsing: true
                        opacity: 0.42
                    }

                    // 6-Act Slide Viewport
                    Item {
                        anchors.fill: parent

                        SlideWelcome {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 0 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        SlideControlCenter {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 1 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        SlideKeybinds {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 2 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        SlideEcosystem {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 3 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        SlideHardware {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 4 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        }

                        SlideLaunch {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 5 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            onFinishTourRequested: window.finishAndClose()
                        }
                    }
                }
            }

            // Island 3: Bottom Floating Dock Capsule
            TourFooter {
                Layout.fillWidth: true
                currentSlide: window.currentSlide
                totalSlides: window.totalSlides
                onPrevClicked: window.prevSlide()
                onNextClicked: window.nextSlide()
                onFinishClicked: window.finishAndClose()
            }
        }
    }
}
