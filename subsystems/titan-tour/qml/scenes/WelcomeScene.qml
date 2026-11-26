import QtQuick
import "../components"

/**
 * WelcomeScene — Slide 01: "Rise, Titan."
 * Matches Image 1 (media_1795534114120_3fe6a3c7.jpg) pixel-for-pixel:
 *   - Centered 3D metallic & electric-cyan faceted diamond/chevron emblem
 *   - Concentric reticle rings & horizontal/vertical cyan flare rays
 *   - Rounded "A R C H T I T A N   O S" pill badge
 *   - "Rise, " (white) + "Titan." (electric cyan)
 *   - "A new desktop. A smarter way to work."
 */
Item {
    id: root

    property real logoOpacity: 1.0
    property real logoScale: 1.0
    property real titleOpacity: 1.0
    property real titleOffsetY: 0.0
    property real subtitleOpacity: 1.0
    property real subtitleOffsetY: 0.0

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -18
        spacing: 22

        // 1. 3D Metallic/Cyan ArchTitan Emblem (800–1500 ms reveal)
        Item {
            width: 170
            height: 170
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.logoOpacity
            scale: root.logoScale

            TitanLogo {
                anchors.centerIn: parent
                size: 138
                metallicStyle: true
                showFlare: true
                showRings: true
            }
        }

        // 2. "A R C H T I T A N   O S" pill + "Rise, Titan." headline (1300–1900 ms reveal)
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14
            opacity: root.titleOpacity
            transform: Translate { y: root.titleOffsetY }

            // Rounded pill badge: A R C H T I T A N   O S
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: badgeTxt.implicitWidth + 36
                height: 28
                radius: 14
                color: "#12131E32" // tdl-allow
                border.width: 1
                border.color: "#666366F1" // tdl-allow

                Text {
                    id: badgeTxt
                    anchors.centerIn: parent
                    text: "A R C H T I T A N   O S"
                    font.family: "Inter"
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.8
                    color: "#CBD5E1" // tdl-allow
                }
            }

            // "Rise, Titan." two-tone headline
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 0

                Text {
                    text: "Rise, "
                    font.family: "Inter"
                    font.pixelSize: 52
                    font.weight: Font.Bold
                    color: "#F8FAFC" // tdl-allow
                }

                Text {
                    text: "Titan."
                    font.family: "Inter"
                    font.pixelSize: 52
                    font.weight: Font.Bold
                    color: "#22D3EE" // tdl-allow
                }
            }
        }

        // 3. Subtitle: "A new desktop. A smarter way to work." (1700–2300 ms reveal)
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "A new desktop. A smarter way to work."
            font.family: "Inter"
            font.pixelSize: 18
            font.weight: Font.Normal
            color: "#8B9BB4" // tdl-allow
            opacity: root.subtitleOpacity
            transform: Translate { y: root.subtitleOffsetY }
        }
    }
}
