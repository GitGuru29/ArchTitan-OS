import QtQuick
import QtQuick.Window

Item {
    id: root
    visible: false

    // ── 1. Spotlight ──────────────────────────────────────────────────────────
    Loader {
        id: spotlightLoader
        active: shell.spotlightActive
        asynchronous: false
        source: "qrc:/spotlight/qml/SpotlightWindow.qml"

        onLoaded: {
            if (item) {
                shell.registerSpotlightWindow(item)
                if (shell.pendingClipboard) {
                    shell.pendingClipboard = false
                    spotlight.reset()
                    spotlight.isClipboardMode = true
                } else {
                    spotlight.reset()
                    spotlight.isClipboardMode = false
                }
                item.openSpotlight()
            }
        }

        Connections {
            target: shell
            function onReqSpotlightToggle() {
                if (spotlightLoader.item) {
                    spotlightLoader.item.toggleSpotlight()
                }
            }
            function onReqSpotlightShow() {
                if (spotlightLoader.item) {
                    spotlightLoader.item.openSpotlight()
                }
            }
            function onReqSpotlightHide() {
                if (spotlightLoader.item) {
                    spotlightLoader.item.closeSpotlight()
                }
            }
            function onReqSpotlightClipboard() {
                if (spotlightLoader.item) {
                    spotlight.reset()
                    spotlight.isClipboardMode = true
                    spotlightLoader.item.openSpotlight()
                }
            }
        }

        Connections {
            target: spotlightLoader.item
            function onVisibleChanged() {
                if (spotlightLoader.item && !spotlightLoader.item.visible) {
                    spotlightUnloadTimer.start()
                }
            }
        }

        Timer {
            id: spotlightUnloadTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (spotlightLoader.item && !spotlightLoader.item.visible) {
                    shell.spotlightActive = false
                }
            }
        }
    }

    // ── 2. Quick Settings ─────────────────────────────────────────────────────
    Loader {
        id: qsLoader
        active: shell.quicksettingsActive
        asynchronous: false
        source: "qrc:/quicksettings/qml/QuickSettingsWindow.qml"

        onLoaded: {
            if (item) {
                shell.registerQuicksettingsWindow(item)
                if (shell.pendingQsWifi) {
                    shell.pendingQsWifi = false
                    item.showWifiPage = true
                } else if (shell.pendingQsNotifs) {
                    shell.pendingQsNotifs = false
                    item.showNotificationPanel = true
                }
                item.openDrawer()
            }
        }

        Connections {
            target: shell
            function onReqQuicksettingsToggle() {
                if (qsLoader.item) qsLoader.item.toggleDrawer()
            }
            function onReqQuicksettingsShow() {
                if (qsLoader.item) qsLoader.item.openDrawer()
            }
            function onReqQuicksettingsHide() {
                if (qsLoader.item) qsLoader.item.closeDrawer()
            }
            function onReqQuicksettingsWifi() {
                if (qsLoader.item) {
                    qsLoader.item.showWifiPage = true
                    qsLoader.item.openDrawer()
                }
            }
            function onReqQuicksettingsNotifs() {
                if (qsLoader.item) {
                    qsLoader.item.showNotificationPanel = true
                    qsLoader.item.openDrawer()
                }
            }
        }

        Connections {
            target: qsLoader.item
            function onDrawerOpenChanged() {
                if (qsLoader.item && !qsLoader.item.drawerOpen) {
                    qsUnloadTimer.start()
                }
            }
        }

        Timer {
            id: qsUnloadTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (qsLoader.item && !qsLoader.item.drawerOpen) {
                    shell.quicksettingsActive = false
                }
            }
        }
    }

    // ── 3. System Monitor ─────────────────────────────────────────────────────
    Loader {
        id: sysmonLoader
        active: shell.sysmonActive
        asynchronous: false
        source: "qrc:/sysmon/qml/SystemMonitorWindow.qml"

        onLoaded: {
            if (item) {
                shell.registerSysmonWindow(item)
                item.openPanel()
            }
        }

        Connections {
            target: shell
            function onReqSysmonToggle() {
                if (sysmonLoader.item) sysmonLoader.item.togglePanel()
            }
            function onReqSysmonShow() {
                if (sysmonLoader.item) sysmonLoader.item.openPanel()
            }
            function onReqSysmonHide() {
                if (sysmonLoader.item) sysmonLoader.item.closePanel()
            }
        }

        Connections {
            target: sysmonLoader.item
            function onPanelOpenChanged() {
                if (sysmonLoader.item && !sysmonLoader.item.panelOpen) {
                    sysmonUnloadTimer.start()
                }
            }
        }

        Timer {
            id: sysmonUnloadTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (sysmonLoader.item && !sysmonLoader.item.panelOpen) {
                    shell.sysmonActive = false
                }
            }
        }
    }

    // ── 4. Menu ───────────────────────────────────────────────────────────────
    Loader {
        id: menuLoader
        active: shell.menuActive
        asynchronous: false
        source: "qrc:/menu/qml/MenuWindow.qml"

        onLoaded: {
            if (item) {
                shell.registerMenuWindow(item)
                item.openMenu()
            }
        }

        Connections {
            target: shell
            function onReqMenuToggle() {
                if (menuLoader.item) menuLoader.item.toggleMenu()
            }
            function onReqMenuShow() {
                if (menuLoader.item) menuLoader.item.openMenu()
            }
            function onReqMenuHide() {
                if (menuLoader.item) menuLoader.item.closeMenu()
            }
        }

        Connections {
            target: menuLoader.item
            function onVisibleChanged() {
                if (menuLoader.item && !menuLoader.item.visible) {
                    menuUnloadTimer.start()
                }
            }
        }

        Timer {
            id: menuUnloadTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (menuLoader.item && !menuLoader.item.visible) {
                    shell.menuActive = false
                }
            }
        }
    }

    // ── 5. Workspace HUD ──────────────────────────────────────────────────────
    Loader {
        id: wsLoader
        active: shell.workspaceHudActive
        asynchronous: false
        source: "qrc:/workspacehud/qml/WorkspaceHudWindow.qml"

        onLoaded: {
            if (item) {
                shell.registerWorkspaceHudWindow(item)
                item.openHud()
            }
        }

        Connections {
            target: shell
            function onReqWorkspaceHudToggle() {
                if (wsLoader.item) wsLoader.item.toggleHud()
            }
            function onReqWorkspaceHudShow() {
                if (wsLoader.item) wsLoader.item.openHud()
            }
            function onReqWorkspaceHudHide() {
                if (wsLoader.item) wsLoader.item.closeHud()
            }
        }

        Connections {
            target: wsLoader.item
            function onVisibleChanged() {
                if (wsLoader.item && !wsLoader.item.visible) {
                    wsUnloadTimer.start()
                }
            }
        }

        Timer {
            id: wsUnloadTimer
            interval: 500
            repeat: false
            onTriggered: {
                if (wsLoader.item && !wsLoader.item.visible) {
                    shell.workspaceHudActive = false
                }
            }
        }
    }
}
