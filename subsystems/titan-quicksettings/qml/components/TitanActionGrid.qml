import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * TitanActionGrid — 2-Column macOS-style Quick Action Bento Grid.
 *
 * Symmetrically arranges TitanActionTile components with live controller
 * state binding, active Titan Orange styling, and custom visibility support.
 */
GridLayout {
    id: gridRoot
    Layout.fillWidth: true
    columns: 2
    columnSpacing: 8
    rowSpacing: 8

    property bool dndActive: false
    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    // ── Tile 1: Dark Mode ───────────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf042" // adjust / contrast
        title: "Dark Mode"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true
        statusText: active ? "Obsidian" : "Light"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.themeDark = !systemCtrl.themeDark;
        }
    }

    // ── Tile 2: Night Light ─────────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf06e" // eye
        title: "Night Light"
        active: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
        statusText: active ? "Warm 4500K" : "Off"
        onClicked: {
            if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                nightLightCtrl.toggleNightLight();
        }
    }

    // ── Tile 3: Stay Awake ──────────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf0f4" // coffee
        title: "Stay Awake"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false
        statusText: active ? "Active" : "Off"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.caffeineActive = !systemCtrl.caffeineActive;
        }
    }

    // ── Tile 4: Microphone ──────────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130"
        title: "Microphone"
        active: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false
        statusText: active ? "Muted" : "Active"
        onClicked: {
            if (typeof audioCtrl !== "undefined" && audioCtrl)
                audioCtrl.toggleSourceMute();
        }
    }

    // ── Tile 5: Screen Capture ──────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf030" // camera
        title: "Screenshot"
        active: false
        statusText: "Region"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.triggerScreenshot();
        }
    }

    // ── Tile 6: Screen Record ───────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf03d" // video
        title: "Screen Record"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false
        statusText: active ? "Recording" : "Ready"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.toggleScreenRecording();
        }
    }

    // ── Tile 7: Game Mode ───────────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf11b" // gamepad
        title: "Game Mode"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false
        statusText: active ? "Performance" : "Standard"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.gameModeActive = !systemCtrl.gameModeActive;
        }
    }

    // ── Tile 8: Airplane Mode ───────────────────────────────────────────────
    TitanActionTile {
        Layout.fillWidth: true
        iconGlyph: "\uf072" // plane
        title: "Airplane Mode"
        active: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.airplaneMode : false
        statusText: active ? "Enabled" : "Off"
        onClicked: {
            if (typeof systemCtrl !== "undefined" && systemCtrl)
                systemCtrl.toggleAirplaneMode();
        }
    }
}

