import QtQuick
import QtQuick.Window
import QtQml

// ShellRoot — lazy host for every titan-shell overlay window.
//
// IMPORTANT: overlays are created with `Instantiator`, NOT `Loader`.
// Since Qt 6.7 a `Window` whose QObject parent is an Item (e.g. a Loader) treats
// that Item as its *visual parent* and refuses to become visible until the Item
// itself lives inside a shown window. Our root has no window, so with Loader
// every overlay stayed hidden forever (shortcuts + hot-zones appeared dead).
// Instantiator is a plain QObject, so the created Window is a real top-level
// surface and LayerShellQt can map it as a layer-shell overlay.
//
// `active: false` destroys the window, freeing its QML scene graph -> low idle RAM.
QtObject {
    id: root

    // ── 1. Spotlight ──────────────────────────────────────────────────────────
    property Instantiator spotlightInst: Instantiator {
        active: shell.spotlightActive
        model: 1
        delegate: Qt.createComponent("qrc:/spotlight/qml/SpotlightWindow.qml")

        onObjectAdded: (index, item) => {
            shell.registerSpotlightWindow(item)
            spotlight.reset()
            spotlight.isClipboardMode = shell.pendingClipboard
            shell.pendingClipboard = false
            item.openSpotlight()
        }
    }

    property Connections spotlightReq: Connections {
        target: shell
        function onReqSpotlightToggle() {
            const w = root.spotlightInst.object
            if (w) w.toggleSpotlight()
        }
        function onReqSpotlightShow() {
            const w = root.spotlightInst.object
            if (w) w.openSpotlight()
        }
        function onReqSpotlightHide() {
            const w = root.spotlightInst.object
            if (w) w.closeSpotlight()
        }
        function onReqSpotlightClipboard() {
            const w = root.spotlightInst.object
            if (w) {
                spotlight.reset()
                spotlight.isClipboardMode = true
                shell.pendingClipboard = false
                w.openSpotlight()
            }
        }
    }

    property Connections spotlightVis: Connections {
        target: root.spotlightInst.object
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            const w = root.spotlightInst.object
            if (w && !w.visible) root.spotlightUnload.restart()
        }
    }

    property Timer spotlightUnload: Timer {
        interval: 500
        onTriggered: {
            const w = root.spotlightInst.object
            if (w && !w.visible) {
                shell.spotlightActive = false
                shell.trimMemory()
            }
        }
    }

    // ── 2. Quick Settings ─────────────────────────────────────────────────────
    property Instantiator qsInst: Instantiator {
        active: shell.quicksettingsActive
        model: 1
        delegate: Qt.createComponent("qrc:/quicksettings/qml/QuickSettingsWindow.qml")

        onObjectAdded: (index, item) => {
            shell.registerQuicksettingsWindow(item)
            if (shell.pendingQsWifi) {
                item.showWifiPage = true
            } else if (shell.pendingQsNotifs) {
                item.showNotificationPanel = true
            }
            shell.pendingQsWifi = false
            shell.pendingQsNotifs = false
            item.openDrawer()
        }
    }

    property Connections qsReq: Connections {
        target: shell
        function onReqQuicksettingsToggle() {
            const w = root.qsInst.object
            if (w) w.toggleDrawer()
        }
        function onReqQuicksettingsShow() {
            const w = root.qsInst.object
            if (w) w.openDrawer()
        }
        function onReqQuicksettingsHide() {
            const w = root.qsInst.object
            if (w) w.closeDrawer()
        }
        function onReqQuicksettingsWifi() {
            const w = root.qsInst.object
            if (w) {
                shell.pendingQsWifi = false
                w.showWifiPage = true
                w.openDrawer()
            }
        }
        function onReqQuicksettingsNotifs() {
            const w = root.qsInst.object
            if (w) {
                shell.pendingQsNotifs = false
                w.showNotificationPanel = true
                w.openDrawer()
            }
        }
    }

    property Connections qsVis: Connections {
        target: root.qsInst.object
        ignoreUnknownSignals: true
        function onDrawerOpenChanged() {
            const w = root.qsInst.object
            if (w && !w.drawerOpen) root.qsUnload.restart()
        }
    }

    property Timer qsUnload: Timer {
        interval: 500
        onTriggered: {
            const w = root.qsInst.object
            if (w && !w.drawerOpen) {
                shell.quicksettingsActive = false
                shell.trimMemory()
            }
        }
    }

    // ── 3. System Monitor ─────────────────────────────────────────────────────
    property Instantiator sysmonInst: Instantiator {
        active: shell.sysmonActive
        model: 1
        delegate: Qt.createComponent("qrc:/sysmon/qml/SystemMonitorWindow.qml")

        onObjectAdded: (index, item) => {
            shell.registerSysmonWindow(item)
            item.openPanel()
        }
    }

    property Connections sysmonReq: Connections {
        target: shell
        function onReqSysmonToggle() {
            const w = root.sysmonInst.object
            if (w) w.togglePanel()
        }
        function onReqSysmonShow() {
            const w = root.sysmonInst.object
            if (w) w.openPanel()
        }
        function onReqSysmonHide() {
            const w = root.sysmonInst.object
            if (w) w.closePanel()
        }
    }

    property Connections sysmonVis: Connections {
        target: root.sysmonInst.object
        ignoreUnknownSignals: true
        function onPanelOpenChanged() {
            const w = root.sysmonInst.object
            if (w && !w.panelOpen) root.sysmonUnload.restart()
        }
    }

    property Timer sysmonUnload: Timer {
        interval: 500
        onTriggered: {
            const w = root.sysmonInst.object
            if (w && !w.panelOpen) {
                shell.sysmonActive = false
                shell.trimMemory()
            }
        }
    }

    // ── 4. Menu ───────────────────────────────────────────────────────────────
    property Instantiator menuInst: Instantiator {
        active: shell.menuActive
        model: 1
        delegate: Qt.createComponent("qrc:/menu/qml/MenuWindow.qml")

        onObjectAdded: (index, item) => {
            shell.registerMenuWindow(item)
            item.openMenu()
        }
    }

    property Connections menuReq: Connections {
        target: shell
        function onReqMenuToggle() {
            const w = root.menuInst.object
            if (w) w.toggleMenu()
        }
        function onReqMenuShow() {
            const w = root.menuInst.object
            if (w) w.openMenu()
        }
        function onReqMenuHide() {
            const w = root.menuInst.object
            if (w) w.closeMenu()
        }
    }

    property Connections menuVis: Connections {
        target: root.menuInst.object
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            const w = root.menuInst.object
            if (w && !w.visible) root.menuUnload.restart()
        }
    }

    property Timer menuUnload: Timer {
        interval: 500
        onTriggered: {
            const w = root.menuInst.object
            if (w && !w.visible) {
                shell.menuActive = false
                shell.trimMemory()
            }
        }
    }

    // ── 5. Workspace HUD ──────────────────────────────────────────────────────
    property Instantiator wsInst: Instantiator {
        active: shell.workspaceHudActive
        model: 1
        delegate: Qt.createComponent("qrc:/workspacehud/qml/WorkspaceHudWindow.qml")

        onObjectAdded: (index, item) => {
            shell.registerWorkspaceHudWindow(item)
            item.openHud()
        }
    }

    property Connections wsReq: Connections {
        target: shell
        function onReqWorkspaceHudToggle() {
            const w = root.wsInst.object
            if (w) w.toggleHud()
        }
        function onReqWorkspaceHudShow() {
            const w = root.wsInst.object
            if (w) w.openHud()
        }
        function onReqWorkspaceHudHide() {
            const w = root.wsInst.object
            if (w) w.closeHud()
        }
    }

    property Connections wsVis: Connections {
        target: root.wsInst.object
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            const w = root.wsInst.object
            if (w && !w.visible) root.wsUnload.restart()
        }
    }

    property Timer wsUnload: Timer {
        interval: 500
        onTriggered: {
            const w = root.wsInst.object
            if (w && !w.visible) {
                shell.workspaceHudActive = false
                shell.trimMemory()
            }
        }
    }
}
