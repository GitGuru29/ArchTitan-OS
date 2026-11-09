import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * CircularActionGrid — Dynamic 4-column grid of 100% Circular Action Buttons.
 *
 * Symmetrically lays out all enabled action buttons across 4 columns (25% cell widths).
 * Fully integrated with ArchTitan's "Edit Quick Panel" customizer:
 * - Focus / DND
 * - Dark Theme
 * - Night Light
 * - Microphone Mute
 * - Caffeine / Stay Awake
 * - Screen Capture
 * - Screen Record
 * - Color Picker (Hyprpicker)
 * - Game Mode
 * - Clipboard History
 * - Virtual Keyboard
 * - Airplane Mode
 */
GridLayout {
    id: gridRoot
    Layout.fillWidth: true
    columns: 4
    columnSpacing: 0
    rowSpacing: 14

    property bool dndActive: false
    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    readonly property var actionMap: ({
        "focus":        { key: "focus",        icon: "\uf186", label: "Focus",       color: TitanTheme.lavender },
        "dark":         { key: "dark",         icon: "\uf042", label: "Dark",        color: TitanTheme.accent },
        "night":        { key: "night",        icon: "\uf06e", label: "Night",       color: TitanTheme.peach },
        "mic":          { key: "mic",          icon: "\uf130", label: "Mic",         color: TitanTheme.red },
        "caffeine":     { key: "caffeine",     icon: "\uf0f4", label: "Awake",       color: TitanTheme.yellow },
        "capture":      { key: "capture",      icon: "\uf030", label: "Screenshot",  color: TitanTheme.cyan },
        "record":       { key: "record",       icon: "\uf03d", label: "Record",      color: TitanTheme.red },
        "colorPick":    { key: "colorPick",    icon: "\uf1fb", label: "Picker",      color: TitanTheme.teal },
        "gameMode":     { key: "gameMode",     icon: "\uf11b", label: "Game",        color: TitanTheme.accentBlue },
        "clipboard":    { key: "clipboard",    icon: "\uf0ea", label: "Clipboard",   color: TitanTheme.lavender },
        "virtualInput": { key: "virtualInput", icon: "\uf11c", label: "Keyboard",    color: TitanTheme.peach },
        "airplane":     { key: "airplane",     icon: "\uf072", label: "Airplane",    color: TitanTheme.red }
    })

    property var visibleActions: {
        var rev = revision;
        var order = (typeof systemCtrl !== "undefined" && systemCtrl)
                    ? systemCtrl.getActionOrder()
                    : ["focus", "dark", "night", "mic", "caffeine", "capture", "record", "colorPick", "gameMode", "clipboard", "virtualInput", "airplane"];
        var list = [];
        for (var i = 0; i < order.length; ++i) {
            var k = order[i];
            var item = actionMap[k];
            if (item) {
                var isVisible = true;
                if (typeof systemCtrl !== "undefined" && systemCtrl) {
                    isVisible = systemCtrl.getTileVisible(k, true);
                }
                if (isVisible) {
                    list.push(item);
                }
            }
        }
        return list;
    }

    Repeater {
        model: gridRoot.visibleActions

        delegate: OneUICircleButton {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter

            iconGlyph: {
                if (modelData.key === "mic") {
                    return (typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sourceMuted) ? "\uf131" : "\uf130";
                }
                return modelData.icon;
            }

            label: modelData.label

            active: {
                var k = modelData.key;
                if (k === "focus") return gridRoot.dndActive;
                if (k === "dark") return (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true;
                if (k === "night") return (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false;
                if (k === "mic") return (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sourceMuted : false;
                if (k === "caffeine") return (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.caffeineActive : false;
                if (k === "record") return (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.screenRecordingActive : false;
                if (k === "gameMode") return (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.gameModeActive : false;
                if (k === "airplane") return (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.airplaneMode : false;
                return false;
            }

            activeColor: modelData.color

            onClicked: {
                var k = modelData.key;
                if (k === "focus") {
                    gridRoot.dndActive = !gridRoot.dndActive;
                } else if (k === "dark") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.themeDark = !systemCtrl.themeDark;
                } else if (k === "night") {
                    if (typeof nightLightCtrl !== "undefined" && nightLightCtrl) nightLightCtrl.toggleNightLight();
                } else if (k === "mic") {
                    if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.toggleSourceMute();
                } else if (k === "caffeine") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.caffeineActive = !systemCtrl.caffeineActive;
                } else if (k === "capture") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.takeScreenshot();
                } else if (k === "record") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleScreenRecording();
                } else if (k === "colorPick") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.pickColor();
                } else if (k === "gameMode") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.gameModeActive = !systemCtrl.gameModeActive;
                } else if (k === "clipboard") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.openClipboard();
                } else if (k === "virtualInput") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleVirtualKeyboard();
                } else if (k === "airplane") {
                    if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.toggleAirplaneMode();
                }
            }
        }
    }
}
