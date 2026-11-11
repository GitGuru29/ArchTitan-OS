import QtQuick

/**
 * KeycapItem — Realistic beveled mechanical keycap with electric neon activation glow.
 */
Rectangle {
    id: keycapRoot
    property string keyText: "SUPER"
    property string subText: ""
    property bool isActive: false
    property color activeGlow: "#0EA5E9"

    implicitWidth: Math.max(46, keyLabel.implicitWidth + 20)
    implicitHeight: 38
    radius: 8

    color: isActive ? Qt.rgba(0.08, 0.22, 0.38, 0.95) : Qt.rgba(0.12, 0.15, 0.22, 0.90)
    border.color: isActive ? activeGlow : Qt.rgba(1, 1, 1, 0.22)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 150 } }
    Behavior on border.color { ColorAnimation { duration: 150 } }

    // 3D beveled keycap top highlight
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        radius: 8
        color: Qt.rgba(1, 1, 1, 0.25)
    }

    // 3D bottom shadow
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        radius: 8
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            id: keyLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: keycapRoot.keyText
            font.pixelSize: 11
            font.weight: Font.Bold
            font.family: "JetBrains Mono, monospace"
            color: keycapRoot.isActive ? "#38BDF8" : "#E2E8F0"
        }

        Text {
            visible: keycapRoot.subText.length > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: keycapRoot.subText
            font.pixelSize: 8
            font.family: "Inter, sans-serif"
            color: "#94A3B8"
        }
    }
}

