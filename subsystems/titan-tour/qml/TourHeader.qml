import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

Item {
    id: root
    height: 52

    property int currentSlide: 0
    property int totalSlides: 5
    signal slideRequested(int index)
    signal closeClicked()

    readonly property var steps: [
        { title: "Welcome",     icon: "\uf015" },
        { title: "Navigation",  icon: "\uf009" },
        { title: "Shortcuts",   icon: "\uf11c" },
        { title: "Hardware",    icon: "\uf2db" },
        { title: "Personalize", icon: "\uf03e" }
    ]

    // Allow moving the window by dragging the header
    DragHandler {
        target: null
        onActiveChanged: {
            if (active && typeof window !== "undefined") {
                window.startSystemMove();
            }
        }
    }

    // Bottom hairline separator
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 14
        spacing: 16

        // Left: Emblem + OS Title + Live/Release Badge
        RowLayout {
            spacing: 10

            Image {
                width: 22
                height: 22
                source: tourCtrl.logoUrl
                fillMode: Image.PreserveAspectFit
                mipmap: true
            }

            Text {
                text: "ArchTitan"
                color: TitanTheme.textHigh
                font.family: TitanTheme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
                font.letterSpacing: 0.5
            }

            Rectangle {
                radius: 4
                implicitHeight: 18
                implicitWidth: badgeText.implicitWidth + 8
                color: tourCtrl.isLiveMode ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.16)
                                           : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
                border.width: 1
                border.color: tourCtrl.isLiveMode ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.4)
                                                  : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: tourCtrl.isLiveMode ? "LIVE MEDIA" : "v2026.11"
                    color: tourCtrl.isLiveMode ? TitanTheme.warning : TitanTheme.accent
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 9
                    font.weight: Font.Bold
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Center: Interactive Step Segmented Pills
        Row {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: root.steps

                Rectangle {
                    id: stepBtn
                    property bool isCurrent: index === root.currentSlide
                    property bool isPast: index < root.currentSlide

                    implicitHeight: 26
                    implicitWidth: stepRow.implicitWidth + 14
                    radius: 13

                    color: isCurrent ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.18)
                                     : (stepMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent")
                    border.width: 1
                    border.color: isCurrent ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)
                                            : "transparent"

                    Behavior on color { ColorAnimation { duration: 150 } }

                    Row {
                        id: stepRow
                        anchors.centerIn: parent
                        spacing: 5

                        // Status dot or icon
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            anchors.verticalCenter: parent.verticalCenter
                            color: stepBtn.isCurrent ? TitanTheme.accent
                                                     : (stepBtn.isPast ? TitanTheme.success : Qt.rgba(1, 1, 1, 0.25))
                        }

                        Text {
                            text: modelData.title
                            color: stepBtn.isCurrent ? TitanTheme.accent
                                                     : (stepBtn.isPast ? TitanTheme.textHigh : TitanTheme.textLow)
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: stepBtn.isCurrent ? Font.Bold : Font.Medium
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    MouseArea {
                        id: stepMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            tourCtrl.playSound("tap");
                            root.slideRequested(index);
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Right: Window Close Button (Circle with X)
        Rectangle {
            id: closeBtn
            width: 28
            height: 28
            radius: 14
            color: closeMouse.pressed ? Qt.rgba(TitanTheme.danger.r, TitanTheme.danger.g, TitanTheme.danger.b, 0.25)
                                      : (closeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(1, 1, 1, 0.04))
            border.width: 1
            border.color: closeMouse.containsMouse ? Qt.rgba(TitanTheme.danger.r, TitanTheme.danger.g, TitanTheme.danger.b, 0.3)
                                                   : Qt.rgba(1, 1, 1, 0.08)

            Behavior on color { ColorAnimation { duration: 120 } }

            Text {
                anchors.centerIn: parent
                text: "\uf00d" // Times / close icon
                color: closeMouse.containsMouse ? TitanTheme.danger : TitanTheme.textLow
                font.family: TitanTheme.monoFamily
                font.pixelSize: 11
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tourCtrl.playSound("click");
                    root.closeClicked();
                }
            }
        }
    }
}
