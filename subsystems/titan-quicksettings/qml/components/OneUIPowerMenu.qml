import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../style"

/**
 * OneUIPowerMenu — Samsung One UI 9.0 Power & Session Overlay.
 *
 * Provides instant access to system power states:
 * - Power Off (Shutdown)
 * - Restart (Reboot)
 * - Lock Screen (Lock)
 * - Suspend (Sleep)
 * - Log Out (Exit session to SDDM)
 */
Rectangle {
    id: powerRoot
    radius: TitanTheme.radiusWindow
    color: TitanTheme.isDark ? "#E60B0E14" : "#EAF4F6F9"
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    signal closeRequested()

    // Smooth entry transition
    opacity: visible ? 1.0 : 0.0
    scale: visible ? 1.0 : 0.94
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 16

        // ── Header: Title & Close Button ────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: Qt.rgba(0.94, 0.27, 0.27, 0.18)
                border.color: Qt.rgba(0.94, 0.27, 0.27, 0.35)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf011" // power icon
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 16
                    color: TitanTheme.red
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: "Power Menu"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Select a power or session action"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textMuted
                }
            }

            // Close 'X' Button
            Rectangle {
                width: 34
                height: 34
                radius: 17
                color: closeMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: closeMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1
                scale: closeMa.pressed ? 0.91 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d" // times / close
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.closeRequested()
                }
            }
        }

        // ── Primary Power Action Cards (Vertical Stack with tactile rows) ───
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            // 1. Power Off Card
            Rectangle {
                id: shutdownCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: pwrMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.16) : TitanTheme.bgOneUICard
                border.color: pwrMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.5) : TitanTheme.borderGlass
                border.width: 1
                scale: pwrMa.pressed ? 0.97 : (pwrMa.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#EF4444"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf011" // power
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Power off"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: "Shut down system completely"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            color: TitanTheme.textMuted
                        }
                    }

                    Text {
                        text: "\uf054"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.poweroffSystem();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }

            // 2. Restart Card
            Rectangle {
                id: rebootCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: rbtMa.containsMouse ? Qt.rgba(0.06, 0.73, 0.51, 0.16) : TitanTheme.bgOneUICard
                border.color: rbtMa.containsMouse ? Qt.rgba(0.06, 0.73, 0.51, 0.5) : TitanTheme.borderGlass
                border.width: 1
                scale: rbtMa.pressed ? 0.97 : (rbtMa.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#10B981"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf01e" // refresh / reboot
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Restart"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: "Reboot computer"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            color: TitanTheme.textMuted
                        }
                    }

                    Text {
                        text: "\uf054"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    id: rbtMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.rebootSystem();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }

            // 3. Lock Screen Card
            Rectangle {
                id: lockCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: lckMa.containsMouse ? Qt.rgba(0.23, 0.51, 0.96, 0.16) : TitanTheme.bgOneUICard
                border.color: lckMa.containsMouse ? Qt.rgba(0.23, 0.51, 0.96, 0.5) : TitanTheme.borderGlass
                border.width: 1
                scale: lckMa.pressed ? 0.97 : (lckMa.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#3B82F6"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf023" // lock
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Lock screen"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: "Secure display and require authentication"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            color: TitanTheme.textMuted
                        }
                    }

                    Text {
                        text: "\uf054"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    id: lckMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.lockSession();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }

            // 4. Suspend Card
            Rectangle {
                id: suspendCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: suspMa.containsMouse ? Qt.rgba(0.55, 0.36, 0.96, 0.16) : TitanTheme.bgOneUICard
                border.color: suspMa.containsMouse ? Qt.rgba(0.55, 0.36, 0.96, 0.5) : TitanTheme.borderGlass
                border.width: 1
                scale: suspMa.pressed ? 0.97 : (suspMa.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#8B5CF6"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf186" // moon
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Suspend"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: "Put system to low-power sleep mode"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            color: TitanTheme.textMuted
                        }
                    }

                    Text {
                        text: "\uf054"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    id: suspMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.suspendSession();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }

            // 5. Log Out Card
            Rectangle {
                id: logoutCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: lgoMa.containsMouse ? Qt.rgba(0.96, 0.62, 0.04, 0.16) : TitanTheme.bgOneUICard
                border.color: lgoMa.containsMouse ? Qt.rgba(0.96, 0.62, 0.04, 0.5) : TitanTheme.borderGlass
                border.width: 1
                scale: lgoMa.pressed ? 0.97 : (lgoMa.containsMouse ? 1.015 : 1.0)
                Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutQuad } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: "#F59E0B"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf2f5" // sign-out
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "Log out"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                        }

                        Text {
                            text: "End session and return to SDDM login screen"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            color: TitanTheme.textMuted
                        }
                    }

                    Text {
                        text: "\uf054"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    id: lgoMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.logoutSession();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Footer: Fullscreen Menu Option & Cancel Button ──────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Fullscreen Rofi Menu Link
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 21
                color: rofiMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: rofiMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1
                scale: rofiMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "\uf2d0" // window / expand
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        color: TitanTheme.textSecondary
                    }

                    Text {
                        text: "Classic Menu"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textSecondary
                    }
                }

                MouseArea {
                    id: rofiMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            systemCtrl.openPowerMenu();
                        }
                        powerRoot.closeRequested();
                    }
                }
            }

            // Cancel Button
            Rectangle {
                Layout.fillWidth: true
                height: 42
                radius: 21
                color: cancelMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: cancelMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1
                scale: cancelMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "Cancel"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: cancelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.closeRequested()
                }
            }
        }
    }
}
