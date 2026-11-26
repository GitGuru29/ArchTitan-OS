import QtQuick

/**
 * CoachCapsule — reusable floating Titan Cinematic Glass panel explaining the
 * current feature, showing its live status, shortcut, interaction prompt, and
 * navigation controls.
 *
 * Automatically positions itself beside the spotlight cutout (`avoidRect`)
 * when a live feature is open so it never covers the control being demonstrated.
 */
Rectangle {
    id: root

    property int stepIndex: 1
    property int totalSteps: 10
    property string eyebrow: "TITAN GUIDE"
    property string title: "Control your environment."
    property string body: "Manage connectivity, sound, brightness and power settings from one place."
    property string featureName: "QuickSettings"
    property string badgeText: "Live feature"
    property string shortcutText: "Super + N"
    property string promptText: "Try opening a control or adjusting a slider."
    property bool liveActive: false
    property bool featureTried: false
    property bool canLaunchLive: true
    property rect avoidRect: Qt.rect(0, 0, 0, 0)
    property size viewportSize: Qt.size(1280, 800)
    property bool reducedMotion: typeof tourCtrl !== "undefined" ? tourCtrl.reducedMotion : false

    signal launchRequested()
    signal skipRequested()
    signal previousRequested()
    signal continueRequested()

    width: 420
    height: capsuleCol.implicitHeight + 44
    radius: 20
    color: "#E8181825"
    border.width: 1.5
    border.color: liveActive ? "#8800D2FF" : "#33FFFFFF"

    // Adaptive placement when liveActive is true so we never cover avoidRect
    function computeSmartPosition() {
        var vw = Math.max(800, viewportSize.width);
        var vh = Math.max(540, viewportSize.height);
        var cw = root.width;
        var ch = root.height;
        var pad = 28;

        if (!liveActive || avoidRect.width <= 0 || avoidRect.height <= 0) {
            return Qt.point(vw - cw - 36, vh - ch - 68);
        }

        var rx = avoidRect.x;
        var ry = avoidRect.y;
        var rw = avoidRect.width;
        var rh = avoidRect.height;

        // 1. If feature is on the right side (e.g. QuickSettings), place capsule to the left of it
        if (rx > cw + pad * 2) {
            var leftX = Math.max(pad, rx - cw - pad);
            var midY = Math.min(vh - ch - 68, Math.max(pad + 40, ry + 24));
            return Qt.point(leftX, midY);
        }

        // 2. If feature is on the left side (e.g. Sysmon), place capsule to the right of it
        if (rx + rw + cw + pad * 2 <= vw) {
            var rightX = Math.min(vw - cw - pad, rx + rw + pad);
            var rMidY = Math.min(vh - ch - 68, Math.max(pad + 40, ry + 24));
            return Qt.point(rightX, rMidY);
        }

        // 3. If feature is in the top half (e.g. Waybar, Workspace HUD, Media HUD, Spotlight),
        //    place capsule centered-bottom below the feature
        if (ry + rh + ch + 76 <= vh) {
            return Qt.point(Math.round((vw - cw) / 2), Math.min(vh - ch - 68, ry + rh + 24));
        }

        // 4. Fallback: bottom-right above progress bar
        return Qt.point(vw - cw - pad, vh - ch - 68);
    }

    // Subtle top cyan accent bar
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        height: 2
        radius: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: "#00D2FF" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Column {
        id: capsuleCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 22
        spacing: 12

        // Row 1: TITAN GUIDE   05 / 10
        Item {
            width: parent.width
            height: 20

            Row {
                spacing: 8
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.liveActive ? "#A6E3A1" : "#00D2FF"
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "TITAN GUIDE"
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.letterSpacing: 1.4
                    color: "#00D2FF"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    var s = root.stepIndex < 10 ? "0" + root.stepIndex : "" + root.stepIndex;
                    var t = root.totalSteps < 10 ? "0" + root.totalSteps : "" + root.totalSteps;
                    return s + " / " + t;
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#A6ADC8"
            }
        }

        // Row 2: Feature headline
        Text {
            width: parent.width
            text: root.title
            font.family: "Inter"
            font.pixelSize: 19
            font.weight: Font.Bold
            color: "#CDD6F4"
            wrapMode: Text.WordWrap
        }

        // Row 3: Concise explanation
        Text {
            width: parent.width
            text: root.body
            font.family: "Inter"
            font.pixelSize: 13
            color: "#A6ADC8"
            lineHeight: 1.38
            wrapMode: Text.WordWrap
        }

        // Row 4: Metadata pills (Feature name · Live feature · Shortcut)
        Flow {
            width: parent.width
            spacing: 8

            // Feature pill
            Rectangle {
                visible: root.featureName.length > 0
                width: featText.implicitWidth + 20
                height: 24
                radius: 8
                color: "#2200D2FF"
                border.width: 1
                border.color: "#5500D2FF"

                Text {
                    id: featText
                    anchors.centerIn: parent
                    text: root.featureName
                    font.family: "Inter"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#00D2FF"
                }
            }

            // Live feature status pill
            Rectangle {
                visible: root.badgeText.length > 0
                width: badgeRow.implicitWidth + 18
                height: 24
                radius: 8
                color: root.featureTried ? "#22A6E3A1" : "#220284C7"
                border.width: 1
                border.color: root.featureTried ? "#66A6E3A1" : "#550284C7"

                Row {
                    id: badgeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: root.featureTried ? "#A6E3A1" : "#38BDF8"
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.featureTried ? "Tried live ✓" : root.badgeText
                        font.family: "Inter"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: root.featureTried ? "#A6E3A1" : "#CDD6F4"
                    }
                }
            }

            // Shortcut keycap pill
            Rectangle {
                visible: root.shortcutText.length > 0
                width: keyText.implicitWidth + 18
                height: 24
                radius: 8
                color: "#CC313244"
                border.width: 1
                border.color: "#38FFFFFF"

                Text {
                    id: keyText
                    anchors.centerIn: parent
                    text: root.shortcutText
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: "#CDD6F4"
                }
            }
        }

        // Row 5: Interactive prompt card + Try Live button
        Rectangle {
            width: parent.width
            height: promptCol.implicitHeight + 20
            radius: 12
            color: "#9911111B"
            border.width: 1
            border.color: root.liveActive ? "#5500D2FF" : "#22FFFFFF"

            Column {
                id: promptCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 10
                spacing: 8

                Text {
                    width: parent.width
                    text: root.promptText
                    font.family: "Inter"
                    font.pixelSize: 12
                    color: "#CDD6F4"
                    wrapMode: Text.WordWrap
                }

                GlassButton {
                    visible: root.canLaunchLive
                    text: root.liveActive ? "Hide Live Overlay" : ("Try " + root.featureName + " Live")
                    glyph: root.liveActive ? "✕" : "✦"
                    variant: root.liveActive ? "secondary" : "primary"
                    buttonHeight: 34
                    horizontalPadding: 14
                    onClicked: root.launchRequested()
                }
            }
        }

        // Row 6: Footer actions (Back / Skip feature  ...  Continue →)
        Item {
            width: parent.width
            height: 38

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                GlassButton {
                    visible: root.stepIndex > 1
                    text: "←"
                    variant: "ghost"
                    buttonHeight: 34
                    horizontalPadding: 12
                    onClicked: root.previousRequested()
                }

                GlassButton {
                    text: "Skip feature"
                    variant: "ghost"
                    buttonHeight: 34
                    horizontalPadding: 12
                    onClicked: root.skipRequested()
                }
            }

            GlassButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "Continue →"
                variant: "primary"
                buttonHeight: 36
                horizontalPadding: 18
                onClicked: root.continueRequested()
            }
        }
    }
}
