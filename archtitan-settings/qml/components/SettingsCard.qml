import QtQuick
import QtQuick.Layouts
import ArchTitanSettings
import ArchTitan.TitanUI

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
                text: cardRoot.title.toUpperCase()
                font { pixelSize: 10; family: "Inter" }
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
                color: TitanTheme.textLow
            }
        }

        // Subtle divider under title
        Rectangle {
            visible: cardRoot.title !== ""
            Layout.fillWidth: true
            height: 1
            color: TitanTheme.borderSubtle
            Layout.bottomMargin: 12
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }
}
