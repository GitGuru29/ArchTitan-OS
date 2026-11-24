import QtQuick

Rectangle {
    id: root

    property string text: ""
    property bool isAccent: false

    implicitWidth: Math.max(26, label.implicitWidth + 14)
    implicitHeight: 24
    radius: 6

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: root.isAccent ? "#1E3A5F" : "#3A3A3E"
        }
        GradientStop {
            position: 1.0
            color: root.isAccent ? "#152944" : "#2C2C30"
        }
    }

    border.width: 1
    border.color: root.isAccent ? "#3B82F6" : Qt.rgba(1, 1, 1, 0.16)

    // Top inner keycap sheen
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: 1
        color: Qt.rgba(1, 1, 1, 0.18)
    }

    // Bottom 3D bevel edge
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        radius: 3
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Text {
        id: label
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -0.5
        text: root.text === "SUPER" ? "⌘ Super" : root.text
        color: root.isAccent ? "#64D2FF" : "#F5F5F7"
        font.family: "Inter"
        font.pixelSize: 11
        font.weight: 600
    }
}
