import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI
import "components"

Item {
    id: root
    height: 58

    property int currentSlide: 0
    property int totalSlides: 5
    signal prevClicked()
    signal nextClicked()
    signal finishClicked()

    // Top hairline separator
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Qt.rgba(1, 1, 1, 0.07)
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 18
        spacing: 16

        // Left: Live ISO Calamares button OR Installed Startup Switch
        RowLayout {
            spacing: 10
            visible: !tourCtrl.isLiveMode

            TitanSwitch {
                checked: tourCtrl.showOnStartup
                onToggled: function(state) {
                    tourCtrl.showOnStartup = state;
                }
            }

            Text {
                text: "Show on login"
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
            }
        }

        // Live ISO Quick Installer Action
        Rectangle {
            id: liveInstallBtn
            visible: tourCtrl.isLiveMode
            implicitHeight: 32
            implicitWidth: liveInstallRow.implicitWidth + 20
            radius: 8
            color: liveInstallMouse.containsMouse ? Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.22)
                                                 : Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.12)
            border.width: 1
            border.color: Qt.rgba(TitanTheme.warning.r, TitanTheme.warning.g, TitanTheme.warning.b, 0.45)

            Row {
                id: liveInstallRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "\uf019" // Download/Install icon
                    color: TitanTheme.warning
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 11
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Install to Disk"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
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
                onClicked: {
                    tourCtrl.launchInstaller();
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Center: Keyboard Navigation Hints
        Row {
            spacing: 6
            Layout.alignment: Qt.AlignVCenter

            Keycap {
                text: "←"
                implicitHeight: 20
                implicitWidth: 20
            }
            Keycap {
                text: "→"
                implicitHeight: 20
                implicitWidth: 20
            }
            Text {
                text: "Navigate"
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { width: 8; height: 1 }

            Keycap {
                text: "ESC"
                implicitHeight: 20
            }
            Text {
                text: "Close"
                color: TitanTheme.textLow
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Item { Layout.fillWidth: true }

        // Right: Navigation Buttons (Back & Next / Finish)
        RowLayout {
            spacing: 10

            // Back button
            Rectangle {
                id: backBtn
                visible: root.currentSlide > 0
                implicitHeight: 34
                implicitWidth: 80
                radius: 8
                color: backMouse.pressed ? Qt.rgba(1, 1, 1, 0.12)
                                         : (backMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.04))
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)

                Text {
                    anchors.centerIn: parent
                    text: "Back"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Medium
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

            // Next / Finish button
            Rectangle {
                id: nextBtn
                property bool isLast: root.currentSlide === root.totalSlides - 1

                implicitHeight: 34
                implicitWidth: isLast ? 120 : 96
                radius: 8

                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: nextBtn.isLast ? TitanTheme.accent : Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.85)
                    }
                    GradientStop {
                        position: 1.0
                        color: nextBtn.isLast ? TitanTheme.teal : TitanTheme.accent
                    }
                }

                border.width: 1
                border.color: Qt.rgba(255, 255, 255, 0.25)

                scale: nextMouse.pressed ? 0.97 : (nextMouse.containsMouse ? 1.02 : 1.0)
                Behavior on scale { NumberAnimation { duration: 100 } }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: nextBtn.isLast ? "Get Started" : "Continue"
                        color: TitanTheme.crust
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    Text {
                        text: nextBtn.isLast ? "\uf00c" : "\uf054"
                        color: TitanTheme.crust
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 10
                        anchors.verticalCenter: parent.verticalCenter
                    }
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
