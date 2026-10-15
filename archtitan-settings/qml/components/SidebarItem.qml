import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitanSettings
import ArchTitan.TitanUI

Item {
    id: root
    height: 44
    implicitHeight: 44

    property string iconSource: ""
    property string label: ""
    property bool   active: false

    signal clicked()

    // Background pill
    Rectangle {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        radius: 9
        color: root.active 
               ? TitanTheme.accentSoft
               : (hover.containsMouse ? TitanTheme.bg4 : "transparent")
        Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 24
            rightMargin: 24
        }
        spacing: 14

        // Fixed 19px icon container for perfect vertical column alignment
        Item {
            Layout.preferredWidth: 19
            Layout.preferredHeight: 19

            Image {
                id: iconImg
                anchors.fill: parent
                source: root.iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: false
            }

            MultiEffect {
                anchors.fill: iconImg
                source: iconImg
                colorization: 1.0
                colorizationColor: root.active 
                                   ? TitanTheme.accent 
                                   : (hover.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid)
                Behavior on colorizationColor { ColorAnimation { duration: TitanTheme.durFast } }
            }
        }

        Text {
            text: root.label
            font {
                pixelSize: 13
                weight: root.active ? Font.Medium : Font.Normal
                family: "Inter"
            }
            color: root.active 
                   ? TitanTheme.textHigh 
                   : (hover.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid)
            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
            Layout.fillWidth: true
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
