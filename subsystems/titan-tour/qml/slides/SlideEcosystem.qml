import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    property bool simWifi: true
    property bool simBt: true
    property bool simShare: false
    property real simBrightness: 0.82
    property real simVolume: 0.68
    property bool simPlaying: true
    property real eqPhase: 0.0

    NumberAnimation on eqPhase {
        from: 0; to: 6.283; duration: 1400; loops: Animation.Infinite; running: root.simPlaying
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 24

        // Left Column: True Concave-Fillet Stepped Bottleneck Control Center Replica
        Rectangle {
            Layout.preferredWidth: 426
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.32)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.teal
                bracketLength: 14
                bracketThickness: 2
                opacity: 0.45
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "STEPPED BOTTLENECK SILHOUETTE // INTERACTIVE"
                        color: TitanTheme.teal
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "CLICK CONTROLS"
                        color: TitanTheme.textLow
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 9
                        font.weight: Font.Bold
                    }
                }

                // Unified Stepped Bottleneck Canvas Container (Matches QuickSettingsWindow.qml lines 176-243!)
                Item {
                    id: bottleneckStage
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    readonly property real stepX: 98
                    readonly property real stepY: height - 50

                    Canvas {
                        id: steppedCanvas
                        anchors.fill: parent
                        onWidthChanged: requestPaint()
                        onHeightChanged: requestPaint()
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            var W = width - 1;
                            var H = height - 1;
                            var x0 = 0.5;
                            var y0 = 0.5;
                            var r = 18;
                            var sx = bottleneckStage.stepX;
                            var sy = bottleneckStage.stepY;
                            var rBot = 16;
                            var rInner = 14;

                            ctx.beginPath();
                            ctx.moveTo(x0 + r, y0);
                            ctx.lineTo(W - r, y0);
                            ctx.arcTo(W, y0, W, y0 + r, r);
                            ctx.lineTo(W, H - r);
                            ctx.arcTo(W, H, W - r, H, r);
                            ctx.lineTo(sx + rBot, H);
                            ctx.arcTo(sx, H, sx, H - rBot, rBot);
                            ctx.lineTo(sx, sy + rInner);
                            ctx.arcTo(sx, sy, sx - rInner, sy, rInner);
                            ctx.lineTo(x0 + r, sy);
                            ctx.arcTo(x0, sy, x0, sy - r, r);
                            ctx.lineTo(x0, y0 + r);
                            ctx.arcTo(x0, y0, x0 + r, y0, r);
                            ctx.closePath();

                            ctx.fillStyle = "rgba(18, 22, 34, 0.92)";
                            ctx.fill();
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = "rgba(56, 189, 248, 0.42)";
                            ctx.stroke();
                        }
                    }

                    // Upper Body Content
                    ColumnLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: bottleneckStage.stepY
                        anchors.margins: 12
                        spacing: 8

                        // Top Row: Connectivity Stack + Now Playing MPRIS Card
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 10

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { label: "Wi-Fi 6E", sub: root.simWifi ? "ArchTitan-5G" : "Offline", icon: "\uf1eb", active: root.simWifi, idx: 0 },
                                        { label: "Bluetooth", sub: root.simBt ? "Connected" : "Off", icon: "\uf293", active: root.simBt, idx: 1 },
                                        { label: "Quick Share", sub: root.simShare ? "Visible" : "Hidden", icon: "\uf1e0", active: root.simShare, idx: 2 }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        radius: 10
                                        color: modelData.active
                                            ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.25)
                                            : Qt.rgba(1, 1, 1, 0.04)
                                        border.width: 1
                                        border.color: modelData.active ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.08)

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            Rectangle {
                                                width: 24; height: 24; radius: 12
                                                color: modelData.active ? TitanTheme.accent : Qt.rgba(1, 1, 1, 0.08)
                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    color: modelData.active ? "#FFFFFF" : TitanTheme.textLow
                                                    font.family: TitanTheme.monoFamily
                                                    font.pixelSize: 11
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 0
                                                Text {
                                                    text: modelData.label
                                                    color: TitanTheme.textHigh
                                                    font.family: TitanTheme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                }
                                                Text {
                                                    text: modelData.sub
                                                    color: TitanTheme.textMid
                                                    font.family: TitanTheme.monoFamily
                                                    font.pixelSize: 8
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                tourCtrl.playSound("click");
                                                if (modelData.idx === 0) root.simWifi = !root.simWifi;
                                                else if (modelData.idx === 1) root.simBt = !root.simBt;
                                                else root.simShare = !root.simShare;
                                            }
                                        }
                                    }
                                }
                            }

                            // Right Now Playing MPRIS2 Card
                            Rectangle {
                                Layout.preferredWidth: 175
                                Layout.fillHeight: true
                                radius: 14
                                color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.78)
                                border.width: 1
                                border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.35)

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text {
                                            text: "NOW PLAYING"
                                            color: TitanTheme.info
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 8
                                            font.weight: Font.Bold
                                        }
                                        Item { Layout.fillWidth: true }
                                        Row {
                                            spacing: 2
                                            Repeater {
                                                model: 4
                                                delegate: Rectangle {
                                                    required property int index
                                                    width: 3
                                                    height: root.simPlaying ? (6 + 8 * Math.abs(Math.sin(root.eqPhase + index * 1.1))) : 4
                                                    radius: 1.5
                                                    color: TitanTheme.info
                                                    anchors.bottom: parent.bottom
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Rectangle {
                                            width: 38; height: 38; radius: 8
                                            color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.25)
                                            border.width: 1
                                            border.color: TitanTheme.info
                                            Image {
                                                anchors.centerIn: parent
                                                width: 26; height: 26
                                                source: tourCtrl.logoUrl
                                                fillMode: Image.PreserveAspectFit
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                Layout.fillWidth: true
                                                text: "SOL VIBRA (Slowed)"
                                                color: TitanTheme.textHigh
                                                font.family: TitanTheme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                text: "DJ Zarek • MPRIS2"
                                                color: TitanTheme.textMid
                                                font.family: TitanTheme.monoFamily
                                                font.pixelSize: 9
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    Item { Layout.fillHeight: true }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 14
                                        Item { Layout.fillWidth: true }
                                        Text { text: "\uf04a"; color: TitanTheme.textMid; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                        Rectangle {
                                            width: 24; height: 24; radius: 12
                                            color: TitanTheme.info
                                            Text {
                                                anchors.centerIn: parent
                                                text: root.simPlaying ? "\uf04c" : "\uf04b"
                                                color: TitanTheme.crust
                                                font.family: TitanTheme.monoFamily
                                                font.pixelSize: 10
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    tourCtrl.playSound("click");
                                                    root.simPlaying = !root.simPlaying;
                                                }
                                            }
                                        }
                                        Text { text: "\uf04e"; color: TitanTheme.textMid; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }

                        // Display & Sound Interactive Sliders
                        Repeater {
                            model: [
                                { name: "DISPLAY", icon: "\uf185", val: root.simBrightness, col: TitanTheme.info, isBri: true },
                                { name: "PIPEWIRE", icon: "\uf028", val: root.simVolume, col: TitanTheme.accent, isBri: false }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 34
                                radius: 10
                                color: Qt.rgba(1, 1, 1, 0.04)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.08)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Text {
                                        text: modelData.icon
                                        color: modelData.col
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        text: modelData.name
                                        color: TitanTheme.textMid
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        Layout.preferredWidth: 54
                                    }

                                    Rectangle {
                                        id: trackBar
                                        Layout.fillWidth: true
                                        height: 10
                                        radius: 5
                                        color: Qt.rgba(1, 1, 1, 0.08)

                                        Rectangle {
                                            width: parent.width * modelData.val
                                            height: parent.height
                                            radius: 5
                                            color: modelData.col
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: function(mouse) {
                                                var v = Math.max(0.08, Math.min(1.0, mouse.x / trackBar.width));
                                                if (modelData.isBri) root.simBrightness = v;
                                                else root.simVolume = v;
                                                tourCtrl.playSound("step");
                                            }
                                        }
                                    }

                                    Text {
                                        text: Math.round(modelData.val * 100) + "%"
                                        color: TitanTheme.textHigh
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        Layout.preferredWidth: 32
                                        horizontalAlignment: Text.AlignRight
                                    }
                                }
                            }
                        }
                    }

                    // Right-Aligned Stepped Bottleneck 5-Icon Dock inside the concave cutout!
                    RowLayout {
                        x: bottleneckStage.stepX + 14
                        y: bottleneckStage.stepY + 8
                        width: bottleneckStage.width - bottleneckStage.stepX - 26
                        height: 34
                        spacing: 10

                        Repeater {
                            model: ["\uf0e7", "\uf013", "\uf040", "\uf023", "\uf011"]
                            delegate: Rectangle {
                                required property string modelData
                                required property int index
                                Layout.fillWidth: true
                                height: 30
                                radius: 15
                                color: index === 2 ? Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.22) : Qt.rgba(1, 1, 1, 0.06)

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: index === 4 ? TitanTheme.danger : (index === 2 ? TitanTheme.teal : TitanTheme.textHigh)
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // Callout Label in the Bottom-Left Cutout Void
                    Text {
                        x: 8
                        y: bottleneckStage.stepY + 16
                        text: "↖ CONCAVE CUTOUT"
                        color: TitanTheme.teal
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                    }
                }
            }
        }

        // Right Column: Architecture Highlights & Live Control Triggers
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: ccTag.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.teal.r, TitanTheme.teal.g, TitanTheme.teal.b, 0.45)

                    Text {
                        id: ccTag
                        anchors.centerIn: parent
                        text: "ACT 04 // STEPPED BOTTLENECK CONTROL CENTER"
                        color: TitanTheme.teal
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Asymmetric Concave-Fillet Glass"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            Text {
                Layout.fillWidth: true
                text: "Look at the bottom-left corner of the replica on the left: titan-quicksettings renders an asymmetric stepped bottleneck silhouette with a smooth concave fillet and a right-aligned 5-icon action dock."
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                lineHeight: 1.35
                wrapMode: Text.WordWrap
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                Repeater {
                    model: [
                        {
                            icon: "\uf001",
                            title: "Smart MPRIS2 Browser & Spotify Priority",
                            desc: "Tracks active browser streams (Plasma Integration), Spotify, VLC, and MPV—preserving real album artwork and artist metadata across play/pause states.",
                            color: TitanTheme.info
                        },
                        {
                            icon: "\uf040",
                            title: "In-Place Edit Mode & Dual-Panel Notifications",
                            desc: "Click the Pencil icon in the bottleneck dock to add/remove tiles live, or expand the 880px side-by-side Notification & Media Hub.",
                            color: TitanTheme.accent
                        },
                        {
                            icon: "\uf028",
                            title: "PipeWire + SwayOSD Hardware Integration",
                            desc: "Low-latency audio sink routing, night light temperature control, Wi-Fi 6E scanning, and Bluetooth device pairing.",
                            color: TitanTheme.success
                        }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.55)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            Rectangle {
                                width: 38; height: 38; radius: 10
                                color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.15)
                                border.width: 1
                                border.color: modelData.color

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: modelData.color
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 15
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: modelData.title
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    color: TitanTheme.textMid
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 11
                                    lineHeight: 1.25
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                TitanButton {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    text: "Summon Control Center (Super+N)"
                    glyph: "\uf1de"
                    variant: "primary"
                    onClicked: tourCtrl.toggleControlCenter()
                }

                TitanButton {
                    Layout.preferredWidth: 210
                    implicitHeight: 40
                    text: "Open Notification Hub"
                    glyph: "\uf0f3"
                    variant: "secondary"
                    onClicked: tourCtrl.openNotifications()
                }
            }
        }
    }
}
