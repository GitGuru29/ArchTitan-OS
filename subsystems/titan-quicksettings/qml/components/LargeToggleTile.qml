import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * LargeToggleTile — wide toggle pill (connectivity, audio, night light).
 *
 * Filled-with-accent when active, tinted sub-badge shows live status beneath
 * the title.  Hover and press states are animated for tactile feedback.
 */
Rectangle {
    id: pillRoot

    Layout.fillWidth: true
    implicitHeight: 50

    property bool active: false
    property string source: "\uf1eb"   // nerd glyph
    property string titleText: "Tile"
    property string statusText: "Status"
    property color accent: TitanTheme.accent
    property int glyphSize: 15

    signal clicked()

    radius: TitanTheme.radiusPill
    color: {
        if (ma.pressed) return active ? Qt.darker(accent, 1.15) : TitanTheme.bgPressed;
        if (active) return accent;
        if (ma.containsMouse) return TitanTheme.bgHover;
        return TitanTheme.bgSurfaceAlt;
    }
    border.color: active ? accent : (ma.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle)
    border.width: 1

    Behavior on color { ColorAnimation { duration: 130 } }
    Behavior on border.color { ColorAnimation { duration: 130 } }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 12
        spacing: 10

        // Icon medallion
        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: active ? Qt.rgba(0, 0, 0, 0.14) : TitanTheme.bgInset
            border.color: active ? Qt.rgba(0, 0, 0, 0.18) : TitanTheme.borderSubtle
            border.width: 1

            HavenIcon {
                anchors.centerIn: parent
                source: pillRoot.source
                tint: active ? TitanTheme.accentText : pillRoot.accent
                glyphSize: pillRoot.glyphSize
                Behavior on color { ColorAnimation { duration: 130 } }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 1

            Text {
                text: pillRoot.titleText
                Layout.fillWidth: true
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeSmall
                font.weight: Font.DemiBold
                color: active ? TitanTheme.accentText : TitanTheme.textPrimary
                elide: Text.ElideRight
            }

            Text {
                text: pillRoot.statusText
                Layout.fillWidth: true
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: active ? Qt.lighter(TitanTheme.accentText, 1.05)
                              : (ma.containsMouse ? TitanTheme.textSecondary : TitanTheme.textMuted)
                elide: Text.ElideRight
            }
        }

        // Active check affordance
        Text {
            text: pillRoot.active ? "\uf00c" : ""
            font.family: TitanTheme.monoFamily
            font.pixelSize: 10
            color: active ? TitanTheme.accentText : "transparent"
            visible: pillRoot.active
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: pillRoot.clicked()
    }

    Accessible.role: Accessible.Button
    Accessible.name: titleText + (active ? " on" : " off")
    Accessible.onPressAction: pillRoot.clicked()
}