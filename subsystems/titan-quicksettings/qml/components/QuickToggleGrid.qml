import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — the "system" controls cluster of the drawer.
 *
 * Connectivity pills, the volume / brightness card and the 4x2 tool grid.
 * All tiles share design tokens and states via the reusable components.
 */
Rectangle {
    id: gridContainer
    Layout.fillWidth: true
    Layout.preferredHeight: 392
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgSurface
    border.color: TitanTheme.borderSubtle
    border.width: 1

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 12
        spacing: 8

        // ── Section label ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Rectangle { width: 3; height: 12; radius: 1.5; color: TitanTheme.accent }
            Text {
                text: "QUICK SETTINGS"
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeCaption
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                color: TitanTheme.textSubtle
            }
            Item { Layout.fillWidth: true }
        }

        // ── Connectivity row ──────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            spacing: 8

            LargeToggleTile {
                active: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : false
                source: "\uf1eb"   // wifi
                titleText: "Internet"
                statusText: (typeof networkCtrl !== "undefined" && networkCtrl)
                            ? networkCtrl.ssid : "No connection"
                accent: TitanTheme.teal
                onClicked: if (typeof networkCtrl !== "undefined" && networkCtrl) networkCtrl.toggleWifi()
            }

            LargeToggleTile {
                active: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) ? bluetoothCtrl.powered : false
                source: "\uf294"   // bluetooth
                titleText: "Bluetooth"
                statusText: (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl)
                            ? bluetoothCtrl.statusText : "Not connected"
                accent: TitanTheme.lavender
                onClicked: if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) bluetoothCtrl.toggleBluetooth()
            }

            // Caffeine mini-toggle
            Rectangle {
                Layout.preferredWidth: 50
                Layout.preferredHeight: 50
                radius: TitanTheme.radiusControl
                color: cafMa.pressed ? TitanTheme.bgPressed
                      : (cafActive ? TitanTheme.yellow
                        : (cafMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgSurfaceAlt))
                border.color: cafActive ? TitanTheme.borderActive
                              : (cafMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle)
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                HavenIcon {
                    anchors.centerIn: parent
                    source: "\uf0f4"   // coffee
                    tint: cafActive ? TitanTheme.accentText : TitanTheme.textMuted
                    glyphSize: 18
                }

                MouseArea {
                    id: cafMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (typeof systemCtrl !== "undefined" && systemCtrl)
                                   systemCtrl.caffeineActive = !systemCtrl.caffeineActive
                }

                property bool cafActive: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false

                Accessible.role: Accessible.Button
                Accessible.name: "Caffeine"
            }
        }

        // ── Volume / brightness card ──────────────────────────────────────────
        VolumeCard {}

        // ── Tools section ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Rectangle { width: 3; height: 12; radius: 1.5; color: TitanTheme.accent }
            Text {
                text: "TOOLS"
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeCaption
                font.weight: Font.Bold
                font.letterSpacing: 1.2
                color: TitanTheme.textSubtle
            }
            Item { Layout.fillWidth: true }
        }

        // Row 1
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 8

            GridTile {
                source: "\uf186"   // moon
                tip: "Toggle dark theme"
                glyphSize: 17
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.themeDark = !systemCtrl.themeDark
            }
            GridTile {
                source: "\uf1fe"   // pulse
                tip: "Audio visualizer"
                glyphSize: 17
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.visualizerActive : false
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.visualizerActive = !systemCtrl.visualizerActive
            }
            GridTile {
                source: "\uf023"   // lock
                tip: "VPN on/off"
                glyphSize: 16
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.vpnActive : false
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.vpnActive = !systemCtrl.vpnActive
            }
            GridTile {
                source: "\uf11b"   // gamepad
                tip: "Game mode"
                glyphSize: 16
                active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.gameModeActive = !systemCtrl.gameModeActive
            }
        }

        // Row 2
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 8

            GridTile {
                source: "\uf030"   // camera
                tip: "Screenshot region"
                glyphSize: 16
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.takeScreenshot()
            }
            GridTile {
                source: "\uf1fb"   // eye dropper
                tip: "Pick screen color"
                glyphSize: 16
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.pickColor()
            }
            GridTile {
                source: "\uf11c"   // keyboard
                tip: "Virtual keyboard"
                glyphSize: 16
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleVirtualKeyboard()
            }
            GridTile {
                source: "\uf001"   // music
                tip: "Media widget"
                glyphSize: 16
                onActivated: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openMediaWidget()
            }
        }
    }
}