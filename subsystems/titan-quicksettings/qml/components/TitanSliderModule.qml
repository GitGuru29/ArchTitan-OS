import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanSliderModule — macOS-style Smooth Continuous Capsule Slider Module.
 *
 * Dedicated dark titanium card with integrated icon medallion, continuous
 * drag tracking, Titan Orange progress fill, and percentage readout.
 */
Rectangle {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: 68
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: sliderMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline
    border.width: 1

    property string title: "Display"
    property string iconGlyph: "\uf185" // sun
    property int from: 0
    property int to: 100
    property int value: 72
    property color fillAccent: TitanTheme.accent

    signal changed(int val)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 6

        // Header Row: Title & Percentage
        RowLayout {
            Layout.fillWidth: true

            Text {
                text: sliderRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Math.round(sliderRoot.value) + "%"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                font.weight: Font.Bold
                color: TitanTheme.textSecondary
            }
        }

        // Capsule Slider Track
        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 24
            radius: 12
            color: TitanTheme.bgInset
            clip: true

            // Progress Fill
            Rectangle {
                id: progressFill
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: Math.max(24, parent.width * Math.max(0, Math.min(1, (sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from))))
                radius: 12
                color: sliderRoot.fillAccent

                Behavior on width {
                    enabled: !sliderMa.drag.active
                    NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                }
            }

            // Integrated Left Icon
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: sliderRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 11
                color: (progressFill.width > 30) ? "#0D1017" : TitanTheme.textMuted
                z: 2
            }

            MouseArea {
                id: sliderMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                function updateVal(mouseX) {
                    var pct = Math.max(0, Math.min(1, mouseX / track.width));
                    var newVal = Math.round(sliderRoot.from + pct * (sliderRoot.to - sliderRoot.from));
                    sliderRoot.changed(newVal);
                }

                onPressed: (mouse) => updateVal(mouse.x)
                onPositionChanged: (mouse) => {
                    if (pressed) updateVal(mouse.x);
                }
            }
        }
    }
}

