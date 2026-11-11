import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI
import "slides"

Window {
    id: window
    width: 1920
    height: 1080
    visible: false
    color: "transparent"
    title: "ArchTitan Virtual Tour"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint

    property int currentSlide: 0
    readonly property int totalSlides: 6
    property real entryProgress: 0.0

    Component.onCompleted: {
        entryAnim.start();
        tourCtrl.playSound("startup");
        keyHandler.forceActiveFocus();
    }

    NumberAnimation {
        id: entryAnim
        target: window
        property: "entryProgress"
        from: 0.0
        to: 1.0
        duration: 420
        easing.type: Easing.OutCubic
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

    // 1. Full-Screen Atmospheric Scrim (Dims live desktop while keeping wallpaper changes visible)
    Rectangle {
        anchors.fill: parent
        opacity: window.entryProgress
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.015, 0.025, 0.05, 0.84) }
            GradientStop { position: 0.5; color: Qt.rgba(0.02, 0.03, 0.06, 0.72) }
            GradientStop { position: 1.0; color: Qt.rgba(0.015, 0.025, 0.05, 0.86) }
        }
    }

    // 2. Vector Targeting Lines Connecting Screen-Edge Beacons to Central Stage
    Canvas {
        id: beaconCanvas
        anchors.fill: parent
        opacity: window.currentSlide === 1 ? 0.85 : 0.32
        Behavior on opacity { NumberAnimation { duration: 280 } }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var cx = width / 2;
            var cy = height / 2;

            var targets = [
                { x: 160, y: 44,  tx: cx - 380, ty: cy - 280, col: "rgba(99, 102, 241, 0.45)" },
                { x: cx,  y: 44,  tx: cx,       ty: cy - 280, col: "rgba(167, 139, 250, 0.45)" },
                { x: width - 160, y: 44, tx: cx + 380, ty: cy - 280, col: "rgba(56, 189, 248, 0.55)" },
                { x: 140, y: cy,  tx: cx - 530, ty: cy,       col: "rgba(52, 211, 153, 0.45)" },
                { x: width - 160, y: height - 44, tx: cx + 380, ty: cy + 280, col: "rgba(251, 191, 36, 0.45)" }
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

    // 3. Full-Screen Peripheral Spatial HUD Beacons (Pointing to Real Desktop Edges)
    Item {
        anchors.fill: parent
        opacity: window.entryProgress

        // Top-Left Beacon: App Menu & Workspaces
        Rectangle {
            x: 18
            y: 14
            width: 248
            height: 44
            radius: 14
            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
            border.width: window.currentSlide === 1 ? 1.5 : 1
            border.color: window.currentSlide === 1 ? TitanTheme.accent : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "↖"
                    color: TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 16
                    font.weight: Font.Black
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "APP MENU & WORKSPACES"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Press Super or Click Corner"
                        color: TitanTheme.accent
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.toggleMenu()
            }
        }

        // Top-Center Beacon: Dynamic Media Island
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            width: 256
            height: 44
            radius: 22
            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
            border.width: window.currentSlide === 1 ? 1.5 : 1
            border.color: window.currentSlide === 1 ? TitanTheme.mauve : Qt.rgba(0.65, 0.55, 0.98, 0.45)

            RowLayout {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    text: "\uf001"
                    color: TitanTheme.mauve
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                }

                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "DYNAMIC MEDIA ISLAND ↑"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Live MPRIS2 Artwork & Clock"
                        color: TitanTheme.mauve
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.testAudio()
            }
        }

        // Top-Right Beacon: Stepped Bottleneck Control Center
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 14
            width: 266
            height: 44
            radius: 14
            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
            border.width: (window.currentSlide === 1 || window.currentSlide === 3) ? 1.5 : 1
            border.color: (window.currentSlide === 1 || window.currentSlide === 3) ? TitanTheme.info : Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.5)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "STEPPED CONTROL CENTER"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Super + N // Click to Summon"
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                    }
                }

                Text {
                    text: "↗"
                    color: TitanTheme.info
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 16
                    font.weight: Font.Black
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.toggleControlCenter()
            }
        }

        // Left-Edge Beacon: Titan System Monitor Cockpit
        Rectangle {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            width: 196
            height: 54
            radius: 14
            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
            border.width: (window.currentSlide === 1 || window.currentSlide === 4) ? 1.5 : 1
            border.color: (window.currentSlide === 1 || window.currentSlide === 4) ? TitanTheme.success : Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.45)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "\uf080"
                    color: TitanTheme.success
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    Text {
                        text: "SYSMON HUD"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Super + M // Telemetry"
                        color: TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.toggleSysmon()
            }
        }

        // Bottom-Right Beacon: Spotlight & Notifications
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            width: 256
            height: 44
            radius: 14
            color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.92)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.45)

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                Text {
                    text: "\uf002"
                    color: TitanTheme.warning
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: "TITAN SPOTLIGHT LAUNCHER"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "Super + Space // Click to Open"
                        color: TitanTheme.warning
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.toggleSpotlight()
            }
        }
    }

    // 4. Central 3-Island Spatial Bento Stage (1060 x 706)
    Item {
        id: centralStage
        anchors.centerIn: parent
        width: 1060
        height: 706
        opacity: window.entryProgress
        scale: 0.96 + 0.04 * window.entryProgress

        ColumnLayout {
            anchors.fill: parent
            spacing: 12

            // Island 1: Top Floating Command Capsule
            TourHeader {
                Layout.fillWidth: true
                currentSlide: window.currentSlide
                totalSlides: window.totalSlides
                onSlideRequested: function(idx) { window.goToSlide(idx); }
                onCloseClicked: window.finishAndClose()
            }

            // Island 2: Main Frosted Bento Stage
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                MultiEffect {
                    anchors.fill: stageCard
                    source: stageCard
                    shadowEnabled: true
                    shadowColor: "#DD000000"
                    shadowBlur: 1.0
                    shadowVerticalOffset: 14
                }

                Rectangle {
                    id: stageCard
                    anchors.fill: parent
                    radius: 26
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.95) }
                        GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b, 0.96) }
                    }
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.12)
                    clip: true

                    // Inner Hairline Border
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 1
                        radius: 25
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.04)
                    }

                    // Top Specular Highlight Bar
                    Rectangle {
                        anchors.top: parent.top
                        anchors.topMargin: 1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 80
                        height: 1
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.25) }
                            GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.65) }
                            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.25) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }

                    // Left & Right Glowing Accent Side-Rims
                    Rectangle {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 140
                        radius: 1
                        color: TitanTheme.accent
                        opacity: 0.75
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 140
                        radius: 1
                        color: TitanTheme.info
                        opacity: 0.75
                    }

                    // Corner Targeting Reticle
                    TitanReticle {
                        anchors.fill: parent
                        anchors.margins: 12
                        color: TitanTheme.accent
                        bracketLength: 16
                        bracketThickness: 2
                        opacity: 0.35
                    }

                    // 6-Act Slide Viewport
                    Item {
                        anchors.fill: parent

                        SlideWelcome {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 0 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }

                        SlideControlCenter {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 1 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }

                        SlideKeybinds {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 2 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }

                        SlideEcosystem {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 3 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }

                        SlideHardware {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 4 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                        }

                        SlideLaunch {
                            anchors.fill: parent
                            visible: opacity > 0.01
                            opacity: window.currentSlide === 5 ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
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
