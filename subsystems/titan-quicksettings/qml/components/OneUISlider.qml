import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUISlider — Apple macOS Control Center Pill Slider.
 *
 * Full-width thick capsule pill with embedded glyph, smooth drag fill, and live value readout.
 */
ColumnLayout {
    id: sliderRoot
    Layout.fillWidth: true
    spacing: 5

    property string title: ""
    property string iconGlyph: "\uf028"
    property int from: 0
    property int to: 100
    property int value: 50
    property bool muted: false
    property color fillAccent: "#FFFFFF"
    property string suffix: "%"

    signal changed(int val)

    function commit(newValue) {
        var clamped = Math.max(sliderRoot.from, Math.min(sliderRoot.to, newValue));
        if (clamped === sliderRoot.value) return;
        sliderRoot.value = clamped;
        sliderRoot.changed(clamped);
    }

    function nudge(delta) {
        var span = sliderRoot.to - sliderRoot.from;
        var step = span > 0 ? Math.max(1, Math.round(span / 20)) : 1;
        sliderRoot.commit(sliderRoot.value + delta * step);
    }

    function setValue(v) {
        sliderRoot.value = Math.max(sliderRoot.from, Math.min(sliderRoot.to, v));
    }

    // ── Optional Title Header (e.g. "Display", "Sound") ────────────────────
    RowLayout {
        Layout.fillWidth: true
        visible: sliderRoot.title.length > 0
        spacing: 4

        Text {
            text: sliderRoot.title
            font.family: TitanTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: TitanTheme.textSecondary
        }

        Item { Layout.fillWidth: true }

        Text {
            text: sliderRoot.value + sliderRoot.suffix
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            color: TitanTheme.textMuted
        }
    }

    // ── Apple macOS Capsule Slider Pill ─────────────────────────────────────
    Rectangle {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 38
        radius: 19
        color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.08)
        border.color: activeFocus ? TitanTheme.accent : (trackMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.10))
        border.width: activeFocus ? 2 : 1
        clip: true

        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Keyboard navigation
        activeFocusOnTab: true
        Keys.onLeftPressed:  (event) => { sliderRoot.nudge(-1); event.accepted = true }
        Keys.onDownPressed:  (event) => { sliderRoot.nudge(-1); event.accepted = true }
        Keys.onRightPressed: (event) => { sliderRoot.nudge(1);  event.accepted = true }
        Keys.onUpPressed:    (event) => { sliderRoot.nudge(1);  event.accepted = true }
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Home) {
                sliderRoot.commit(sliderRoot.from);
                event.accepted = true;
            } else if (event.key === Qt.Key_End) {
                sliderRoot.commit(sliderRoot.to);
                event.accepted = true;
            }
        }

        readonly property real norm: {
            var range = sliderRoot.to - sliderRoot.from;
            if (range <= 0) return 0;
            return Math.max(0.0, Math.min(1.0, (sliderRoot.value - sliderRoot.from) / range));
        }

        // Filled Progress Capsule
        Rectangle {
            id: fillBar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.max(38, parent.width * track.norm)
            radius: 19
            color: sliderRoot.muted
                   ? Qt.rgba(1, 1, 1, 0.25)
                   : (TitanTheme.isDark ? "#FFFFFF" : TitanTheme.accent)

            Behavior on width {
                enabled: !trackMa.pressed
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }

            // Top Specular Sheen (3D Horizon Sheen)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 14
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.24) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // Left Embedded Icon Glyph
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: sliderRoot.iconGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: 15
            z: 2
            color: {
                if (sliderRoot.muted) return TitanTheme.textMuted;
                // If fill reaches past the icon, use dark text on white fill
                if (fillBar.width > 32) {
                    return TitanTheme.isDark ? "#1E1E2E" : "#FFFFFF";
                }
                return TitanTheme.textPrimary;
            }
        }

        // Right Percentage Indicator (visible when title row is not displayed)
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            visible: sliderRoot.title.length === 0
            text: sliderRoot.value + sliderRoot.suffix
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.DemiBold
            z: 2
            color: {
                if (track.norm > 0.88) {
                    return TitanTheme.isDark ? "#1E1E2E" : "#FFFFFF";
                }
                return TitanTheme.textMuted;
            }
        }

        // MouseArea for instant click and smooth scrubbing
        MouseArea {
            id: trackMa
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            function updateFromMouse(mouseX) {
                var ratio = Math.max(0.0, Math.min(1.0, mouseX / track.width));
                var newVal = Math.round(sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from));
                sliderRoot.commit(newVal);
            }

            onPressed: (mouse) => {
                track.forceActiveFocus();
                updateFromMouse(mouse.x);
            }
            onPositionChanged: (mouse) => {
                if (pressed) {
                    updateFromMouse(mouse.x);
                }
            }
        }
    }
}
