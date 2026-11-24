import QtQuick
import QtQuick.Window
import QtQml

// FocusRoot — lazy top-level host for TitanFocus overlay windows.
// Uses Instantiator (plain QObject parent) so created Windows are genuine
// top-level Wayland layer-shell surfaces, and `active: false` destroys the
// scene graph when hidden to keep idle daemon RAM minimal.
QtObject {
    id: root

    // ── 1. Focus Pill Overlay ────────────────────────────────────────────────
    property Instantiator pillInst: Instantiator {
        active: focusCtrl.pillActive
        model: 1
        delegate: Qt.createComponent("qrc:/qml/FocusPill.qml")

        onObjectAdded: (index, item) => {
            focusCtrl.registerPillWindow(item)
            item.openPill()
        }
    }

    property Connections pillReq: Connections {
        target: focusCtrl
        function onReqPillToggle() {
            const w = root.pillInst.object
            if (w) w.togglePill()
        }
        function onReqPillShow() {
            const w = root.pillInst.object
            if (w) w.openPill()
        }
        function onReqPillHide() {
            const w = root.pillInst.object
            if (w) w.closePill()
        }
    }

    property Connections pillVis: Connections {
        target: root.pillInst.object
        ignoreUnknownSignals: true
        function onPillOpenChanged() {
            const w = root.pillInst.object
            if (w && !w.pillOpen) root.pillUnload.restart()
        }
    }

    property Timer pillUnload: Timer {
        interval: 350
        onTriggered: {
            const w = root.pillInst.object
            if (w && !w.pillOpen) {
                focusCtrl.pillActive = false
                focusCtrl.trimMemory()
            }
        }
    }

    // ── 2. Break Countdown Overlay ───────────────────────────────────────────
    property Instantiator breakInst: Instantiator {
        active: focusCtrl.breakActive
        model: 1
        delegate: Qt.createComponent("qrc:/qml/BreakOverlay.qml")

        onObjectAdded: (index, item) => {
            focusCtrl.registerBreakWindow(item)
            item.visible = true
        }
    }
}
