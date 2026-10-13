import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * VolumeCard — system audio & display controls.
 *
 * Live volume slider bound to the PipeWire/WirePlumber controller plus quick
 * microphone and night-light toggles.  All state reads come through the
 * context controllers and degrade gracefully when they are absent.
 */
Rectangle {
    id: volumeCard

    Layout.fillWidth: true
    implicitHeight: 148
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgSurface
    border.color: TitanTheme.borderSubtle
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        anchors.topMargin: 12
        anchors.bottomMargin: 12
        spacing: 8

        // ── Volume slider ─────────────────────────────────────────────────────
        LevelSlider {
            id: volSlider
            Layout.fillWidth: true

            source: {
                if (muted) return "\uf026";                       // volume-off
                if (value <= 30) return "\uf027";                  // volume-low
                return "\uf028";                                   // volume-high
            }
            tint: muted ? TitanTheme.textSubtle : TitanTheme.cyan
            value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
            from: 0
            to: 150
            muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted

            onChanged: if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
        }

        // ── Brightness slider ─────────────────────────────────────────────────
        LevelSlider {
            id: brightSlider
            Layout.fillWidth: true

            source: "\uf185"   // sun
            tint: TitanTheme.yellow
            value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
            from: 0
            to: 100
            onChanged: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
        }

        // ── Microphone + night light ──────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 10

            // Microphone mute square
            Rectangle {
                id: micRect
                Layout.preferredWidth: 46
                Layout.preferredHeight: 46
                radius: TitanTheme.radiusControl
                color: micMa.pressed ? TitanTheme.bgPressed
                      : (micActive ? TitanTheme.accent
                        : (micMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgSurfaceAlt))
                border.color: micActive ? TitanTheme.borderActive
                              : (micMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                HavenIcon {
                    anchors.centerIn: parent
                    source: micActive ? "\uf130" : "\uf131"   // mic / mic-off
                    tint: micActive ? TitanTheme.accentText : TitanTheme.textMuted
                    glyphSize: 17
                }

                MouseArea {
                    id: micMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.toggleSourceMute()
                }

                property bool micActive: (typeof audioCtrl !== "undefined" && audioCtrl) ? !audioCtrl.sourceMuted : true

                ToolTip.visible: micMa.containsMouse
                ToolTip.text: micActive ? "Microphone on" : "Microphone muted"
                ToolTip.toolTip.background: Rectangle {
                    color: TitanTheme.bgWindow; border.color: TitanTheme.borderSubtle; border.width: 1; radius: 8
                }
                ToolTip.toolTip.contentItem: Text {
                    text: micRect.ToolTip.text
                    color: TitanTheme.textPrimary
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeSmall
                    padding: 6
                }
            }

            // Night light toggle pill
            LargeToggleTile {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
                source: "\uf186"   // moon
                titleText: "Night Light"
                statusText: (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                            ? nightLightCtrl.statusText : "Inactive"
                accent: TitanTheme.peach
                glyphSize: 15
                onClicked: if (typeof nightLightCtrl !== "undefined" && nightLightCtrl) nightLightCtrl.toggleNightLight()
            }
        }
    }
}