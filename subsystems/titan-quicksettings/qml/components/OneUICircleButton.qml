import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUICircleButton — Samsung One UI 9.0 round quick action toggle.
 *
 * 52px circular button with centered glyph and descriptive label below.
 */
ColumnLayout {
    id: buttonRoot
    spacing: 6
    Layout.alignment: Qt.AlignHCenter

    property string iconGlyph: "\uf186"
    property string label: "Dark mode"
    property bool active: false
    property color activeColor: TitanTheme.accentBlue

    signal clicked()

    Rectangle {
        id: circle
        Layout.preferredWidth: 52
        Layout.preferredHeight: 52
        Layout.alignment: Qt.AlignHCenter
        radius: 26
        color: buttonRoot.active ? buttonRoot.activeColor : (btnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
        border.color: buttonRoot.active ? TitanTheme.borderActive : (btnMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 130 } }

        Text {
            anchors.centerIn: parent
            text: buttonRoot.iconGlyph
            font.family: TitanTheme.fontFamily
            font.pixelSize: 19
            color: buttonRoot.active ? "#FFFFFF" : TitanTheme.textPrimary
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: buttonRoot.clicked()
        }
    }

    Text {
        Layout.alignment: Qt.AlignHCenter
        text: buttonRoot.label
        font.family: TitanTheme.fontFamily
        font.pixelSize: 10
        font.weight: Font.DemiBold
        color: buttonRoot.active ? TitanTheme.textPrimary : TitanTheme.textSubtle
        horizontalAlignment: Text.AlignHCenter
    }

    Accessible.role: Accessible.Button
    Accessible.name: label
}
