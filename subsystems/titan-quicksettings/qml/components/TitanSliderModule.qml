import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanSliderModule — ArchTitan macOS-style Dedicated Capsule Slider Bento Module.
 *
 * Implements the capsule slider card:
 * - Header: Module Title + Percentage Readout
 * - Capsule Slider: Deep inset track, glowing Sapphire Cyan progress bar, circular white drag thumb
 * - Integrated Icon on right
 */
Rectangle {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: 66
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (sliderMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property string title: "Brightness"
    property string iconGlyph: "\uf185" // sun
    property int from: 0
    property int to: 100
    property int value: 72
    property color fillAccent: TitanTheme.accent

    signal changed(int val)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 5

        // ── Card Header ─────────────────────────────────────────────────────
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
                color: TitanTheme.accent
            }
        }

        // ── Capsule Slider Track ────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                id: track
                Layout.fillWidth: true
                height: 24
                radius: 12
                color: TitanTheme.bgInset
                clip: true

                // Glowing Sapphire Cyan Progress Fill
                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(24, parent.width * Math.max(0, Math.min(1, (sliderRoot.value - sliderRoot.from) / (sliderRoot.to - sliderRoot.from))))
                    radius: 12

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.darker(sliderRoot.fillAccent, 1.2) }
                        GradientStop { position: 1.0; color: sliderRoot.fillAccent }
                    }

                    Behavior on width {
                        enabled: !sliderMa.drag.active
                        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                    }

                    // Circular Drag Thumb
                    Rectangle {
                        id: thumb
                        width: 18
                        height: 18
                        radius: 9
                        anchors.right: parent.right
                        anchors.rightMargin: 3
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#FFFFFF"
                        border.color: Qt.rgba(1, 1, 1, 0.6)
                        border.width: 1

                        // Subtle glow around thumb
                        Rectangle {
                            anchors.centerIn: parent
                            width: 22
                            height: 22
                            radius: 11
                            color: TitanTheme.accentGlow
                            z: -1
                        }
                    }
                }

                MouseArea {
                    id: sliderMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateVal(mouseX) {
                        var ratio = Math.max(0.0, Math.min(1.0, mouseX / track.width));
                        var newVal = Math.round(sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from));
                        if (newVal !== sliderRoot.value) {
                            sliderRoot.value = newVal;
                            sliderRoot.changed(newVal);
                        }
                    }

                    onPressed: (mouse) => updateVal(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateVal(mouse.x);
                    }
                }
            }

            // Right-Side Icon
            Text {
                text: sliderRoot.iconGlyph
                font.family: TitanTheme.monoFamily
                font.pixelSize: 13
                color: TitanTheme.textSecondary
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
