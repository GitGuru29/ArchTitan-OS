import QtQuick
import "../components"
import "../animations"

/**
 * WorkspaceScene — Slide 04: "Your Workspace. Your Flow."
 * Matches panel 4/10 in Image 2 (media_1795534773489_da4d70fb.jpg):
 *   - Left: "Your Workspace.\nYour Flow.", "Organize your work with Mission Control.",
 *           and "[ ⌘  Super + Tab ]" badge
 *   - Right: Frosted Mission Control card containing a 3×2 grid of workspace
 *            previews with miniature app windows and glowing active border.
 */
Item {
    id: root

    property int activeWorkspace: 3
    onVisibleChanged: if (visible) stagger.trigger()

    StaggerReveal {
        id: stagger
        durationMs: 550
    }

    SlideContainer {
        anchors.fill: parent
        title: "Your Workspace.\nYour Flow."
        subtitle: "Organize your work with\nMission Control."
        shortcutText: "Super + Tab"
        featureId: "workspace"
        featureExplored: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
        onShortcutTriggered: if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature()

        // Right Column Artwork: 3x2 Mission Control Workspace Grid
        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, 456)
            height: 256
            radius: 18
            color: "#CC09101E" // tdl-allow
            border.width: 1.5
            border.color: "#3800D2FF"

            Grid {
                anchors.fill: parent
                anchors.margins: 16
                columns: 3
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: [
                        { title: "Code · THM",   win1: "#1E293B", win2: "#0F172A", accent: "#00D2FF" }, // tdl-allow
                        { title: "Desktop 2",    win1: "#1E1B4B", win2: "#312E81", accent: "#89B4FA" }, // tdl-allow
                        { title: "Terminal",     win1: "#091526", win2: "#16243A", accent: "#38BDF8" }, // tdl-allow
                        { title: "Sysmon HUD",   win1: "#06283D", win2: "#00D2FF", accent: "#00D2FF" }, // tdl-allow
                        { title: "TitanBrowser", win1: "#1E293B", win2: "#E2E8F0", accent: "#38BDF8" }, // tdl-allow
                        { title: "Media Studio", win1: "#1E1B4B", win2: "#0284C7", accent: "#CBA6F7" }  // tdl-allow
                    ]

                    Rectangle {
                        readonly property bool isSel: index === root.activeWorkspace
                        width: (parent.width - 24) / 3
                        height: (parent.height - 12) / 2
                        radius: 10
                        color: "#0A1324" // tdl-allow
                        border.width: isSel ? 2 : 1
                        border.color: isSel ? "#00D2FF" : "#2D3E56" // tdl-allow
                        opacity: stagger.itemFactor(index, 6)
                        clip: true

                        // Wallpaper backdrop inside workspace thumbnail
                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: typeof tourCtrl !== "undefined" ? tourCtrl.activeWallpaperUrl : ""
                            sourceSize: Qt.size(160, 90)
                            fillMode: Image.PreserveAspectCrop
                            opacity: 0.48
                        }

                        // Miniature window tile 1
                        Rectangle {
                            x: 10; y: 12
                            width: parent.width * 0.56
                            height: parent.height * 0.58
                            radius: 5
                            color: modelData.win1
                            border.width: 1
                            border.color: "#55FFFFFF"

                            // Window header strip
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 7
                                radius: 4
                                color: modelData.accent
                                opacity: 0.7
                            }
                        }

                        // Miniature window tile 2
                        Rectangle {
                            x: parent.width * 0.36
                            y: parent.height * 0.32
                            width: parent.width * 0.54
                            height: parent.height * 0.54
                            radius: 5
                            color: modelData.win2
                            opacity: 0.9
                            border.width: 1
                            border.color: "#6600D2FF"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeWorkspace = index;
                                if (typeof tourCtrl !== "undefined") tourCtrl.toggleLiveFeature();
                            }
                        }
                    }
                }
            }
        }
    }
}
