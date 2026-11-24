import QtQuick
import "../components"

/**
 * WhatsNewScene — macOS-inspired post-update highlights ("What's New in ArchTitan").
 * Driven dynamically by ReleaseManager from data/release-highlights.json.
 */
Item {
    id: root

    signal continueToDesktop()
    signal openFullTour()
    signal tryFeature(string featureId)

    Rectangle {
        anchors.centerIn: parent
        width: Math.min(parent.width - 72, 880)
        height: col.implicitHeight + 68
        radius: 24
        color: "#D8181825"
        border.width: 1.5
        border.color: "#4400D2FF"

        Column {
            id: col
            anchors.centerIn: parent
            width: parent.width - 64
            spacing: 18

            // Header badge
            Row {
                spacing: 12

                TitanLogo {
                    size: 52
                    glowing: true
                }

                Column {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        text: "WHAT'S NEW IN ARCHTITAN  ·  VERSION " + (typeof tourCtrl !== "undefined" ? tourCtrl.releaseVersion : "2.0.0")
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        font.letterSpacing: 1.4
                        color: "#00D2FF"
                    }

                    Text {
                        text: (typeof tourCtrl !== "undefined" ? tourCtrl.releaseTitle : "ArchTitan 2.0") + " — "
                            + (typeof tourCtrl !== "undefined" ? tourCtrl.releaseTagline : "A new era of desktop computing.")
                        font.family: "Inter"
                        font.pixelSize: 24
                        font.weight: Font.Bold
                        color: "#CDD6F4"
                    }
                }
            }

            // 2x2 grid of release highlights from release-highlights.json
            Grid {
                width: parent.width
                columns: 2
                rowSpacing: 12
                columnSpacing: 12

                Repeater {
                    model: typeof tourCtrl !== "undefined" ? tourCtrl.releaseHighlights : []

                    Rectangle {
                        width: (parent.width - 12) / 2
                        height: 118
                        radius: 16
                        color: "#B81E1E2E"
                        border.width: 1
                        border.color: "#2EFFFFFF"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 6

                            Row {
                                spacing: 10
                                Rectangle {
                                    width: 28; height: 28; radius: 8
                                    color: "#2200D2FF"; border.width: 1; border.color: "#5500D2FF"
                                    Text { anchors.centerIn: parent; text: modelData.glyph || "✦"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; color: "#00D2FF" }
                                }
                                Text {
                                    text: modelData.title
                                    font.family: "Inter"; font.pixelSize: 15; font.weight: Font.Bold; color: "#CDD6F4"
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                width: parent.width
                                text: modelData.body
                                font.family: "Inter"; font.pixelSize: 12; color: "#A6ADC8"
                                wrapMode: Text.WordWrap
                            }
                        }

                        GlassButton {
                            visible: (modelData.feature || "").length > 0
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 10
                            text: "Try it →"
                            variant: "ghost"
                            buttonHeight: 26
                            horizontalPadding: 10
                            onClicked: root.tryFeature(modelData.feature)
                        }
                    }
                }
            }

            // Footer actions
            Item {
                width: parent.width
                height: 44

                GlassButton {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Replay Full Tour"
                    variant: "secondary"
                    buttonHeight: 40
                    onClicked: root.openFullTour()
                }

                GlassButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Continue to ArchTitan →"
                    shortcutHint: "Enter"
                    variant: "primary"
                    buttonHeight: 42
                    horizontalPadding: 24
                    onClicked: root.continueToDesktop()
                }
            }
        }
    }
}

