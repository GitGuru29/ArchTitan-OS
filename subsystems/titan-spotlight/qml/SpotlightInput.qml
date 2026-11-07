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
            color: TitanTheme.accentSoft
            border.width: 1
            border.color: TitanTheme.accentEdge

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
                color: TitanTheme.stateHover
                border.width: 1
                border.color: TitanTheme.borderSubtle
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

            // Segmented View Mode Switcher via native TitanSegmentedControl (Grid | Bento | List)
            TitanSegmentedControl {
                id: viewSwitcher
                anchors.verticalCenter: parent.verticalCenter
                visible: !spotlight.isClipboardMode
                model: ["Grid", "Bento", "List"]
                currentIndex: spotlight.viewMode === "bento" ? 1 : (spotlight.viewMode === "list" ? 2 : 0)
                onSelected: function(idx, label) {
                    if (idx === 0) spotlight.viewMode = "grid";
                    else if (idx === 1) spotlight.viewMode = "bento";
                    else if (idx === 2) spotlight.viewMode = "list";
                    textInput.forceActiveFocus();
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
