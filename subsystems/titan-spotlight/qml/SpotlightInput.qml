import QtQuick
import ArchTitan.TitanUI

Item {
    id: inputRoot
    width: parent.width
    height: 64

    property alias text: textInput.text
    property alias inputItem: textInput

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18

        // Frosted Glowing 3D Search Icon Pedestal
        Rectangle {
            id: searchBadge
            width: 38
            height: 38
            radius: 12
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.18)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.40)

            // 3D subtle pedestal shadow
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                anchors.bottomMargin: -2
                radius: parent.radius
                z: -1
                color: Qt.rgba(0, 0, 0, 0.25)
            }

            Text {
                anchors.centerIn: parent
                text: spotlight.isClipboardMode ? "󰅍" : "󰍉"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 20
                color: TitanTheme.accent
            }
        }

        // Right-side controls: Clear/Clipboard Pill + Segmented View Switcher
        Row {
            id: rightControls
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            // Mode badge or Clear button
            Rectangle {
                id: badgeRect
                anchors.verticalCenter: parent.verticalCenter
                height: 28
                radius: 8
                color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 0
                visible: textInput.text.length > 0 || spotlight.isClipboardMode
                width: badgeText.implicitWidth + 18

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: spotlight.isClipboardMode ? "CLIPBOARD ✕" : "CLEAR ✕"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.bold: true
                    color: TitanTheme.textMid
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (spotlight.isClipboardMode) {
                            spotlight.isClipboardMode = false;
                        }
                        textInput.text = "";
                        textInput.forceActiveFocus();
                    }
                }
            }

            // Segmented Glass View Mode Switcher (Grid | Bento | List)
            Rectangle {
                id: viewSwitcher
                anchors.verticalCenter: parent.verticalCenter
                visible: !spotlight.isClipboardMode
                height: 34
                width: switcherRow.implicitWidth + 8
                radius: 11
                color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.42) : Qt.rgba(0, 0, 0, 0.06)
                border.width: 0

                Row {
                    id: switcherRow
                    anchors.centerIn: parent
                    spacing: 3

                    Repeater {
                        model: [
                            { mode: "grid",  icon: "󰕰", label: "Grid"  },
                            { mode: "bento", icon: "󰙀", label: "Bento" },
                            { mode: "list",  icon: "󰉹", label: "List"  }
                        ]

                        delegate: Rectangle {
                            id: modePill
                            required property var modelData
                            readonly property bool active: spotlight.viewMode === modelData.mode

                            height: 26
                            width: pillRow.implicitWidth + 16
                            radius: 8
                            color: active
                                   ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                                   : (pillMouse.containsMouse
                                      ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05))
                                      : "transparent")
                            border.width: active ? 1 : 0
                            border.color: active ? TitanTheme.accent : "transparent"

                            // Drop shadow behind active pill
                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 1
                                anchors.bottomMargin: -1
                                radius: parent.radius
                                z: -1
                                visible: modePill.active
                                color: Qt.rgba(0, 0, 0, 0.35)
                            }

                            Behavior on color { ColorAnimation { duration: 110 } }

                            Row {
                                id: pillRow
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modePill.modelData.icon
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 13
                                    color: modePill.active ? TitanTheme.accent : TitanTheme.textMid
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modePill.modelData.label
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: modePill.active ? Font.Bold : Font.Medium
                                    color: modePill.active
                                           ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 1.0) : TitanTheme.textHigh)
                                           : TitanTheme.textMid
                                }
                            }

                            MouseArea {
                                id: pillMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    spotlight.viewMode = modePill.modelData.mode;
                                    textInput.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }
        }

        // Search Input Field
        TextInput {
            id: textInput
            anchors.left: searchBadge.right
            anchors.leftMargin: 14
            anchors.right: rightControls.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            font.family: TitanTheme.fontFamily
            font.pixelSize: 17
            font.weight: Font.Medium
            color: TitanTheme.textHigh
            selectionColor: TitanTheme.accent
            selectedTextColor: TitanTheme.textOnAccent
            clip: true
            focus: true

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: spotlight.isClipboardMode
                      ? "Search clipboard history..."
                      : "Search apps, > commands, math, or web..."
                font.family: textInput.font.family
                font.pixelSize: textInput.font.pixelSize
                color: TitanTheme.textLow
                visible: !textInput.text && !textInput.inputMethodComposing
            }

            onTextChanged: {
                spotlight.query = text;
            }

            Keys.onPressed: function(event) {
                const ctrl = (event.modifiers & Qt.ControlModifier) !== 0;
                const alt  = (event.modifiers & Qt.AltModifier) !== 0;

                if (event.key === Qt.Key_Escape) {
                    inputRoot.escapePressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    inputRoot.returnPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Up) {
                    inputRoot.upPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Down) {
                    inputRoot.downPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Tab) {
                    spotlight.cycleViewMode();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab) {
                    spotlight.cycleCategory(1);
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_1) {
                    spotlight.viewMode = "grid";
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_2) {
                    spotlight.viewMode = "bento";
                    event.accepted = true;
                } else if (ctrl && event.key === Qt.Key_3) {
                    spotlight.viewMode = "list";
                    event.accepted = true;
                } else if (event.key === Qt.Key_Left && (textInput.text.length === 0 || alt) && spotlight.gridColumns > 1) {
                    inputRoot.leftPressed();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Right && (textInput.text.length === 0 || alt) && spotlight.gridColumns > 1) {
                    inputRoot.rightPressed();
                    event.accepted = true;
                }
            }
        }
    }
}
