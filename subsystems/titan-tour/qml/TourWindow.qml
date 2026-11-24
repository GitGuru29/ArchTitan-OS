import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Effects
import "slides"

Window {
    id: rootWindow
    width: 900
    height: 580
    visible: true
    title: "Welcome to ArchTitan"
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property int currentSlide: 0
    readonly property int totalSlides: 5
    property real entryProgress: 0.0
    property real slideFade: 1.0
    property real slideOffset: 0.0

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

    ParallelAnimation {
        id: pageTransitionAnim
        NumberAnimation {
            target: rootWindow
            property: "slideFade"
            from: 0.25
            to: 1.0
            duration: 220
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: rootWindow
            property: "slideOffset"
            from: 18
            to: 0
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    function activeWallpaperUrl() {
        var list = tourCtrl.wallpapers;
        for (var i = 0; i < list.length; i++) {
            if (list[i].path === tourCtrl.selectedWallpaper) {
                return list[i].url;
            }
        }
        return list.length > 0 ? list[0].url : "";
    }

    function goToSlide(idx) {
        if (idx < 0 || idx >= totalSlides || idx === currentSlide) return;
        currentSlide = idx;
        pageTransitionAnim.restart();
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

    // ── macOS Sequoia Dark Vibrancy Window Surface ──────────────────────────
    Rectangle {
        id: mainCard
        anchors.fill: parent
        radius: 18
        opacity: rootWindow.entryProgress
        scale: 0.985 + 0.015 * rootWindow.entryProgress

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#222228" }
            GradientStop { position: 0.5; color: "#19191E" }
            GradientStop { position: 1.0; color: "#131317" }
        }

        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
        clip: true

        // Subtle Behind-Window Wallpaper Vibrancy Tint
        Image {
            anchors.fill: parent
            source: rootWindow.activeWallpaperUrl()
            fillMode: Image.PreserveAspectCrop
            opacity: 0.065
            asynchronous: true
        }

        // Inner Hairline Frame
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: 17
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.05)
        }

        // Top Specular Glass Rim
        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 36
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.24) }
                GradientStop { position: 0.5; color: Qt.rgba(100/255, 210/255, 255/255, 0.45) }
                GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.24) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // macOS Titlebar with Traffic Lights & Sliding Segmented Chapter Bar
            TourHeader {
                Layout.fillWidth: true
                currentSlide: rootWindow.currentSlide
                totalSlides: rootWindow.totalSlides
                onSlideRequested: function(idx) { rootWindow.goToSlide(idx); }
                onCloseClicked: rootWindow.finishAndClose()
            }

            // 5-Screen macOS Onboarding Stage with Smooth Transition Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                StackLayout {
                    id: slideStack
                    anchors.fill: parent
                    anchors.leftMargin: rootWindow.slideOffset
                    anchors.rightMargin: -rootWindow.slideOffset
                    opacity: rootWindow.slideFade
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
