import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import ArchTitan.TitanUI
import "slides"

Window {
    id: rootWindow
    width: 860
    height: 540
    visible: true
    title: "ArchTitan Onboarding Tour"
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
        duration: 300
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

    // ── Main Obsidian Glass Card ────────────────────────────────────────────
    Rectangle {
        id: mainCard
        anchors.fill: parent
        radius: 16
        opacity: rootWindow.entryProgress
        scale: 0.98 + 0.02 * rootWindow.entryProgress

        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.96) }
            GradientStop { position: 1.0; color: Qt.rgba(TitanTheme.base.r, TitanTheme.base.g, TitanTheme.base.b, 0.98) }
        }

        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        clip: true

        // Inner Hairline Border
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 15
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.04)
        }

        // Top Specular Highlight Bar
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 60
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.50) }
                GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.20) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header (52px)
            TourHeader {
                Layout.fillWidth: true
                currentSlide: rootWindow.currentSlide
                totalSlides: rootWindow.totalSlides
                onSlideRequested: function(idx) { rootWindow.goToSlide(idx); }
                onCloseClicked: rootWindow.finishAndClose()
            }

            // Slide Viewport (430px)
            StackLayout {
                id: slideStack
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: rootWindow.currentSlide

                StepWelcome {}
                StepNavigation {}
                StepShortcuts {}
                StepHardware {}
                StepPersonalize {
                    onFinishRequested: rootWindow.finishAndClose()
                }
            }

            // Footer (58px)
            TourFooter {
                Layout.fillWidth: true
                currentSlide: rootWindow.currentSlide
                totalSlides: rootWindow.totalSlides
                onPrevClicked: rootWindow.prevSlide()
                onNextClicked: rootWindow.nextSlide()
                onFinishClicked: rootWindow.finishAndClose()
            }
        }
    }
}
