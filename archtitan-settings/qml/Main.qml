import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ArchTitan.TitanUI
import ArchTitanSettings


ApplicationWindow {
    id: root
    width: 1100
    height: 750
    minimumWidth: 820
    minimumHeight: 580
    visible: true
    title: "ArchTitan Settings"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    // ── Design tokens ──────────────────────────────────────────────
    // Single source of truth: the shared ArchTitan.TitanUI design system
    // (Titan Design Language). No palette values are declared locally.
    readonly property bool isDarkTheme: WallpaperManager.isDark

    readonly property color bg0:          TitanTheme.bg0
    readonly property color bg1:          TitanTheme.bg1
    readonly property color bg2:          TitanTheme.bg2
    readonly property color bg3:          TitanTheme.bg3
    readonly property color bg4:          TitanTheme.bg4
    readonly property color border0:      TitanTheme.border
    readonly property color border1:      TitanTheme.borderSubtle
    property color accent:                TitanTheme.accent
    readonly property color accentDim:    TitanTheme.accentSoft
    readonly property color textHigh:     TitanTheme.textHigh
    readonly property color textMid:      TitanTheme.textMid
    readonly property color textLow:      TitanTheme.textLow
    readonly property color green:        TitanTheme.success
    readonly property color red:          TitanTheme.danger
    readonly property color orange:       TitanTheme.warning
    readonly property color purple:       TitanTheme.mauve

    // Legacy page-body aliases (resolved up the component scope chain).
    readonly property color globalBg0:     TitanTheme.bg0
    readonly property color globalBg1:     TitanTheme.bg1
    readonly property color globalBg2:     TitanTheme.bg2
    readonly property color globalBg3:     TitanTheme.bg3
    readonly property color globalBg4:     TitanTheme.bg4
    readonly property color globalBorder0: TitanTheme.border
    readonly property color globalBorder1: TitanTheme.borderSubtle

    // Material-3-ish surface roles used by the host desktop's settings panel:
    // dark canvas + one lifted, rounded surface container for the content.
    readonly property color m3Background: TitanTheme.crust
    readonly property color m3Surface:    TitanTheme.bg1
    readonly property color m3Outline:    TitanTheme.border

    property bool railExpanded: true
    property int currentPage: 0

    readonly property var pages: [
        { name: "Appearance", icon: "appearance", source: "qrc:/ArchTitanSettings/qml/pages/AppearancePage.qml" },
        { name: "Display",    icon: "display",    source: "qrc:/ArchTitanSettings/qml/pages/DisplayPage.qml"    },
        { name: "Network",    icon: "network",    source: "qrc:/ArchTitanSettings/qml/pages/NetworkPage.qml"    },
        { name: "Audio",      icon: "audio",      source: "qrc:/ArchTitanSettings/qml/pages/AudioPage.qml"      },
        { name: "Power",      icon: "power",      source: "qrc:/ArchTitanSettings/qml/pages/PowerPage.qml"      },
        { name: "Security",   icon: "security",   source: "qrc:/ArchTitanSettings/qml/pages/SecurityPage.qml"   },
        { name: "System",     icon: "system",     source: "qrc:/ArchTitanSettings/qml/pages/SystemPage.qml"     },
        { name: "About",      icon: "about",      source: "qrc:/ArchTitanSettings/qml/pages/AboutPage.qml"      }
    ]

    // ── Window shell ───────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        radius: 18
        color: root.m3Background
        border.width: 1
        border.color: root.m3Outline
        clip: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Title bar (also the drag handle) ──────────────────
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 46

                MouseArea {
                    id: titleDrag
                    anchors.fill: parent
                    property point dragStart
                    onPressed: (mouse) => { dragStart = Qt.point(mouse.x, mouse.y) }
                    onPositionChanged: (mouse) => {
                        root.x += mouse.x - dragStart.x
                        root.y += mouse.y - dragStart.y
                    }
                    onDoubleClicked: {
                        if (root.visibility === ApplicationWindow.Maximized)
                            root.showNormal()
                        else
                            root.showMaximized()
                    }
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 22
                        verticalCenter: parent.verticalCenter
                    }
                    text: "Settings"
                    font { pixelSize: 13; family: "Inter"; weight: Font.DemiBold }
                    color: root.textMid
                }

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 84
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.pages[root.currentPage].name
                    font { pixelSize: 13; family: "Inter"; weight: Font.Medium }
                    color: root.textHigh
                }

                RowLayout {
                    anchors {
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    spacing: 4

                    Repeater {
                        model: [
                            { act: "minimize", sym: "−", tip: "Minimize" },
                            { act: "maximize", sym: "□", tip: "Maximize" },
                            { act: "close",    sym: "×", tip: "Close"    }
                        ]
                        delegate: Item {
                            width: 30; height: 30
                            Rectangle {
                                anchors.fill: parent
                                radius: 15
                                color: winHover.containsMouse
                                       ? (modelData.act === "close" ? TitanTheme.danger : root.bg4)
                                       : "transparent"
                                Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
                            }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.sym
                                font { pixelSize: 15; family: "Inter"; weight: Font.Medium }
                                color: winHover.containsMouse ? root.textHigh : root.textMid
                            }
                            MouseArea {
                                id: winHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.act === "close")    root.close()
                                    else if (modelData.act === "minimize") root.showMinimized()
                                    else {
                                        if (root.visibility === ApplicationWindow.Maximized) root.showNormal()
                                        else root.showMaximized()
                                    }
                                }
                            }
                            ToolTip { visible: winHover.containsMouse; text: modelData.tip; delay: 500 }
                        }
                    }
                }
            }

            // ── Body: navigation rail + content surface ───────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8

                // Navigation rail
                Item {
                    Layout.preferredWidth: root.railExpanded ? 154 : 72
                    Layout.fillHeight: true
                    Layout.leftMargin: 8
                    Layout.bottomMargin: 8

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2

                        // Brand FAB — tapping it jumps to About
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.topMargin: 4
                            Layout.bottomMargin: 6
                            width: 46; height: 46
                            radius: 23
                            color: brandHover.containsMouse ? TitanTheme.accentHover : TitanTheme.accent
                            border.width: 1
                            border.color: TitanTheme.accentEdge
                            Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

                            Image {
                                anchors.centerIn: parent
                                width: 27; height: 27
                                source: "qrc:/ArchTitanSettings/assets/icons/LOGO.png"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                            }
                            MouseArea {
                                id: brandHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentPage = root.pages.length - 1
                            }
                            ToolTip { visible: brandHover.containsMouse; text: "About ArchTitan"; delay: 500 }
                        }

                        // Rail expand / collapse toggle
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            Rectangle {
                                anchors.centerIn: parent
                                width: 30; height: 30
                                radius: 15
                                color: railHover.containsMouse ? root.bg4 : "transparent"
                                Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }
                                Text {
                                    anchors.centerIn: parent
                                    text: root.railExpanded ? "‹" : "›"
                                    font { pixelSize: 17; family: "Inter" }
                                    color: root.textMid
                                }
                            }
                            MouseArea {
                                id: railHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.railExpanded = !root.railExpanded
                            }
                            ToolTip {
                                visible: railHover.containsMouse
                                text: root.railExpanded ? "Collapse rail" : "Expand rail"
                                delay: 500
                            }
                        }

                        // Nav destinations
                        Repeater {
                            model: root.pages
                            delegate: NavRailItem {
                                Layout.fillWidth: true
                                iconSource: "qrc:/ArchTitanSettings/assets/icons/" + modelData.icon + ".svg"
                                label: modelData.name
                                active: root.currentPage === index
                                expanded: root.railExpanded
                                onClicked: root.currentPage = index
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // Rounded content surface
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.rightMargin: 8
                    Layout.bottomMargin: 8
                    radius: 12
                    color: root.m3Surface
                    border.width: 1
                    border.color: root.border1
                    clip: true

                    Loader {
                        id: pageLoader
                        anchors.fill: parent
                        anchors.topMargin: 8
                        opacity: 1
                        source: root.pages[0].source

                        onLoaded: {
                            if (item)
                                item.anchors.fill = pageLoader
                        }
                    }

                    // Fade + slide, matching the host settings panel
                    SequentialAnimation {
                        id: switchAnim

                        NumberAnimation {
                            target: pageLoader
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: 100
                            easing.type: Easing.InQuad
                        }
                        PropertyAction {
                            target: pageLoader
                            property: "source"
                            value: root.pages[root.currentPage].source
                        }
                        ParallelAnimation {
                            NumberAnimation {
                                target: pageLoader
                                property: "opacity"
                                from: 0
                                to: 1
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                            NumberAnimation {
                                target: pageLoader
                                property: "anchors.topMargin"
                                from: 20
                                to: 8
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }
                    }

                    Connections {
                        target: root
                        function onCurrentPageChanged() {
                            switchAnim.stop()
                            switchAnim.start()
                        }
                    }
                }
            }
        }
    }

    // ── Power profile switch toast overlay ─────────────────────────────────
    property var _profileMeta: {
        var p = SettingsBackend.powerProfile;
        if (p === "Performance")
            return { icon: "qrc:/ArchTitanSettings/assets/icons/performance_nobg.png",
                     label: "Performance", accent: TitanTheme.danger, colorize: false }
        if (p === "Power Saver")
            return { icon: "qrc:/ArchTitanSettings/assets/icons/powersaving.png",
                     label: "Power Saver", accent: TitanTheme.success, colorize: false }
        return { icon: "qrc:/ArchTitanSettings/assets/icons/balanced.png",
                 label: "Balanced", accent: TitanTheme.info, colorize: false }
    }

    Item {
        id: profileToast
        anchors.fill: parent
        opacity: 0
        z: 999
        visible: opacity > 0

        // Backdrop tint
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.53)
            radius: 18
        }

        // Central card
        Rectangle {
            anchors.centerIn: parent
            width: 240; height: 220
            radius: 24
            color: Qt.rgba(TitanTheme.bg0.r, TitanTheme.bg0.g, TitanTheme.bg0.b, 0.85)
            border.width: 1
            border.color: root._profileMeta.accent

            // Outer glow ring
            Rectangle {
                anchors.centerIn: parent
                width: parent.width + 6; height: parent.height + 6
                radius: parent.radius + 3
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(
                    Qt.color(root._profileMeta.accent).r,
                    Qt.color(root._profileMeta.accent).g,
                    Qt.color(root._profileMeta.accent).b,
                    0.35)
                z: -1
            }

            Column {
                anchors.centerIn: parent
                spacing: 18

                // Icon container — pops in large
                Rectangle {
                    id: iconBox
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 120; height: 120; radius: 28
                    color: Qt.rgba(
                        Qt.color(root._profileMeta.accent).r,
                        Qt.color(root._profileMeta.accent).g,
                        Qt.color(root._profileMeta.accent).b,
                        0.18)
                    border.width: 1
                    border.color: Qt.rgba(
                        Qt.color(root._profileMeta.accent).r,
                        Qt.color(root._profileMeta.accent).g,
                        Qt.color(root._profileMeta.accent).b,
                        0.5)
                    scale: 0.1   // starts tiny, springs up via iconPopAnim

                    SequentialAnimation {
                        id: iconPopAnim
                        NumberAnimation {
                            target: iconBox; property: "scale"
                            from: 0.1; to: 1.12
                            duration: 280; easing.type: Easing.OutBack; easing.overshoot: 1.8
                        }
                        NumberAnimation {
                            target: iconBox; property: "scale"
                            to: 1.0; duration: 120; easing.type: Easing.InOutQuad
                        }
                    }

                    Image {
                        anchors.centerIn: parent
                        width: 88; height: 88
                        source: root._profileMeta.icon
                        fillMode: Image.PreserveAspectFit
                        smooth: true; mipmap: true
                    }
                }

                // Label
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 4

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "PROFILE SWITCHED"
                        font { pixelSize: 9; family: "Inter" }
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.6
                        color: TitanTheme.textLow
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root._profileMeta.label
                        font { pixelSize: 20; family: "Inter" }
                        font.weight: Font.Bold
                        color: root._profileMeta.accent
                    }
                }
            }
        }

        // Fade-in → hold → fade-out
        SequentialAnimation {
            id: toastAnim
            NumberAnimation { target: profileToast; property: "opacity"; to: 1.0; duration: 220; easing.type: Easing.OutCubic }
            PauseAnimation  { duration: 2200 }
            NumberAnimation { target: profileToast; property: "opacity"; to: 0.0; duration: 380; easing.type: Easing.InCubic }
        }
    }

    // Watch for profile changes and trigger toast + icon pop
    Connections {
        target: SettingsBackend
        function onPowerProfileChanged() {
            toastAnim.stop()
            iconPopAnim.stop()
            profileToast.opacity = 0
            iconBox.scale = 0.1
            toastAnim.start()
            iconPopAnim.start()
        }
    }
}
