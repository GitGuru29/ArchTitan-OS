import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI

Item {
    id: root
    height: 58

    property int currentSlide: 0
    property int totalSlides: 6
    signal slideRequested(int index)
    signal closeClicked()

    readonly property var actMeta: [
        { code: "01", label: "GENESIS",  icon: "\uf135", color: TitanTheme.accent },
        { code: "02", label: "HOTZONES", icon: "\uf05b", color: TitanTheme.info },
        { code: "03", label: "HYPRLAND", icon: "\uf11c", color: TitanTheme.mauve },
        { code: "04", label: "CONTROL",  icon: "\uf1de", color: TitanTheme.teal },
        { code: "05", label: "THM v3",   icon: "\uf2db", color: TitanTheme.success },
        { code: "06", label: "IGNITION", icon: "\uf0e7", color: TitanTheme.warning }
    ]

    // Floating Capsule Drop Shadow
    MultiEffect {
        anchors.fill: capsuleBg
        source: capsuleBg
        shadowEnabled: true
        shadowColor: "#CC000000"
        shadowBlur: 0.85
        shadowVerticalOffset: 8
    }

    Rectangle {
        id: capsuleBg
        anchors.fill: parent
        radius: 29
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.94) }
            GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b, 0.94) }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.11)

        // Top Specular Highlight
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 56
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.24) }
                GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.55) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.24) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 14
        spacing: 12

        // Left: Brand Emblem + Telemetry Tag
        RowLayout {
            spacing: 10

            Item {
                width: 34
                height: 34

                TitanArcItem {
                    anchors.fill: parent
                    color: root.actMeta[root.currentSlide].color
                    trackColor: Qt.rgba(1, 1, 1, 0.08)
                    lineWidth: 3
                    startAngle: -90.0
                    sweepAngle: 360.0 * ((root.currentSlide + 1) / root.totalSlides)
                    showTrack: true
                    roundCaps: true
                }

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: tourCtrl.logoUrl
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                }
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: "ARCHTITAN"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Black
                    font.letterSpacing: 1.6
                }
                Text {
                    text: "TDL 2.0 SPATIAL TOUR"
                    color: TitanTheme.info
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 24
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // Center: Interactive 6-Act Segmented Pill Navigation Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 5

            Repeater {
                model: root.actMeta

                delegate: Rectangle {
                    id: actPill
                    required property var modelData
                    required property int index

                    readonly property bool isCurrent: index === root.currentSlide
                    readonly property bool isPast: index < root.currentSlide

                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 18
                    color: isCurrent
                        ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.18)
                        : (pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(1, 1, 1, 0.02))
                    border.width: 1
                    border.color: isCurrent
                        ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.65)
                        : (isPast ? Qt.rgba(modelData.color.r, modelData.color.g, modelData.color.b, 0.25) : Qt.rgba(1, 1, 1, 0.05))

                    Behavior on color { ColorAnimation { duration: 180 } }
                    Behavior on border.color { ColorAnimation { duration: 180 } }

                    // Active bottom glow bar
                    Rectangle {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: actPill.isCurrent ? 28 : 0
                        height: 2
                        radius: 1
                        color: actPill.modelData.color
                        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: actPill.isPast ? "\uf00c" : actPill.modelData.icon
                            color: actPill.isCurrent ? actPill.modelData.color : (actPill.isPast ? TitanTheme.textMid : TitanTheme.textLow)
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 11
                        }

                        Text {
                            text: actPill.modelData.code + " " + actPill.modelData.label
                            color: actPill.isCurrent ? TitanTheme.textHigh : (actPill.isPast ? TitanTheme.textMid : TitanTheme.textLow)
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: actPill.isCurrent ? Font.Bold : Font.Medium
                            font.letterSpacing: 0.5
                        }
                    }

                    MouseArea {
                        id: pillMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tourCtrl.playSound("step");
                            root.slideRequested(actPill.index);
                        }
                    }
                }
            }
        }

        // Divider
        Rectangle {
            width: 1
            height: 24
            color: Qt.rgba(1, 1, 1, 0.08)
        }

        // Right: Mode Badge + Audio SFX Toggle + Close Button
        RowLayout {
            spacing: 8

            // Environment Mode Pill
            Rectangle {
                height: 28
                width: modeRow.implicitWidth + 18
                radius: 14
                color: tourCtrl.isLiveMode
                    ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.14)
                    : Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.14)
                border.width: 1
                border.color: tourCtrl.isLiveMode
                    ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.45)
                    : Qt.rgba(TitanTheme.success.r, TitanTheme.success.g, TitanTheme.success.b, 0.45)

                RowLayout {
                    id: modeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: tourCtrl.isLiveMode ? TitanTheme.warning : TitanTheme.success
                    }

                    Text {
                        text: tourCtrl.isLiveMode ? "LIVE ISO" : "INSTALLED"
                        color: tourCtrl.isLiveMode ? TitanTheme.warning : TitanTheme.success
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        font.letterSpacing: 0.6
                    }
                }
            }

            // Audio SFX Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: sfxArea.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: tourCtrl.soundFxEnabled
                    ? Qt.rgba(TitanTheme.info.r, TitanTheme.info.g, TitanTheme.info.b, 0.4)
                    : Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: tourCtrl.soundFxEnabled ? "\uf028" : "\uf026"
                    color: tourCtrl.soundFxEnabled ? TitanTheme.info : TitanTheme.textLow
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: sfxArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.soundFxEnabled = !tourCtrl.soundFxEnabled;
                        if (tourCtrl.soundFxEnabled) tourCtrl.playSound("click");
                    }
                }
            }

            // Close Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: closeArea.containsMouse
                    ? Qt.rgba(TitanTheme.danger.r, TitanTheme.danger.g, TitanTheme.danger.b, 0.24)
                    : Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: closeArea.containsMouse
                    ? Qt.rgba(TitanTheme.danger.r, TitanTheme.danger.g, TitanTheme.danger.b, 0.6)
                    : Qt.rgba(1, 1, 1, 0.08)

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    color: closeArea.containsMouse ? TitanTheme.danger : TitanTheme.textMid
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.closeClicked()
                }
            }
        }
    }
}

