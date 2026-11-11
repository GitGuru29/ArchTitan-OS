import QtQuick
import QtQuick.Layouts

/**
 * TourHeader — Glass-morphism navigation header with window drag and status badges.
 */
Rectangle {
    id: headerRoot
    implicitHeight: 64
    color: "transparent"

    signal closeRequested()

    MouseArea {
        id: dragArea
        anchors.fill: parent
        property point clickPos: "0,0"
        onPressed: {
            clickPos = Qt.point(mouse.x, mouse.y)
        }
        onPositionChanged: {
            if (pressed && typeof rootWindow !== "undefined") {
                var delta = Qt.point(mouse.x - clickPos.x, mouse.y - clickPos.y)
                rootWindow.x += delta.x
                rootWindow.y += delta.y
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 20
        spacing: 14

        // Glowing Titan Logo Squircle
        Rectangle {
            width: 38
            height: 38
            radius: 11
            color: Qt.rgba(0.04, 0.45, 0.88, 0.28)
            border.color: "#0EA5E9"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "⚡"
                font.pixelSize: 18
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            RowLayout {
                spacing: 8
                Text {
                    text: "ARCHTITAN OS"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    font.letterSpacing: 1.2
                    color: "#FFFFFF"
                    font.family: "Inter, sans-serif"
                }

                // Mode Badge (Live ISO vs Installed)
                Rectangle {
                    radius: 4
                    implicitWidth: modeText.implicitWidth + 10
                    implicitHeight: 18
                    color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                           ? Qt.rgba(0.95, 0.60, 0.05, 0.20)
                           : Qt.rgba(0.10, 0.75, 0.45, 0.20)
                    border.color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
                                  ? "#F59E0B"
                                  : "#10B981"
                    border.width: 1

                    Text {
                        id: modeText
                        anchors.centerIn: parent
                        text: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "LIVE ENVIRONMENT" : "INSTALLED SYSTEM"
                        font.pixelSize: 9
                        font.weight: Font.Bold
                        font.letterSpacing: 0.8
                        color: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode) ? "#FBBF24" : "#34D399"
                    }
                }
            }

            Text {
                text: "INTERACTIVE SYSTEM WALKTHROUGH & ONBOARDING"
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 1.0
                color: "#64748B"
                font.family: "Inter, sans-serif"
            }
        }

        // SFX Audio Toggle Button
        Rectangle {
            id: sfxBtn
            width: 34
            height: 34
            radius: 8
            color: sfxHover.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.06)
            border.color: (typeof tourCtrl !== "undefined" && tourCtrl.soundFxEnabled)
                          ? Qt.rgba(0.05, 0.65, 1.0, 0.5)
                          : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: (typeof tourCtrl !== "undefined" && tourCtrl.soundFxEnabled) ? "🔊" : "🔇"
                font.pixelSize: 13
            }

            MouseArea {
                id: sfxHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof tourCtrl !== "undefined") {
                        tourCtrl.soundFxEnabled = !tourCtrl.soundFxEnabled
                    }
                }
            }
        }

        // Close Button
        Rectangle {
            id: closeBtn
            width: 34
            height: 34
            radius: 8
            color: closeHover.containsMouse ? Qt.rgba(0.9, 0.2, 0.2, 0.4) : Qt.rgba(1, 1, 1, 0.06)
            border.color: closeHover.containsMouse ? "#EF4444" : Qt.rgba(1, 1, 1, 0.12)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                font.weight: Font.Bold
                color: closeHover.containsMouse ? "#FCA5A5" : "#94A3B8"
            }

            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: headerRoot.closeRequested()
            }
        }
    }
}

