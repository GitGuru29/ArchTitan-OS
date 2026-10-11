import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * HeaderBar — session badge, live clock and the system action row.
 *
 * Left: ArchTitan delta + uptime.  Right: live HH:MM clock, then the
 * edit / refresh / settings / power icon buttons (with tooltips).
 */
RowLayout {
    id: headerRoot
    Layout.fillWidth: true
    Layout.preferredHeight: 42
    spacing: 8

    property alias uptimeText: uptimeLabel.text

    // ── Uptime badge ─────────────────────────────────────────────────────────
    Rectangle {
        Layout.preferredHeight: 36
        Layout.preferredWidth: 118
        radius: 18
        color: TitanTheme.bgSurfaceAlt
        border.color: TitanTheme.borderSubtle
        border.width: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 8

            // ArchTitan Delta mark
            Canvas {
                Layout.preferredWidth: 15
                Layout.preferredHeight: 15
                onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    ctx.beginPath();
                    ctx.moveTo(width * 0.5, 2);
                    ctx.lineTo(width - 2, height - 2);
                    ctx.lineTo(width * 0.65, height - 2);
                    ctx.lineTo(width * 0.5, height * 0.52);
                    ctx.lineTo(width * 0.35, height - 2);
                    ctx.lineTo(2, height - 2);
                    ctx.closePath();
                    ctx.fillStyle = TitanTheme.cyan;
                    ctx.fill();
                }
            }

            Text {
                id: uptimeLabel
                text: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.uptime : "Up 0m"
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeSmall
                font.weight: Font.DemiBold
                color: TitanTheme.textPrimary
                elide: Text.ElideRight
            }
        }
    }

    Item { Layout.fillWidth: true }

    // ── Live clock ───────────────────────────────────────────────────────────
    ColumnLayout {
        spacing: 0

        Text {
            id: clockTime
            text: "00:00"
            Layout.alignment: Qt.AlignHCenter
            font.family: TitanTheme.fontFamily
            font.pixelSize: TitanTheme.sizeTitle + 2
            font.weight: Font.Bold
            color: TitanTheme.textPrimary
        }
        Text {
            id: clockSeconds
            text: ""
            Layout.alignment: Qt.AlignHCenter
            font.family: TitanTheme.fontFamily
            font.pixelSize: 9
            color: TitanTheme.textSubtle
        }
    }

    // ── Action buttons ───────────────────────────────────────────────────────
    RowLayout {
        spacing: 6

        IconButton {
            source: "\uf1de"          // sliders — edit tiles
            tip: "Edit quick settings"
            onClicked: {} // tile editor (placeholder surface)
        }
        IconButton {
            source: "\uf021"          // sync
            tip: "Refresh all"
            onClicked: {
                if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.refresh();
                if (typeof networkCtrl !== "undefined" && networkCtrl) networkCtrl.refresh();
                if (typeof bluetoothCtrl !== "undefined" && bluetoothCtrl) bluetoothCtrl.refresh();
                if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.refresh();
            }
        }
        IconButton {
            source: "\uf013"          // cog
            tip: "Open system settings"
            onClicked: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openSettings()
        }
        IconButton {
            source: "\uf011"          // power
            tip: "Power menu"
            destructive: true
            active: false
            onClicked: if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openPowerMenu()
        }
    }

    // Tick the clock every second
    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var d = new Date();
            var hh = ("0" + d.getHours()).slice(-2);
            var mm = ("0" + d.getMinutes()).slice(-2);
            var ss = ("0" + d.getSeconds()).slice(-2);
            clockTime.text = hh + ":" + mm;
            clockSeconds.text = ss;
        }
    }
}