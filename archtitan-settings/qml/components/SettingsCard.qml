import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI
import ArchTitanSettings

Rectangle {
    id: cardRoot
    color: TitanTheme.bg3
    radius: TitanTheme.radiusLg
    border.width: 1
    border.color: hover.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle
    implicitHeight: col.implicitHeight + 36
    clip: true

    Behavior on border.color { ColorAnimation { duration: TitanTheme.durFast } }

    default property alias content: col.children
    property string title: ""
    property string headerIcon: ""

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 20 }
        spacing: 0

        // Optional title
        Item {
            visible: cardRoot.title !== ""
            Layout.fillWidth: true
            height: 28

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: cardRoot.title
                font { pixelSize: 13; family: "Inter" }
                font.weight: Font.DemiBold
                color: TitanTheme.textHigh
            }
        }

        // Spacer in place of the old divider — M3 groups breathe instead of ruling lines
        Item {
            visible: cardRoot.title !== ""
            Layout.fillWidth: true
            Layout.preferredHeight: 8
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
