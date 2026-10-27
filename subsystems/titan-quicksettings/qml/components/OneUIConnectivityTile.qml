import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUIConnectivityTile — Samsung One UI 9.0 squircle connectivity card.
 *
 * Used side-by-side for Wi-Fi and Bluetooth with active glow and status label.
 */
Rectangle {
    id: tileRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 74
    radius: TitanTheme.radiusBento
    color: active ? TitanTheme.accentBlue : (tileMa.containsMouse || activeFocus ? TitanTheme.bgHover : TitanTheme.bgOneUICard)
    border.color: activeFocus ? TitanTheme.accent
                  : active ? TitanTheme.borderActive
                  : (tileMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
    border.width: activeFocus ? 2 : 1

    // Keyboard: reachable with Tab / arrows, activated with Enter or Space.
    activeFocusOnTab: true
    Keys.onReturnPressed: (event) => { tileRoot.clicked(); event.accepted = true }
    Keys.onEnterPressed:  (event) => { tileRoot.clicked(); event.accepted = true }
    Keys.onSpacePressed:  (event) => { tileRoot.clicked(); event.accepted = true }
    clip: true

    // Top specular edge highlight (macOS glass bevel)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1
        radius: parent.radius
        color: tileRoot.active ? Qt.rgba(1, 1, 1, 0.35) : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.45))
        z: 2
    }

    property bool active: false
    property string iconGlyph: "\uf1eb"
    property string title: "Wi-Fi"
    property string subtitle: "Connected"
    property color activeAccent: TitanTheme.accentBlue

    signal clicked()
    signal toggleClicked()
    signal detailClicked()

    // Tactile Liquid Touch: spring bounce on hover and press
    scale: tileMa.pressed ? 0.96 : (tileMa.containsMouse ? 1.02 : 1.0)
    Behavior on scale {
        NumberAnimation { duration: 140; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        // Icon Medallion (Tap to quick toggle)
        Rectangle {
            id: iconMedallion
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 21
            color: tileRoot.active ? "#38FFFFFF" : (iconMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
            z: 2

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: tileRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 18
                color: tileRoot.active ? "#FFFFFF" : TitanTheme.textMuted
            }

            MouseArea {
                id: iconMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tileRoot.toggleClicked();
                }
            }
        }

        // Text cluster
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: tileRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                color: tileRoot.active ? "#FFFFFF" : TitanTheme.textPrimary
            }

            Text {
                text: tileRoot.subtitle
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: tileRoot.active ? "#D9FFFFFF" : TitanTheme.textSubtle
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        // Chevron
        Text {
            text: "\uf054"
            font.family: TitanTheme.monoFamily
            font.pixelSize: 11
            color: tileRoot.active ? "#B3FFFFFF" : TitanTheme.textSubtle
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: tileMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            tileRoot.detailClicked();
            tileRoot.clicked();
        }
    }

    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.onPressAction: {
        tileRoot.detailClicked();
        tileRoot.clicked();
    }
}
