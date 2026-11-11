import QtQuick
import QtQuick.Layouts

/**
 * TourFooter — Cinematic navigation footer with animated step pills, CTA, and startup checkbox.
 */
Rectangle {
    id: footerRoot
    implicitHeight: 70
    color: "transparent"

    property int currentStep: 0
    property int totalSteps: 6
    signal previousRequested()
    signal nextRequested()
    signal installRequested()
    signal finishRequested()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 16

        // Startup Checkbox (Installed mode) / Live info (Live mode)
        RowLayout {
            spacing: 8
            visible: !(typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)

            Rectangle {
                id: checkSquare
                width: 18
                height: 18
                radius: 4
                color: (typeof tourCtrl !== "undefined" && !tourCtrl.showOnStartup)
                       ? "#0EA5E9"
                       : Qt.rgba(1, 1, 1, 0.08)
                border.color: (typeof tourCtrl !== "undefined" && !tourCtrl.showOnStartup)
                              ? "#38BDF8"
                              : Qt.rgba(1, 1, 1, 0.20)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    visible: (typeof tourCtrl !== "undefined" && !tourCtrl.showOnStartup)
                    text: "✓"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof tourCtrl !== "undefined") {
                            tourCtrl.showOnStartup = !tourCtrl.showOnStartup
                        }
                    }
                }
            }

            Text {
                text: "Don't show on system startup"
                font.pixelSize: 11
                color: "#94A3B8"
                font.family: "Inter, sans-serif"

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof tourCtrl !== "undefined") {
                            tourCtrl.showOnStartup = !tourCtrl.showOnStartup
                        }
                    }
                }
            }
        }

        // Live Mode Installer Quick CTA
        Rectangle {
            visible: (typeof tourCtrl !== "undefined" && tourCtrl.isLiveMode)
            implicitHeight: 34
            implicitWidth: 160
            radius: 8
            color: installHover.containsMouse ? Qt.rgba(0.95, 0.55, 0.05, 0.35) : Qt.rgba(0.95, 0.55, 0.05, 0.20)
            border.color: "#F59E0B"
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Text { text: "🚀"; font.pixelSize: 12 }
                Text {
                    text: "Install ArchTitan"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: "#FDE68A"
                    font.family: "Inter, sans-serif"
                }
            }

            MouseArea {
                id: installHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: footerRoot.installRequested()
            }
        }

        Item { Layout.fillWidth: true }

        // Stepper Progress Indicators
        Row {
            spacing: 8
            Layout.alignment: Qt.AlignVCenter

            Repeater {
                model: footerRoot.totalSteps
                delegate: Rectangle {
                    required property int index
                    width: index === footerRoot.currentStep ? 24 : 8
                    height: 8
                    radius: 4
                    color: index === footerRoot.currentStep
                           ? "#0EA5E9"
                           : (index < footerRoot.currentStep ? Qt.rgba(0.05, 0.65, 1.0, 0.45) : Qt.rgba(1, 1, 1, 0.18))
                    Behavior on width { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: footerRoot.currentStep = index
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Back Button
        Rectangle {
            id: backBtn
            visible: footerRoot.currentStep > 0
            implicitHeight: 36
            implicitWidth: 84
            radius: 8
            color: backHover.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "❮ Back"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: "#E2E8F0"
                font.family: "Inter, sans-serif"
            }

            MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: footerRoot.previousRequested()
            }
        }

        // Next / Finish Button
        Rectangle {
            id: nextBtn
            implicitHeight: 36
            implicitWidth: (footerRoot.currentStep === footerRoot.totalSteps - 1) ? 120 : 96
            radius: 8
            color: nextHover.containsMouse ? "#0284C7" : "#0EA5E9"
            border.color: "#38BDF8"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: (footerRoot.currentStep === footerRoot.totalSteps - 1) ? "Get Started 🚀" : "Next ❯"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#FFFFFF"
                font.family: "Inter, sans-serif"
            }

            MouseArea {
                id: nextHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (footerRoot.currentStep === footerRoot.totalSteps - 1) {
                        footerRoot.finishRequested()
                    } else {
                        footerRoot.nextRequested()
                    }
                }
            }
        }
    }
}
