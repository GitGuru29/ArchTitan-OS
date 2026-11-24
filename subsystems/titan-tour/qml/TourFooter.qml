import QtQuick
import QtQuick.Layouts

Item {
    id: root
    height: 60

    property int currentSlide: 0
    property int totalSlides: 5
    signal prevClicked()
    signal nextClicked()
    signal finishClicked()
    signal slideRequested(int index)

    // Subtle macOS footer top divider
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 16

        // ── Left: macOS Checkbox ("Show Welcome Guide at login") or Live Install ──
        Row {
            spacing: 8
            visible: !tourCtrl.isLiveMode
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: macCheck
                width: 16
                height: 16
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: tourCtrl.showOnStartup ? "#0A84FF" : "#2C2C2E"
                border.width: 1
                border.color: tourCtrl.showOnStartup ? "#389BFF" : Qt.rgba(1, 1, 1, 0.22)

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    visible: tourCtrl.showOnStartup
                    anchors.centerIn: parent
                    text: "\uf00c"
                    color: "#FFFFFF"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        tourCtrl.showOnStartup = !tourCtrl.showOnStartup;
                    }
                }
            }

            Text {
                text: "Show Welcome Guide at login"
                color: "#98989D"
                font.family: "Inter"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        tourCtrl.showOnStartup = !tourCtrl.showOnStartup;
                    }
                }
            }
        }

        // Live ISO Quick Installer Action
        Rectangle {
            visible: tourCtrl.isLiveMode
            implicitHeight: 32
            implicitWidth: liveInstallRow.implicitWidth + 20
            radius: 8
            color: liveInstallMouse.containsMouse ? Qt.rgba(10/255, 132/255, 255/255, 0.22)
                                                  : Qt.rgba(10/255, 132/255, 255/255, 0.14)
            border.width: 1
            border.color: "#0A84FF"

            Row {
                id: liveInstallRow
                anchors.centerIn: parent
                spacing: 7

                Text {
                    text: "\uf019"
                    color: "#0A84FF"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Install ArchTitan to Disk…"
                    color: "#F5F5F7"
                    font.family: "Inter"
                    font.pixelSize: 12
                    font.weight: 600
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: liveInstallMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tourCtrl.launchInstaller()
            }
        }

        Item { Layout.fillWidth: true }

        // ── Center: macOS Animated Page Indicator Dots ──────────────────────
        Row {
            spacing: 7
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: root.totalSlides

                Rectangle {
                    property bool isActive: index === root.currentSlide
                    width: isActive ? 22 : 7
                    height: 7
                    radius: 3.5
                    color: isActive ? "#0A84FF"
                                    : (dotMouse.containsMouse ? "#8E8E93" : "#48484A")

                    Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 150 } }

                    MouseArea {
                        id: dotMouse
                        anchors.fill: parent
                        anchors.margins: -3
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

        // ── Right: macOS Setup Assistant Navigation Buttons ─────────────────
        Row {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            // Secondary macOS Back Button
            Rectangle {
                visible: root.currentSlide > 0
                implicitHeight: 32
                implicitWidth: 78
                radius: 7
                color: backMouse.pressed ? "#444448"
                                         : (backMouse.containsMouse ? "#3A3A3E" : "#323236")
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    color: "#F5F5F7"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: 500
                }

                MouseArea {
                    id: backMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        tourCtrl.playSound("tap");
                        root.prevClicked();
                    }
                }
            }

            // Primary Apple System Blue Button
            Rectangle {
                id: nextBtn
                property bool isLast: root.currentSlide === root.totalSlides - 1

                implicitHeight: 32
                implicitWidth: isLast ? 114 : 98
                radius: 7

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: nextMouse.pressed ? "#0070E0"
                                                 : (nextMouse.containsMouse ? "#2894FF" : "#188BFF")
                    }
                    GradientStop {
                        position: 1.0
                        color: nextMouse.pressed ? "#0062CC"
                                                 : (nextMouse.containsMouse ? "#0A84FF" : "#007AFF")
                    }
                }

                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.25)

                Text {
                    anchors.centerIn: parent
                    text: nextBtn.isLast ? "Get Started" : "Continue"
                    color: "#FFFFFF"
                    font.family: "Inter"
                    font.pixelSize: 13
                    font.weight: 600
                }

                MouseArea {
                    id: nextMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (nextBtn.isLast) {
                            root.finishClicked();
                        } else {
                            tourCtrl.playSound("tap");
                            root.nextClicked();
                        }
                    }
                }
            }
        }
    }
}
