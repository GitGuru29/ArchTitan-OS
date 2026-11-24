import QtQuick
import "../components"

/**
 * FeatureScene — Unified guided scene for Steps 03..09.
 *
 * Signature interaction (Live Spotlight Tour):
 * - When the user activates the live feature (Spotlight, Workspace HUD,
 *   QuickSettings, Media HUD, Sysmon), the desktop background gently dims
 *   via SpotlightMask with a glowing cyan aperture around the real overlay,
 *   and CoachCapsule repositions itself beside the highlighted region.
 * - Alongside/before live activation, FeaturePreview displays the interactive
 *   Main Stage on the left while CoachCapsule floats on the right.
 */
Item {
    id: root

    property var stepData: typeof tourCtrl !== "undefined" ? tourCtrl.currentStep : ({})
    property string featureId: typeof tourCtrl !== "undefined" ? tourCtrl.currentFeatureId : "spotlight"
    property bool liveOpen: typeof tourCtrl !== "undefined" ? tourCtrl.liveFeatureOpen : false
    property bool featureTried: typeof tourCtrl !== "undefined" ? tourCtrl.featureTried : false
    property rect spotRect: typeof tourCtrl !== "undefined" ? tourCtrl.spotlightRect : Qt.rect(320, 120, 560, 380)

    readonly property bool supportsExternalOverlay:
        featureId === "spotlight" ||
        featureId === "workspace" ||
        featureId === "quicksettings" ||
        featureId === "media" ||
        featureId === "sysmon"

    signal previousClicked()
    signal skipClicked()
    signal continueClicked()
    signal toggleLiveClicked()

    // 1. Live Spotlight Mask when external overlay is active
    SpotlightMask {
        anchors.fill: parent
        active: root.liveOpen && root.supportsExternalOverlay
        targetRect: root.spotRect
        cornerRadius: 20
        dimOpacity: 0.72
    }

    // 2. Main Stage (visible when external overlay is not covering the viewport)
    Item {
        id: mainStageContainer
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -14
        width: Math.max(520, parent.width - coach.width - 96)
        height: Math.min(parent.height - 130, 420)
        opacity: (root.liveOpen && root.supportsExternalOverlay) ? 0.12 : 1.0

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        FeaturePreview {
            anchors.fill: parent
            featureId: root.featureId
            liveActive: root.liveOpen
            onLaunchLiveRequested: root.toggleLiveClicked()
        }
    }

    // 3. Floating Coach Capsule — adapts position to avoid covering the live spotlight
    CoachCapsule {
        id: coach
        stepIndex: root.stepData.index || 3
        totalSteps: typeof tourCtrl !== "undefined" ? tourCtrl.totalSteps : 10
        title: root.stepData.title || ""
        body: root.stepData.body || ""
        featureName: {
            var map = {
                "spotlight": "Titan Spotlight",
                "workspace": "Workspace HUD",
                "quicksettings": "QuickSettings",
                "media": "Media HUD",
                "sysmon": "THM & Sysmon",
                "security": "Sandbox · Guard · BTRFS",
                "personalize": "Themes & Wallpapers"
            };
            return map[root.featureId] || "ArchTitan";
        }
        badgeText: root.stepData.badge || "Live feature"
        shortcutText: root.stepData.shortcut || ""
        promptText: root.stepData.prompt || ""
        liveActive: root.liveOpen && root.supportsExternalOverlay
        featureTried: root.featureTried
        canLaunchLive: root.supportsExternalOverlay
        avoidRect: root.spotRect
        viewportSize: Qt.size(root.width, root.height)

        x: (root.liveOpen && root.supportsExternalOverlay)
            ? computeSmartPosition().x
            : (root.width - width - 36)
        y: (root.liveOpen && root.supportsExternalOverlay)
            ? computeSmartPosition().y
            : Math.round((root.height - height - 28) / 2)

        Behavior on x {
            NumberAnimation {
                duration: (typeof tourCtrl !== "undefined" && tourCtrl.reducedMotion) ? 50 : 280
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: (typeof tourCtrl !== "undefined" && tourCtrl.reducedMotion) ? 50 : 280
                easing.type: Easing.OutBack
                easing.overshoot: 0.6
            }
        }

        onLaunchRequested: root.toggleLiveClicked()
        onPreviousRequested: root.previousClicked()
        onSkipRequested: root.skipClicked()
        onContinueRequested: root.continueClicked()
    }
}

