import QtQuick
import QtQuick.Effects
import ArchTitan.TitanUI

/**
 * SpotlightInput — Floating Island Search Capsule.
 * Apple macOS App Library style capsule with Applications icon, centered input, and options menu.
 */
Rectangle {
    id: inputRoot
    width: 380
    height: 44
    radius: 22

    color: TitanTheme.isDark ? TitanTheme.alphaColor(TitanTheme.mantle, 0.96)
                             : TitanTheme.alphaColor(TitanTheme.surface0, 0.96)
    border.width: 1
    border.color: textInput.activeFocus
                  ? TitanTheme.accent
                  : TitanTheme.alphaColor(TitanTheme.border, 0.55)

    Behavior on border.color {
        ColorAnimation { duration: TitanTheme.durFast }
    }

    // Top Specular Sheen (Horizon Glint)
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 36
        height: 1
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.35) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Drop shadow
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: TitanTheme.scrim
        shadowBlur: 0.8
        shadowVerticalOffset: 8
        autoPaddingEnabled: true
    }

    property alias text: textInput.text
    property alias inputItem: textInput

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()
    signal leftPressed()
    signal rightPressed()

    Row {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 10

        // 1. Applications Glyph (App Store A style)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰀻"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 18
            color: textInput.activeFocus ? TitanTheme.accent : "#FFFFFF"
            opacity: 0.90
            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
        }

        // 2. Search Text Input
        Item {
            anchors.verticalCenter: parent.verticalCenter
            height: parent.height
            width: parent.width - 18 - 10 - rightRow.width - 10

            TextInput {
                id: textInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: TitanTheme.fontFamily
                font.pixelSize: 15
                font.weight: TitanTheme.weightMedium
                color: "#FFFFFF"
                selectionColor: TitanTheme.accent
                selectedTextColor: TitanTheme.textOnAccent
                clip: true
                focus: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: spotlight.isClipboardMode ? "Search clipboard history..." : "Applications"
                    font.family: textInput.font.family
                    font.pixelSize: textInput.font.pixelSize
                    font.weight: textInput.font.weight
                    color: TitanTheme.textLow
                    visible: !textInput.text && !textInput.inputMethodComposing
                }

                onTextChanged: {
                    spotlight.query = text;
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        inputRoot.escapePressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        inputRoot.returnPressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up) {
                        spotlight.selectUp();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        spotlight.selectDown();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left) {
                        if (textInput.text.length === 0 || textInput.cursorPosition === 0) {
                            spotlight.selectPrev();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Right) {
                        if (textInput.text.length === 0 || textInput.cursorPosition === textInput.text.length) {
                            spotlight.selectNext();
                            event.accepted = true;
                        }
                    } else if (event.key === Qt.Key_Tab) {
                        spotlight.selectNext();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Backtab) {
                        spotlight.selectPrev();
                        event.accepted = true;
                    }
                }
            }
        }

        // 3. Right Controls: Clear button and '···' Options Pill
        Row {
            id: rightRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Clear Button (✕)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                radius: 9
                color: clearMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.20) : Qt.rgba(1, 1, 1, 0.10)
                visible: textInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 9
                    font.bold: true
                    color: TitanTheme.textMid
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        textInput.text = "";
                        textInput.forceActiveFocus();
                    }
                }
            }

            // More Options Glyph (···)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 20
                radius: 10
                color: moreMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(1, 1, 1, 0.06)

                Text {
                    anchors.centerIn: parent
                    text: "···"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.bold: true
                    color: TitanTheme.textLow
                }

                MouseArea {
                    id: moreMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        spotlight.cycleCategory(1);
                    }
                }
            }
        }
    }
}
