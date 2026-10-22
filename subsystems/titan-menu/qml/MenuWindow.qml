import QtQuick
import QtQuick.Window
import QtQuick.Effects
import ArchTitan.TitanUI
import "components"

/**
 * titan-menu — ArchTitan system menu.
 *
 * A keyboard-first command palette: type to search everything, or arrow
 * through categories. Full-screen layer surface; the scrim catches click-away
 * and the frosted card sits in the upper third of the screen. Blur comes from
 * the compositor (see the `titan-menu` layer rule).
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

    readonly property int rowHeight: 52
    readonly property int rowGap: 2
    readonly property int maxRows: 8

    function openMenu() {
        menu.reset();
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
        const n = list.count;
        if (n === 0) return;
        list.currentIndex = (list.currentIndex + delta + n) % n;
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    // Keep in step with MenuController::kExecBaseDelayMs (230 ms): the layer
    // surface must be gone before a launched command asks for keyboard focus.
    Timer {
        id: closeTimer
        interval: 180
        onTriggered: if (!root.menuOpen) root.visible = false
    }

    Connections {
        target: menu
        function onCloseRequested() { root.closeMenu(); }
        function onEntriesChanged() { list.currentIndex = menu.entries.length > 0 ? 0 : -1; }
        function onQueryChanged() {
            if (searchInput.text !== menu.query) searchInput.text = menu.query;
        }
    }

    // ── Scrim ────────────────────────────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.55)
        opacity: root.menuOpen ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeMenu()
        }
    }

    // ── Card ─────────────────────────────────────────────────────────────────
    Item {
        id: card
        width: 660
        height: cardBody.height
        x: (parent.width - width) / 2
        y: parent.height * 0.18

        opacity: root.menuOpen ? 1.0 : 0.0
        scale: root.menuOpen ? 1.0 : 0.965
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
        Behavior on scale { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingEmphasis } }

        // Swallow clicks so they do not reach the scrim underneath.
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: cardBody
            width: parent.width
            height: header.height + divider.height + listArea.height + footer.height + 2 * TitanTheme.space2
            radius: TitanTheme.radiusBento
            border.width: 1
            border.color: TitanTheme.borderSubtle

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.96) }
                GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b, 0.92) }
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

            // ── Search header ────────────────────────────────────────────────
            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 64

                TitanIcon {
                    id: searchGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: TitanTheme.space6
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "\uf002"
                    size: 16
                    color: TitanTheme.textLow
                }

                // Breadcrumb chip: where we are when drilled into a group.
                Rectangle {
                    id: crumb
                    visible: menu.breadcrumb !== ""
                    anchors.left: searchGlyph.right
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
                }

                TextInput {
                    id: searchInput
                    anchors.left: crumb.visible ? crumb.right : searchGlyph.right
                    anchors.leftMargin: TitanTheme.space3
                    anchors.right: parent.right
                    anchors.rightMargin: TitanTheme.space6
                    anchors.verticalCenter: parent.verticalCenter
                    color: TitanTheme.textHigh
                    selectionColor: TitanTheme.accentEdge
                    selectedTextColor: TitanTheme.textOnAccent
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeTitle + 2
                    clip: true
                    focus: true

                    // textEdited fires only for user typing, so syncing the
                    // field from the controller cannot loop back.
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
                        if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (ctrl && e.key === Qt.Key_N) || (ctrl && e.key === Qt.Key_J)) {
                            root.moveSelection(1); e.accepted = true;
                        } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && e.key === Qt.Key_P) || (ctrl && e.key === Qt.Key_K)) {
                            root.moveSelection(-1); e.accepted = true;
                        } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) {
                            menu.activate(list.currentIndex); e.accepted = true;
                        } else if (e.key === Qt.Key_Escape) {
                            menu.back(); e.accepted = true;
                        } else if (e.key === Qt.Key_Backspace && searchInput.text === "" && !menu.atRoot) {
                            menu.back(); e.accepted = true;
                        } else if (e.key === Qt.Key_Left && searchInput.text === "" && !menu.atRoot) {
                            menu.back(); e.accepted = true;
                        } else if (e.key === Qt.Key_Right && searchInput.cursorPosition === searchInput.text.length) {
                            menu.enter(list.currentIndex); e.accepted = true;
                        }
                    }
                }
            }

            Rectangle {
                id: divider
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: TitanTheme.space4
                anchors.rightMargin: TitanTheme.space4
                height: 1
                color: TitanTheme.borderSubtle
            }

            // ── Rows ─────────────────────────────────────────────────────────
            Item {
                id: listArea
                anchors.top: divider.bottom
                anchors.topMargin: TitanTheme.space2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: TitanTheme.space2
                anchors.rightMargin: TitanTheme.space2
                height: list.count === 0
                        ? 84
                        : Math.min(list.count, root.maxRows) * (root.rowHeight + root.rowGap) - root.rowGap
                Behavior on height { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

                ListView {
                    id: list
                    anchors.fill: parent
                    model: menu.entries
                    spacing: root.rowGap
                    clip: true
                    currentIndex: 0
                    interactive: count > root.maxRows
                    boundsBehavior: Flickable.StopAtBounds
                    highlightMoveDuration: 0

                    delegate: MenuRow {
                        required property int index
                        required property var modelData
                        width: list.width
                        entry: modelData
                        current: ListView.isCurrentItem
                        onHovered: list.currentIndex = index
                        onClicked: menu.activate(index)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: "No matches for \u201C" + menu.query + "\u201D"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeBody
                }
            }

            // ── Footer hints ─────────────────────────────────────────────────
            Item {
                id: footer
                anchors.top: listArea.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: TitanTheme.space6
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\u2191\u2193 navigate     \u23CE select     \u2190 back     esc " + (menu.atRoot ? "close" : "back")
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeCaption + 1
                }
            }
        }
    }
}
