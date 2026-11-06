import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import ArchTitan.TitanUI

Window {
    id: root

    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    visible: true
    visibility: Window.FullScreen
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: "titan-wallpaper-picker"

    // ── State ────────────────────────────────────────────────────────────────
    property var filteredPaths: []
    property string selectedPath: ""
    property string activeFilter: "all"
    property string query: ""
    property string scaleMode: "fill"
    property string currentPath: (typeof WallpaperBackend !== "undefined" && WallpaperBackend.currentPath)
                                ? WallpaperBackend.currentPath : ""

    readonly property var filters: [
        { key: "all",    label: "All" },
        { key: "system", label: "System" },
        { key: "yours",  label: "Yours" }
    ]

    readonly property var scaleModes: [
        { key: "fill",    label: "Fill" },
        { key: "fit",     label: "Fit" },
        { key: "stretch", label: "Stretch" },
        { key: "center",  label: "Center" },
        { key: "tile",    label: "Tile" }
    ]

    // Last-resort list for installs where the backend scan returns nothing.
    // These are the wallpapers shipped under /usr/share/backgrounds/archtitan.
    readonly property var systemFallbacks: [
        "/usr/share/backgrounds/archtitan/wallpaper.png",
        "/usr/share/backgrounds/archtitan/1-matte-black.jpg",
        "/usr/share/backgrounds/archtitan/1-nord.png",
        "/usr/share/backgrounds/archtitan/watchtower-mountains-and-forests.jpg",
        "/usr/share/backgrounds/archtitan/titan-tokyonight.jpg",
        "/usr/share/backgrounds/archtitan/titan-mocha.jpg",
        "/usr/share/backgrounds/archtitan/titan-dracula.jpg",
        "/usr/share/backgrounds/archtitan/titan-gruvbox.jpg",
        "/usr/share/backgrounds/archtitan/titan-everforest.jpg",
        "/usr/share/backgrounds/archtitan/titan-kanagawa.jpg",
        "/usr/share/backgrounds/archtitan/titan-rosepine.jpg",
        "/usr/share/backgrounds/archtitan/titan-latte.jpg",
        "/usr/share/backgrounds/archtitan/titan-custom.jpg",
        "/usr/share/backgrounds/archtitan/titan-blue.jpg",
        "/usr/share/backgrounds/archtitan/titan-green.jpg",
        "/usr/share/backgrounds/archtitan/titan-lavender.jpg",
        "/usr/share/backgrounds/archtitan/titan-mauve.jpg",
        "/usr/share/backgrounds/archtitan/titan-peach.jpg",
        "/usr/share/backgrounds/archtitan/titan-pink.jpg",
        "/usr/share/backgrounds/archtitan/titan-teal.jpg"
    ]

    // ── Helpers ──────────────────────────────────────────────────────────────
    function baseName(path) {
        var name = String(path || "").split("/").pop() || String(path || "")
        name = name.replace(/\.[^/.]+$/, "")
        return name.replace(/[-_]+/g, " ").trim()
    }

    function isSystem(path) {
        return String(path || "").indexOf("/usr/share/") === 0
    }

    function rebuildModel() {
        var source = (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.paths)
                   ? WallpaperLibrary.paths : []
        if (!source || source.length === 0) source = root.systemFallbacks
        var out = []
        var q = root.query.toLowerCase()

        for (var i = 0; i < source.length; i++) {
            var path = String(source[i])
            var name = root.baseName(path)

            if (root.activeFilter === "system" && !root.isSystem(path)) continue
            if (root.activeFilter === "yours" && root.isSystem(path)) continue
            if (q.length > 0 && name.toLowerCase().indexOf(q) < 0) continue

            out.push({
                path: path,
                name: name,
                system: root.isSystem(path)
            })
        }

        out.sort(function (a, b) {
            return a.name.localeCompare(b.name)
        })

        root.filteredPaths = out

        var stillVisible = false
        for (var j = 0; j < out.length; j++) {
            if (out[j].path === root.selectedPath) {
                stillVisible = true
                break
            }
        }
        if (!stillVisible) {
            root.selectedPath = out.length > 0 ? out[0].path : ""
        }
        root.updateCurrentIndex()
    }

    function updateCurrentIndex() {
        for (var i = 0; i < root.filteredPaths.length; i++) {
            if (root.filteredPaths[i].path === root.selectedPath) {
                if (grid.currentIndex !== i) grid.currentIndex = i
                return
            }
        }
        if (root.filteredPaths.length > 0) {
            if (grid.currentIndex !== 0) grid.currentIndex = 0
        } else {
            grid.currentIndex = -1
        }
    }

    function selectPath(path) {
        root.selectedPath = path || ""
    }

    function applySelected() {
        if (root.selectedPath.length === 0) return

        // WallpaperBackend.apply() persists the selection and starts the
        // wallpaper service. Do not call WallpaperLibrary.setCurrent() here:
        // that call blocks the GUI thread in the current backend.
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.apply) {
            WallpaperBackend.apply(root.selectedPath, root.scaleMode, false)
        }
        Qt.quit()
    }

    function cancel() {
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
            WallpaperBackend.revertPreview()
        }
        Qt.quit()
    }

    function setFilter(key) {
        root.activeFilter = key
        root.rebuildModel()
    }

    function setScaleMode(mode) {
        root.scaleMode = mode
    }

    Component.onCompleted: {
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.currentMode) {
            root.scaleMode = WallpaperBackend.currentMode
        }
        if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.current) {
            root.selectedPath = WallpaperLibrary.current
        }
        root.rebuildModel()
        Qt.callLater(function () {
            grid.forceActiveFocus()
        })
    }

    // ── Live data ────────────────────────────────────────────────────────────
    Connections {
        target: (typeof WallpaperLibrary !== "undefined") ? WallpaperLibrary : null
        function onPathsChanged() { root.rebuildModel() }
        function onCurrentChanged() {
            if (typeof WallpaperLibrary !== "undefined") {
                root.currentPath = WallpaperLibrary.current
            }
        }
    }

    Connections {
        target: (typeof WallpaperBackend !== "undefined") ? WallpaperBackend : null
        function onCurrentModeChanged() {
            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.currentMode) {
                root.scaleMode = WallpaperBackend.currentMode
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: !searchInput.activeFocus
        onActivated: root.cancel()
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: searchInput.forceActiveFocus()
    }

    Shortcut {
        sequence: "Return"
        enabled: grid.activeFocus
        onActivated: root.applySelected()
    }

    // ── Backdrop ─────────────────────────────────────────────────────────────
    Image {
        anchors.fill: parent
        source: root.currentPath.length > 0 ? "file://" + root.currentPath : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        opacity: 0.32
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.03, 0.05, 0.82) }
            GradientStop { position: 0.55; color: Qt.rgba(0.03, 0.04, 0.07, 0.62) }
            GradientStop { position: 1.0; color: Qt.rgba(0.01, 0.02, 0.04, 0.88) }
        }
    }

    Rectangle {
        id: scrim
        anchors.fill: parent
        color: TitanTheme.scrim

        MouseArea {
            anchors.fill: parent
            onClicked: root.cancel()
        }
    }

    // ── Gallery sheet ────────────────────────────────────────────────────────
    Rectangle {
        id: card
        width: Math.min(1320, parent.width - 64)
        height: Math.min(860, parent.height - 64)
        anchors.centerIn: parent
        radius: TitanTheme.radiusWindow

        color: TitanTheme.bg1
        border.width: 1
        border.color: TitanTheme.borderSubtle

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: TitanTheme.radiusWindow - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.06)
        }

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: TitanTheme.space6
            spacing: TitanTheme.space4

            // ── Header ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: TitanTheme.space3

                Text {
                    text: "󰸉"
                    color: TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 26
                    Layout.alignment: Qt.AlignVCenter
                }

                ColumnLayout {
                    spacing: 1
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                        text: "Wallpapers"
                        color: TitanTheme.textHigh
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: TitanTheme.sizeHeadline
                        font.weight: TitanTheme.weightSemiBold
                    }

                    Text {
                        text: "Choose a background for every workspace"
                        color: TitanTheme.textLow
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: TitanTheme.sizeLabel
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 250
                    Layout.preferredHeight: 34
                    radius: TitanTheme.radiusControl
                    color: TitanTheme.bgInset
                    border.width: 1
                    border.color: searchInput.activeFocus ? TitanTheme.accent : TitanTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "⌕"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 15
                        }

                        TextField {
                            id: searchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            activeFocusOnTab: true
                            placeholderText: "Search wallpapers…"
                            placeholderTextColor: TitanTheme.textLow
                            color: TitanTheme.textHigh
                            selectionColor: TitanTheme.accent
                            selectedTextColor: TitanTheme.accentFg
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeBody
                            background: null
                            padding: 0
                            leftPadding: 0
                            rightPadding: 0
                            topPadding: 0
                            bottomPadding: 0
                            verticalAlignment: TextInput.AlignVCenter
                            selectByMouse: true
                            clip: true

                            onTextChanged: {
                                root.query = text
                                root.rebuildModel()
                            }

                            Keys.onEscapePressed: {
                                text = ""
                                root.query = ""
                                root.rebuildModel()
                                grid.forceActiveFocus()
                                event.accepted = true
                            }

                            Keys.onReturnPressed: grid.forceActiveFocus()
                            Keys.onEnterPressed: grid.forceActiveFocus()
                        }
                    }
                }

                Rectangle {
                    width: 32
                    height: 32
                    radius: TitanTheme.radiusControl
                    color: closeArea.containsMouse ? TitanTheme.stateHover : TitanTheme.bgInset
                    border.width: 1
                    border.color: TitanTheme.border

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        color: TitanTheme.textMid
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 15
                    }

                    MouseArea {
                        id: closeArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancel()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: TitanTheme.borderSubtle
            }

            // ── Filters ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: TitanTheme.space2

                Row {
                    spacing: TitanTheme.space2

                    Repeater {
                        model: root.filters

                        Rectangle {
                            width: chipLabel.implicitWidth + 22
                            height: 28
                            radius: 14
                            activeFocusOnTab: true
                            color: root.activeFilter === modelData.key
                                   ? TitanTheme.accentSoft
                                   : (chipArea.containsMouse ? TitanTheme.stateHover : TitanTheme.bgInset)
                            border.width: activeFocus ? TitanTheme.focusRingWidth : 1
                            border.color: activeFocus
                                          ? TitanTheme.focusRing
                                          : (root.activeFilter === modelData.key
                                             ? TitanTheme.accentEdge
                                             : TitanTheme.border)

                            Keys.onReturnPressed: root.setFilter(modelData.key)
                            Keys.onEnterPressed: root.setFilter(modelData.key)
                            Keys.onSpacePressed: root.setFilter(modelData.key)

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: modelData.label
                                color: root.activeFilter === modelData.key
                                       ? TitanTheme.accent
                                       : TitanTheme.textMid
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: TitanTheme.sizeLabel
                                font.weight: root.activeFilter === modelData.key
                                             ? TitanTheme.weightSemiBold
                                             : TitanTheme.weightMedium
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setFilter(modelData.key)
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: root.filteredPaths.length + (root.filteredPaths.length === 1 ? " wallpaper" : " wallpapers")
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeLabel
                }
            }

            // ── Content ──────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: TitanTheme.space4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    GridView {
                        id: grid
                        anchors.fill: parent
                        clip: true
                        focus: true
                        boundsBehavior: Flickable.StopAtBounds
                        cellWidth: Math.floor(width / Math.max(2, Math.floor(width / 250)))
                        cellHeight: Math.floor(cellWidth * 0.62)
                        model: root.filteredPaths

                        currentIndex: -1

                        onCurrentIndexChanged: {
                            if (currentIndex >= 0 && currentIndex < root.filteredPaths.length) {
                                root.selectPath(root.filteredPaths[currentIndex].path)
                            }
                        }

                        delegate: Item {
                            id: cell
                            width: grid.cellWidth
                            height: grid.cellHeight

                            readonly property var entry: modelData
                            readonly property bool isCurrent: entry
                                && typeof WallpaperLibrary !== "undefined"
                                && WallpaperLibrary.current === entry.path
                            readonly property bool isSelected: entry && root.selectedPath === entry.path

                            Rectangle {
                                id: thumb
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: TitanTheme.radiusCard
                                color: TitanTheme.surface0
                                clip: true
                                border.width: cell.isSelected ? 2 : 1
                                border.color: cell.isSelected
                                              ? TitanTheme.accent
                                              : (thumbArea.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle)

                                Image {
                                    anchors.fill: parent
                                    source: cell.entry ? "image://thumbs/" + cell.entry.path : ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    mipmap: true
                                    sourceSize.width: 640
                                    sourceSize.height: 400
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.48; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.78) }
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    anchors.bottomMargin: 9
                                    text: cell.entry ? cell.entry.name : ""
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeLabel
                                    font.weight: TitanTheme.weightSemiBold
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    visible: cell.isCurrent
                                    width: 22
                                    height: 22
                                    radius: 11
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 9
                                    color: TitanTheme.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        color: TitanTheme.accentFg
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: TitanTheme.weightBold
                                    }
                                }

                                MouseArea {
                                    id: thumbArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        grid.currentIndex = index
                                        root.selectPath(cell.entry.path)
                                    }
                                    onDoubleClicked: {
                                        grid.currentIndex = index
                                        root.selectPath(cell.entry.path)
                                        root.applySelected()
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: TitanTheme.space2
                        visible: grid.count === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰋩"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 34
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.query.length > 0 ? "No matching wallpapers" : "No wallpapers found"
                            color: TitanTheme.textMid
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeTitle
                            font.weight: TitanTheme.weightSemiBold
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "Try a different search or filter"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeLabel
                        }
                    }
                }

                // ── Preview pane ─────────────────────────────────────────────
                Rectangle {
                    id: previewPane
                    visible: card.width > 1080
                    Layout.preferredWidth: 352
                    Layout.fillHeight: true
                    radius: TitanTheme.radiusLg
                    color: TitanTheme.bgInset
                    border.width: 1
                    border.color: TitanTheme.borderSubtle

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: TitanTheme.space4
                        spacing: TitanTheme.space3

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 186
                            radius: TitanTheme.radiusCard
                            color: TitanTheme.surface0
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.selectedPath.length > 0
                                        ? "file://" + root.selectedPath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                sourceSize.width: 720
                                sourceSize.height: 420
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.selectedPath.length === 0
                                text: "Select a wallpaper"
                                color: TitanTheme.textLow
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: TitanTheme.sizeLabel
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.selectedPath.length > 0
                                  ? root.baseName(root.selectedPath) : "—"
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeTitle
                            font.weight: TitanTheme.weightSemiBold
                            elide: Text.ElideRight
                        }

                        RowLayout {
                            spacing: TitanTheme.space2

                            Rectangle {
                                width: typeLabel.implicitWidth + 16
                                height: 22
                                radius: 11
                                color: TitanTheme.bg4
                                border.width: 1
                                border.color: TitanTheme.borderSubtle

                                Text {
                                    id: typeLabel
                                    anchors.centerIn: parent
                                    text: root.isSystem(root.selectedPath) ? "System" : "Personal"
                                    color: TitanTheme.textMid
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    font.weight: TitanTheme.weightMedium
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.selectedPath.length > 0
                                      ? root.selectedPath.replace(/^.*\//, "") : ""
                                color: TitanTheme.textLow
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: TitanTheme.sizeCaption
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: TitanTheme.borderSubtle
                        }

                        Text {
                            text: "Scale mode"
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeLabel
                            font.weight: TitanTheme.weightMedium
                        }

                        Row {
                            spacing: 6

                            Repeater {
                                model: root.scaleModes

                                Rectangle {
                                    width: 60
                                    height: 28
                                    radius: TitanTheme.radiusControl
                                    activeFocusOnTab: true
                                    color: root.scaleMode === modelData.key
                                           ? TitanTheme.accentSoft
                                           : (modeArea.containsMouse ? TitanTheme.stateHover : TitanTheme.bgInset)
                                    border.width: activeFocus ? TitanTheme.focusRingWidth : 1
                                    border.color: activeFocus
                                                  ? TitanTheme.focusRing
                                                  : (root.scaleMode === modelData.key
                                                     ? TitanTheme.accentEdge
                                                     : TitanTheme.border)

                                    Keys.onReturnPressed: root.setScaleMode(modelData.key)
                                    Keys.onEnterPressed: root.setScaleMode(modelData.key)
                                    Keys.onSpacePressed: root.setScaleMode(modelData.key)

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        color: root.scaleMode === modelData.key
                                               ? TitanTheme.accent
                                               : TitanTheme.textMid
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: TitanTheme.sizeCaption
                                        font.weight: root.scaleMode === modelData.key
                                                     ? TitanTheme.weightSemiBold
                                                     : TitanTheme.weightMedium
                                    }

                                    MouseArea {
                                        id: modeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.setScaleMode(modelData.key)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: TitanTheme.space2

                            TitanButton {
                                Layout.fillWidth: true
                                text: "Apply"
                                variant: "primary"
                                onClicked: root.applySelected()
                            }

                            TitanButton {
                                Layout.fillWidth: true
                                text: "Cancel"
                                variant: "ghost"
                                onClicked: root.cancel()
                            }
                        }
                    }
                }
            }

            // ── Footer ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: TitanTheme.space3

                Text {
                    text: "↑↓←→ navigate  ·  Enter apply  ·  Esc close"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeCaption
                }

                Item { Layout.fillWidth: true }

                TitanButton {
                    text: "Rescan"
                    variant: "ghost"
                    implicitHeight: 30
                    onClicked: {
                        if (typeof WallpaperLibrary !== "undefined") {
                            WallpaperLibrary.rescan()
                        }
                        root.rebuildModel()
                    }
                }
            }
        }
    }
}
