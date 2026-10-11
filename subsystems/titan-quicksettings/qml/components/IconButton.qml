import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * IconButton — reusable circular action/toolbar button.
 *
 * Handles the full interactive state machine (idle / hover / pressed /
 * active) and exposes an optional hover tooltip, so every clickable icon
 * across the panel behaves and feels identical.
 */
Item {
    id: btnRoot

    implicitWidth: 34
    implicitHeight: 34

    property string source: "\uf0a9"        // nerd icon codepoint
    property string tip: ""
    property int glyphSize: 14
    property bool active: false
    property bool destructive: false
    property color tint: TitanTheme.textMuted
    property color activeTint: TitanTheme.accentText
    property color activeColor: TitanTheme.accent
    property color bg: TitanTheme.bgSurfaceAlt
    property color bgHover: TitanTheme.bgHover
    property bool round: true

    signal clicked()

    // ── Tooltip (QtQuick.Controls) ───────────────────────────────────────────
    ToolTip.visible: tipMa.containsMouse && tip.length > 0
    ToolTip.text: tip
    ToolTip.delay: 500
    ToolTip.toolTip.background: Rectangle {
        color: TitanTheme.bgWindow
        border.color: TitanTheme.borderSubtle
        border.width: 1
        radius: 8
    }
    ToolTip.toolTip.contentItem: Text {
        text: btnRoot.tip
        color: TitanTheme.textPrimary
        font.family: TitanTheme.fontFamily
        font.pixelSize: TitanTheme.sizeSmall
        padding: 6
    }

    // ── Hit surface ───────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: btnRoot.round ? width / 2 : TitanTheme.radiusControl
        color: {
            if (ma.pressed) return btnRoot.active ? btnRoot.activeColor : TitanTheme.bgPressed;
            if (btnRoot.active) return btnRoot.activeColor;
            if (ma.containsMouse) return btnRoot.bgHover;
            return btnRoot.bg;
        }
        border.color: ma.containsMouse || btnRoot.active ? TitanTheme.borderHover : TitanTheme.borderSubtle
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }

        HavenIcon {
            anchors.centerIn: parent
            source: btnRoot.source
            tint: {
                if (btnRoot.active) return btnRoot.activeTint;
                if (ma.pressed && btnRoot.destructive) return TitanTheme.red;
                if (ma.containsMouse && btnRoot.destructive) return TitanTheme.red;
                if (ma.containsMouse) return TitanTheme.textPrimary;
                return btnRoot.tint;
            }
            glyphSize: btnRoot.glyphSize
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // Subtle glow when active
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: btnRoot.active ? TitanTheme.borderActive : "transparent"
            border.width: 1
            visible: btnRoot.active
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: btnRoot.clicked()
    }

    Accessible.role: Accessible.Button
    Accessible.name: btnRoot.tip.length > 0 ? btnRoot.tip : "button"
    Accessible.onPressAction: btnRoot.clicked()
}