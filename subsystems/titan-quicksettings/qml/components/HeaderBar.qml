import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * HeaderBar — Samsung One UI 9.0 session header.
 *
 * Left: Bold clock, date, and user greeting ("Good evening, Siluna 🌙").
 * Right: Quick edit and settings action buttons.
 */
RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 68
    spacing: 12

    property string userName: (typeof systemCtrl !== "undefined" && systemCtrl && systemCtrl.userName)
                              ? systemCtrl.userName
                              : "User"
    property bool showNotificationPanel: false
    signal toggleNotificationPanel()
    property bool editMode: false
    signal toggleEditMode()
    property bool showPowerMenu: false
    signal togglePowerMenu()

    function getGreeting() {
        var h = new Date().getHours();
        var period = "Good evening";
        var icon = "🌙";
        if (h >= 5 && h < 12) {
            period = "Good morning";
            icon = "☀️";
        } else if (h >= 12 && h < 17) {
            period = "Good afternoon";
            icon = "🌤️";
        } else if (h >= 17 && h < 22) {
            period = "Good evening";
            icon = "🌙";
        } else {
            period = "Good night";
            icon = "🌙";
        }
        return period + ", " + userName + " " + icon;
    }

    // ── Clock & Date Cluster ────────────────────────────────────────────────
    ColumnLayout {
        spacing: 2
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            spacing: 6
            Layout.alignment: Qt.AlignLeft

            Text {
                id: clockTime
                text: "23:03"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 34
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
            }

            Text {
                id: clockSeconds
                text: "40"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                color: TitanTheme.textSubtle
                Layout.alignment: Qt.AlignBaseline
            }
        }

        Text {
            id: dateLabel
            text: "Sun, Oct 11"
            font.family: TitanTheme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: TitanTheme.textSecondary
        }

        Text {
            id: greetingLabel
            text: headerRoot.getGreeting()
            font.family: TitanTheme.fontFamily
            font.pixelSize: 12
            color: TitanTheme.textMuted
            elide: Text.ElideRight
            Layout.maximumWidth: 190
        }
    }

    Item { Layout.fillWidth: true }

    // ── One UI Action Buttons (Notifications, Edit, Settings) ─────────────
    RowLayout {
        spacing: 8
        Layout.alignment: Qt.AlignTop
        Layout.topMargin: 4

        // Notification toggle button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            clip: true
            scale: notifMa.pressed ? 0.91 : (notifMa.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
            color: headerRoot.showNotificationPanel
                   ? TitanTheme.accentBlue
                   : (notifMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
            border.color: headerRoot.showNotificationPanel ? TitanTheme.borderActive : TitanTheme.borderGlass
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf0f3" // bell
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: headerRoot.showNotificationPanel ? "#FFFFFF" : TitanTheme.textPrimary
            }

            // Badge count
            Rectangle {
                visible: (typeof notifModel !== "undefined" && notifModel && notifModel.totalCount > 0)
                width: 14
                height: 14
                radius: 7
                color: TitanTheme.red
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -2
                anchors.rightMargin: -2

                Text {
                    anchors.centerIn: parent
                    text: (typeof notifModel !== "undefined" && notifModel) ? notifModel.totalCount : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 8
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }
            }

            MouseArea {
                id: notifMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    headerRoot.toggleNotificationPanel();
                }
            }
        }

        // Edit button (Toggles Quick Panel Customizer)
        Rectangle {
            width: 36
            height: 36
            radius: 18
            clip: true
            scale: editMa.pressed ? 0.91 : (editMa.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
            color: headerRoot.editMode
                   ? TitanTheme.accentBlue
                   : (editMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
            border.color: headerRoot.editMode
                          ? TitanTheme.borderActive
                          : (editMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: headerRoot.editMode ? "\uf00c" : "\uf044" // checkmark when in edit mode, pencil normally
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: headerRoot.editMode ? "#FFFFFF" : TitanTheme.textPrimary
            }

            MouseArea {
                id: editMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    headerRoot.toggleEditMode();
                }
            }
        }

        // Settings Gear
        Rectangle {
            width: 36
            height: 36
            radius: 18
            clip: true
            scale: setMa.pressed ? 0.91 : (setMa.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
            color: setMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
            border.color: setMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf013" // gear
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: TitanTheme.textPrimary
            }

            MouseArea {
                id: setMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.openSettings();
                }
            }
        }

        // Power Button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            clip: true
            scale: pwrMa.pressed ? 0.91 : (pwrMa.containsMouse ? 1.08 : 1.0)
            Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack; easing.overshoot: 1.25 } }
            color: headerRoot.showPowerMenu
                   ? TitanTheme.red
                   : (pwrMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.22) : TitanTheme.bgOneUIPill)
            border.color: headerRoot.showPowerMenu
                          ? TitanTheme.red
                          : (pwrMa.containsMouse ? Qt.rgba(0.94, 0.27, 0.27, 0.5) : TitanTheme.borderGlass)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf011" // power-off glyph
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: headerRoot.showPowerMenu ? "#FFFFFF" : (pwrMa.containsMouse ? TitanTheme.red : TitanTheme.textPrimary)
            }

            MouseArea {
                id: pwrMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    headerRoot.togglePowerMenu();
                }
            }
        }
    }

    // Tick the clock every second
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            var d = new Date();
            var hh = ("0" + d.getHours()).slice(-2);
            var mm = ("0" + d.getMinutes()).slice(-2);
            var ss = ("0" + d.getSeconds()).slice(-2);
            clockTime.text = hh + ":" + mm;
            clockSeconds.text = ss;
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
            dateLabel.text = days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate();
            greetingLabel.text = headerRoot.getGreeting();
        }
    }
}