import QtQuick

/**
 * GlassButton — Titan Cinematic Glass action button.
 * Supports primary (laser cyan accent), secondary (titanium frosted glass),
 * and ghost (subtle outline / text link) styles with keyboard accessibility.
 */
Rectangle {
    id: root

    property string text: ""
    property string glyph: ""
    property string shortcutHint: ""
    property string variant: "primary"   // "primary" | "secondary" | "ghost"
    property color accentColor: "#00D2FF"
    property int horizontalPadding: 22
    property int buttonHeight: 42

    signal clicked()

    readonly property bool isPrimary: variant === "primary"
    readonly property bool isSecondary: variant === "secondary"
    readonly property bool isGhost: variant === "ghost"

    implicitWidth: contentRow.implicitWidth + horizontalPadding * 2
    implicitHeight: buttonHeight
    radius: 14
    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: root.text

    color: {
        if (isPrimary) {
            if (mouseArea.pressed) return "#0284C7"
            if (mouseArea.containsMouse) return "#38BDF8"
            return root.accentColor
        }
        if (isSecondary) {
            if (mouseArea.pressed) return "#CC313244"
            if (mouseArea.containsMouse) return "#D8313244"
            return "#B81E1E2E"
        }
        if (mouseArea.pressed) return "#33FFFFFF"
        if (mouseArea.containsMouse) return "#1FFFFFFF"
        return "transparent"
    }

    border.width: isPrimary ? 0 : 1
    border.color: {
        if (root.activeFocus) return "#00D2FF"
        if (isSecondary) return mouseArea.containsMouse ? "#6600D2FF" : "#33FFFFFF"
        if (isGhost) return mouseArea.containsMouse ? "#38FFFFFF" : "#18FFFFFF"
        return "transparent"
    }

    scale: mouseArea.pressed ? 0.975 : 1.0
    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 8

        Text {
            visible: root.glyph.length > 0
            text: root.glyph
            font.family: "Inter"
            font.pixelSize: 14
            font.weight: Font.DemiBold
            color: root.isPrimary ? "#11111B" : "#00D2FF"
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.text
            font.family: "Inter"
            font.pixelSize: 13
            font.weight: root.isPrimary ? Font.Bold : Font.DemiBold
            color: root.isPrimary ? "#11111B" : (root.isSecondary ? "#CDD6F4" : "#A6ADC8")
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            visible: root.shortcutHint.length > 0
            width: hintLabel.implicitWidth + 10
            height: 20
            radius: 6
            color: root.isPrimary ? "#26000000" : "#22FFFFFF"
            border.width: 1
            border.color: root.isPrimary ? "#33000000" : "#28FFFFFF"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: hintLabel
                anchors.centerIn: parent
                text: root.shortcutHint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: root.isPrimary ? "#11111B" : "#CDD6F4"
            }
        }
    }

    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}

