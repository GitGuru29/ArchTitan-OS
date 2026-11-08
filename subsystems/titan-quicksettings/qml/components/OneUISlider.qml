import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUISlider — Apple macOS Control Center Refined Pill Slider.
 *
 * Slim, inset capsule slider with non-bleeding 2px margin, smooth dragging,
 * authentic frosted accent fill, and clean leading glyph.
 */
ColumnLayout {
    id: sliderRoot
    Layout.fillWidth: true
    spacing: 6

    property string title: ""
    property string iconGlyph: "\uf028"
    property int from: 0
    property int to: 100
    property int value: 50
    property bool muted: false
    property color fillAccent: TitanTheme.accent
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

    // ── Title & Percentage Header Row ───────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        visible: sliderRoot.title.length > 0

        Text {
            text: sliderRoot.title
            font.family: TitanTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: TitanTheme.textPrimary
        }

        Item { Layout.fillWidth: true }

        Text {
            text: sliderRoot.value + sliderRoot.suffix
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            color: TitanTheme.textMuted
        }
    }

    // ── Leading Icon + Inset Capsule Slider Track ───────────────────────────
    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        // Leading Icon (Clean, unobscured, outside the track)
        Text {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: sliderRoot.iconGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: 14
            color: sliderRoot.muted ? TitanTheme.textMuted : TitanTheme.textPrimary
            Layout.alignment: Qt.AlignVCenter
        }

        // Inset Pill Slider Track
        Rectangle {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            radius: 12
            color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.40) : Qt.rgba(0, 0, 0, 0.10)
            border.color: activeFocus ? TitanTheme.accent : (trackMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.08))
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

            // Inset Filled Bar — anchored with 2px margins so it NEVER bleeds outside borders
            Rectangle {
                id: fillBar
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.top: parent.top
                anchors.topMargin: 2
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 2
                visible: track.norm > 0
                width: track.norm <= 0 ? 0 : Math.max(parent.height - 4, (parent.width - 4) * track.norm)
                radius: 10

                // Frosted Gradient Fill (refined accent or liquid glass)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: sliderRoot.muted
                               ? Qt.rgba(1, 1, 1, 0.20)
                               : Qt.rgba(sliderRoot.fillAccent.r, sliderRoot.fillAccent.g, sliderRoot.fillAccent.b, 0.90)
                    }
                    GradientStop {
                        position: 1.0
                        color: sliderRoot.muted
                               ? Qt.rgba(1, 1, 1, 0.30)
                               : Qt.rgba(sliderRoot.fillAccent.r, sliderRoot.fillAccent.g, sliderRoot.fillAccent.b, 1.0)
                    }
                }

                Behavior on width {
                    enabled: !trackMa.pressed
                    NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                }

                // Top Specular Sheen (Subtle 3D Gloss Glint)
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 10
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.30) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }

            // MouseArea for instant scrubbing
            MouseArea {
                id: trackMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateFromMouse(mouseX) {
                    var ratio = Math.max(0.0, Math.min(1.0, (mouseX - 2) / (track.width - 4)));
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
}
