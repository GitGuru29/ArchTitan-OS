import QtQuick
import "../components"
import "../animations"

/**
 * SpotlightScene — Slide 03: "Everything, Instantly"
 * Matches panel 3/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Everything, Instantly", "Find apps, files, and more with Titan Spotlight.",
 *           and "[ ⌘  Super ]" badge
 *   - Right: Glowing cyan-bordered frosted Spotlight card with "Search anything..."
 *            and 5 staggered items: Titan Browser, Settings, Calculator, Terminal, Files
 */
Item {
    id: root

    property int selectedItem: 0
    onVisibleChanged: if (visible) stagger.trigger()

    StaggerReveal {
        id: stagger
        durationMs: 550
    }

    SlideContainer {
        anchors.fill: parent
        title: "Everything,\nInstantly"
        subtitle: "Find apps, files, and more\nwith Titan Spotlight."
        shortcutText: "Super"
        featureId: "spotlight"
        featureExplored: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
        onShortcutTriggered: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()

        // Right Column Artwork: Frosted Spotlight Card
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, 410)
            height: 274
            radius: 18
            color: "#D80A1220" // tdl-allow
            border.width: 1.5
            border.color: "#6600D2FF"

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8

                // Top search input bar: "🔍  Search anything..."
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 11
                    color: "#060B14" // tdl-allow
                    border.width: 1
                    border.color: "#3300D2FF"

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            text: "⌕"
                            font.family: "Inter"
                            font.pixelSize: 16
                            color: "#64748B" // tdl-allow
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "Search anything..."
                            font.family: "Inter"
                            font.pixelSize: 13
                            color: "#64748B" // tdl-allow
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // 5 staggered results matching Image 2
                Repeater {
                    model: [
                        { label: "Titan Browser", glyph: "🌐", badgeColor: "#0284C7" },
                        { label: "Settings",      glyph: "⚙",  badgeColor: "#3B82F6" }, // tdl-allow
                        { label: "Calculator",    glyph: "⊞",  badgeColor: "#0EA5E9" }, // tdl-allow
                        { label: "Terminal",      glyph: ">_", badgeColor: "#1E293B" }, // tdl-allow
                        { label: "Files",         glyph: "▣",  badgeColor: "#2563EB" }  // tdl-allow
                    ]

                    Rectangle {
                        readonly property bool isSel: index === root.selectedItem
                        width: parent.width
                        height: 36
                        radius: 9
                        color: isSel ? "#2400D2FF" : "transparent"
                        border.width: isSel ? 1 : 0
                        border.color: "#4400D2FF"
                        opacity: stagger.itemFactor(index, 5)

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 12

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 6
                                color: modelData.badgeColor
                                border.width: 1
                                border.color: "#44FFFFFF"
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.glyph
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: "#FFFFFF"
                                }
                            }

                            Text {
                                text: modelData.label
                                font.family: "Inter"
                                font.pixelSize: 13
                                font.weight: isSel ? Font.DemiBold : Font.Normal
                                color: isSel ? "#FFFFFF" : "#CBD5E1" // tdl-allow
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedItem = index;
                                if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature();
                            }
                        }
                    }
                }
            }
        }
    }
}
