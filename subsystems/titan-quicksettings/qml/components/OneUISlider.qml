import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUISlider — Samsung One UI 9.0 thick pill slider.
 *
 * Left: Round icon medallion.
 * Center: Thick pill slider with electric blue/violet gradient fill.
 * Right: Live percentage value.
 */
RowLayout {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: 36

    /**
     * Commit a value: clamp, store, and let consumers react exactly once.
     * Keyboard and pointer paths both funnel through here so the two can
     * never disagree about the current value.
     */
    function commit(newValue) {
        var clamped = Math.max(sliderRoot.from, Math.min(sliderRoot.to, newValue));
        if (clamped === sliderRoot.value) return;
        sliderRoot.value = clamped;
        sliderRoot.changed(clamped);
    }

    /** Step the slider by `delta` clicks (5% of the range per click). */
    function nudge(delta) {
        var span = sliderRoot.to - sliderRoot.from;
        var step = span > 0 ? Math.max(1, Math.round(span / 20)) : 1;
        sliderRoot.commit(sliderRoot.value + delta * step);
    }
    Layout.preferredHeight: 36
    spacing: 12

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

    // ── Leading Round Icon Medallion ─────────────────────────────────────────
    Rectangle {
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        Layout.alignment: Qt.AlignVCenter
        radius: 18
        color: TitanTheme.bgOneUIPill
        border.color: TitanTheme.borderGlass
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: sliderRoot.iconGlyph
            font.family: TitanTheme.monoFamily
            font.pixelSize: 14
            color: sliderRoot.muted ? TitanTheme.textSubtle : TitanTheme.textPrimary
        }
    }

    // ── Pill Slider Track ───────────────────────────────────────────────────
    Rectangle {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        Layout.alignment: Qt.AlignVCenter
        radius: 18
        color: TitanTheme.bgOneUITrack
        border.color: activeFocus ? TitanTheme.accent : TitanTheme.borderGlass
        border.width: activeFocus ? 2 : 1
        clip: true
        scale: mouseArea.pressed ? 1.015 : 1.0
        Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutQuad } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        // Keyboard: focusable, stepped with the arrow keys, home/end to extremes.
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

        // Active fill with One UI 9 gradient
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
                return Math.max(ratio > 0.01 ? parent.height : 0, ratio * parent.width);
            }
            radius: parent.radius

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: sliderRoot.muted ? TitanTheme.textSubtle : TitanTheme.accent }
                GradientStop { position: 1.0; color: sliderRoot.muted ? TitanTheme.textSubtle : TitanTheme.lavender }
            }

            Behavior on width {
                enabled: !mouseArea.pressed
                NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
            }
        }

        // Interactive Drag & Click Area
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

    // ── Trailing Percentage Value ───────────────────────────────────────────
    Text {
        Layout.preferredWidth: 36
        Layout.alignment: Qt.AlignVCenter
        horizontalAlignment: Text.AlignRight
        text: sliderRoot.muted ? "0%" : (sliderRoot.value + sliderRoot.suffix)
        font.family: TitanTheme.fontFamily
        font.pixelSize: 11
        font.weight: Font.DemiBold
        color: TitanTheme.textMuted
    }

    Accessible.role: Accessible.Slider
    Accessible.name: "One UI pill slider"
    Accessible.onIncreaseAction: sliderRoot.nudge(1)
    Accessible.onDecreaseAction: sliderRoot.nudge(-1)
}
