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

    property string userName: "Siluna"
    property bool showNotificationPanel: false
    signal toggleNotificationPanel()

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
            color: headerRoot.showNotificationPanel
                   ? TitanTheme.accentBlue
                   : (notifMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
            border.color: TitanTheme.borderGlass
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

        // Edit button
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: editMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
            border.color: TitanTheme.borderGlass
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\uf044" // pencil edit
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: TitanTheme.textPrimary
            }

            MouseArea {
                id: editMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.refresh();
                }
            }
        }

        // Settings Gear
        Rectangle {
            width: 36
            height: 36
            radius: 18
            color: setMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
            border.color: TitanTheme.borderGlass
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