import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import ArchTitan.TitanUI
import ArchTitanSettings

ScrollView {
    id: root
    contentWidth: -1
    ScrollBar.vertical.policy: ScrollBar.AsNeeded

    property color textHigh:  TitanTheme.textHigh
    property color textMid:   TitanTheme.textMid
    property color textLow:   TitanTheme.textLow
    property color accent:    TitanTheme.accent
    property color green:     TitanTheme.success
    property color orange:    TitanTheme.warning

    readonly property var accentColors: [
        "#4C8BF5", "#00D2D3", "#9575CD", "#66BB6A",
        "#FFA726", "#FC5C65", "#26A69A", "#FED33C"
    ]

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Item { height: 20 }

        // ── Page Header ──────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 4

            Text {
                text: "Appearance"
                font { pixelSize: 22; family: "Inter" }
                font.weight: Font.Bold
                color: root.textHigh
            }

            Text {
                text: "Customize how ArchTitan OS looks and feels"
                font { pixelSize: 13; family: "Inter" }
                color: root.textLow
            }
        }

        Item { height: 24 }

        // ── Theme Templates Section ──────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "THEME TEMPLATES"
                    font { pixelSize: 10; family: "Inter" }
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    color: root.textLow
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "Active: " + (SettingsBackend.currentThemeId.toUpperCase())
                    font { pixelSize: 11; family: "Inter" }
                    font.weight: Font.Medium
                    color: root.accent
                }
            }

            ScrollView {
                Layout.fillWidth: true
                implicitHeight: 124
                contentWidth: themeRow.implicitWidth
                contentHeight: 124
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                clip: true

                RowLayout {
                    id: themeRow
                    spacing: 12

                    readonly property var defaultThemes: [
                        { id: "archtitan",  name: "ArchTitan Signature", accent: "#00D2FF", wallpaper: "/usr/share/backgrounds/archtitan/wallpaper.png", base: "#1E1E2E" },
                        { id: "mocha",      name: "Catppuccin Mocha",    accent: "#89B4FA", wallpaper: "/usr/share/backgrounds/archtitan/titan-mocha.jpg", base: "#1E1E2E" },
                        { id: "tokyonight", name: "Tokyo Night",         accent: "#7AA2F7", wallpaper: "/usr/share/backgrounds/archtitan/titan-tokyonight.jpg", base: "#24283B" },
                        { id: "dracula",    name: "Dracula",             accent: "#BD93F9", wallpaper: "/usr/share/backgrounds/archtitan/titan-dracula.jpg", base: "#282A36" },
                        { id: "gruvbox",    name: "Gruvbox",             accent: "#83A598", wallpaper: "/usr/share/backgrounds/archtitan/titan-gruvbox.jpg", base: "#282828" },
                        { id: "everforest", name: "Everforest",          accent: "#A7C080", wallpaper: "/usr/share/backgrounds/archtitan/titan-everforest.jpg", base: "#2D353B" },
                        { id: "kanagawa",   name: "Kanagawa",            accent: "#7E9CD8", wallpaper: "/usr/share/backgrounds/archtitan/titan-kanagawa.jpg", base: "#1F1F28" },
                        { id: "rosepine",   name: "Rosé Pine",           accent: "#C4A7E7", wallpaper: "/usr/share/backgrounds/archtitan/titan-rosepine.jpg", base: "#1F1D2E" },
                        { id: "nord",       name: "Nord",                accent: "#88C0D0", wallpaper: "/usr/share/backgrounds/archtitan/1-nord.png", base: "#3B4252" },
                        { id: "latte",      name: "Catppuccin Latte",    accent: "#1E66F5", wallpaper: "/usr/share/backgrounds/archtitan/titan-latte.jpg", base: "#EFF1F5" },
                        { id: "custom",     name: "ArchTitan Custom",    accent: "#00D2FF", wallpaper: "/usr/share/backgrounds/archtitan/titan-custom.jpg", base: "#1A1D27" }
                    ]

                    Repeater {
                        model: (SettingsBackend.installedThemes && SettingsBackend.installedThemes.length > 0)
                               ? SettingsBackend.installedThemes
                               : themeRow.defaultThemes

                        delegate: Rectangle {
                            width: 148
                            height: 114
                            radius: 10
                            color: globalBg3
                            border.width: SettingsBackend.currentThemeId === modelData.id ? 2 : 1
                            border.color: SettingsBackend.currentThemeId === modelData.id
                                          ? root.accent : globalBorder0
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            ColumnLayout {
                                anchors { fill: parent; margins: 8 }
                                spacing: 6

                                // Mini wallpaper / theme preview
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 58
                                    radius: 6
                                    clip: true
                                    color: modelData.base || "#1A1D27"
                                    border.width: 1; border.color: globalBorder0

                                    Image {
                                        anchors.fill: parent
                                        source: modelData.wallpaper ? "file://" + modelData.wallpaper : ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        smooth: true
                                        opacity: 0.95
                                    }

                                    // Accent color indicator pip
                                    Rectangle {
                                        anchors { right: parent.right; top: parent.top; margins: 5 }
                                        width: 12; height: 12; radius: 6
                                        color: modelData.accent || root.accent
                                        border.width: 1.5; border.color: "#FFFFFF"
                                    }

                                    // Active checkmark badge
                                    Rectangle {
                                        visible: SettingsBackend.currentThemeId === modelData.id
                                        anchors { left: parent.left; top: parent.top; margins: 5 }
                                        width: 18; height: 18; radius: 9
                                        color: root.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\uf00c"
                                            font.pixelSize: 10
                                            color: "#FFFFFF"
                                        }
                                    }
                                }

                                Text {
                                    text: modelData.name
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.fillWidth: true
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    font { pixelSize: 11; family: "Inter" }
                                    font.weight: SettingsBackend.currentThemeId === modelData.id ? Font.DemiBold : Font.Normal
                                    color: SettingsBackend.currentThemeId === modelData.id ? root.textHigh : root.textMid
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    SettingsBackend.applyThemeTemplate(modelData.id);
                                    WallpaperManager.refresh();
                                }
                            }
                        }
                    }
                }
            }
        }

        Item { height: 24 }

        // ── Desktop Wallpapers Section ────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "DESKTOP WALLPAPERS"
                    font { pixelSize: 10; family: "Inter" }
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    color: root.textLow
                }
                Item { Layout.fillWidth: true }

                TitanButton {
                    text: "Change Wallpaper..."
                    primary: false
                    width: 150
                    height: 28
                    // The shipped picker supports both the system gallery and
                    // importing custom images from disk.
                    onClicked: WallpaperManager.launchPicker()
                }
            }

            ScrollView {
                Layout.fillWidth: true
                implicitHeight: 96
                contentWidth: wallpaperRow.implicitWidth
                contentHeight: 96
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                clip: true

                RowLayout {
                    id: wallpaperRow
                    spacing: 10

                    Repeater {
                        model: WallpaperManager.wallpaperList
                        delegate: Rectangle {
                            width: 130
                            height: 84
                            radius: 8
                            color: globalBg3
                            clip: true
                            border.width: WallpaperManager.currentWallpaper === modelData ? 2 : 1
                            border.color: WallpaperManager.currentWallpaper === modelData
                                          ? root.accent : globalBorder0
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                            }

                            // Active check badge
                            Rectangle {
                                visible: WallpaperManager.currentWallpaper === modelData
                                anchors { right: parent.right; top: parent.top; margins: 4 }
                                width: 16; height: 16; radius: 8
                                color: root.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf00c"
                                    font.pixelSize: 9
                                    color: "#FFFFFF"
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperManager.setCurrentWallpaper(modelData)
                            }
                        }
                    }
                }
            }

            // ── Titan Adaptive Wallpaper (TAW) Controls ───────────
            SettingsCard {
                Layout.fillWidth: true
                Layout.topMargin: 6

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    // Header row: TAW master toggle
                    RowLayout {
                        Layout.fillWidth: true
                        ColumnLayout {
                            spacing: 3
                            RowLayout {
                                spacing: 8
                                Text {
                                    text: "Titan Adaptive Wallpaper (TAW)"
                                    font { pixelSize: 13; family: "Inter" }
                                    font.weight: Font.SemiBold
                                    color: root.textHigh
                                }
                                Rectangle {
                                    height: 18; width: 44; radius: 4
                                    color: WallpaperManager.adaptiveEnabled
                                           ? Qt.hsla(root.accent.hslHue, root.accent.hslSaturation, root.accent.hslLightness, 0.20)
                                           : Qt.rgba(1, 1, 1, 0.08)
                                    border.width: 1
                                    border.color: WallpaperManager.adaptiveEnabled ? root.accent : globalBorder0
                                    Text {
                                        anchors.centerIn: parent
                                        text: WallpaperManager.adaptiveEnabled ? "ACTIVE" : "OFF"
                                        font { pixelSize: 9; family: "Inter" }
                                        font.weight: Font.Bold
                                        color: WallpaperManager.adaptiveEnabled ? root.accent : root.textLow
                                    }
                                }
                            }
                            Text {
                                text: "Automatically adapts wallpaper color atmosphere to complement the active desktop theme"
                                font { pixelSize: 12; family: "Inter" }
                                color: root.textLow
                            }
                        }
                        Item { Layout.fillWidth: true }
                        TitanSwitch {
                            onColor: root.accent
                            checked: WallpaperManager.adaptiveEnabled
                            onCheckedChanged: WallpaperManager.setAdaptiveEnabled(checked)
                        }
                    }

                    // Expanded controls when TAW is enabled
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: WallpaperManager.adaptiveEnabled

                        Rectangle {
                            Layout.fillWidth: true
                            height: 1
                            color: globalBorder1
                            Layout.topMargin: 4
                            Layout.bottomMargin: 4
                        }

                        // Auto theme sync toggle
                        RowLayout {
                            Layout.fillWidth: true
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Auto Theme Synchronization"
                                    font { pixelSize: 12; family: "Inter" }
                                    font.weight: Font.Medium
                                    color: root.textHigh
                                }
                                Text {
                                    text: "Recolor active wallpaper instantly when switching desktop themes"
                                    font { pixelSize: 11; family: "Inter" }
                                    color: root.textLow
                                }
                            }
                            Item { Layout.fillWidth: true }
                            TitanSwitch {
                                onColor: root.accent
                                checked: WallpaperManager.adaptiveAutoSync
                                onCheckedChanged: WallpaperManager.setAdaptiveAutoSync(checked)
                            }
                        }

                        // Color Intensity Slider
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Color Adaptation Intensity"
                                    font { pixelSize: 12; family: "Inter" }
                                    font.weight: Font.Medium
                                    color: root.textHigh
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: Math.round(WallpaperManager.adaptiveIntensity * 100) + "%"
                                    font { pixelSize: 12; family: "Inter" }
                                    font.weight: Font.SemiBold
                                    color: root.accent
                                }
                            }

                            TitanSlider {
                                Layout.fillWidth: true
                                from: 0.10; to: 1.0; stepSize: 0.05
                                fillColor: root.accent
                                value: WallpaperManager.adaptiveIntensity
                                onValueChanged: WallpaperManager.setAdaptiveIntensity(value)
                            }
                        }

                        // Palette selection pills
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "Theme Palette Mode"
                                font { pixelSize: 12; family: "Inter" }
                                font.weight: Font.Medium
                                color: root.textHigh
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: WallpaperManager.paletteList
                                    delegate: Rectangle {
                                        height: 26
                                        width: palText.implicitWidth + 18
                                        radius: 6
                                        color: WallpaperManager.adaptivePalette === modelData
                                               ? Qt.hsla(root.accent.hslHue, root.accent.hslSaturation, root.accent.hslLightness, 0.22)
                                               : globalBg3
                                        border.width: 1
                                        border.color: WallpaperManager.adaptivePalette === modelData
                                                      ? root.accent
                                                      : globalBorder0

                                        Text {
                                            id: palText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font { pixelSize: 11; family: "Inter" }
                                            font.weight: WallpaperManager.adaptivePalette === modelData ? Font.DemiBold : Font.Normal
                                            color: WallpaperManager.adaptivePalette === modelData ? root.textHigh : root.textMid
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: WallpaperManager.setAdaptivePalette(modelData)
                                        }
                                    }
                                }
                            }
                        }

                        // Action Buttons: Re-sync & Restore
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 4
                            spacing: 10

                            TitanButton {
                                text: "Re-sync Wallpaper"
                                primary: true
                                width: 140
                                height: 28
                                onClicked: WallpaperManager.syncAdaptive()
                            }

                            TitanButton {
                                text: "Restore Original"
                                primary: false
                                width: 140
                                height: 28
                                onClicked: WallpaperManager.restoreOriginal()
                            }

                            Item { Layout.fillWidth: true }
                        }
                    }
                }
            }
        }

        Item { height: 24 }

        // ── Accent Color Section ──────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "ACCENT COLOR"
                    font { pixelSize: 10; family: "Inter" }
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                    color: root.textLow
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    height: 24; width: hexText.implicitWidth + 16; radius: 6
                    color: Qt.hsla(accent.hslHue, accent.hslSaturation, accent.hslLightness, 0.15)
                    border.width: 1; border.color: Qt.hsla(accent.hslHue, accent.hslSaturation, accent.hslLightness, 0.3)

                    Text {
                        id: hexText
                        anchors.centerIn: parent
                        text: SettingsBackend.accentColor.toUpperCase()
                        font { pixelSize: 11; family: "Inter" }
                        font.weight: Font.DemiBold
                        color: root.accent
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Repeater {
                    model: root.accentColors
                    delegate: Item {
                        width: 32; height: 32
                        
                        // Outer selection ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: 32; height: 32; radius: 16
                            color: "transparent"
                            border.width: SettingsBackend.accentColor === modelData ? 2 : 0
                            border.color: root.accent
                            Behavior on border.width { NumberAnimation { duration: 120 } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: SettingsBackend.accentColor === modelData ? 24 : 28
                            height: width; radius: width / 2
                            color: modelData
                            Behavior on width { NumberAnimation { duration: 120 } }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsBackend.accentColor = modelData
                            }
                        }
                    }
                }
            }
        }

        Item { height: 24 }

        // ── Visual Effects Section ───────────────────────────────
        SettingsCard {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            title: "VISUAL EFFECTS"

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 3
                    Text {
                        text: "Blur / transparency"
                        font { pixelSize: 13; family: "Inter" }
                        font.weight: Font.Medium
                        color: root.textHigh
                    }
                    Text {
                        text: "Frosted glass effect on panels"
                        font { pixelSize: 12; family: "Inter" }
                        color: root.textLow
                    }
                }
                Item { Layout.fillWidth: true }
                TitanSwitch {
                    onColor: root.accent
                    checked: SettingsBackend.glassmorphism
                    onCheckedChanged: SettingsBackend.glassmorphism = checked
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: globalBorder1; Layout.topMargin: 8; Layout.bottomMargin: 8 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: "Panel opacity"
                            font { pixelSize: 13; family: "Inter" }
                            font.weight: Font.Medium
                            color: root.textHigh
                        }
                        Text {
                            text: "Transparency level for sidebars"
                            font { pixelSize: 12; family: "Inter" }
                            color: root.textLow
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Math.round(SettingsBackend.panelOpacity * 100) + "%"
                        font { pixelSize: 13; family: "Inter" }
                        font.weight: Font.DemiBold
                        color: root.accent
                    }
                }

                TitanSlider {
                    Layout.fillWidth: true
                    from: 0.4; to: 1.0; stepSize: 0.01
                    fillColor: root.accent
                    value: SettingsBackend.panelOpacity
                    onValueChanged: SettingsBackend.panelOpacity = value
                }
            }
        }

        Item { height: 24 }

        // ── Icon Theme Section ────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            spacing: 10

            Text {
                text: "ICON THEME"
                font { pixelSize: 10; family: "Inter" }
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
                color: root.textLow
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                    model: ["Papirus-dark", "Papirus", "Adwaita", "Breeze-dark"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 84; radius: 10
                        color: globalBg3
                        border.width: SettingsBackend.iconTheme === modelData ? 2 : 1
                        border.color: SettingsBackend.iconTheme === modelData ? root.accent : globalBorder0
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            // Folder icon preview badge
                            Rectangle {
                                Layout.alignment: Qt.AlignHCenter
                                width: 36; height: 26; radius: 5
                                color: modelData === "Adwaita" ? "#E0A93B" :
                                       modelData === "Papirus-dark" ? "#3B82F6" :
                                       modelData === "Papirus" ? "#60A5FA" : "#38BDF8"

                                Rectangle {
                                    x: 3; y: -3; width: 14; height: 8; radius: 2
                                    color: Qt.lighter(parent.color, 1.2)
                                }
                            }

                            Text {
                                text: modelData
                                Layout.alignment: Qt.AlignHCenter
                                font { pixelSize: 12; family: "Inter" }
                                font.weight: SettingsBackend.iconTheme === modelData ? Font.Medium : Font.Normal
                                color: SettingsBackend.iconTheme === modelData ? root.textHigh : root.textMid
                            }
                        }

                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: SettingsBackend.iconTheme = modelData
                        }
                    }
                }
            }
        }

        Item { height: 24 }

        // ── Typography Section ────────────────────────────────────
        SettingsCard {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            title: "TYPOGRAPHY"

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "Font family"
                    font { pixelSize: 13; family: "Inter" }
                    font.weight: Font.Medium
                    color: root.textHigh
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: ["Inter", "JetBrains Mono", "Fira Code", "Roboto", "Noto Sans"]
                        delegate: Rectangle {
                            height: 32
                            Layout.fillWidth: true
                            radius: 6
                            color: SettingsBackend.fontFamily === modelData ? root.accent : globalBg4
                            border.width: 1
                            border.color: SettingsBackend.fontFamily === modelData ? root.accent : globalBorder0

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font { pixelSize: 12; family: modelData }
                                font.weight: SettingsBackend.fontFamily === modelData ? Font.Medium : Font.Normal
                                color: SettingsBackend.fontFamily === modelData ? TitanTheme.accentFg : root.textMid
                            }

                            MouseArea {
                                anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: SettingsBackend.fontFamily = modelData
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: globalBorder1; Layout.topMargin: 8; Layout.bottomMargin: 8 }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 3
                        Text {
                            text: "Font size"
                            font { pixelSize: 13; family: "Inter" }
                            font.weight: Font.Medium
                            color: root.textHigh
                        }
                        Text {
                            text: "System-wide interface font size"
                            font { pixelSize: 12; family: "Inter" }
                            color: root.textLow
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: SettingsBackend.fontSize + " pt"
                        font { pixelSize: 13; family: "Inter" }
                        font.weight: Font.DemiBold
                        color: root.accent
                    }
                }

                TitanSlider {
                    Layout.fillWidth: true
                    from: 9; to: 18; stepSize: 1
                    fillColor: root.accent
                    value: SettingsBackend.fontSize
                    onValueChanged: SettingsBackend.fontSize = value
                }
            }
        }

        Item { height: 24 }

        // ── Action Buttons ────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24; Layout.rightMargin: 24
            Item { Layout.fillWidth: true }
            TitanButton { text: "Reset Defaults"; primary: false; width: 140; onClicked: SettingsBackend.resetToDefaults() }
            Item { width: 10 }
            TitanButton { text: "Apply & Save"; primary: true; width: 130; onClicked: SettingsBackend.applyAppearance() }
        }

        Item { height: 28 }
    }
}
