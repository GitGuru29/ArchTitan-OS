import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanSliderModule — Authentic macOS Control Center Embedded-Icon Capsule Slider.
 *
 * Modes:
 * - Standard Capsule Mode (Display, Sound): Header + 26px thick white capsule with embedded left icon.
 * - Headerless Capsule Mode (showHeader: false): 46px compact card with 26px thick white capsule + embedded icon.
 * - Thumb Bar Mode (thumbStyle: true, for Liquid Glass): 46px compact card with "Liquid Glass" header,
 *   sleek glowing white bar, circular thumb handle, and right percentage label.
 */
Rectangle {
    id: sliderRoot
    Layout.fillWidth: true
    implicitHeight: (!showHeader || thumbStyle) ? 50 : 64
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgTitanium
    border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                  ? TitanTheme.accent
                  : (sliderMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
    border.width: 1

    property string title: "Display"
    property string iconGlyph: "\uf185" // sun
    property int from: 0
    property int to: 100
    property int value: 75
    property color fillAccent: "#FFFFFF"
    property bool showOutputButton: false
    property bool showHeader: true
    property bool thumbStyle: false

    signal changed(int val)
    signal outputClicked()

    readonly property real normVal: Math.max(0.0, Math.min(1.0, (value - from) / Math.max(1, (to - from))))

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: sliderRoot.showHeader ? 7 : 11
        anchors.bottomMargin: sliderRoot.showHeader ? 9 : 11
        spacing: sliderRoot.thumbStyle ? 4 : 5

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            visible: sliderRoot.showHeader

            Text {
                text: sliderRoot.title
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
            }

            Item { Layout.fillWidth: true }
        }

        // ── Mode A: macOS Thick Capsule Slider Track + Optional Output Circle ─
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: !sliderRoot.thumbStyle

            Rectangle {
                id: track
                Layout.fillWidth: true
                height: 26
                radius: 13
                color: Qt.rgba(1, 1, 1, 0.14)
                border.color: Qt.rgba(1, 1, 1, 0.08)
                border.width: 1
                clip: true

                // Luminous White / Ice-Sapphire Capsule Fill
                Rectangle {
                    id: progressFill
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(28, parent.width * sliderRoot.normVal)
                    radius: 13

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#F8FAFC" }
                        GradientStop { position: 1.0; color: "#FFFFFF" }
                    }

                    Behavior on width {
                        enabled: !sliderMa.pressed
                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                    }

                    // Percentage inside right edge of the white fill when wide enough
                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        visible: progressFill.width >= 58
                        text: Math.round(sliderRoot.value) + "%"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: "#1E293B"
                    }
                }

                // Embedded Icon Inside Left of Track (macOS signature look)
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    z: 3
                    text: sliderRoot.iconGlyph
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: "#1E293B"
                }

                // Fallback Percentage on Right of Track when fill is very narrow (< 58px)
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 9
                    anchors.verticalCenter: parent.verticalCenter
                    visible: progressFill.width < 58
                    text: Math.round(sliderRoot.value) + "%"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: TitanTheme.textSecondary
                }

                MouseArea {
                    id: sliderMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function updateFromMouse(mx) {
                        if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                        var ratio = Math.max(0.0, Math.min(1.0, mx / Math.max(1, track.width)));
                        var newVal = Math.round(sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from));
                        if (newVal !== sliderRoot.value) {
                            sliderRoot.value = newVal;
                            sliderRoot.changed(newVal);
                        }
                    }

                    onPressed: (mouse) => updateFromMouse(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateFromMouse(mouse.x);
                    }
                }
            }

            // Optional Circular AirPlay / Audio Output Selector Button (on Sound Card)
            Rectangle {
                visible: sliderRoot.showOutputButton
                width: 26
                height: 26
                radius: 13
                color: outMa.containsMouse ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(1, 1, 1, 0.12)
                border.color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1
                scale: outMa.pressed ? 0.90 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf025" // headphones / audio output
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    color: "#FFFFFF"
                }

                MouseArea {
                    id: outMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        sliderRoot.outputClicked();
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.openAudioSettings();
                        }
                    }
                }
            }
        }

        // ── Mode B: Sleek Thumb Bar Slider (Liquid Glass Card in Row 3) ─────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            visible: sliderRoot.thumbStyle

            Item {
                id: thinTrackContainer
                Layout.fillWidth: true
                height: 16

                Rectangle {
                    id: thinTrack
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.rgba(1, 1, 1, 0.16)

                    Rectangle {
                        width: Math.max(8, parent.width * sliderRoot.normVal)
                        height: parent.height
                        radius: 4
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "#E2E8F0" }
                            GradientStop { position: 1.0; color: "#FFFFFF" }
                        }
                    }
                }

                // Glowing circular white thumb
                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(parent.width - width, parent.width * sliderRoot.normVal - width / 2))
                    color: "#FFFFFF"
                    border.color: Qt.rgba(0, 0, 0, 0.25)
                    border.width: 1
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function updateThin(mx) {
                        if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                        var ratio = Math.max(0.0, Math.min(1.0, mx / Math.max(1, thinTrackContainer.width)));
                        var newVal = Math.round(sliderRoot.from + ratio * (sliderRoot.to - sliderRoot.from));
                        if (newVal !== sliderRoot.value) {
                            sliderRoot.value = newVal;
                            sliderRoot.changed(newVal);
                        }
                    }
                    onPressed: (mouse) => updateThin(mouse.x)
                    onPositionChanged: (mouse) => { if (pressed) updateThin(mouse.x); }
                }
            }

            Text {
                text: Math.round(sliderRoot.value) + "%"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: TitanTheme.textSecondary
            }
        }
    }
}
