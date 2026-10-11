import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * LevelSlider — labeled horizontal level control (volume, brightness).
 *
 * Dragging fires `changed(value)` live; `value` may be bound back from the
 * backend via `setValue` to keep the knob in sync with the OS.
 */
Item {
    id: sliderRoot

    implicitHeight: 30
    Layout.fillWidth: true

    property string source: "\uf028"
    property color tint: TitanTheme.accent
    property int from: 0
    property int to: 100
    property int value: 0
    property bool muted: false
    property string suffix: "%"
    property int precision: 1

    signal changed(int value)

    function setValue(v) { control.value = Math.max(sliderRoot.from, Math.min(sliderRoot.to, v)); }

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // Leading icon
        Item {
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            Layout.alignment: Qt.AlignVCenter

            HavenIcon {
                anchors.centerIn: parent
                source: sliderRoot.source
                tint: sliderRoot.muted ? TitanTheme.textSubtle : sliderRoot.tint
                glyphSize: 16
            }
        }

        // Track + knob
        Slider {
            id: control
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter

            from: sliderRoot.from
            to: sliderRoot.to
            value: sliderRoot.value
            stepSize: 1
            snapMode: Slider.NoSnap
            focusPolicy: Qt.NoFocus

            background: Rectangle {
                height: 6
                radius: 3
                color: TitanTheme.bgInset
                border.color: TitanTheme.borderSubtle
                border.width: 1

                // Filled portion
                Rectangle {
                    height: parent.height
                    width: {
                        var span = control.to - control.from;
                        if (span === 0) return 0;
                        return (control.visualPosition * parent.width);
                    }
                    radius: 3
                    color: sliderRoot.muted ? TitanTheme.textSubtle : sliderRoot.tint
                }
            }

            handle: Rectangle {
                x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
                y: control.topPadding + control.availableHeight / 2 - height / 2
                width: 14
                height: 14
                radius: 7
                color: sliderRoot.muted ? TitanTheme.textMuted
                                        : (control.visualPosition > 0 && control.visualPosition < 1
                                           ? TitanTheme.textPrimary : sliderRoot.tint)
                border.color: TitanTheme.borderHover
                border.width: 1

                Behavior on color { ColorAnimation { duration: 90 } }
            }

            onMoved: sliderRoot.changed(Math.round(control.value))
        }

        // Value readout
        Text {
            Layout.preferredWidth: 42
            Layout.alignment: Qt.AlignVCenter
            text: sliderRoot.muted ? "MUTED" : (Math.round(control.value) + sliderRoot.suffix)
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeSmall
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignRight
            color: sliderRoot.muted ? TitanTheme.textSubtle : TitanTheme.textSecondary
        }
    }

    Accessible.role: Accessible.Slider
    Accessible.name: "level slider"
}