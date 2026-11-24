import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls.Basic
import ArchTitan.TitanUI
import ArchTitanSettings

/**
 * NavRailItem — Material 3 style navigation rail button.
 * Icon sits in a rounded "active indicator" pill with the label below it,
 * mirroring the host desktop's Quickshell settings navigation rail.
 */
Item {
    id: root
    height: 70
    implicitHeight: 70

    property string iconSource: ""
    property string label: ""
    property bool active: false
    property bool expanded: false

    signal clicked()

    // Active / hover indicator pill behind the icon
    Rectangle {
        id: indicator
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 5
        width: root.expanded ? Math.min(root.width - 22, 148) : 48
        height: 40
        radius: 14
        color: root.active
               ? TitanTheme.accentSoft
               : (hover.containsMouse ? TitanTheme.bg4 : "transparent")
        Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
        Behavior on width { NumberAnimation { duration: TitanTheme.durFast } }
    }

    // Leading accent bar on the active item (M3 active indicator nuance)
    Rectangle {
        anchors {
            left: parent.left
            verticalCenter: indicator.verticalCenter
        }
        width: 3
        height: root.active ? 22 : 0
        radius: 2
        color: TitanTheme.accent
        visible: root.active
        Behavior on height { NumberAnimation { duration: TitanTheme.durBase } }
    }

    ColumnLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: 5
        }
        spacing: 4

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            Layout.alignment: Qt.AlignHCenter

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
            visible: root.expanded
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font {
                pixelSize: 11
                family: "Inter"
                weight: root.active ? Font.Medium : Font.Normal
            }
            color: root.active
                   ? TitanTheme.textHigh
                   : (hover.containsMouse ? TitanTheme.textHigh : TitanTheme.textMid)
            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ToolTip {
        visible: hover.containsMouse && !root.expanded
        text: root.label
        delay: 450
    }
}
