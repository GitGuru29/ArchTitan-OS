import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUISlider — Samsung One UI 9.0 signature thick pill slider.
 *
 * Full 50px rounded pill bar with embedded reactive glyph and smooth drag.
 */
Item {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: 50

    property string iconGlyph: "\uf028"
    property int from: 0
    property int to: 100
    property int value: 50
    property bool muted: false
    property color fillAccent: TitanTheme.accentBlue
    property string suffix: "%"

    signal changed(int val)

    function setValue(v) {
        sliderRoot.value = Math.max(sliderRoot.from, Math.min(sliderRoot.to, v));
    }

    Rectangle {
        id: track
        anchors.fill: parent
        radius: TitanTheme.radiusSlider
        color: TitanTheme.bgOneUITrack
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        // ── Active fill pill ────────────────────────────────────────────────
        Rectangle {
            id: fillRect
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: {
                if (sliderRoot.muted) return 0;
                var span = sliderRoot.to - sliderRoot.from;
                if (span <= 0) return 0;
                var ratio = Math.max(0.0, Math.min(1.0, (sliderRoot.value - sliderRoot.from) / span));
                // Ensure pill has minimum width for its circular cap once started
                return Math.max(ratio > 0.02 ? 46 : 0, ratio * parent.width);
            }
            radius: TitanTheme.radiusSlider
            color: sliderRoot.muted ? TitanTheme.textSubtle : sliderRoot.fillAccent

            Behavior on width {
                enabled: !mouseArea.pressed
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        // ── Embedded Leading Icon ───────────────────────────────────────────
        Text {
            id: iconText
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: sliderRoot.iconGlyph
            font.family: TitanTheme.fontFamily
            font.pixelSize: 18
            color: (fillRect.width > 36 && !sliderRoot.muted) ? "#FFFFFF" : TitanTheme.textMuted
            z: 2

            Behavior on color { ColorAnimation { duration: 120 } }
        }

        // ── Embedded Value / Status Text ────────────────────────────────────
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: sliderRoot.muted ? "MUTED" : (sliderRoot.value + sliderRoot.suffix)
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeSmall
            font.weight: Font.DemiBold
            color: (fillRect.width > (parent.width - 60) && !sliderRoot.muted) ? "#FFFFFF" : TitanTheme.textMuted
            z: 2
        }

        // ── Interactive Drag & Click Area ───────────────────────────────────
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function updateValue(mouse) {
                var ratio = Math.max(0.0, Math.min(1.0, mouse.x / parent.width));
                var newVal = Math.round(sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from));
                sliderRoot.value = newVal;
                sliderRoot.changed(newVal);
            }

            onPressed: (mouse) => updateValue(mouse)
            onPositionChanged: (mouse) => {
                if (pressed) updateValue(mouse);
            }
        }
    }

    Accessible.role: Accessible.Slider
    Accessible.name: "One UI pill slider"
}
