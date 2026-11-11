import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root

    // 0: Dwindle Split, 1: Floating Overlay, 2: Fullscreen Monocle, 3: 4-Pane Matrix
    property int simMode: 0
    property int activeKeyIndex: 0

    readonly property var keyDeck: [
        {
            keys: ["SUPER", "T"],
            title: "Spawn Foot Terminal",
            desc: "Splits the active workspace automatically using Hyprland's dynamic dwindle tree.",
            mode: 0,
            icon: "\uf120",
            color: TitanTheme.accent,
            canRun: true,
            runAction: function() { tourCtrl.launchTerminal(); }
        },
        {
            keys: ["SUPER", "SPACE"],
            title: "Titan Spotlight Launcher",
            desc: "Summons the floating C++20 fuzzy application & command launcher over your workspace.",
            mode: 1,
            icon: "\uf002",
            color: TitanTheme.info,
            canRun: true,
            runAction: function() { tourCtrl.toggleSpotlight(); }
        },
        {
            keys: ["SUPER", "F"],
            title: "Fullscreen Monocle Mode",
            desc: "Expands the focused window edge-to-edge while preserving your underlying dwindle tree.",
            mode: 2,
            icon: "\uf065",
            color: TitanTheme.mauve,
            canRun: false,
            runAction: function() {}
        },
        {
            keys: ["SUPER", "1..4"],
            title: "Multi-Pane Workspace Matrix",
            desc: "Switch instantly across 10 independent workspaces or move windows with Super+Shift+1..9.",
            mode: 3,
            icon: "\uf009",
            color: TitanTheme.success,
            canRun: false,
            runAction: function() {}
        },
        {
            keys: ["SUPER", "N"],
            title: "Stepped Control Center",
            desc: "Opens the TDL 2.0 quick settings, audio router, Wi-Fi/BT toggles, and MPRIS deck.",
            mode: 1,
            icon: "\uf1de",
            color: TitanTheme.teal,
            canRun: true,
            runAction: function() { tourCtrl.toggleControlCenter(); }
        },
        {
            keys: ["SUPER", "Q"],
            title: "Close Focused Window",
            desc: "Cleanly terminates the active window and dynamically reflows remaining tiled siblings.",
            mode: 0,
            icon: "\uf00d",
            color: TitanTheme.warning,
            canRun: false,
            runAction: function() {}
        }
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: 28
        spacing: 26

        // Left Column: Interactive Animated Hyprland Tiling Simulator
        Rectangle {
            Layout.preferredWidth: 430
            Layout.fillHeight: true
            radius: 20
            color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.72)
            border.width: 1
            border.color: Qt.rgba(0.65, 0.55, 0.98, 0.32)

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

                // Simulator Header & Mode Selector Pills
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "HYPRLAND COMPOSITOR SIMULATOR"
                        color: TitanTheme.mauve
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 1.0
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: ["DWINDLE TREE", "FLOATING HUD", "MONOCLE MAX", "QUAD MATRIX"][root.simMode]
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

                    // Window 1: Primary Terminal
                    Rectangle {
                        x: stageBox.pad
                        y: stageBox.pad
                        width: root.simMode === 2 ? stageBox.w : (stageBox.w * 0.54 - 4)
                        height: (root.simMode === 3) ? (stageBox.h * 0.5 - 4) : stageBox.h
                        radius: 10
                        color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                        border.width: 2
                        border.color: TitanTheme.accent

                        Behavior on width { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf120"; color: TitanTheme.accent; font.family: TitanTheme.monoFamily; font.pixelSize: 12 }
                                Text { text: "foot // zsh + tmux"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 10; font.weight: Font.Bold }
                            }
                            Text {
                                text: "$ fastfetch --logo ArchTitan\nKernel: Linux Zen\nWM: Hyprland (Wayland)\nShell: TDL 2.0 Native"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 9
                                lineHeight: 1.3
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Window 2: Code Editor (Top-Right)
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
                                Text { text: "\uf121"; color: TitanTheme.info; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "nvim // tourcontroller.cpp"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Text {
                                text: "LayerShellQt::Window::get(win)\n->setLayer(LayerOverlay);"
                                color: TitanTheme.textLow
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 8
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Window 3: Telemetry / Browser (Bottom-Right)
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
                                Text { text: "\uf080"; color: TitanTheme.success; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "btop // telemetry"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
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
                        color: Qt.rgba(0.65, 0.55, 0.98, 0.15)
                        border.width: 1
                        border.color: TitanTheme.mauve

                        Behavior on opacity { NumberAnimation { duration: 240 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            RowLayout {
                                spacing: 6
                                Text { text: "\uf07b"; color: TitanTheme.mauve; font.family: TitanTheme.monoFamily; font.pixelSize: 11 }
                                Text { text: "thunar // airootfs"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 9; font.weight: Font.Bold }
                            }
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // Floating Overlay Card (In Mode 1 - Spotlight / QuickSettings)
                    Rectangle {
                        visible: opacity > 0.02
                        opacity: root.simMode === 1 ? 1.0 : 0.0
                        anchors.centerIn: parent
                        width: stageBox.w * 0.68
                        height: 92
                        radius: 16
                        color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.96)
                        border.width: 2
                        border.color: TitanTheme.info

                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            RowLayout {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 8
                                Text { text: "\uf002"; color: TitanTheme.info; font.family: TitanTheme.monoFamily; font.pixelSize: 14 }
                                Text { text: "FLOAT OVERLAY // LAYER-SHELL"; color: TitanTheme.textHigh; font.family: TitanTheme.monoFamily; font.pixelSize: 11; font.weight: Font.Bold }
                            }
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: "Floats above tiled windows without breaking layout"
                                color: TitanTheme.textMid
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                // 4 Layout Mode Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: ["01 Dwindle", "02 Float HUD", "03 Monocle", "04 Quad Grid"]

                        delegate: Rectangle {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            height: 30
                            radius: 8
                            color: root.simMode === index
                                ? Qt.rgba(0.65, 0.55, 0.98, 0.24)
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

        // Right Column: Mechanical Keycap Matrix
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
                    color: Qt.rgba(0.65, 0.55, 0.98, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(0.65, 0.55, 0.98, 0.45)

                    Text {
                        id: actBadge
                        anchors.centerIn: parent
                        text: "ACT 03 // HYPRLAND KEYBOARD WORKFLOW"
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
                text: "Zero-Friction Tiling & Hotkeys"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 26
                font.weight: Font.Black
            }

            Text {
                Layout.fillWidth: true
                text: "Click any mechanical keybind card below to preview its behavior in the compositor simulator—or fire the command live on your desktop."
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
                            ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.15)
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

                                // Mechanical Keycap Pills
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

                                        // Bottom mechanical keycap bevel
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

                                // Optional "Run Live" pill button
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
