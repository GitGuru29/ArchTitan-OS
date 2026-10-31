import QtQuick
import QtQuick.Window
import QtQuick.Effects
import ArchTitan.TitanUI
import "components"

/**
 * titan-menu — ArchTitan system menu & command palette.
 *
 * Supports both Grid View and List View with a Liquid Glass aesthetic.
 */
Window {
    id: root

    width: Screen.width
    height: Screen.height

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false
    title: "titan-menu"

    property bool menuOpen: false
    property string viewMode: "grid" // "grid" | "list"
    property int selectedIndex: 0
    readonly property int gridCols: viewMode === "grid" ? 3 : 1

    readonly property int rowHeight: 54
    readonly property int rowGap: 3
    readonly property int maxRows: 8

    function openMenu() {
        menu.reset();
        selectedIndex = 0;
        menuOpen = true;
        visible = true;
        requestActivate();
        Qt.callLater(function () { searchInput.forceActiveFocus(); });
    }
    function closeMenu() {
        menuOpen = false;
        closeTimer.restart();
    }
    function toggleMenu() {
        if (menuOpen) closeMenu();
        else openMenu();
    }

    function moveSelection(delta) {
        const n = menu.entries.length;
        if (n === 0) return;
        selectedIndex = (selectedIndex + delta + n) % n;
        syncScroll();
    }

    function syncScroll() {
        if (viewMode === "grid") {
            grid.currentIndex = selectedIndex;
            grid.positionViewAtIndex(selectedIndex, GridView.Contain);
        } else {
            list.currentIndex = selectedIndex;
            list.positionViewAtIndex(selectedIndex, ListView.Contain);
        }
    }

    Timer {
        id: closeTimer
        interval: 180
        onTriggered: if (!root.menuOpen) root.visible = false
    }

    Connections {
        target: menu
        function onCloseRequested() { root.closeMenu(); }
        function onEntriesChanged() {
            root.selectedIndex = menu.entries.length > 0 ? 0 : -1;
            root.syncScroll();
        }
        function onQueryChanged() {
            if (searchInput.text !== menu.query) searchInput.text = menu.query;
        }
    }

    // ── Scrim ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.50)
        opacity: root.menuOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeMenu()
        }
    }

    // ── Liquid Glass Card ────────────────────────────────────────────────────
    Item {
        id: card
        width: 720
        height: cardBody.height
        x: (parent.width - width) / 2
        y: parent.height * 0.15

        opacity: root.menuOpen ? 1.0 : 0.0
        scale: root.menuOpen ? 1.0 : 0.96
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
        Behavior on scale { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingEmphasis } }

        // Swallow clicks so they do not reach the scrim underneath.
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: cardBody
            width: parent.width
            height: header.height + divider.height + contentArea.height + footer.height + 2 * TitanTheme.space2
            radius: 26
            border.width: 1.5
            border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.42)

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.62) }
                GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.50) }
            }

            // 3D Glass Specular Sheen (Curved top-light wash)
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: Math.min(parent.height * 0.45, 190)
                radius: cardBody.radius
                z: 0
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                    GradientStop { position: 0.40; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Top Specular Horizon Glint
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 48
                height: 1.5
                radius: 1
                z: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, 0.20) }
                    GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.55) }
                    GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.20) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.7)
                shadowBlur: 0.9
                shadowVerticalOffset: 14
                autoPaddingEnabled: true
            }

            Behavior on height { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

            // ── Search header + Layout Switcher ──────────────────────────────
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64

                Rectangle {
                    id: searchBadge
                    width: 38
                    height: 38
                    radius: 12
                    anchors.left: parent.left
                    anchors.leftMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.42)

                    TitanIcon {
                        anchors.centerIn: parent
                        glyph: "\uf002"
                        size: 16
                        color: TitanTheme.accent
                    }
                }

                // Breadcrumb chip: where we are when drilled into a group.
                Rectangle {
                    id: crumb
                    visible: menu.breadcrumb !== ""
                    anchors.left: searchBadge.right
                    anchors.leftMargin: TitanTheme.space3
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    width: visible ? crumbText.implicitWidth + 20 : 0
                    radius: TitanTheme.radiusPill
                    color: TitanTheme.accentSoft
                    border.width: 1
                    border.color: TitanTheme.accentEdge

                    Text {
                        id: crumbText
                        anchors.centerIn: parent
                        text: menu.breadcrumb
                        color: TitanTheme.accent
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: TitanTheme.sizeLabel
                        font.weight: TitanTheme.weightSemiBold
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: menu.back()
                    }
                }

                // Segmented Grid / List View Switcher
                Rectangle {
                    id: viewSwitcher
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    height: 34
                    width: switcherRow.implicitWidth + 8
                    radius: 11
                    color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.36) : Qt.rgba(0, 0, 0, 0.06)
                    border.width: 1
                    border.color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)

                    Row {
                        id: switcherRow
                        anchors.centerIn: parent
                        spacing: 3

                        Repeater {
                            model: [
                                { mode: "grid", icon: "󰕰", label: "Grid" },
                                { mode: "list", icon: "󰉹", label: "List" }
                            ]

                            delegate: Rectangle {
                                id: modePill
                                required property var modelData
                                readonly property bool active: root.viewMode === modelData.mode

                                height: 26
                                width: pillRow.implicitWidth + 16
                                radius: 8
                                color: active
                                       ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.24)
                                       : (pillMouse.containsMouse
                                          ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05))
                                          : "transparent")
                                border.width: active ? 1 : 0
                                border.color: active ? TitanTheme.accent : "transparent"

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modePill.modelData.icon
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 13
                                        color: modePill.active ? TitanTheme.accent : TitanTheme.textMid
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: modePill.modelData.label
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: modePill.active ? Font.Bold : Font.Medium
                                        color: modePill.active ? TitanTheme.textHigh : TitanTheme.textMid
                                    }
                                }

                                MouseArea {
                                    id: pillMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.viewMode = modePill.modelData.mode;
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    anchors.left: crumb.visible ? crumb.right : searchBadge.right
                    anchors.leftMargin: TitanTheme.space3
                    anchors.right: viewSwitcher.left
                    anchors.rightMargin: TitanTheme.space3
                    anchors.verticalCenter: parent.verticalCenter
                    color: TitanTheme.textHigh
                    selectionColor: TitanTheme.accentEdge
                    selectedTextColor: TitanTheme.textOnAccent
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeTitle + 2
                    clip: true
                    focus: true

                    onTextEdited: menu.query = text

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: searchInput.text === ""
                        text: menu.atRoot ? "Search everything, or pick a category\u2026"
                                          : "Filter\u2026"
                        color: TitanTheme.textLow
                        font: searchInput.font
                    }

                    Keys.onPressed: function (e) {
                        const ctrl = (e.modifiers & Qt.ControlModifier) !== 0;
                        if (e.key === Qt.Key_Down || (ctrl && e.key === Qt.Key_N) || (ctrl && e.key === Qt.Key_J)) {
                            root.moveSelection(root.gridCols); e.accepted = true;
                        } else if (e.key === Qt.Key_Up || (ctrl && e.key === Qt.Key_P) || (ctrl && e.key === Qt.Key_K)) {
                            root.moveSelection(-root.gridCols); e.accepted = true;
                        } else if (e.key === Qt.Key_Tab) {
                            root.viewMode = (root.viewMode === "grid" ? "list" : "grid"); e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            menu.activate(root.selectedIndex); e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            menu.back(); e.accepted = true;
                        } else if (e.key === Qt.Key_Backspace && searchInput.text === "" && !menu.atRoot) {
                            menu.back(); e.accepted = true;
                        } else if (e.key === Qt.Key_Left && searchInput.text === "") {
                            if (root.viewMode === "grid") root.moveSelection(-1);
                            else if (!menu.atRoot) menu.back();
                            e.accepted = true;
                        } else if (e.key === Qt.Key_Right && searchInput.cursorPosition === searchInput.text.length) {
                            if (root.viewMode === "grid" && searchInput.text === "") root.moveSelection(1);
                            else menu.enter(root.selectedIndex);
                            e.accepted = true;
                        }
                    }
                }
            }

            // ── Content Area (Grid View or List View) ────────────────────────
            Item {
                id: contentArea
                anchors.top: header.bottom
                anchors.topMargin: TitanTheme.space2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: TitanTheme.space2
                anchors.rightMargin: TitanTheme.space2
                height: menu.entries.length === 0
                        ? 88
                        : (root.viewMode === "grid"
                           ? Math.min(Math.ceil(menu.entries.length / 3) * 114, 342)
                           : Math.min(menu.entries.length, root.maxRows) * (root.rowHeight + root.rowGap) - root.rowGap)
                Behavior on height { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

                // GRID VIEW
                GridView {
                    id: grid
                    visible: root.viewMode === "grid" && menu.entries.length > 0
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    cellWidth: 230
                    cellHeight: 112
                    model: menu.entries
                    clip: true
                    currentIndex: root.selectedIndex
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Item {
                        id: tileDelegate
                        required property int index
                        required property var modelData
                        width: grid.cellWidth
                        height: grid.cellHeight

                        readonly property bool current: index === root.selectedIndex

                        scale: tileHover.pressed ? 0.96 : ((current || tileHover.containsMouse) ? 1.03 : 1.0)
                        transform: Translate {
                            y: (tileDelegate.current || tileHover.containsMouse) ? -2 : 0
                            Behavior on y { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                        Behavior on scale { NumberAnimation { duration: 130; easing.type: Easing.OutBack } }

                        // 3D Drop Shadow behind tile
                        Rectangle {
                            anchors.fill: gridTile
                            anchors.topMargin: tileDelegate.current ? 4 : (tileHover.containsMouse ? 3 : 2)
                            anchors.bottomMargin: tileDelegate.current ? -4 : (tileHover.containsMouse ? -3 : -2)
                            radius: gridTile.radius + 1
                            z: -2
                            color: Qt.rgba(0, 0, 0, tileDelegate.current ? 0.55 : (tileHover.containsMouse ? 0.45 : 0.30))
                        }

                        // Outer glowing halo
                        Rectangle {
                            anchors.fill: gridTile
                            anchors.margins: -2
                            radius: gridTile.radius + 2
                            z: -1
                            color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.22)
                            visible: tileDelegate.current || tileHover.containsMouse
                            opacity: tileDelegate.current ? 1.0 : (tileHover.containsMouse ? 0.50 : 0.0)
                        }

                        Rectangle {
                            id: gridTile
                            anchors.centerIn: parent
                            width: parent.width - 10
                            height: parent.height - 8
                            radius: 18

                            readonly property bool current: tileDelegate.current

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: gridTile.current
                                           ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.26)
                                           : (tileHover.containsMouse
                                              ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                                              : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(1, 1, 1, 0.70)))
                                }
                                GradientStop {
                                    position: 1.0
                                    color: gridTile.current
                                           ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.11)
                                           : (tileHover.containsMouse
                                              ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                                              : (TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.50) : Qt.rgba(1, 1, 1, 0.50)))
                                }
                            }

                            border.width: gridTile.current ? 1.5 : (tileHover.containsMouse ? 1 : 0)
                            border.color: gridTile.current
                                          ? TitanTheme.accent
                                          : (tileHover.containsMouse
                                             ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.40)
                                             : "transparent")

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                spacing: 6

                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: 12
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: gridTile.current ? TitanTheme.accentSoft : Qt.rgba(0, 0, 0, 0.35)
                                    border.width: gridTile.current ? 1 : 0
                                    border.color: gridTile.current ? TitanTheme.accentEdge : "transparent"

                                    // Subtle pedestal shadow
                                    Rectangle {
                                        anchors.fill: parent
                                        anchors.topMargin: 2
                                        anchors.bottomMargin: -2
                                        radius: parent.radius
                                        z: -1
                                        color: Qt.rgba(0, 0, 0, 0.25)
                                    }

                                    TitanIcon {
                                        anchors.centerIn: parent
                                        glyph: modelData.icon
                                        size: 18
                                        color: gridTile.current ? TitanTheme.accent : TitanTheme.textMid
                                    }
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.title
                                    elide: Text.ElideRight
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 13
                                    font.weight: gridTile.current ? Font.Bold : Font.DemiBold
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.crumb !== "" ? modelData.crumb : modelData.hint
                                    elide: Text.ElideRight
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                id: tileHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selectedIndex = index
                                onClicked: menu.activate(index)
                            }
                        }
                    }
                }

                // LIST VIEW
                ListView {
                    id: list
                    visible: root.viewMode === "list" && menu.entries.length > 0
                    anchors.fill: parent
                    model: menu.entries
                    spacing: root.rowGap
                    clip: true
                    currentIndex: root.selectedIndex
                    interactive: count > root.maxRows
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: MenuRow {
                        required property int index
                        required property var modelData
                        width: list.width
                        entry: modelData
                        current: index === root.selectedIndex
                        onHovered: root.selectedIndex = index
                        onClicked: menu.activate(index)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: menu.entries.length === 0
                    text: "No matches for \u201C" + menu.query + "\u201D"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeBody
                }
            }

            // ── Footer hints ─────────────────────────────────────────────────
            Item {
                id: footer
                anchors.top: contentArea.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: TitanTheme.space6
                    anchors.verticalCenter: parent.verticalCenter
                    text: (root.viewMode === "grid" ? "\u2191\u2193\u2190\u2192 navigate" : "\u2191\u2193 navigate")
                          + "     \u23CE select     tab layout     esc " + (menu.atRoot ? "close" : "back")
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeCaption + 1
                }
            }
        }
    }
}
