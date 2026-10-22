import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Presentation {
    id: presentation

    Timer {
        interval: 7000
        running: true
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    // ── Slide 1: Welcome ──────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#11111B"

            // Background image
            Image {
                anchors.fill: parent
                source: "bg.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.55
            }

            // Top neon line
            Rectangle {
                width: parent.width; height: 2
                anchors.top: parent.top
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.4; color: "#89B4FA" }
                    GradientStop { position: 0.6; color: "#CBA6F7" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Bottom neon line
            Rectangle {
                width: parent.width; height: 1
                anchors.bottom: parent.bottom
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "rgba(137,180,250,0.3)" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 22
                width: parent.width * 0.72

                // Logo ring
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 128; height: 128

                    Rectangle {
                        anchors.centerIn: parent
                        width: 128; height: 128; radius: 64
                        color: "transparent"
                        border.width: 1
                        border.color: "rgba(137,180,250,0.25)"
                    }
                    Rectangle {
                        anchors.centerIn: parent
                        width: 112; height: 112; radius: 56
                        color: "rgba(137,180,250,0.05)"
                        border.width: 1
                        border.color: "rgba(137,180,250,0.15)"
                    }
                    Image {
                        anchors.centerIn: parent
                        source: "logo.png"
                        width: 88; height: 88
                        fillMode: Image.PreserveAspectFit
                    }
                }

                // Glassmorphic title card
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    height: 72
                    radius: 12
                    color: "rgba(137,180,250,0.05)"
                    border.width: 1
                    border.color: "rgba(137,180,250,0.22)"

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "WELCOME TO ARCHTITAN OS"
                            font.pointSize: 18
                            font.weight: Font.Bold
                            color: "#89B4FA"
                            font.letterSpacing: 3
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "VERSION  1.0  ·  ARCH LINUX"
                            font.pointSize: 9
                            color: "#6C7086"
                            font.letterSpacing: 4
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "A powerful, developer-focused Arch Linux distribution\nbuilt for performance, elegance, and speed."
                    font.pointSize: 11
                    color: "#A6ADC8"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.65
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Tag row
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Repeater {
                        model: ["Wayland", "Rolling Release", "Dev-Ready", "Minimal"]
                        Rectangle {
                            height: 26; radius: 13
                            width: tagText.implicitWidth + 24
                            color: "rgba(137,180,250,0.08)"
                            border.width: 1
                            border.color: "rgba(137,180,250,0.25)"
                            Text {
                                id: tagText
                                anchors.centerIn: parent
                                text: modelData
                                color: "#89B4FA"
                                font.pointSize: 8
                                font.letterSpacing: 1
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Slide 2: Hyprland Desktop ─────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#11111B"

            Image {
                anchors.fill: parent
                source: "bg.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.45
            }

            Rectangle {
                width: parent.width; height: 2
                anchors.top: parent.top
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#89B4FA" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width * 0.75

                // Icon badge
                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72; height: 72; radius: 36
                    color: "rgba(137,180,250,0.08)"
                    border.width: 1
                    border.color: "rgba(137,180,250,0.35)"
                    Text {
                        anchors.centerIn: parent
                        text: "⬡"
                        font.pointSize: 28
                        color: "#89B4FA"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "HYPRLAND DESKTOP"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    color: "#89B4FA"
                    font.letterSpacing: 3
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "A blazing-fast Wayland compositor with GPU-accelerated\nanimations, dynamic tiling, and total visual control."
                    font.pointSize: 11
                    color: "#A6ADC8"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.6
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Feature cards
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Repeater {
                        model: [
                            { icon: "◈", title: "Waybar", sub: "Status Bar" },
                            { icon: "◉", title: "Wofi",   sub: "App Launcher" },
                            { icon: "▣", title: "Kitty",  sub: "GPU Terminal" }
                        ]
                        Rectangle {
                            width: 110; height: 72; radius: 10
                            color: "rgba(137,180,250,0.06)"
                            border.width: 1
                            border.color: "rgba(137,180,250,0.2)"
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; font.pointSize: 18; color: "#89B4FA" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.title; font.pointSize: 9; font.weight: Font.Bold; color: "#CDD6F4" }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.sub; font.pointSize: 8; color: "#6C7086" }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Slide 3: Developer Tools ───────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#11111B"

            Image {
                anchors.fill: parent
                source: "bg.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.45
            }

            Rectangle {
                width: parent.width; height: 2
                anchors.top: parent.top
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#A6E3A1" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width * 0.75

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72; height: 72; radius: 36
                    color: "rgba(166,227,161,0.08)"
                    border.width: 1
                    border.color: "rgba(166,227,161,0.35)"
                    Text {
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pointSize: 28
                        color: "#A6E3A1"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "DEVELOPER POWERHOUSE"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    color: "#A6E3A1"
                    font.letterSpacing: 3
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Pre-configured with a complete development environment.\nCode from the moment you log in — zero setup required."
                    font.pointSize: 11
                    color: "#A6ADC8"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.6
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Tool grid
                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 3
                    spacing: 10

                    Repeater {
                        model: [
                            { icon: "◈", name: "VS Code" },
                            { icon: "◉", name: "Neovim" },
                            { icon: "▲", name: "Node.js" },
                            { icon: "◆", name: "Go + Rust" },
                            { icon: "⬡", name: "Docker" },
                            { icon: "✦", name: "GitHub CLI" }
                        ]
                        Rectangle {
                            width: 100; height: 52; radius: 8
                            color: "rgba(166,227,161,0.05)"
                            border.width: 1
                            border.color: "rgba(166,227,161,0.18)"
                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text { text: modelData.icon; font.pointSize: 14; color: "#A6E3A1"; anchors.verticalCenter: parent.verticalCenter }
                                Text { text: modelData.name; font.pointSize: 9; font.weight: Font.Bold; color: "#CDD6F4"; anchors.verticalCenter: parent.verticalCenter }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Slide 4: Performance & Security ───────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#11111B"

            Image {
                anchors.fill: parent
                source: "bg.png"
                fillMode: Image.PreserveAspectCrop
                opacity: 0.45
            }

            Rectangle {
                width: parent.width; height: 2
                anchors.top: parent.top
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: "#CBA6F7" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width * 0.75

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72; height: 72; radius: 36
                    color: "rgba(203,166,247,0.08)"
                    border.width: 1
                    border.color: "rgba(203,166,247,0.35)"
                    Text {
                        anchors.centerIn: parent
                        text: "🛡"
                        font.pointSize: 28
                        color: "#CBA6F7"
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "BUILT FOR PERFORMANCE"
                    font.pointSize: 18
                    font.weight: Font.Bold
                    color: "#CBA6F7"
                    font.letterSpacing: 3
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "ArchTitan ships with optimized defaults that balance\nperformance, security, and usability out of the box."
                    font.pointSize: 11
                    color: "#A6ADC8"
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.6
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Stat cards
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Repeater {
                        model: [
                            { value: "Rolling", label: "Release Model",  color: "#CBA6F7" },
                            { value: "LUKS",    label: "Disk Encryption", color: "#CBA6F7" },
                            { value: "Zero",    label: "Bloatware",       color: "#A6E3A1" }
                        ]
                        Rectangle {
                            width: 115; height: 72; radius: 10
                            color: "rgba(203,166,247,0.05)"
                            border.width: 1
                            border.color: "rgba(203,166,247,0.18)"
                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.value
                                    font.pointSize: 14
                                    font.weight: Font.Bold
                                    color: modelData.color
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pointSize: 8
                                    color: "#6C7086"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
