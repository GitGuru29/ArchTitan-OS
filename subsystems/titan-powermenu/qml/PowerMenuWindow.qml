import QtQuick
import QtQuick.Window
import ArchTitan.TitanUI

Window {
    id: root
    width: Screen.width
    height: Screen.height
    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false
    title: "titan-powermenu"

    property bool powerMenuOpen: false
    property int selectedIndex: 0
    property string confirmingAction: "" // "", "logout", "restart", "shutdown"

    function openPowerMenu() {
        confirmingAction = "";
        selectedIndex = 0;
        powerMenuOpen = true;
        visible = true;
        requestActivate();
        keyListener.forceActiveFocus();
    }

    function closePowerMenu() {
        confirmingAction = "";
        powerMenuOpen = false;
        closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 160
        onTriggered: {
            if (!root.powerMenuOpen) {
                root.visible = false;
            }
        }
    }

    // Scrim
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        opacity: root.powerMenuOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closePowerMenu()
        }
    }

    // Centered Content
    Item {
        id: contentContainer
        anchors.centerIn: parent
        width: cardsRow.implicitWidth + 80
        height: columnLayout.implicitHeight

        opacity: root.powerMenuOpen ? 1.0 : 0.0
        scale: root.powerMenuOpen ? 1.0 : 0.95
        transformOrigin: Item.Center

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
        }

        Column {
            id: columnLayout
            anchors.centerIn: parent
            spacing: 28

            // Power Cards Row (Active when not confirming)
            Row {
                id: cardsRow
                visible: root.confirmingAction === ""
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                PowerCard {
                    title: "Lock"
                    subtitle: "Lock Session"
                    iconGlyph: "󰌾"
                    keyHint: "L"
                    accentColor: "#89B4FA"
                    isSelected: root.selectedIndex === 0
                    onTriggered: powerMenu.lockSession()
                }

                PowerCard {
                    title: "Suspend"
                    subtitle: "Sleep to RAM"
                    iconGlyph: "󰒲"
                    keyHint: "S"
                    accentColor: "#A6E3A1"
                    isSelected: root.selectedIndex === 1
                    onTriggered: powerMenu.suspendSession()
                }

                PowerCard {
                    title: "Log Out"
                    subtitle: "Exit Hyprland"
                    iconGlyph: "󰍃"
                    keyHint: "E"
                    accentColor: "#F9E2AF"
                    isSelected: root.selectedIndex === 2
                    onTriggered: root.confirmingAction = "logout"
                }

                PowerCard {
                    title: "Restart"
                    subtitle: "Reboot System"
                    iconGlyph: "󰑓"
                    keyHint: "R"
                    accentColor: "#FAB387"
                    isSelected: root.selectedIndex === 3
                    onTriggered: root.confirmingAction = "restart"
                }

                PowerCard {
                    title: "Shut Down"
                    subtitle: "Power Off"
                    iconGlyph: "󰐥"
                    keyHint: "P"
                    accentColor: "#F38BA8"
                    isSelected: root.selectedIndex === 4
                    onTriggered: root.confirmingAction = "shutdown"
                }
            }

            // Confirmation Modal Card (Accidental Trigger Prevention)
            Rectangle {
                id: confirmCard
                visible: root.confirmingAction !== ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: 460
                height: 220
                radius: 26
                color: TitanTheme.isDark ? "#D911111B" : "#F2FFFFFF"
                border.width: 1.5
                border.color: {
                    if (root.confirmingAction === "restart") return "#FAB387";
                    if (root.confirmingAction === "shutdown") return "#F38BA8";
                    return "#F9E2AF";
                }
                clip: true

                // Glow halo
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -4
                    radius: 30
                    z: -1
                    color: {
                        if (root.confirmingAction === "restart") return Qt.rgba(0.98, 0.70, 0.53, 0.22);
                        if (root.confirmingAction === "shutdown") return Qt.rgba(0.95, 0.55, 0.66, 0.22);
                        return Qt.rgba(0.98, 0.89, 0.69, 0.22);
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    width: parent.width - 48

                    // Top icon circle
                    Rectangle {
                        width: 54
                        height: 54
                        radius: 27
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: {
                            if (root.confirmingAction === "restart") return Qt.rgba(0.98, 0.70, 0.53, 0.18);
                            if (root.confirmingAction === "shutdown") return Qt.rgba(0.95, 0.55, 0.66, 0.18);
                            return Qt.rgba(0.98, 0.89, 0.69, 0.18);
                        }
                        border.width: 1
                        border.color: {
                            if (root.confirmingAction === "restart") return "#FAB387";
                            if (root.confirmingAction === "shutdown") return "#F38BA8";
                            return "#F9E2AF";
                        }

                        Text {
                            anchors.centerIn: parent
                            text: {
                                if (root.confirmingAction === "restart") return "󰑓";
                                if (root.confirmingAction === "shutdown") return "󰐥";
                                return "󰍃";
                            }
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 26
                            color: {
                                if (root.confirmingAction === "restart") return "#FAB387";
                                if (root.confirmingAction === "shutdown") return "#F38BA8";
                                return "#F9E2AF";
                            }
                        }
                    }

                    // Headings
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4
                        width: parent.width

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (root.confirmingAction === "restart") return "Restart ArchTitan OS?";
                                if (root.confirmingAction === "shutdown") return "Shut Down ArchTitan OS?";
                                return "Log Out of Hyprland?";
                            }
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 18
                            font.bold: true
                            color: TitanTheme.textHigh
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Unsaved work will be lost. Press Enter to proceed or Esc to cancel."
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 12
                            color: TitanTheme.textMid
                        }
                    }

                    // Button Row
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 14

                        // Confirm Button (Enter)
                        Rectangle {
                            width: 160
                            height: 40
                            radius: 12
                            color: {
                                if (root.confirmingAction === "restart") return "#FAB387";
                                if (root.confirmingAction === "shutdown") return "#F38BA8";
                                return "#F9E2AF";
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: {
                                        if (root.confirmingAction === "restart") return "Restart Now";
                                        if (root.confirmingAction === "shutdown") return "Shut Down Now";
                                        return "Log Out Now";
                                    }
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: "#11111B"
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 18
                                    radius: 4
                                    color: Qt.rgba(0, 0, 0, 0.20)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↵"
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 11
                                        font.bold: true
                                        color: "#11111B"
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: keyListener.executeConfirmedAction()
                            }
                        }

                        // Cancel Button (Esc)
                        Rectangle {
                            width: 120
                            height: 40
                            radius: 12
                            color: cancelConfirmMa.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08)
                            border.width: 1
                            border.color: Qt.rgba(255, 255, 255, 0.14)

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "Cancel"
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 13
                                    font.bold: true
                                    color: TitanTheme.textHigh
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 32
                                    height: 18
                                    radius: 4
                                    color: Qt.rgba(255, 255, 255, 0.08)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "ESC"
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 9
                                        font.bold: true
                                        color: TitanTheme.textLow
                                    }
                                }
                            }

                            MouseArea {
                                id: cancelConfirmMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.confirmingAction = ""
                            }
                        }
                    }
                }
            }

            // Footer Cancel Pill (Only shown when not confirming)
            Rectangle {
                visible: root.confirmingAction === ""
                anchors.horizontalCenter: parent.horizontalCenter
                width: cancelRow.implicitWidth + 30
                height: 38
                radius: 19
                color: cancelArea.containsMouse ? Qt.rgba(255, 255, 255, 0.16) : Qt.rgba(255, 255, 255, 0.08)
                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.14)

                Behavior on color { ColorAnimation { duration: 120 } }

                Row {
                    id: cancelRow
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰅖"
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 14
                        color: TitanTheme.textLow
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Cancel"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 13
                        font.bold: true
                        color: TitanTheme.textHigh
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 18
                        radius: 4
                        color: Qt.rgba(255, 255, 255, 0.08)

                        Text {
                            anchors.centerIn: parent
                            text: "ESC"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 9
                            font.bold: true
                            color: TitanTheme.textLow
                        }
                    }
                }

                MouseArea {
                    id: cancelArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closePowerMenu()
                }
            }
        }
    }

    // Global Key Listener
    Item {
        id: keyListener
        anchors.fill: parent
        focus: true

        function executeConfirmedAction() {
            var act = root.confirmingAction;
            root.confirmingAction = "";
            root.closePowerMenu();
            if (act === "restart") powerMenu.rebootSystem();
            else if (act === "shutdown") powerMenu.shutdownSystem();
            else if (act === "logout") powerMenu.logoutSession();
        }

        function triggerSelected() {
            if (root.selectedIndex === 0) powerMenu.lockSession();
            else if (root.selectedIndex === 1) powerMenu.suspendSession();
            else if (root.selectedIndex === 2) root.confirmingAction = "logout";
            else if (root.selectedIndex === 3) root.confirmingAction = "restart";
            else if (root.selectedIndex === 4) root.confirmingAction = "shutdown";
        }

        Keys.onPressed: function(event) {
            // Confirmation Interlock Mode
            if (root.confirmingAction !== "") {
                if (event.key === Qt.Key_Escape) {
                    root.confirmingAction = "";
                    event.accepted = true;
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    executeConfirmedAction();
                    event.accepted = true;
                }
                return;
            }

            // Normal Card Navigation Mode
            if (event.key === Qt.Key_Escape) {
                root.closePowerMenu();
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                root.selectedIndex = (root.selectedIndex - 1 + 5) % 5;
                event.accepted = true;
            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Tab) {
                root.selectedIndex = (root.selectedIndex + 1) % 5;
                event.accepted = true;
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                triggerSelected();
                event.accepted = true;
            } else if (event.key === Qt.Key_L) {
                powerMenu.lockSession();
                event.accepted = true;
            } else if (event.key === Qt.Key_S) {
                powerMenu.suspendSession();
                event.accepted = true;
            } else if (event.key === Qt.Key_E || event.key === Qt.Key_U) {
                root.confirmingAction = "logout";
                event.accepted = true;
            } else if (event.key === Qt.Key_R) {
                root.confirmingAction = "restart";
                event.accepted = true;
            } else if (event.key === Qt.Key_P || event.key === Qt.Key_X) {
                root.confirmingAction = "shutdown";
                event.accepted = true;
            }
        }
    }
}
