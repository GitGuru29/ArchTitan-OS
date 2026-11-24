import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "components"
import "slides"

Window {
    id: rootWindow
    width: coachMode ? 580 : 960
    height: coachMode ? 112 : 620
    visible: true
    title: "Welcome to ArchTitan"
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    property int currentSlide: 0
    readonly property int totalSlides: 8
    property bool coachMode: false
    property int activeCoachStep: 0
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
            duration: 210
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: rootWindow
            property: "slideOffset"
            from: 14
            to: 0
            duration: 220
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

    function enterCoachMode(stepIdx) {
        activeCoachStep = (typeof stepIdx === "number" && stepIdx >= 0 && stepIdx < 5) ? stepIdx : 0;
        coachMode = true;
        tourCtrl.setCoachWindowGeometry(true);
    }

    function exitCoachMode() {
        coachMode = false;
        tourCtrl.setCoachWindowGeometry(false);
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
            if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
                if (!rootWindow.coachMode && rootWindow.currentSlide < rootWindow.totalSlides - 1) {
                    rootWindow.goToSlide(rootWindow.currentSlide + 1);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
                if (!rootWindow.coachMode && rootWindow.currentSlide > 0) {
                    rootWindow.goToSlide(rootWindow.currentSlide - 1);
                }
                event.accepted = true;
            } else if (event.key === Qt.Key_Escape) {
                if (rootWindow.coachMode) {
                    rootWindow.exitCoachMode();
                } else {
                    rootWindow.finishAndClose();
                }
                event.accepted = true;
            }
        }
    }

    // ── MODE B: Floating Hands-On Desktop Coach Capsule (580 x 112) ─────────
    CoachCapsule {
        visible: rootWindow.coachMode
        anchors.fill: parent
        coachStep: rootWindow.activeCoachStep
        onExpandGuideRequested: rootWindow.exitCoachMode()
        onCloseRequested: rootWindow.finishAndClose()
    }

    // ── MODE A: macOS "What's New & Tips" Master–Detail Split Hub (960 x 620)
    Rectangle {
        id: mainCard
        visible: !rootWindow.coachMode
        anchors.fill: parent
        radius: 18
        opacity: rootWindow.entryProgress

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#212127" }
            GradientStop { position: 0.5; color: "#18181D" }
            GradientStop { position: 1.0; color: "#131317" }
        }

        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
        clip: true

        // Subtle Behind-Window Wallpaper Vibrancy Bleed
        Image {
            anchors.fill: parent
            source: rootWindow.activeWallpaperUrl()
            fillMode: Image.PreserveAspectCrop
            opacity: 0.065
            asynchronous: true
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
                GradientStop { position: 0.25; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 0.5; color: Qt.rgba(100/255, 210/255, 255/255, 0.42) }
                GradientStop { position: 0.75; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ── Left Pane: 244px Frosted Translucent macOS Sidebar ──────────
            TourSidebar {
                Layout.fillHeight: true
                Layout.preferredWidth: 244
                currentChapter: rootWindow.currentSlide
                onChapterSelected: function(idx) { rootWindow.goToSlide(idx); }
                onStartCoachRequested: rootWindow.enterCoachMode(0)
                onCloseRequested: rootWindow.finishAndClose()
            }

            // ── Right Pane: 716px Editorial Visual Story Canvas ─────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Item {
                    anchors.fill: parent
                    anchors.topMargin: rootWindow.slideOffset
                    anchors.bottomMargin: -rootWindow.slideOffset
                    opacity: rootWindow.slideFade

                    StepWelcome {
                        visible: rootWindow.currentSlide === 0
                        anchors.fill: parent
                        onJumpToChapter: function(idx) { rootWindow.goToSlide(idx); }
                        onStartCoachAt: function(cIdx) { rootWindow.enterCoachMode(cIdx); }
                    }

                    StepPersonalize {
                        visible: rootWindow.currentSlide === 1
                        anchors.fill: parent
                        onJumpToChapter: function(idx) { rootWindow.goToSlide(idx); }
                    }

                    StepNavigation {
                        visible: rootWindow.currentSlide === 2 || rootWindow.currentSlide === 3 || rootWindow.currentSlide === 4 || rootWindow.currentSlide === 6
                        anchors.fill: parent
                        chapterIndex: rootWindow.currentSlide
                        onJumpToChapter: function(idx) { rootWindow.goToSlide(idx); }
                        onStartCoachAt: function(cIdx) { rootWindow.enterCoachMode(cIdx); }
                    }

                    StepShortcuts {
                        visible: rootWindow.currentSlide === 5
                        anchors.fill: parent
                        onJumpToChapter: function(idx) { rootWindow.goToSlide(idx); }
                    }

                    StepHardware {
                        visible: rootWindow.currentSlide === 7
                        anchors.fill: parent
                        onFinishRequested: rootWindow.finishAndClose()
                        onStartCoachAt: function(cIdx) { rootWindow.enterCoachMode(cIdx); }
                    }
                }
            }
        }
    }
}
