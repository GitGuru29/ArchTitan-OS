import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * HeaderBar — Samsung One UI 9.0 session header.
 *
 * Left: Bold clock and date with uptime indicator.
 * Right: Quick action pills (Power, Settings, Refresh).
 */
RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 52
    spacing: 12

    // ── Clock & Date Cluster ────────────────────────────────────────────────
    ColumnLayout {
        spacing: 1
        Layout.alignment: Qt.AlignVCenter

        RowLayout {
            spacing: 6

            Text {
                id: clockTime
                text: "21:45"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 22
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
            }

            Text {
                id: clockSeconds
                text: ""
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: TitanTheme.textSubtle
                Layout.alignment: Qt.AlignBaseline
            }
        }

        RowLayout {
            spacing: 6

            Text {
                id: dateLabel
                text: "Saturday, Oct 11"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: TitanTheme.textSecondary
            }

            Text {
                text: "• " + ((typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.uptime : "Up 0m")
                font.family: TitanTheme.fontFamily
                font.pixelSize: 10
                color: TitanTheme.textSubtle
            }
        }
    }

    Item { Layout.fillWidth: true }

    // ── One UI Action Pills ─────────────────────────────────────────────────
    RowLayout {
        spacing: 8
        Layout.alignment: Qt.AlignVCenter

        // Refresh all
        IconButton {
            source: "\uf021"
            tip: "Refresh status"
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.refresh();
                if (typeof networkCtrl !== "undefined" && networkCtrl) networkCtrl.refresh();
                if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) bluetoothCtrl.refresh();
                if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.refresh();
            }
        }

        // Settings Gear
        IconButton {
            source: "\uf013"
            tip: "System Settings"
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.openSettings();
            }
        }

        // Power Menu
        IconButton {
            source: "\uf011"
            tip: "Power menu"
            destructive: true
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl)
                    systemCtrl.openPowerMenu();
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
        }
    }
}