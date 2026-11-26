import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import ArchTitan.Media 1.0
import ArchTitan.TitanUI

Window {
    id: root
    title: "titan-media-hud"
    width: 508
    height: 116
    color: "transparent"
    visible: false

    readonly property int cardWidth: 476
    readonly property int cardHeight: 88
    readonly property int cardRadius: 18
    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined") ? AppearanceSettings.glassmorphism : true

    readonly property color accentColor: TitanTheme.accent
    readonly property color cardColor: liquidGlass ? TitanTheme.glassAlt : TitanTheme.base
    readonly property color textHigh: TitanTheme.textHigh
    readonly property color textMid: TitanTheme.textMid
    readonly property color textLow: TitanTheme.textLow

    property bool showVolumeToast: false
    property real currentVolume: Mpris ? Mpris.volume : 1.0

    Timer {
        id: volumeToastTimer
        interval: 1200
        onTriggered: root.showVolumeToast = false
    }

    Item {
        focus: Island.isVisible
        Keys.onEscapePressed: Island.dismiss()
        Keys.onSpacePressed: if (Mpris) Mpris.playPause()
        Keys.onLeftPressed: {
            if (Mpris && Mpris.length > 0) Mpris.seek(Math.max(0.0, Mpris.progress - 0.05))
        }
        Keys.onRightPressed: {
            if (Mpris && Mpris.length > 0) Mpris.seek(Math.min(1.0, Mpris.progress + 0.05))
        }
    }

    Item {
        id: clipContainer
        anchors.fill: parent

        Item {
            id: islandContent
            width: root.cardWidth
            height: root.cardHeight
            anchors.horizontalCenter: parent.horizontalCenter
            y: 12

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 5
                radius: root.cardRadius
                color: "#6604080C"
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: root.cardRadius + 3
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b,
                                      (Mpris && Mpris.isPlaying) ? 0.28 : 0.12)

                SequentialAnimation on opacity {
                    running: Island.isVisible && (Mpris && Mpris.isPlaying)
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.65; to: 1.0; duration: 1600; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 1.0; to: 0.65; duration: 1600; easing.type: Easing.InOutQuad }
                }
            }

            Rectangle {
                id: glassCard
                anchors.fill: parent
                radius: root.cardRadius
                color: root.cardColor
                border.width: 1
                border.color: TitanTheme.borderSubtle
                clip: true

                Image {
                    id: ambientArt
                    anchors.fill: parent
                    source: Mpris ? Mpris.artUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    smooth: true
                    scale: 1.3
                    opacity: 0.20
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0.07, 0.07, 0.11, root.liquidGlass ? 0.58 : 0.82)
                }
                Canvas {
                    id: ambientWave
                    anchors.fill: parent
                    opacity: 0.12
                    visible: Mpris && Mpris.isPlaying
                    onPaint: {
                        var ctx = getContext("2d")
                        if (!ctx) return
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = accentColor.toString()
                        ctx.lineWidth = 2
                        for (var row = 0; row < 3; row++) {
                            ctx.beginPath()
                            for (var x = 0; x <= width; x += 6) {
                                var y = height * (0.35 + row * 0.15) + Math.sin(x / 40 - Date.now() / 500 + row) * 6
                                if (x === 0) ctx.moveTo(x, y)
                                else ctx.lineTo(x, y)
                            }
                            ctx.stroke()
                        }
                    }
                    Timer {
                        interval: 90
                        repeat: true
                        running: visible && root.visible
                        onTriggered: requestPaint()
                    }
                }


                Rectangle {
                    anchors.fill: parent
                    radius: root.cardRadius
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#22FFFFFF" }
                        GradientStop { position: 0.42; color: "#06FFFFFF" }
                        GradientStop { position: 1.0; color: "#14000000" }
                    }
                }

                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.72
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#4DFFFFFF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Rectangle {
                    id: sheen
                    width: 78
                    height: 220
                    x: -130
                    y: -70
                    rotation: -26
                    visible: root.liquidGlass
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.48; color: "#16FFFFFF" }
                        GradientStop { position: 0.62; color: "#05FFFFFF" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    SequentialAnimation on x {
                        running: root.visible && root.liquidGlass
                        loops: Animation.Infinite
                        NumberAnimation { from: -130; to: root.cardWidth + 40; duration: 4200; easing.type: Easing.InOutSine }
                        PauseAnimation { duration: 1800 }
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 12
                z: 2

                AlbumArt {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    Layout.alignment: Qt.AlignVCenter
                    artSize: 72
                    cornerRadius: 14
                    showGlow: false
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: (Mpris && Mpris.title.length > 0) ? Mpris.title : "No Media Playing"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                color: root.textHigh
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                Layout.fillWidth: true
                                text: (Mpris && Mpris.artist.length > 0) ? Mpris.artist : "ArchTitan Audio"
                                font.pixelSize: 10
                                color: root.textMid
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }

                        Rectangle {
                            id: playBadge
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            Layout.alignment: Qt.AlignVCenter
                            radius: (Mpris && Mpris.isPlaying) ? 20 : 13
                            color: (Mpris && Mpris.isPlaying) ? accentColor : Qt.rgba(1, 1, 1, 0.07)
                            border.width: (Mpris && Mpris.isPlaying) ? 0 : 1
                            border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.35)

                            Behavior on radius { NumberAnimation { duration: 160 } }
                            Behavior on color { ColorAnimation { duration: 160 } }

                            TransportButton {
                                anchors.fill: parent
                                type: "playpause"
                                isPlaying: Mpris && Mpris.isPlaying
                                hitSize: 40
                                glyphColor: (Mpris && Mpris.isPlaying) ? TitanTheme.textOnAccent : "#FFFFFF"
                                onActivated: if (Mpris) Mpris.playPause()
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Item {
                        id: progressArea
                        Layout.fillWidth: true
                        Layout.preferredHeight: 26

                        Text {
                            anchors.left: parent.left
                            anchors.bottom: progressRow.top
                            anchors.bottomMargin: 2
                            text: (Mpris && Mpris.length > 0) ? (Mpris.positionText + " / " + Mpris.lengthText) : "0:00 / 0:00"
                            font.pixelSize: 9
                            color: root.textLow
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            id: progressRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            spacing: 6

                            TransportButton {
                                type: "previous"
                                hitSize: 26
                                iconSize: 9
                                onActivated: if (Mpris) Mpris.previous()
                            }

                            Item {
                                id: trackArea
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20

                                property bool isDragging: false
                                property real dragProgress: 0.0
                                property real scrubProgress: isDragging ? dragProgress : (Mpris ? Mpris.progress : 0.0)

                                Rectangle {
                                    id: trackBg
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 5
                                    radius: 2.5
                                    color: Qt.rgba(TitanTheme.surface1.r, TitanTheme.surface1.g, TitanTheme.surface1.b, 0.75)
                                }

                                Rectangle {
                                    id: progressFill
                                    anchors.left: parent.left
                                    anchors.top: trackBg.top
                                    anchors.bottom: trackBg.bottom
                                    width: Math.max(0, Math.min(trackBg.width, trackBg.width * trackArea.scrubProgress))
                                    radius: 2.5
                                    color: accentColor
                                }

                                Canvas {
                                    id: waveCanvas
                                    anchors.fill: trackBg
                                    visible: Mpris && Mpris.isPlaying
                                    opacity: 0.5
                                    onPaint: {
                                        var ctx = getContext("2d")
                                        if (!ctx) return
                                        ctx.clearRect(0, 0, width, height)
                                        ctx.strokeStyle = accentColor.toString()
                                        ctx.lineWidth = 1
                                        ctx.beginPath()
                                        for (var x = 0; x <= width; x += 4) {
                                            var y = height / 2 + Math.sin(x / 8 - Date.now() / 240) * 1.6
                                            if (x === 0) ctx.moveTo(x, y)
                                            else ctx.lineTo(x, y)
                                        }
                                        ctx.stroke()
                                    }

                                    Timer {
                                        interval: 70
                                        repeat: true
                                        running: waveCanvas.visible && root.visible
                                        onTriggered: waveCanvas.requestPaint()
                                    }
                                }

                                Rectangle {
                                    id: pip
                                    width: 9
                                    height: 9
                                    x: Math.max(0, Math.min(trackBg.width - width, trackBg.width * trackArea.scrubProgress - width / 2))
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: 4.5
                                    color: "#FFFFFF"
                                    border.color: accentColor
                                    border.width: 1.5
                                }

                                MouseArea {
                                    id: scrubArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    function seekTo(x) {
                                        if (!Mpris || Mpris.length <= 0) return
                                        var norm = Math.max(0.0, Math.min(1.0, x / width))
                                        trackArea.dragProgress = norm
                                        Mpris.seek(norm)
                                    }
                                    onPressed: (mouse) => { trackArea.isDragging = true; seekTo(mouse.x) }
                                    onPositionChanged: (mouse) => { if (trackArea.isDragging && pressed) seekTo(mouse.x) }
                                    onReleased: trackArea.isDragging = false
                                }
                            }

                            TransportButton {
                                type: "next"
                                hitSize: 26
                                iconSize: 9
                                onActivated: if (Mpris) Mpris.next()
                            }
                        }
                    }
                }
            }

            WheelHandler {
                anchors.fill: parent
                onWheel: (event) => {
                    if (!Mpris) return
                    var delta = event.angleDelta.y > 0 ? 0.05 : -0.05
                    var vol = Math.max(0.0, Math.min(1.0, Mpris.volume + delta))
                    Mpris.volume = vol
                    root.currentVolume = vol
                    root.showVolumeToast = true
                    volumeToastTimer.restart()
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: root.cardRadius
                color: TitanTheme.glass
                border.color: Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.5)
                border.width: 1
                visible: root.showVolumeToast
                opacity: root.showVolumeToast ? 1.0 : 0.0
                z: 10

                Row {
                    anchors.centerIn: parent
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.currentVolume > 0.5 ? "🔊" : (root.currentVolume > 0 ? "🔉" : "🔇")
                        font.pixelSize: 16
                        color: root.textHigh
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 180
                        height: 6
                        radius: 3
                        color: TitanTheme.surface1
                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * root.currentVolume
                            radius: 3
                            color: accentColor
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(root.currentVolume * 100) + "%"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: root.textHigh
                    }
                }
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }
        }
    }

    Component.onCompleted: {
        islandContent.opacity = 0.0
        islandContent.scale = 0.85
        islandContent.y = -50
    }

    ParallelAnimation {
        id: openAnim
        NumberAnimation { target: islandContent; property: "opacity"; from: 0; to: 1; duration: 150 }
        NumberAnimation { target: islandContent; property: "scale"; from: 0.85; to: 1; duration: 340; easing.type: Easing.OutBack }
        NumberAnimation { target: islandContent; property: "y"; from: -50; to: 12; duration: 340; easing.type: Easing.OutBack }
        onFinished: Island.onOpenAnimationFinished()
    }

    ParallelAnimation {
        id: closeAnim
        NumberAnimation { target: islandContent; property: "opacity"; from: 1; to: 0; duration: 180 }
        NumberAnimation { target: islandContent; property: "scale"; from: 1; to: 0.88; duration: 220; easing.type: Easing.InBack }
        NumberAnimation { target: islandContent; property: "y"; from: 12; to: -50; duration: 220; easing.type: Easing.InCubic }
        onFinished: {
            Island.onCloseAnimationFinished()
            root.visible = false
            islandContent.y = -50
            islandContent.scale = 0.85
        }
    }

    Connections {
        target: Island

        function onRequestOpen() {
            closeAnim.stop()
            root.visible = true
            islandContent.y = -50
            islandContent.scale = 0.85
            islandContent.opacity = 0
            openAnim.start()
        }
        function onRequestClose() { openAnim.stop(); closeAnim.start() }
        function onRequestExpand() { Island.onExpandAnimationFinished() }
        function onRequestCollapse() { Island.onCollapseAnimationFinished() }
    }
}
