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
    color: TitanTheme.bgMenu
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    signal closeRequested()

    // Session actions. The pointer path and the keyboard path both call these,
    // so the two can never drift apart.
    function doClose()   { powerRoot.closeRequested() }
    function doPowerOff() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.poweroffSystem();
        powerRoot.closeRequested();
    }
    function doReboot() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.rebootSystem();
        powerRoot.closeRequested();
    }
    function doLock() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.lockSession();
        powerRoot.closeRequested();
    }
    function doSuspend() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.suspendSession();
        powerRoot.closeRequested();
    }
    function doLogout() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.logoutSession();
        powerRoot.closeRequested();
    }
    function doClassicMenu() {
        if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openPowerMenu();
        powerRoot.closeRequested();
    }

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
                color: Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.18)
                border.color: Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.35)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf011" // power icon
                    font.family: TitanTheme.monoFamily
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
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: TitanTheme.textPrimary
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doClose(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doClose(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doClose(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Close"
                Accessible.onPressAction: powerRoot.doClose()

                FocusRing {}

                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doClose()
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
                color: pwrMa.containsMouse ? Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.16) : TitanTheme.bgOneUICard
                border.color: pwrMa.containsMouse ? Qt.rgba(TitanTheme.red.r, TitanTheme.red.g, TitanTheme.red.b, 0.5) : TitanTheme.borderGlass
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
                        color: TitanTheme.red

                        Text {
                            anchors.centerIn: parent
                            text: "\uf011" // power
                            font.family: TitanTheme.monoFamily
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
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doPowerOff(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doPowerOff(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doPowerOff(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Power off"
                Accessible.onPressAction: powerRoot.doPowerOff()

                FocusRing {}

                MouseArea {
                    id: pwrMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doPowerOff()
                }
            }

            // 2. Restart Card
            Rectangle {
                id: rebootCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: rbtMa.containsMouse ? Qt.rgba(TitanTheme.green.r, TitanTheme.green.g, TitanTheme.green.b, 0.16) : TitanTheme.bgOneUICard
                border.color: rbtMa.containsMouse ? Qt.rgba(TitanTheme.green.r, TitanTheme.green.g, TitanTheme.green.b, 0.5) : TitanTheme.borderGlass
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
                        color: TitanTheme.green

                        Text {
                            anchors.centerIn: parent
                            text: "\uf01e" // refresh / reboot
                            font.family: TitanTheme.monoFamily
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
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doReboot(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doReboot(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doReboot(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Restart"
                Accessible.onPressAction: powerRoot.doReboot()

                FocusRing {}

                MouseArea {
                    id: rbtMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doReboot()
                }
            }

            // 3. Lock Screen Card
            Rectangle {
                id: lockCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: lckMa.containsMouse ? Qt.rgba(TitanTheme.accentBlue.r, TitanTheme.accentBlue.g, TitanTheme.accentBlue.b, 0.16) : TitanTheme.bgOneUICard
                border.color: lckMa.containsMouse ? Qt.rgba(TitanTheme.accentBlue.r, TitanTheme.accentBlue.g, TitanTheme.accentBlue.b, 0.5) : TitanTheme.borderGlass
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
                        color: TitanTheme.accentBlue

                        Text {
                            anchors.centerIn: parent
                            text: "\uf023" // lock
                            font.family: TitanTheme.monoFamily
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
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doLock(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doLock(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doLock(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Lock screen"
                Accessible.onPressAction: powerRoot.doLock()

                FocusRing {}

                MouseArea {
                    id: lckMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doLock()
                }
            }

            // 4. Suspend Card
            Rectangle {
                id: suspendCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: suspMa.containsMouse ? Qt.rgba(TitanTheme.lavender.r, TitanTheme.lavender.g, TitanTheme.lavender.b, 0.16) : TitanTheme.bgOneUICard
                border.color: suspMa.containsMouse ? Qt.rgba(TitanTheme.lavender.r, TitanTheme.lavender.g, TitanTheme.lavender.b, 0.5) : TitanTheme.borderGlass
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
                        color: TitanTheme.lavender

                        Text {
                            anchors.centerIn: parent
                            text: "\uf186" // moon
                            font.family: TitanTheme.monoFamily
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
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doSuspend(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doSuspend(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doSuspend(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Suspend"
                Accessible.onPressAction: powerRoot.doSuspend()

                FocusRing {}

                MouseArea {
                    id: suspMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doSuspend()
                }
            }

            // 5. Log Out Card
            Rectangle {
                id: logoutCard
                Layout.fillWidth: true
                Layout.preferredHeight: 70
                radius: TitanTheme.radiusCard
                color: lgoMa.containsMouse ? Qt.rgba(TitanTheme.yellow.r, TitanTheme.yellow.g, TitanTheme.yellow.b, 0.16) : TitanTheme.bgOneUICard
                border.color: lgoMa.containsMouse ? Qt.rgba(TitanTheme.yellow.r, TitanTheme.yellow.g, TitanTheme.yellow.b, 0.5) : TitanTheme.borderGlass
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
                        color: TitanTheme.yellow

                        Text {
                            anchors.centerIn: parent
                            text: "\uf2f5" // sign-out
                            font.family: TitanTheme.monoFamily
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
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textSubtle
                    }
                }

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doLogout(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doLogout(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doLogout(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Log out"
                Accessible.onPressAction: powerRoot.doLogout()

                FocusRing {}

                MouseArea {
                    id: lgoMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doLogout()
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
                        font.family: TitanTheme.monoFamily
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

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doClassicMenu(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doClassicMenu(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doClassicMenu(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Classic power menu"
                Accessible.onPressAction: powerRoot.doClassicMenu()

                FocusRing {}

                MouseArea {
                    id: rofiMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doClassicMenu()
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

                // Keyboard: Tab-reachable, Enter / Space activate.
                activeFocusOnTab: true
                Keys.onReturnPressed: (event) => { powerRoot.doClose(); event.accepted = true }
                Keys.onEnterPressed:  (event) => { powerRoot.doClose(); event.accepted = true }
                Keys.onSpacePressed:  (event) => { powerRoot.doClose(); event.accepted = true }
                Accessible.role: Accessible.Button
                Accessible.name: "Cancel"
                Accessible.onPressAction: powerRoot.doClose()

                FocusRing {}

                MouseArea {
                    id: cancelMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerRoot.doClose()
                }
            }
        }
    }
}
