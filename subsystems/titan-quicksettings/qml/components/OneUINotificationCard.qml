import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUINotificationCard — Samsung One UI 9.0 grouped notification card.
 *
 * Squircles with frosted glass depth, app medallion, expandable sub-items,
 * and quick dismiss button.
 */
Rectangle {
    id: cardRoot
    width: parent ? parent.width : 390
    implicitHeight: mainLayout.implicitHeight + 20
    radius: TitanTheme.radiusCard
    color: cardMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
    border.color: cardMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
    border.width: 1
    clip: true

    property int cardIndex: (typeof index !== "undefined") ? index : 0
    property string appNameText: (typeof appName !== "undefined") ? appName : "System"
    property string summaryText: (typeof summary !== "undefined") ? summary : ""
    property string bodyText: (typeof body !== "undefined") ? body : ""
    property string dateText: (typeof dateStr !== "undefined") ? dateStr : ""
    property string iconTypeVal: (typeof iconType !== "undefined") ? iconType : "message"
    property int countVal: (typeof itemCount !== "undefined") ? itemCount : 1
    property bool expandedVal: (typeof isExpanded !== "undefined") ? isExpanded : false
    property var subItemsList: (typeof subItems !== "undefined") ? subItems : []

    readonly property color typeColor: {
        switch (iconTypeVal) {
        case "update":      return "#2563EB"; // Blue
        case "terminal":    return "#16A34A"; // Green
        case "github":      return "#7C3AED"; // Purple
        case "youtube":     return "#DC2626"; // Red
        case "download":    return "#0284C7"; // Sky
        case "calendar":    return "#8B5CF6"; // Violet
        case "telegram":    return "#0EA5E9"; // Cyan
        case "battery":     return "#10B981"; // Emerald
        case "weather":     return "#38BDF8"; // Sky blue
        case "wifi":        return "#14B8A6"; // Teal
        case "antigravity": return "#2563EB";
        default:            return "#2563EB";
        }
    }

    readonly property string typeGlyph: {
        switch (iconTypeVal) {
        case "update":      return "\uf013"; // cog / update
        case "terminal":    return "\uf120"; // terminal >_
        case "github":      return "\uf09b"; // github
        case "youtube":     return "\uf16a"; // youtube play
        case "download":    return "\uf019"; // download
        case "calendar":    return "\uf133"; // calendar
        case "telegram":    return "\uf1d8"; // paper airplane
        case "battery":     return "\uf240"; // battery
        case "weather":     return "\uf6c4"; // cloud-sun
        case "wifi":        return "\uf1eb";
        case "antigravity": return "▲";
        default:            return "\uf0f3"; // bell
        }
    }

    Behavior on color { ColorAnimation { duration: 130 } }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 6

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            // App Icon Medallion
            Rectangle {
                width: 36
                height: 36
                radius: 18
                color: cardRoot.typeColor

                Text {
                    anchors.centerIn: parent
                    text: cardRoot.typeGlyph
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 15
                    color: "#FFFFFF"
                }
            }

            // App Name & Summary Body
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    spacing: 6
                    Text {
                        text: cardRoot.appNameText
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                        elide: Text.ElideRight
                    }

                    Text {
                        text: cardRoot.dateText
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        color: TitanTheme.textSubtle
                    }
                }

                Text {
                    text: cardRoot.summaryText.length > 0 ? cardRoot.summaryText : cardRoot.bodyText
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Right Chevron or Thumbnail
            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24
                Layout.alignment: Qt.AlignVCenter

                // Dismiss button on hover
                Rectangle {
                    anchors.fill: parent
                    radius: 12
                    visible: cardMa.containsMouse
                    color: dismissMa.containsMouse ? TitanTheme.red : TitanTheme.bgOneUIPill

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        id: dismissMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof notifModel !== "undefined" && notifModel) {
                                notifModel.dismissGroup(cardRoot.cardIndex);
                            }
                        }
                    }
                }

                // Default chevron when not hovered
                Text {
                    anchors.centerIn: parent
                    visible: !cardMa.containsMouse
                    text: "\uf054"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }
            }
        }

        // ── Summary Text ────────────────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: cardRoot.summaryText
            font.family: TitanTheme.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            color: TitanTheme.textPrimary
            elide: Text.ElideRight
        }

        // ── Body Text ───────────────────────────────────────────────────────
        Text {
            Layout.fillWidth: true
            text: cardRoot.bodyText
            font.family: TitanTheme.fontFamily
            font.pixelSize: 11
            color: TitanTheme.textSecondary
            wrapMode: cardRoot.expandedVal ? Text.Wrap : Text.NoWrap
            elide: cardRoot.expandedVal ? Text.ElideNone : Text.ElideRight
            maximumLineCount: cardRoot.expandedVal ? 4 : 1
        }

        // ── Sub-items (when expanded) ───────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            visible: cardRoot.expandedVal && cardRoot.subItemsList.length > 1
            spacing: 6

            Repeater {
                model: cardRoot.subItemsList.slice(1) // show older items in stack
                delegate: Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: subTextCol.implicitHeight + 12
                    radius: 10
                    color: TitanTheme.bgOneUIPill

                    ColumnLayout {
                        id: subTextCol
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 2

                        Text {
                            text: modelData.summary || ""
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: TitanTheme.textPrimary
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: modelData.body || ""
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            color: TitanTheme.textMuted
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        z: -1
        onClicked: {
            if (typeof notifModel !== "undefined" && notifModel) {
                notifModel.toggleExpanded(cardRoot.cardIndex);
            }
        }
    }
}
