import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    // 0: Dwindle Split, 1: Floating Overlay, 2: Fullscreen Monocle, 3: 10-Workspace HUD
    property int simMode: 0
    property int activeKeyIndex: 0

    readonly property var keyDeck: [
        {
            keys: ["SUPER", "T"],
            title: "Spawn Kitty GPU Terminal",
            desc: "Launches Kitty via titan-sandboxd (titan-exec-hook) and splits the active dwindle tree.",
            mode: 0,
            icon: "\uf120",
            color: TitanTheme.accent,
            canRun: true,
            runAction: function() { tourCtrl.launchTerminal(); }
        },
        {
            keys: ["SUPER", "SPACE"],
            title: "Titan Spotlight & Clipboard",
            desc: "Tap Super alone or press Super+Space for fuzzy launch. Press Super+V for Clipboard History.",
            mode: 1,
            icon: "\uf002",
            color: TitanTheme.info,
            canRun: true,
            runAction: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            keys: ["SUPER", "TAB"],
            title: "10-Workspace HUD Switcher",
            desc: "Summons titan-workspace-hud (or use 3-finger horizontal touchpad swipe for 1:1 slide).",
            mode: 3,
            icon: "\uf009",
            color: TitanTheme.teal,
            canRun: true,
            runAction: function() { tourCtrl.toggleWorkspaceHud(); }
        },
        {
            keys: ["SUPER", "/"],
            title: "Liquid Glass Command Menu",
            desc: "Opens titan-menu (Grid & List views) or swipe 3 fingers up on your touchpad.",
            mode: 1,
            icon: "\uf00a",
            color: TitanTheme.mauve,
            canRun: true,
            runAction: function() { tourCtrl.toggleMenu(); }
        },
        {
            keys: ["SUPER", "\\"],
            title: "Wallpaper Picker Studio",
            desc: "Opens titan-wallpaper-picker to switch live swww wallpapers and adaptive TDL themes.",
            mode: 2,
            icon: "\uf03e",
            color: TitanTheme.warning,
            canRun: true,
            runAction: function() { tourCtrl.launchWallpaperPicker(); }
        },
        {
            keys: ["3/4", "SWIPE"],
            title: "Native Touchpad Gestures",
            desc: "3-Right/Left: Workspace • 3-Up: Menu • 3-Down: Close • 4-Up: Magic Scratchpad (Super+S).",
            mode: 3,
            icon: "\uf25a",
            color: TitanTheme.success,
            canRun: false,
            runAction: function() {}
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 26
        spacing: 24

        // Left Column: Interactive Animated Hyprland Tiling Simulator
        Rectangle {
            Layout.preferredWidth: 426
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.32)

            TitanReticle {
                anchors.fill: parent
                anchors.margins: 10
                color: TitanTheme.mauve
                bracketLength: 14
                bracketThickness: 2
                opacity: 0.45
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "HYPRLAND >= 0.55 LUA COMPOSITOR"
                        color: TitanTheme.mauve
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: ["DWINDLE TREE", "LIQUID OVERLAY", "MONOCLE MAX", "10-WS MATRIX"][root.simMode]
                        color: TitanTheme.info
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                // Animated Compositor Stage
                Rectangle {
                    id: stageBox
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 14
                    color: Qt.rgba(0.03, 0.04, 0.08, 0.95)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)
                    clip: true

                    readonly property real pad: 10
                    readonly property real w: width - pad * 2
                    readonly property real h: height - pad * 2

                    // Window 1: Primary Kitty Terminal
                    Rectangle {
                        x: stageBox.pad
                        y: stageBox.pad
                        width: root.simMode === 2 ? stageBox.w : (stageBox.w * 0.54 - 4)
                        height: (root.simMode === 3) ? (stageBox.h * 0.5 - 4) : stageBox.h
                        radius: 10
                        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                        border.width: 2
                        border.color: TitanTheme.accent

                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf120"; color: TitanTheme.accent; font.family: TitanTheme.monoFamily; font.pixelSize: 12 }
                                Text { text: "kitty // titan-exec-hook"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                            Text {
                                text: "$ fastfetch\nOS: ArchTitan x86_64\nWM: Hyprland 0.55 (Lua)\nSandbox: titan-sandboxd\nShell: TDL 2.0 Liquid Glass"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 9
                                lineHeight: 1.3
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Window 2: TitanBrowser (Top-Right)
                    Rectangle {
                        visible: opacity > 0.02
                        opacity: root.simMode === 2 ? 0.0 : 1.0
                        x: stageBox.pad + stageBox.w * 0.54 + 4
                        y: stageBox.pad
                        width: stageBox.w * 0.46 - 4
                        height: stageBox.h * 0.5 - 4
                        radius: 10
                        color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.55)

                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf268"; color: TitanTheme.info; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "titanbrowser // Super+B"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Text {
                                text: "Sandboxed policy active\nHardware VA-API enabled"
                                color: TitanTheme.textLow
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 8
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Window 3: Ranger File Manager (Bottom-Right)
                    Rectangle {
                        visible: opacity > 0.02
                        opacity: root.simMode === 2 ? 0.0 : 1.0
                        x: stageBox.pad + stageBox.w * 0.54 + 4
                        y: stageBox.pad + stageBox.h * 0.5 + 4
                        width: stageBox.w * 0.46 - 4
                        height: stageBox.h * 0.5 - 4
                        radius: 10
                        color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.12)
                        border.width: 1
                        border.color: Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.5)

                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf07b"; color: TitanTheme.success; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "ranger // Super+E"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Text {
                                text: "CPU: " + Math.round(tourCtrl.cpuUsage * 100) + "%  TEMP: " + tourCtrl.cpuTemp + "°C"
                                color: TitanTheme.success
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 9
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Window 4: Bottom-Left Quad Pane (In Mode 3)
                    Rectangle {
                        visible: opacity > 0.02
                        opacity: root.simMode === 3 ? 1.0 : 0.0
                        x: stageBox.pad
                        y: stageBox.pad + stageBox.h * 0.5 + 4
                        width: stageBox.w * 0.54 - 4
                        height: stageBox.h * 0.5 - 4
                        radius: 10
                        color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.15)
                        border.width: 1
                        border.color: TitanTheme.mauve

                        Behavior on opacity { NumberAnimation { duration: 240 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf009"; color: TitanTheme.mauve; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "titan-workspace-hud // WS 1..10"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Text {
                                text: "3-Finger Swipe • Super+Tab"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 8
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Floating Overlay Card (In Mode 1 - Spotlight / Menu)
                    Rectangle {
                        visible: opacity > 0.02
                        opacity: root.simMode === 1 ? 1.0 : 0.0
                        anchors.centerIn: parent
                        width: stageBox.w * 0.72
                        height: 94
                        radius: 18
                        color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.96)
                        border.width: 1.5
                        border.color: TitanTheme.accent

                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8
                                Text { text: "\uf002"; color: TitanTheme.accent; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                                Text { text: "LIQUID GLASS OVERLAY // LAYER-SHELL"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Dual-Kawase blur (size=8, passes=4, vibrancy=0.42)"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 9
                            }
                        }
                    }
                }

                // 4 Layout Mode Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: ["01 Dwindle", "02 Liquid HUD", "03 Monocle", "04 10-WS Grid"]

                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: root.simMode === index
                                ? Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.24)
                                : Qt.rgba(1, 1, 1, 0.04)
                            border.width: 1
                            border.color: root.simMode === index ? TitanTheme.mauve : Qt.rgba(1, 1, 1, 0.08)

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                color: root.simMode === index ? TitanTheme.textHigh : TitanTheme.textLow
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    tourCtrl.playSound("step");
                                    root.simMode = index;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Right Column: Mechanical Keycap Matrix & Trackpad Gestures
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                spacing: 10
                Rectangle {
                    height: 24
                    width: actBadge.implicitWidth + 16
                    radius: 12
                    color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.mauve.r, TitanTheme.mauve.g, TitanTheme.mauve.b, 0.45)

                    Text {
                        id: actBadge
                        anchors.centerIn: parent
                        text: "ACT 03 // CHORDS, GESTURES & SANDBOXD"
                        color: TitanTheme.mauve
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Chords, 1:1 Touchpad Swipes & Tiling"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            Text {
                Layout.fillWidth: true
                text: "Click any card below to preview its compositor state on the left—or click RUN LIVE ↗ to fire the native ArchTitan subsystem right now."
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            // 2-Column Grid of Mechanical Keybind Cards
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: 10
                columnSpacing: 10

                Repeater {
                    model: root.keyDeck

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool isSelected: index === root.activeKeyIndex

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: isSelected
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.16)
                            : Qt.rgba(TitanTheme.surface0.r, TitanTheme.surface0.g, TitanTheme.surface0.b, 0.55)
                        border.width: isSelected ? 1.5 : 1
                        border.color: isSelected ? modelData.color : Qt.rgba(1, 1, 1, 0.08)

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: modelData.keys
                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 24
                                        width: kTxt.implicitWidth + 14
                                        radius: 6
                                        color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.9)
                                        border.width: 1
                                        border.color: Qt.rgba(1, 1, 1, 0.22)

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            height: 2
                                            radius: 1
                                            color: Qt.rgba(1, 1, 1, 0.18)
                                        }

                                        Text {
                                            id: kTxt
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: TitanTheme.textHigh
                                            font.family: TitanTheme.monoFamily
                                            font.pixelSize: 10
                                            font.weight: Font.Black
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    visible: modelData.canRun
                                    height: 22
                                    width: runLbl.implicitWidth + 12
                                    radius: 11
                                    color: Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.22)
                                    border.width: 1
                                    border.color: modelData.color
                                    z: 2

                                    Text {
                                        id: runLbl
                                        anchors.centerIn: parent
                                        text: "RUN LIVE ↗"
                                        color: modelData.color
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: modelData.runAction()
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.title
                                color: TitanTheme.textHigh
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: modelData.desc
                                color: TitanTheme.textMid
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 11
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                tourCtrl.playSound("step");
                                root.activeKeyIndex = index;
                                root.simMode = modelData.mode;
                            }
                        }
                    }
                }
            }
        }
    }
}
