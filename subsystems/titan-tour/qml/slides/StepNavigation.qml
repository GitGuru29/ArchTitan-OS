import QtQuick
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property int chapterIndex: 2
    signal jumpToChapter(int chapterIdx)
    signal startCoachAt(int coachStepIdx)

    readonly property var stories: ({
        2: {
            eyebrow: "DESKTOP & WORKFLOW • CHAPTER 3",
            title: "Top Bar & Dynamic Media Island",
            keys: ["SUPER", "1–9"],
            accent: "#BF5AF2",
            coachIdx: 2,
            nextIdx: 3,
            nextTitle: "Control Center",
            actionLabel: "Open App Menu Live",
            lead: "Your top bar keeps workspaces, live media playback, and system telemetry visible at a glance without cluttering your screen.",
            how1Title: "Categorized App Launcher",
            how1Desc: "Click the top-left ArchTitan emblem to browse all installed software by category.",
            how2Title: "Dynamic MPRIS2 Media Island",
            how2Desc: "Automatically morphs open when music or browser audio plays, showing album art and waveforms.",
            tip1Title: "Instant Workspace Switching",
            tip1Desc: "Click any workspace dot or press ⌘ Super + 1–9 to switch across 10 independent spaces.",
            tip2Title: "Quick Track Controls",
            tip2Desc: "Click the center Media Island to pause playback or skip tracks without leaving your active app.",
            trigger: function() { tourCtrl.toggleMenu(); }
        },
        3: {
            eyebrow: "DESKTOP & WORKFLOW • CHAPTER 4",
            title: "Stepped Control Center",
            keys: ["SUPER", "N"],
            accent: "#5E5CE6",
            coachIdx: 1,
            nextIdx: 4,
            nextTitle: "Spotlight Command Bar",
            actionLabel: "Open Control Center Live",
            lead: "Summon a macOS-inspired frosted bento control center from the top-right corner for instant connectivity, audio, and power toggles.",
            how1Title: "One-Click Wireless & Bluetooth",
            how1Desc: "Toggle Wi-Fi networks, pair Bluetooth headphones, or enable Focus mode from the top tiles.",
            how2Title: "PipeWire Audio & Display Sliders",
            how2Desc: "Drag smooth hardware-accelerated sliders to adjust studio audio output and screen brightness.",
            tip1Title: "Keyboard Summon Chord",
            tip1Desc: "Press ⌘ Super + N from any fullscreen app to toggle Control Center without touching the mouse.",
            tip2Title: "Rapid Power Cycling",
            tip2Desc: "Press ⌘ Super + Shift + P anytime to cycle Low Power, Balanced, and High Performance modes.",
            trigger: function() { tourCtrl.toggleControlCenter(); }
        },
        4: {
            eyebrow: "DESKTOP & WORKFLOW • CHAPTER 5",
            title: "Spotlight Command Bar",
            keys: ["SUPER", "Space"],
            accent: "#32ADE6",
            coachIdx: 0,
            nextIdx: 5,
            nextTitle: "Window Tiling & Spaces",
            actionLabel: "Summon Spotlight Live",
            lead: "Built in native C++20 for sub-millisecond response, Spotlight floats at the center of your display for instant app launching and math.",
            how1Title: "Fuzzy Application Search",
            how1Desc: "Type just 2 or 3 letters—like 'kit' for Kitty or 'set' for Settings—and press Return to launch.",
            how2Title: "Inline Math & Expressions",
            how2Desc: "Type any arithmetic expression directly into Spotlight to evaluate and copy the result.",
            tip1Title: "Single-Key Super Tap",
            tip1Desc: "Tap the ⌘ Super key on its own—or press ⌘ Super + Space—to open Spotlight immediately.",
            tip2Title: "System Power Actions",
            tip2Desc: "Type 'lock', 'reboot', or 'tour' in Spotlight to trigger system actions directly from the keyboard.",
            trigger: function() { tourCtrl.toggleSpotlight(); }
        },
        6: {
            eyebrow: "INTELLIGENCE & CARE • CHAPTER 7",
            title: "TitanFocus Deep Work",
            keys: ["SUPER", "Alt", "F"],
            accent: "#00C7BE",
            coachIdx: 3,
            nextIdx: 7,
            nextTitle: "Hardware Guard (THM v3)",
            actionLabel: "Toggle TitanFocus Live",
            lead: "Protect your attention during coding or study sessions with a lightweight, zero-overhead Pomodoro focus pill anchored at the top edge.",
            how1Title: "25-Minute Deep Work Blocks",
            how1Desc: "Start a structured focus timer that tracks your session progress quietly along the top bezel.",
            how2Title: "Automatic Notification Silencing",
            how2Desc: "While a focus block is active, non-urgent desktop popup banners are held silently in the tray.",
            tip1Title: "Instant Toggle Shortcut",
            tip1Desc: "Press ⌘ Super + Alt + F at any time to summon, pause, or hide the TitanFocus overlay.",
            tip2Title: "Zero Idle Resource Drain",
            tip2Desc: "TitanFocus unloads its rendering surface when hidden, consuming 0% GPU while inactive.",
            trigger: function() { tourCtrl.toggleFocus(); }
        }
    })

    function activeStory() {
        return root.stories[root.chapterIndex] || root.stories[2];
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: 14

        // ── Top 60fps Self-Playing Visual Motion Stage ──────────────────────
        MotionStage {
            Layout.fillWidth: true
            Layout.preferredHeight: 186
            chapterIndex: root.chapterIndex
        }

        // ── Editorial Title, Keycaps & Lead Narrative ───────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.activeStory().eyebrow
                        color: root.activeStory().accent
                        font.family: "Inter"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                    }

                    Text {
                        text: root.activeStory().title
                        color: "#FFFFFF"
                        font.family: "Inter"
                        font.pixelSize: 22
                        font.weight: Font.Bold
                    }
                }

                // 3D Keycap Chord
                Row {
                    spacing: 5
                    Repeater {
                        model: root.activeStory().keys
                        Keycap {
                            text: modelData
                            isAccent: true
                        }
                    }
                }
            }

            Text {
                text: root.activeStory().lead
                color: "#AEAEB2"
                font.family: "Inter"
                font.pixelSize: 13
                lineHeight: 1.35
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        // ── 2-Column Editorial Bento Cards ("How It Works" & "Pro Tips") ────
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // Left Card: How It Works
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.045)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Row {
                        spacing: 6
                        Rectangle {
                            width: 18; height: 18; radius: 5
                            color: root.activeStory().accent
                            Text { anchors.centerIn: parent; text: "\uf05a"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                        }
                        Text {
                            text: "HOW IT WORKS"
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: root.activeStory().how1Title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                        Text { text: root.activeStory().how1Desc; color: "#98989D"; font.family: "Inter"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: root.activeStory().how2Title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                        Text { text: root.activeStory().how2Desc; color: "#98989D"; font.family: "Inter"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Right Card: Pro Tips & Gestures
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 12
                color: Qt.rgba(1, 1, 1, 0.045)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.08)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Row {
                        spacing: 6
                        Rectangle {
                            width: 18; height: 18; radius: 5
                            color: "#FF9F0A"
                            Text { anchors.centerIn: parent; text: "\uf0eb"; color: "#FFF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 9 }
                        }
                        Text {
                            text: "PRO TIPS & SHORTCUTS"
                            color: "#F5F5F7"
                            font.family: "Inter"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            font.letterSpacing: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: root.activeStory().tip1Title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                        Text { text: root.activeStory().tip1Desc; color: "#98989D"; font.family: "Inter"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: root.activeStory().tip2Title; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                        Text { text: root.activeStory().tip2Desc; color: "#98989D"; font.family: "Inter"; font.pixelSize: 11; Layout.fillWidth: true; wrapMode: Text.WordWrap }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }

        // ── Bottom Interactive Hands-On Playground Bar ──────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Try Live Overlay Button
            Rectangle {
                implicitHeight: 34
                implicitWidth: tryRow.implicitWidth + 20
                radius: 8
                color: tryArea.containsMouse ? "#383840" : "#2A2A30"
                border.width: 1
                border.color: root.activeStory().accent

                Row {
                    id: tryRow; anchors.centerIn: parent; spacing: 7
                    Text { text: "▶"; color: root.activeStory().accent; font.family: "Inter"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: root.activeStory().actionLabel; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    id: tryArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.activeStory().trigger()
                }
            }

            // Guide Me on Desktop Button (Enters Floating Coach Capsule Mode)
            Rectangle {
                implicitHeight: 34
                implicitWidth: gRow.implicitWidth + 20
                radius: 8
                color: gArea.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.22)
                                           : Qt.rgba(10/255, 132/255, 255/255, 0.12)
                border.width: 1
                border.color: "#0A84FF"

                Row {
                    id: gRow; anchors.centerIn: parent; spacing: 7
                    Text { text: "\uf140"; color: "#64D2FF"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                    Text { text: "Guide Me on Desktop"; color: "#F5F5F7"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600; anchors.verticalCenter: parent.verticalCenter }
                }

                MouseArea {
                    id: gArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: root.startCoachAt(root.activeStory().coachIdx)
                }
            }

            Item { Layout.fillWidth: true }

            // Next Topic Button
            Rectangle {
                implicitHeight: 34
                implicitWidth: nxtRow.implicitWidth + 22
                radius: 8
                gradient: Gradient {
                    GradientStop { position: 0.0; color: nxtArea.containsMouse ? "#2894FF" : "#188BFF" }
                    GradientStop { position: 1.0; color: nxtArea.containsMouse ? "#0A84FF" : "#007AFF" }
                }
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                Row {
                    id: nxtRow; anchors.centerIn: parent; spacing: 6
                    Text { text: "Next: " + root.activeStory().nextTitle; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 12; font.weight: 600 }
                    Text { text: "→"; color: "#FFFFFF"; font.family: "Inter"; font.pixelSize: 13; font.weight: Font.Bold }
                }

                MouseArea {
                    id: nxtArea; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.jumpToChapter(root.activeStory().nextIdx);
                    }
                }
            }
        }
    }
}
