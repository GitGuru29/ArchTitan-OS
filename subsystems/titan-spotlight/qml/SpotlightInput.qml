import QtQuick
import ArchTitan.TitanUI

Item {
    id: inputRoot
    width: parent.width
    height: 58

    property alias text: textInput.text
    property alias inputItem: textInput

    signal escapePressed()
    signal returnPressed()
    signal upPressed()
    signal downPressed()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 18

        // Spotlight Magnifying Glass / Icon
        Text {
            id: searchIcon
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: spotlight.isClipboardMode ? "󰅍" : "󰍉"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 22
            color: TitanTheme.accent
        }

        // Mode badge or Clear button
        Rectangle {
            id: badgeRect
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            height: 24
            radius: 6
            color: Qt.rgba(255, 255, 255, 0.08)
            border.width: 1
            border.color: Qt.rgba(255, 255, 255, 0.1)
            visible: textInput.text.length > 0 || spotlight.isClipboardMode
            width: badgeText.implicitWidth + 16

            Text {
                id: badgeText
                anchors.centerIn: parent
                text: spotlight.isClipboardMode ? "CLIPBOARD" : "CLEAR"
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
                }
            }
        }

        // Search Input Field
        TextInput {
            id: textInput
            anchors.left: searchIcon.right
            anchors.leftMargin: 14
            anchors.right: badgeRect.visible ? badgeRect.left : parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            font.family: TitanTheme.fontFamily
            font.pixelSize: 18
            color: TitanTheme.textHigh
            selectionColor: TitanTheme.accent
            selectedTextColor: TitanTheme.textOnAccent
            clip: true
            focus: true

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: spotlight.isClipboardMode ? "Search clipboard history..." : "Spotlight Search..."
                font.family: textInput.font.family
                font.pixelSize: textInput.font.pixelSize
                color: TitanTheme.textLow
                visible: !textInput.text && !textInput.inputMethodComposing
            }

            onTextChanged: {
                spotlight.query = text;
            }

            Keys.onEscapePressed: {
                inputRoot.escapePressed();
            }
            Keys.onReturnPressed: {
                inputRoot.returnPressed();
            }
            Keys.onUpPressed: {
                inputRoot.upPressed();
            }
            Keys.onDownPressed: {
                inputRoot.downPressed();
            }
        }
    }
}
