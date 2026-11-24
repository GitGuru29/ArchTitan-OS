import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "slides"

Window {
    id: rootWindow
    width: 860
    height: 560
    visible: true
    title: "Welcome to ArchTitan"
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property int currentSlide: 0
    readonly property int totalSlides: 5
    property real entryProgress: 0.0

    Component.onCompleted: {
        entryAnim.start();
        tourCtrl.playSound("startup");
        keyHandler.forceActiveFocus();
    }

    NumberAnimation {
        id: entryAnim
        target: rootWindow
        property: "entryProgress"
        from: 0.0
        to: 1.0
        duration: 280
        easing.type: Easing.OutCubic
    }

    function goToSlide(idx) {
        if (idx < 0 || idx >= totalSlides || idx === currentSlide) return;
        currentSlide = idx;
    }

    function nextSlide() {
        if (currentSlide < totalSlides - 1) {
            goToSlide(currentSlide + 1);
        }
    }

    function prevSlide() {
        if (currentSlide > 0) {
            goToSlide(currentSlide - 1);
        }
    }

    function finishAndClose() {
        tourCtrl.finishTour(!tourCtrl.showOnStartup);
    }

    // Global Keyboard Navigation
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: true

        Keys.onPressed: function(event) {
            if (event.key === Qt.Key_Right || event.key === Qt.Key_Space || event.key === Qt.Key_Return) {
                if (rootWindow.currentSlide < rootWindow.totalSlides - 1) {
                    rootWindow.nextSlide();
                } else {
                    rootWindow.finishAndClose();
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Backspace) {
                rootWindow.prevSlide();
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                rootWindow.finishAndClose();
                event.accepted = true;
            } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) {
                tourCtrl.playSound("step");
                rootWindow.goToSlide(event.key - Qt.Key_1);
                event.accepted = true;
            }
        }
    }

    // ── macOS Dark Vibrancy Window Surface ──────────────────────────────────
    Rectangle {
        id: mainCard
        anchors.fill: parent
        radius: 18
        opacity: rootWindow.entryProgress
        scale: 0.985 + 0.015 * rootWindow.entryProgress

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#202024" }
            GradientStop { position: 0.45; color: "#1A1A1E" }
            GradientStop { position: 1.0; color: "#141417" }
        }

        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)
        clip: true

        // Top Specular Rim Highlight
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 36
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.34) }
                GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // macOS Titlebar with Traffic Lights & Segmented Chapter Bar
            TourHeader {
                Layout.fillWidth: true
                currentSlide: rootWindow.currentSlide
                totalSlides: rootWindow.totalSlides
                onSlideRequested: function(idx) { rootWindow.goToSlide(idx); }
                onCloseClicked: rootWindow.finishAndClose()
            }

            // 5-Screen macOS Onboarding Stage
            StackLayout {
                id: slideStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: rootWindow.currentSlide

                StepWelcome {
                    onJumpToSlide: function(idx) { rootWindow.goToSlide(idx); }
                }
                StepNavigation {}
                StepShortcuts {}
                StepPersonalize {
                    onFinishRequested: rootWindow.finishAndClose()
                }
                StepHardware {}
            }

            // macOS Setup Assistant Bottom Bar
            TourFooter {
                Layout.fillWidth: true
                currentSlide: rootWindow.currentSlide
                totalSlides: rootWindow.totalSlides
                onPrevClicked: rootWindow.prevSlide()
                onNextClicked: rootWindow.nextSlide()
                onFinishClicked: rootWindow.finishAndClose()
                onSlideRequested: function(idx) { rootWindow.goToSlide(idx); }
            }
        }
    }
}
