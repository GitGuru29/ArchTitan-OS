import QtQuick
import "../components"

/**
 * PersonalizationScene — Slide 09: "Make It Yours"
 * Matches panel 9/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Make It Yours",
 *           "Customize your experience with themes, wallpapers and more."
 *   - Right: 3D fanned floating wallpaper preview cards above a pill of
 *            5 circular theme accent swatches.
 *   Non-destructive preview: selecting a card or swatch previews it without
 *   altering the installed desktop theme unless explicitly applied.
 */
Item {
    id: root

    property int selectedCard: 1
    property int selectedSwatch: 0

    readonly property var swatches: [
        { id: "archtitan",  color: "#00D2FF", name: "ArchTitan Cyan" },
        { id: "mocha",      color: "#3B82F6", name: "Sapphire Mocha" }, // tdl-allow
        { id: "rosepine",   color: "#FB7185", name: "Rosé Coral" },     // tdl-allow
        { id: "dracula",    color: "#A855F7", name: "Dracula Violet" }, // tdl-allow
        { id: "tokyonight", color: "#334155", name: "Obsidian Stealth" } // tdl-allow
    ]

    SlideContainer {
        anchors.fill: parent
        title: "Make It Yours"
        subtitle: "Customize your experience\nwith themes, wallpapers\nand more."

        // Right Column Artwork: 3D Fanned Floating Wallpaper Cards + 5 Accent Swatches
        Item {
            anchors.fill: parent

            // Left tilted wallpaper card
            Rectangle {
                id: cardLeft
                width: 146
                height: 112
                radius: 14
                x: parent.width * 0.06
                y: parent.height * 0.34
                rotation: -14
                scale: root.selectedCard === 0 ? 1.06 : 0.96
                color: "#140F2D" // tdl-allow
                border.width: root.selectedCard === 0 ? 2 : 1.5
                border.color: root.selectedCard === 0 ? "#00D2FF" : "#88A855F7" // tdl-allow
                clip: true

                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: (typeof tourCtrl !== "undefined" && tourCtrl.wallpapers.length > 6)
                        ? tourCtrl.wallpapers[6].url
                        : (typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : "")
                    sourceSize: Qt.size(240, 150)
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#44C084FC" } // tdl-allow
                        GradientStop { position: 1.0; color: "#66090D1A" } // tdl-allow
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedCard = 0;
                        if (typeof tourCtrl !== "undefined" && tourCtrl.wallpapers.length > 6)
                            tourCtrl.selectPreviewWallpaper(tourCtrl.wallpapers[6].path);
                    }
                }
            }

            // Right tilted wallpaper card
            Rectangle {
                id: cardRight
                width: 152
                height: 116
                radius: 14
                x: parent.width * 0.58
                y: parent.height * 0.28
                rotation: 12
                scale: root.selectedCard === 2 ? 1.06 : 0.96
                color: "#09192F" // tdl-allow
                border.width: root.selectedCard === 2 ? 2 : 1.5
                border.color: root.selectedCard === 2 ? "#00D2FF" : "#6638BDF8"
                clip: true

                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: (typeof tourCtrl !== "undefined" && tourCtrl.wallpapers.length > 2)
                        ? tourCtrl.wallpapers[2].url
                        : (typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : "")
                    sourceSize: Qt.size(240, 150)
                    fillMode: Image.PreserveAspectCrop
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#3300D2FF" }
                        GradientStop { position: 1.0; color: "#66050B16" } // tdl-allow
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectedCard = 2;
                        if (typeof tourCtrl !== "undefined" && tourCtrl.wallpapers.length > 2)
                            tourCtrl.selectPreviewWallpaper(tourCtrl.wallpapers[2].path);
                    }
                }
            }

            // Center hero floating wallpaper card (elevated z-order)
            Rectangle {
                id: cardCenter
                width: 192
                height: 146
                radius: 16
                x: parent.width * 0.27
                y: parent.height * 0.14
                rotation: -4
                z: 5
                scale: root.selectedCard === 1 ? 1.04 : 0.98
                color: "#0C1428" // tdl-allow
                border.width: 2
                border.color: root.swatches[root.selectedSwatch].color
                clip: true

                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Image {
                    anchors.fill: parent
                    anchors.margins: 2
                    source: typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : ""
                    sourceSize: Qt.size(320, 200)
                    fillMode: Image.PreserveAspectCrop
                }

                // Mountain / cosmic aurora highlight inside center card
                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#338B5CF6" } // tdl-allow
                        GradientStop { position: 0.55; color: "#2200D2FF" }
                        GradientStop { position: 1.0; color: "#77050A14" } // tdl-allow
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedCard = 1
                }
            }

            // Bottom floating dock of 5 circular color accent dots (matching Image 2 panel 9/10)
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                width: swatchRow.implicitWidth + 28
                height: 42
                radius: 21
                color: "#CC0B1322" // tdl-allow
                border.width: 1
                border.color: "#2EFFFFFF"
                z: 10

                Row {
                    id: swatchRow
                    anchors.centerIn: parent
                    spacing: 14

                    Repeater {
                        model: root.swatches

                        Rectangle {
                            readonly property bool isSel: index === root.selectedSwatch
                            width: 22
                            height: 22
                            radius: 11
                            color: modelData.color
                            border.width: isSel ? 2.5 : 1
                            border.color: isSel ? "#FFFFFF" : "#44FFFFFF"
                            scale: isSel ? 1.15 : 1.0

                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedSwatch = index;
                                    if (typeof tourCtrl !== "undefined") {
                                        tourCtrl.selectPreviewTheme(modelData.id);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
