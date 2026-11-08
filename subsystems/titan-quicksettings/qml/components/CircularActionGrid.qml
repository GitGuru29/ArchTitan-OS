import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * CircularActionGrid — Perfectly balanced 4-column grid of 100% Circular Action Buttons.
 *
 * 8 circular glass toggles distributed evenly across 4 columns with exact 25% cell widths:
 * - Focus / DND
 * - Dark Mode
 * - Night Light
 * - Mic Mute
 * - Caffeine / Awake
 * - Screenshot (Area Grab)
 * - Screen Record
 * - Color Picker (Hyprpicker)
 */
GridLayout {
    id: gridRoot
    Layout.fillWidth: true
    columns: 4
    columnSpacing: 0
    rowSpacing: 14

    property bool dndActive: false

    // ── Row 1 (4 Circles) ───────────────────────────────────────────────────
    // 1. Focus / DND
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf186" // moon
        label: "Focus"
        active: gridRoot.dndActive
        activeColor: TitanTheme.lavender
        onClicked: {
            gridRoot.dndActive = !gridRoot.dndActive;
        }
    }

    // 2. Dark Mode
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf042" // adjust / half-moon
        label: "Dark"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
        activeColor: TitanTheme.accent
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                systemCtrl.themeDark = !systemCtrl.themeDark;
            }
        }
    }

    // 3. Night Light
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf06e" // eye
        label: "Night"
        active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
        activeColor: TitanTheme.peach
        onClicked: {
            if (typeof nightLightCtrl !== "undefined" && nightLightCtrl) {
                nightLightCtrl.toggleNightLight();
            }
        }
    }

    // 4. Mic Mute
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130" // mic-slash / mic
        label: "Mic"
        active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
        activeColor: TitanTheme.red
        onClicked: {
            if (typeof audioCtrl !== "undefined" && audioCtrl) {
                audioCtrl.toggleSourceMute();
            }
        }
    }

    // ── Row 2 (4 Circles) ───────────────────────────────────────────────────
    // 5. Caffeine / Keep Awake
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf0f4" // coffee
        label: "Awake"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false
        activeColor: TitanTheme.yellow
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                systemCtrl.caffeineActive = !systemCtrl.caffeineActive;
            }
        }
    }

    // 6. Screenshot (Snip)
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf030" // camera
        label: "Screenshot"
        active: false
        activeColor: TitanTheme.cyan
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                systemCtrl.takeScreenshot();
            }
        }
    }

    // 7. Screen Record
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf03d" // video
        label: "Record"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false
        activeColor: TitanTheme.red
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                systemCtrl.toggleScreenRecording();
            }
        }
    }

    // 8. Color Picker
    OneUICircleButton {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignHCenter
        iconGlyph: "\uf1fb" // eyedropper
        label: "Picker"
        active: false
        activeColor: TitanTheme.teal
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                systemCtrl.pickColor();
            }
        }
    }
}
