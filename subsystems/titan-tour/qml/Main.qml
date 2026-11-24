import QtQuick
import QtQuick.Window
import "components"
import "scenes"
import "animations"

/**
 * Main.qml — Root window for ArchTitan Titan Tour ("Rise, Titan.").
 *
 * Visual structure (matching Image 1 & Image 2):
 *   - 3-Layer Fluted Gradient Backdrop (AnimatedBackground)
 *   - Centered floating dark obsidian window (TourWindow) with traffic lights,
 *     bottom progress bar, and navigation buttons
 *   - 10 bespoke animated scenes (WelcomeScene → DesktopScene → SpotlightScene →
 *     WorkspaceScene → QuickSettingsScene → MediaScene → IntelligenceScene →
 *     SecurityScene → PersonalizationScene → CompletionScene)
 *   - Horizontal cinematic slide transitions (+35px → 0 in 420ms OutCubic) that
 *     animate the inner content while the window frame & background stay stable.
 */
Window {
    id: rootWindow

    width: 1180
    height: 720
    visible: true
    title: "Rise, Titan. — ArchTitan Tour"
    flags: Qt.FramelessWindowHint | Qt.Window
    color: "transparent"

    readonly property int totalSlides: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10
    property int currentSlide: typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0
    property int previousSlide: 0
    property real entryProgress: 1.0
    property real slideFade: 1.0
    property real slideOffset: 0.0

    readonly property string activeSceneName: typeof tourCtrl !== "undefined" ? tourCtrl.currentScene : "welcome"
    readonly property bool liveOverlayOpen: typeof tourCtrl !== "undefined" ? tourCtrl.liveFeatureOpen : false

    onWidthChanged: if (typeof tourCtrl !== "undefined") tourCtrl.updateViewportSize(width, height)
    onHeightChanged: if (typeof tourCtrl !== "undefined") tourCtrl.updateViewportSize(width, height)

    WelcomeReveal {
        id: welcomeChoreography
        reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    }

    SlideTransition {
        id: slideTransition
        targetItem: slideStage
        reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
    }

    FinaleTransition {
        id: finaleFade
        targetItem: masterRoot
        reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false
        onFinishedFade: if (typeof tourCtrl !== "undefined") tourCtrl.finishTour()
    }

    Component.onCompleted: {
        if (typeof tourCtrl !== "undefined") {
            tourCtrl.updateViewportSize(width, height);
            tourCtrl.playSound("startup");
        }
        welcomeChoreography.play();
        keyFocusScope.forceActiveFocus();
    }

    function goToSlide(idx) {
        welcomeChoreography.completeImmediately();
        if (typeof tourCtrl !== "undefined") {
            tourCtrl.goToStep(idx);
        }
        slideStage.opacity = 1.0;
        slideStage.x = 0;
        slideStage.scale = 1.0;
    }

    Connections {
        target: typeof tourCtrl !== "undefined" ? tourCtrl : null
        function onCurrentStepChanged() {
            var curr = typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0;
            var isForward = curr >= rootWindow.previousSlide;
            rootWindow.previousSlide = curr;
            welcomeChoreography.completeImmediately();
            slideTransition.trigger(isForward);
            keyFocusScope.forceActiveFocus();
        }
        function onModeChanged() {
            welcomeChoreography.completeImmediately();
            slideTransition.trigger(true);
            keyFocusScope.forceActiveFocus();
        }
    }

    // Master outer canvas (Fluted Gradient Background + Centered Floating Obsidian Window)
    Item {
        id: masterRoot
        anchors.fill: parent

        // Layer 1..3 Fluted Gradient Backdrop (Image 1 & Image 2 outer frame)
        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "#050914" // tdl-allow
            opacity: welcomeChoreography.bgOpacity
            clip: true

            AnimatedBackground {
                anchors.fill: parent
                active: rootWindow.visible
            }
        }

        // Soft drop shadow halo beneath the floating dark window
        Rectangle {
            anchors.centerIn: floatingWindow
            width: floatingWindow.width + 24
            height: floatingWindow.height + 24
            radius: 26
            color: "#66000000"
            opacity: welcomeChoreography.windowOpacity
        }

        // Centered Floating Dark Obsidian Window (stable frame across all 10 slides)
        TourWindow {
            id: floatingWindow
            anchors.centerIn: parent
            width: parent.width - 108
            height: parent.height - 96
            scale: welcomeChoreography.windowScale
            opacity: welcomeChoreography.windowOpacity
            progressOpacity: welcomeChoreography.progressOpacity
            buttonOpacity: welcomeChoreography.buttonOpacity
            buttonOffsetY: welcomeChoreography.buttonOffsetY

            onCloseRequested: if (typeof tourCtrl !== "undefined") tourCtrl.skipForNow()
            onBackRequested: if (typeof tourCtrl !== "undefined") tourCtrl.previous()
            onContinueRequested: if (typeof tourCtrl !== "undefined") tourCtrl.next()
            onStepRequested: function(idx) {
                if (typeof tourCtrl !== "undefined") tourCtrl.goToStep(idx);
            }

            // Inner animated slide content container
            Item {
                id: slideStage
                anchors.fill: parent

                WelcomeScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "welcome"
                    logoOpacity: welcomeChoreography.logoOpacity
                    logoScale: welcomeChoreography.logoScale
                    titleOpacity: welcomeChoreography.titleOpacity
                    titleOffsetY: welcomeChoreography.titleOffsetY
                    subtitleOpacity: welcomeChoreography.subtitleOpacity
                    subtitleOffsetY: welcomeChoreography.subtitleOffsetY
                }

                DesktopScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "desktop"
                }

                SpotlightScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "spotlight"
                }

                WorkspaceScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "workspace"
                }

                QuickSettingsScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "quicksettings"
                }

                MediaScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "media"
                }

                IntelligenceScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "intelligence" || rootWindow.activeSceneName === "sysmon"
                }

                SecurityScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "security"
                }

                PersonalizationScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "personalization" || rootWindow.activeSceneName === "personalize"
                }

                CompletionScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "completion"
                    onEnterDesktopClicked: finaleFade.start()
                    onReplayClicked: if (typeof tourCtrl !== "undefined") tourCtrl.restartTour()
                }

                WhatsNewScene {
                    anchors.fill: parent
                    visible: rootWindow.activeSceneName === "whats-new"
                    onContinueToDesktop: if (typeof tourCtrl !== "undefined") tourCtrl.acknowledgeWhatsNew()
                    onOpenFullTour: if (typeof tourCtrl !== "undefined") tourCtrl.restartTour()
                    onTryFeature: function(fid) {
                        if (typeof tourCtrl !== "undefined") tourCtrl.jumpToFeatureFromWhatsNew(fid);
                    }
                }
            }

            // Live Spotlight Mask & Coach Capsule when an external OS overlay is summoned
            SpotlightMask {
                anchors.fill: parent
                active: rootWindow.liveOverlayOpen
                targetRect: typeof tourCtrl !== "undefined" ? tourCtrl.spotlightRect : Qt.rect(320, 100, 480, 320)
                cornerRadius: 18
                dimOpacity: 0.72
                z: 40
            }

            CoachCapsule {
                visible: rootWindow.liveOverlayOpen
                z: 45
                stepIndex: (typeof tourCtrl !== "undefined" ? tourCtrl.currentIndex : 0) + 1
                totalSteps: rootWindow.totalSlides
                title: typeof tourCtrl !== "undefined" ? (tourCtrl.currentStep.title || "") : ""
                body: typeof tourCtrl !== "undefined" ? (tourCtrl.currentStep.body || "") : ""
                featureName: typeof tourCtrl !== "undefined" ? (tourCtrl.currentStep.badge || "Live feature") : "Live feature"
                shortcutText: typeof tourCtrl !== "undefined" ? (tourCtrl.currentStep.shortcut || "") : ""
                promptText: typeof tourCtrl !== "undefined" ? (tourCtrl.currentStep.prompt || "") : ""
                liveActive: rootWindow.liveOverlayOpen
                featureTried: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
                avoidRect: typeof tourCtrl !== "undefined" ? tourCtrl.spotlightRect : Qt.rect(0, 0, 0, 0)
                viewportSize: Qt.size(floatingWindow.width, floatingWindow.height)
                x: computeSmartPosition().x
                y: computeSmartPosition().y
                onLaunchRequested: if (typeof tourCtrl !== "undefined") tourCtrl.dismissLiveFeature()
                onPreviousRequested: if (typeof tourCtrl !== "undefined") tourCtrl.previous()
                onSkipRequested: if (typeof tourCtrl !== "undefined") tourCtrl.skipFeature()
                onContinueRequested: if (typeof tourCtrl !== "undefined") tourCtrl.next()
            }
        }
    }

    // Global keyboard navigation (Esc, Left/Right arrows, Enter, Space)
    FocusScope {
        id: keyFocusScope
        anchors.fill: parent
        focus: true

        Keys.onEscapePressed: {
            if (typeof tourCtrl !== "undefined") {
                if (tourCtrl.liveFeatureOpen) {
                    tourCtrl.dismissLiveFeature();
                } else {
                    tourCtrl.skipForNow();
                }
            }
        }
        Keys.onRightPressed: {
            if (typeof tourCtrl !== "undefined") tourCtrl.next();
        }
        Keys.onLeftPressed: {
            if (typeof tourCtrl !== "undefined") tourCtrl.previous();
        }
        Keys.onReturnPressed: {
            if (rootWindow.activeSceneName === "completion") {
                finaleFade.start();
            } else if (typeof tourCtrl !== "undefined") {
                tourCtrl.next();
            }
        }
        Keys.onEnterPressed: {
            if (rootWindow.activeSceneName === "completion") {
                finaleFade.start();
            } else if (typeof tourCtrl !== "undefined") {
                tourCtrl.next();
            }
        }
        Keys.onSpacePressed: {
            if (typeof tourCtrl !== "undefined" && tourCtrl.currentFeatureId.length > 0) {
                tourCtrl.toggleLiveFeature();
            }
        }
    }
}
