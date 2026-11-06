import QtQuick
import ArchTitan.TitanUI

/* TitanSearchField — desktop search text input with focus ring and clear action. */
Rectangle {
    id: root

    property alias text: input.text
    property string placeholderText: "Search..."
    property bool active: input.activeFocus

    signal accepted()
    signal cleared()

    implicitWidth: 260
    implicitHeight: 36
    radius: TitanTheme.radiusControl
    color: TitanTheme.bgInset
    border.width: 1
    border.color: active ? TitanTheme.focusRing : hover.hovered ? TitanTheme.borderHover : TitanTheme.borderSubtle

    Behavior on border.color { ColorAnimation { duration: TitanTheme.durFast } }

    Row {
        anchors.fill: parent
        anchors.leftMargin: TitanTheme.space3
        anchors.rightMargin: TitanTheme.space3
        spacing: TitanTheme.space2

        // Search glyph (Nerd Font search icon)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uF002"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 13
            color: root.active ? TitanTheme.accent : TitanTheme.textLow
        }

        Item {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 44
            height: parent.height

            TextInput {
                id: input
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                clip: true
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeBody
                selectionColor: TitanTheme.accentSoft
                selectedTextColor: TitanTheme.textHigh

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: root.placeholderText
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeBody
                    visible: !input.text && !input.inputMethodComposing
                }

                Keys.onEscapePressed: {
                    input.text = ""
                    root.cleared()
                }
                Keys.onReturnPressed: root.accepted()
                Keys.onEnterPressed: root.accepted()
            }
        }

        // Clear action button
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 18
            height: 18
            radius: 9
            visible: input.text.length > 0
            color: clearHover.hovered ? TitanTheme.surface1 : "transparent"

            Text {
                anchors.centerIn: parent
                text: "\uF00D" // Nerd Font close cross
                font.family: TitanTheme.monoFamily
                font.pixelSize: 10
                color: clearHover.hovered ? TitanTheme.textHigh : TitanTheme.textLow
            }

            HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    input.text = ""
                    root.cleared()
                }
            }
        }
    }

    HoverHandler { id: hover }
}
