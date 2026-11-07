import QtQuick
import ArchTitan.TitanUI

/**
 * SpotlightInput — Apple Spotlight-style search header.
 * Minimalist, crystal-clear, focused input with native typography and zero clutter.
 */
Item {
    id: inputRoot
    width: parent.width
    height: 56

    property alias text: textInput.text
    property alias inputItem: textInput

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()

    Row {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 18
        spacing: 14

        // 1. Apple-style Magnifying Glass Icon
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: spotlight.isClipboardMode ? "󰅍" : "󰍉"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 21
            color: textInput.activeFocus ? TitanTheme.accent : TitanTheme.textMid

            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
        }

        // 2. Search Text Input
        Item {
            height: parent.height
            width: parent.width - 21 - 14 - (rightControls.visible ? rightControls.width + 12 : 0)

            TextInput {
                id: textInput
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                font.family: TitanTheme.fontFamily
                font.pixelSize: 19
                font.weight: TitanTheme.weightRegular
                color: TitanTheme.textHigh
                selectionColor: TitanTheme.accent
                selectedTextColor: TitanTheme.textOnAccent
                clip: true
                focus: true

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: spotlight.isClipboardMode ? "Search clipboard history..." : "Spotlight Search"
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
                        inputRoot.upPressed();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down) {
                        inputRoot.downPressed();
                        event.accepted = true;
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

        // 3. Right-side Quick Clear / Mode Pill
        Row {
            id: rightControls
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            visible: textInput.text.length > 0 || spotlight.isClipboardMode

            // Clipboard Mode Tag
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                height: 24
                width: clipText.implicitWidth + 14
                radius: 6
                color: TitanTheme.accentSoft
                border.width: 1
                border.color: TitanTheme.accentEdge
                visible: spotlight.isClipboardMode

                Text {
                    id: clipText
                    anchors.centerIn: parent
                    text: "Clipboard"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: TitanTheme.weightSemiBold
                    color: TitanTheme.accent
                }
            }

            // Circular Clear Button (✕)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 20
                height: 20
                radius: 10
                color: clearMouse.containsMouse ? TitanTheme.borderHover : TitanTheme.stateHover
                visible: textInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 10
                    font.bold: true
                    color: TitanTheme.textMid
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
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
        }
    }
}
