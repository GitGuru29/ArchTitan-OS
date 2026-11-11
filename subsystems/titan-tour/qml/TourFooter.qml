import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI

Item {
    id: root
    height: 62

    property int currentSlide: 0
    property int totalSlides: 6
    signal prevClicked()
    signal nextClicked()
    signal finishClicked()

    MultiEffect {
        anchors.fill: dockBg
        source: dockBg
        shadowEnabled: true
        shadowColor: "#CC000000"
        shadowBlur: 0.85
        shadowVerticalOffset: 8
    }

    Rectangle {
        id: dockBg
        anchors.fill: parent
        radius: 31
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
            color: Qt.rgba(1, 1, 1, 0.16)
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 16
        spacing: 16

        // Left: Startup Toggle (Installed) or Direct Calamares Trigger (Live ISO)
        RowLayout {
            spacing: 10
            visible: !tourCtrl.isLiveMode

            TitanSwitch {
                checked: tourCtrl.showOnStartup
                onToggled: function(state) {
                    tourCtrl.showOnStartup = state;
                }
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: "Launch Spatial Tour at Login"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: TitanTheme.weightSemiBold
                }
                Text {
                    text: "Re-open anytime via Super+Space -> 'Tour'"
                    color: TitanTheme.textLow
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                }
            }
        }

        // Live ISO Quick Install Button
        TitanButton {
            visible: tourCtrl.isLiveMode
            text: "Install ArchTitan OS"
            glyph: "\uf019"
            variant: "primary"
            implicitHeight: 38
            implicitWidth: 196
            onClicked: tourCtrl.launchInstaller()
        }

        Item { Layout.fillWidth: true }

        // Center: Tactile Keyboard Navigation Hints
        RowLayout {
            spacing: 12

            Repeater {
                model: [
                    { key: "← / →", desc: "Switch Act" },
                    { key: "1..6",  desc: "Jump" },
                    { key: "ESC",   desc: "Dismiss" }
                ]

                delegate: RowLayout {
                    required property var modelData
                    spacing: 6

                    Rectangle {
                        height: 24
                        width: keyLbl.implicitWidth + 14
                        radius: 6
                        color: Qt.rgba(1, 1, 1, 0.05)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.12)

                        Text {
                            id: keyLbl
                            anchors.centerIn: parent
                            text: modelData.key
                            color: TitanTheme.info
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        text: modelData.desc
                        color: TitanTheme.textLow
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Right: Previous / Next Act Controls
        RowLayout {
            spacing: 10

            TitanButton {
                text: "Previous"
                glyph: "\uf053"
                variant: "ghost"
                enabled: root.currentSlide > 0
                opacity: enabled ? 1.0 : 0.35
                implicitHeight: 38
                implicitWidth: 112
                onClicked: root.prevClicked()
            }

            TitanButton {
                text: root.currentSlide === root.totalSlides - 1 ? "Enter ArchTitan" : "Next Act"
                glyph: root.currentSlide === root.totalSlides - 1 ? "\uf00c" : "\uf054"
                variant: "primary"
                implicitHeight: 38
                implicitWidth: root.currentSlide === root.totalSlides - 1 ? 168 : 132
                onClicked: {
                    if (root.currentSlide === root.totalSlides - 1) {
                        root.finishClicked();
                    } else {
                        root.nextClicked();
                    }
                }
            }
        }
    }
}

