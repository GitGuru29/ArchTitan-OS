import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import "components"
import "slides"

Window {
    id: rootWindow
    width: 880
    height: 560
    visible: true
    title: "ArchTitan Onboarding Tour"
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property int currentSlideIndex: 0
    readonly property int totalSlides: 6

    // Keyboard navigation
    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (typeof tourCtrl !== "undefined") tourCtrl.closeApp();
            else rootWindow.close();
        }
        Keys.onRightPressed: advanceSlide()
        Keys.onSpacePressed: advanceSlide()
        Keys.onLeftPressed: previousSlide()
    }

    function advanceSlide() {
        if (currentSlideIndex < totalSlides - 1) {
            currentSlideIndex++;
            if (typeof tourCtrl !== "undefined") tourCtrl.playSound("tap");
        } else {
            if (typeof tourCtrl !== "undefined") {
                tourCtrl.finishTour(!tourCtrl.showOnStartup);
            } else {
                rootWindow.close();
            }
        }
    }

    function previousSlide() {
        if (currentSlideIndex > 0) {
            currentSlideIndex--;
            if (typeof tourCtrl !== "undefined") tourCtrl.playSound("tap");
        }
    }

    // ── Main Glass Surface ──────────────────────────────────────────────────
    Rectangle {
        id: glassBackground
        anchors.fill: parent
        radius: 22
        clip: true

        // Deep obsidian base
        color: Qt.rgba(0.045, 0.065, 0.095, 0.95)
        border.color: Qt.rgba(1, 1, 1, 0.14)
        border.width: 1

        // Top-Right Ambient Sapphire Aura
        Rectangle {
            width: 450
            height: 450
            radius: 225
            x: parent.width - 250
            y: -150
            color: Qt.rgba(0.05, 0.65, 1.0, 0.12)
        }

        // Bottom-Left Ambient Indigo Aura
        Rectangle {
            width: 400
            height: 400
            radius: 200
            x: -120
            y: parent.height - 200
            color: Qt.rgba(0.40, 0.20, 0.90, 0.10)
        }

        // Window Content Layout
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // 1. Header (64px)
            TourHeader {
                Layout.fillWidth: true
                onCloseRequested: {
                    if (typeof tourCtrl !== "undefined") tourCtrl.closeApp();
                    else rootWindow.close();
                }
            }

            // Top Hairline Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // 2. Central Slide Stage
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Slide 0: Welcome
                SlideWelcome {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 0 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 0 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Slide 1: Keybinds
                SlideKeybinds {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 1 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 1 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Slide 2: Control Center
                SlideControlCenter {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 2 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 2 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Slide 3: Hardware Manager
                SlideHardware {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 3 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 3 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Slide 4: Ecosystem
                SlideEcosystem {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 4 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 4 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                // Slide 5: Launchpad
                SlideLaunch {
                    anchors.fill: parent
                    visible: opacity > 0.001
                    opacity: rootWindow.currentSlideIndex === 5 ? 1.0 : 0.0
                    scale: rootWindow.currentSlideIndex === 5 ? 1.0 : 0.95
                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }
            }

            // Bottom Hairline Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // 3. Navigation Footer (70px)
            TourFooter {
                Layout.fillWidth: true
                currentStep: rootWindow.currentSlideIndex
                totalSteps: rootWindow.totalSlides
                onPreviousRequested: rootWindow.previousSlide()
                onNextRequested: rootWindow.advanceSlide()
                onInstallRequested: {
                    if (typeof tourCtrl !== "undefined") tourCtrl.launchInstaller();
                }
                onFinishRequested: {
                    if (typeof tourCtrl !== "undefined") {
                        tourCtrl.finishTour(!tourCtrl.showOnStartup);
                    } else {
                        rootWindow.close();
                    }
                }
            }
        }
    }
}

