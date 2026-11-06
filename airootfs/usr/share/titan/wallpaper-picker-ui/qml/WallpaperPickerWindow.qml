import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Window {
    id: root

    width: Screen.width > 0 ? Screen.width : 1920
    height: Screen.height > 0 ? Screen.height : 1080
    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    title: "titan-wallpaper-picker"

    // ── Design System Constants ──────────────────────────────────────────────
    readonly property color accentColor: (typeof Theme !== "undefined" && Theme.accent) ? Theme.accent : "#00D2FF"
    readonly property color cardSurface: Qt.rgba(0.06, 0.08, 0.13, 0.94)
    readonly property color cardBorder: Qt.rgba(1.0, 1.0, 1.0, 0.12)
    readonly property color glassItemBg: Qt.rgba(1.0, 1.0, 1.0, 0.05)
    readonly property color glassItemBorder: Qt.rgba(1.0, 1.0, 1.0, 0.08)
    readonly property color textHigh: "#F3F4F6"
    readonly property color textMid: "#9CA3AF"
    readonly property color textLow: "#6B7280"

    // Shipped ArchTitan system wallpapers (Guaranteed fallback so picker is never empty)
    readonly property var fallbackWallpapers: [
        "/usr/share/backgrounds/archtitan/wallpaper.png",
        "/usr/share/backgrounds/archtitan/1-matte-black.jpg",
        "/usr/share/backgrounds/archtitan/watchtower-mountains-and-forests.jpg",
        "/usr/share/backgrounds/archtitan/titan-tokyonight.jpg",
        "/usr/share/backgrounds/archtitan/titan-mocha.jpg",
        "/usr/share/backgrounds/archtitan/titan-dracula.jpg",
        "/usr/share/backgrounds/archtitan/titan-gruvbox.jpg",
        "/usr/share/backgrounds/archtitan/titan-everforest.jpg",
        "/usr/share/backgrounds/archtitan/titan-kanagawa.jpg",
        "/usr/share/backgrounds/archtitan/titan-rosepine.jpg",
        "/usr/share/backgrounds/archtitan/1-nord.png",
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

    property string searchQuery: ""
    property string activeCategory: "All"

    // Combines backend discovered paths with fallback shipped wallpapers
    function getAllWallpapers() {
        var rawList = [];
        if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.paths && WallpaperLibrary.paths.length > 0) {
            for (var i = 0; i < WallpaperLibrary.paths.length; i++) {
                rawList.push(WallpaperLibrary.paths[i]);
            }
        }
        for (var j = 0; j < fallbackWallpapers.length; j++) {
            if (rawList.indexOf(fallbackWallpapers[j]) === -1) {
                rawList.push(fallbackWallpapers[j]);
            }
        }
        return rawList;
    }

    function getFriendlyTitle(path) {
        if (!path) return "";
        var parts = path.split("/");
        var filename = parts[parts.length - 1] || "";
        var name = filename.replace(/\.[^/.]+$/, "");
        
        var titles = {
            "wallpaper": "ArchTitan Signature",
            "1-matte-black": "Matte Obsidian Black",
            "watchtower-mountains-and-forests": "Watchtower Horizon",
            "titan-tokyonight": "Tokyo Night",
            "titan-mocha": "Catppuccin Mocha",
            "titan-dracula": "Dracula Gothic",
            "titan-gruvbox": "Retro Gruvbox",
            "titan-everforest": "Everforest Mystic",
            "titan-kanagawa": "Kanagawa Wave",
            "titan-rosepine": "Rosé Pine",
            "1-nord": "Nordic Frost",
            "titan-latte": "Catppuccin Latte",
            "titan-custom": "Cyber Cyan",
            "titan-blue": "Deep Ocean Blue",
            "titan-green": "Emerald Forest",
            "titan-lavender": "Twilight Lavender",
            "titan-mauve": "Royal Mauve",
            "titan-peach": "Sunset Peach",
            "titan-pink": "Sakura Pink",
            "titan-teal": "Bioluminescent Teal"
        };
        return titles[name] || name.replace(/^[0-9]+-/, "").replace(/^titan-/, "").replace(/[-_]/g, " ").replace(/\b\w/g, function(l){ return l.toUpperCase(); });
    }

    function getTag(path) {
        var title = getFriendlyTitle(path).toLowerCase();
        if (title.indexOf("signature") !== -1 || title.indexOf("obsidian") !== -1 || title.indexOf("watchtower") !== -1)
            return "Signature";
        if (title.indexOf("tokyo") !== -1 || title.indexOf("mocha") !== -1 || title.indexOf("dracula") !== -1 ||
            title.indexOf("gruvbox") !== -1 || title.indexOf("everforest") !== -1 || title.indexOf("kanagawa") !== -1 ||
            title.indexOf("rose") !== -1 || title.indexOf("nord") !== -1)
            return "Theme";
        return "Color";
    }

    function applyWallpaper(path) {
        if (!path) return;
        if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.setCurrent) {
            WallpaperLibrary.setCurrent(path);
        }
        if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.apply) {
            WallpaperBackend.apply(path, "fill", false);
        }
        Qt.quit();
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                WallpaperBackend.revertPreview();
            }
            Qt.quit();
        }
    }

    // ── Fullscreen Darkened Blur Scrim ───────────────────────────────────────
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                    WallpaperBackend.revertPreview();
                }
                Qt.quit();
            }
        }
    }

    // ── Centered Modern Liquid Glass Card ────────────────────────────────────
    Rectangle {
        id: card
        width: Math.min(1080, parent.width - 64)
        height: Math.min(740, parent.height - 64)
        anchors.centerIn: parent

        color: root.cardSurface
        radius: 24
        border.width: 1
        border.color: root.cardBorder

        // Smooth Entrance Pop Animation
        scale: 0.97
        opacity: 0.0
        Component.onCompleted: {
            entranceAnim.start();
        }
        ParallelAnimation {
            id: entranceAnim
            NumberAnimation { target: card; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
        }

        // Inner 3D specular highlight ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 23
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1.0, 1.0, 1.0, 0.07)
        }

        MouseArea {
            // Prevent clicks inside card from propagating to scrim
            anchors.fill: parent
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 26
            spacing: 16

            // ── Top Header Row ───────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                // Gradient Icon Badge
                Rectangle {
                    width: 44
                    height: 44
                    radius: 12
                    color: Qt.rgba(0, 0.82, 1.0, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(0, 0.82, 1.0, 0.35)

                    Text {
                        anchors.centerIn: parent
                        text: "🖼️"
                        font.pixelSize: 22
                    }
                }

                // Title & Subtitle
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: "ArchTitan Wallpapers"
                        font { pixelSize: 20; bold: true; family: "Inter, sans-serif" }
                        color: root.textHigh
                    }

                    Text {
                        text: "Choose from signature backgrounds or search by theme & palette"
                        font { pixelSize: 12; family: "Inter, sans-serif" }
                        color: root.textMid
                    }
                }

                // Close Button
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: closeMa.containsMouse ? Qt.rgba(1, 0.2, 0.3, 0.25) : Qt.rgba(1, 1, 1, 0.07)
                    border.width: 1
                    border.color: closeMa.containsMouse ? Qt.rgba(1, 0.2, 0.3, 0.45) : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font { pixelSize: 13; bold: true }
                        color: closeMa.containsMouse ? "#FF6B6B" : root.textHigh
                    }

                    MouseArea {
                        id: closeMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof WallpaperBackend !== "undefined" && WallpaperBackend.revertPreview) {
                                WallpaperBackend.revertPreview();
                            }
                            Qt.quit();
                        }
                    }
                }
            }

            // ── Search & Filter Controls ─────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Search Input Box
                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: 10
                    color: Qt.rgba(0.0, 0.0, 0.0, 0.35)
                    border.width: searchInput.activeFocus ? 1.5 : 1
                    border.color: searchInput.activeFocus ? root.accentColor : Qt.rgba(1, 1, 1, 0.10)
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "🔍"
                            font.pixelSize: 13
                            opacity: 0.7
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: root.textHigh
                            font { pixelSize: 13; family: "Inter, sans-serif" }
                            clip: true
                            onTextChanged: root.searchQuery = text.trim().toLowerCase()

                            Text {
                                text: "Search wallpapers by name or theme..."
                                font: searchInput.font
                                color: root.textLow
                                visible: !searchInput.text && !searchInput.activeFocus
                            }
                        }

                        // Clear search button
                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: root.textMid
                            visible: searchInput.text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // Category Filter Pills
                RowLayout {
                    spacing: 6

                    Repeater {
                        model: ["All", "Signature", "Theme", "Color"]

                        delegate: Rectangle {
                            height: 36
                            width: catText.implicitWidth + 24
                            radius: 18
                            color: root.activeCategory === modelData
                                   ? Qt.rgba(0, 0.82, 1.0, 0.20)
                                   : (catMa.containsMouse ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(1, 1, 1, 0.04))
                            border.width: 1
                            border.color: root.activeCategory === modelData
                                          ? root.accentColor
                                          : Qt.rgba(1, 1, 1, 0.08)
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                id: catText
                                anchors.centerIn: parent
                                text: modelData
                                font { pixelSize: 12; family: "Inter, sans-serif"; bold: root.activeCategory === modelData }
                                color: root.activeCategory === modelData ? root.accentColor : root.textHigh
                            }

                            MouseArea {
                                id: catMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeCategory = modelData
                            }
                        }
                    }
                }
            }

            // Divider Line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            // ── Wallpaper Grid View ──────────────────────────────────────────
            ScrollView {
                id: scrollArea
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                GridView {
                    id: grid
                    cellWidth: 334
                    cellHeight: 215
                    boundsBehavior: Flickable.StopAtBounds

                    model: {
                        var all = root.getAllWallpapers();
                        var filtered = [];
                        for (var i = 0; i < all.length; i++) {
                            var p = all[i];
                            var title = root.getFriendlyTitle(p).toLowerCase();
                            var tag = root.getTag(p);

                            var matchesSearch = (root.searchQuery === "") || (title.indexOf(root.searchQuery) !== -1);
                            var matchesCategory = (root.activeCategory === "All") || (tag === root.activeCategory);

                            if (matchesSearch && matchesCategory) {
                                filtered.push(p);
                            }
                        }
                        return filtered;
                    }

                    delegate: Item {
                        width: grid.cellWidth
                        height: grid.cellHeight

                        property string wpPath: modelData
                        property string friendlyName: root.getFriendlyTitle(modelData)
                        property string categoryTag: root.getTag(modelData)
                        property bool isCurrent: {
                            var cur = (typeof WallpaperBackend !== "undefined" && WallpaperBackend.currentPath)
                                      ? WallpaperBackend.currentPath
                                      : ((typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.current) ? WallpaperLibrary.current : "");
                            return cur === modelData || cur.indexOf(modelData.split("/").pop()) !== -1;
                        }
                        property bool isHovered: tileMa.containsMouse

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 7
                            radius: 14
                            color: Qt.rgba(0.09, 0.11, 0.16, 0.90)
                            clip: true
                            border.width: isCurrent ? 2.5 : (isHovered ? 1.5 : 1)
                            border.color: isCurrent
                                          ? root.accentColor
                                          : (isHovered ? Qt.rgba(0, 0.82, 1.0, 0.5) : Qt.rgba(1, 1, 1, 0.09))

                            scale: isHovered ? 1.025 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            // Wallpaper Image Preview (with fallback to file:// if thumbs provider fails)
                            Image {
                                id: thumbImg
                                anchors.fill: parent
                                anchors.margins: isCurrent ? 2 : 1
                                source: "image://thumbs/" + wpPath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                mipmap: true

                                onStatusChanged: {
                                    if (status === Image.Error && source.toString().indexOf("image://") === 0) {
                                        // Fallback directly to file:// scheme
                                        source = "file://" + wpPath;
                                    }
                                }

                                // Dark gradient scrim for legibility of text
                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
                                        GradientStop { position: 0.5; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.80) }
                                    }
                                }
                            }

                            // Active Check Badge
                            Rectangle {
                                visible: isCurrent
                                width: 78
                                height: 26
                                radius: 13
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 9
                                color: root.accentColor

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: "✓"
                                        font { bold: true; pixelSize: 11 }
                                        color: "#0F172A"
                                    }
                                    Text {
                                        text: "Active"
                                        font { bold: true; pixelSize: 11; family: "Inter, sans-serif" }
                                        color: "#0F172A"
                                    }
                                }
                            }

                            // Tag Badge on top-left (e.g. Signature, Theme, Color)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 9
                                width: tagText.implicitWidth + 14
                                height: 22
                                radius: 11
                                color: Qt.rgba(0, 0, 0, 0.65)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.12)

                                Text {
                                    id: tagText
                                    anchors.centerIn: parent
                                    text: categoryTag
                                    font { pixelSize: 10; family: "Inter, sans-serif"; weight: Font.Medium }
                                    color: root.textMid
                                }
                            }

                            // Bottom Info Strip with Title
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 42
                                color: Qt.rgba(0.06, 0.08, 0.12, 0.85)

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 8

                                    Text {
                                        Layout.fillWidth: true
                                        text: friendlyName
                                        font { family: "Inter, sans-serif"; pixelSize: 13; bold: isCurrent }
                                        color: isCurrent ? root.accentColor : root.textHigh
                                        elide: Text.ElideRight
                                    }

                                    // Resolution / Format Pill
                                    Rectangle {
                                        width: 32; height: 18; radius: 4
                                        color: Qt.rgba(1, 1, 1, 0.08)
                                        Text {
                                            anchors.centerIn: parent
                                            text: wpPath.indexOf(".png") !== -1 ? "PNG" : "JPG"
                                            font { pixelSize: 9; family: "Inter"; bold: true }
                                            color: root.textLow
                                        }
                                    }
                                }
                            }

                            // Hover Overlay: Click to Apply Pill
                            Rectangle {
                                anchors.centerIn: parent
                                width: 140
                                height: 38
                                radius: 19
                                color: Qt.rgba(0, 0.82, 1.0, 0.90)
                                opacity: isHovered && !isCurrent ? 1.0 : 0.0
                                Behavior on opacity { NumberAnimation { duration: 120 } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text { text: "✓"; font.bold: true; color: "#0B101B" }
                                    Text {
                                        text: "Apply Wallpaper"
                                        font { family: "Inter, sans-serif"; pixelSize: 12; bold: true }
                                        color: "#0B101B"
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.applyWallpaper(wpPath)
                            }
                        }
                    }
                }
            }

            // ── Footer Bar ───────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.07)
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Wallpapers count badge
                Rectangle {
                    height: 28
                    width: countText.implicitWidth + 18
                    radius: 14
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.08)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Rectangle { width: 6; height: 6; radius: 3; color: "#22C55E" }
                        Text {
                            id: countText
                            text: (grid.count || 0) + " Wallpapers Available"
                            font { family: "Inter, sans-serif"; pixelSize: 11; weight: Font.Medium }
                            color: root.textMid
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Quick Random Button
                Rectangle {
                    height: 32
                    width: randText.implicitWidth + 24
                    radius: 16
                    color: randMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "🎲"; font.pixelSize: 11 }
                        Text {
                            id: randText
                            text: "Random"
                            font { family: "Inter, sans-serif"; pixelSize: 12; weight: Font.Medium }
                            color: root.textHigh
                        }
                    }

                    MouseArea {
                        id: randMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var all = root.getAllWallpapers();
                            if (all.length > 0) {
                                var randIndex = Math.floor(Math.random() * all.length);
                                root.applyWallpaper(all[randIndex]);
                            }
                        }
                    }
                }

                // Rescan Button
                Rectangle {
                    height: 32
                    width: rescanText.implicitWidth + 24
                    radius: 16
                    color: rescanMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text { text: "🔄"; font.pixelSize: 11 }
                        Text {
                            id: rescanText
                            text: "Rescan"
                            font { family: "Inter, sans-serif"; pixelSize: 12; weight: Font.Medium }
                            color: root.textHigh
                        }
                    }

                    MouseArea {
                        id: rescanMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof WallpaperLibrary !== "undefined" && WallpaperLibrary.rescan) {
                                WallpaperLibrary.rescan();
                            }
                        }
                    }
                }

                // Done / Close Pill
                Rectangle {
                    height: 32
                    width: 76
                    radius: 16
                    color: doneMa.containsMouse ? Qt.rgba(0, 0.82, 1.0, 0.35) : Qt.rgba(0, 0.82, 1.0, 0.20)
                    border.width: 1
                    border.color: root.accentColor
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Done"
                        font { family: "Inter, sans-serif"; pixelSize: 12; bold: true }
                        color: root.accentColor
                    }

                    MouseArea {
                        id: doneMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }
}
