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
    color: active ? TitanTheme.accentBlue : TitanTheme.bgOneUICard
    border.color: active ? TitanTheme.borderActive : TitanTheme.borderGlass
    border.width: 1

    property bool active: false
    property string iconGlyph: "\uf1eb"
    property string title: "Wi-Fi"
    property string subtitle: "Connected"
    property color activeAccent: TitanTheme.accentBlue

    signal clicked()

    Behavior on color { ColorAnimation { duration: 150 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 12

        // Icon Medallion
        Rectangle {
            Layout.preferredWidth: 42
            Layout.preferredHeight: 42
            radius: 21
            color: tileRoot.active ? "#38FFFFFF" : TitanTheme.bgOneUIPill

            Text {
                anchors.centerIn: parent
                text: tileRoot.iconGlyph
                font.family: TitanTheme.fontFamily
                font.pixelSize: 18
                color: tileRoot.active ? "#FFFFFF" : TitanTheme.textMuted
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
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tileRoot.clicked()
    }

    Accessible.role: Accessible.Button
    Accessible.name: title
}
