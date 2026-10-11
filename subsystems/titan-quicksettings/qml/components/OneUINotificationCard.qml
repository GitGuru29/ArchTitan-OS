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
        case "wifi":        return TitanTheme.teal;
        case "antigravity": return TitanTheme.accentBlue;
        case "terminal":    return TitanTheme.green;
        case "message":     return TitanTheme.yellow;
        default:            return TitanTheme.accentBlue;
        }
    }

    readonly property string typeGlyph: {
        switch (iconTypeVal) {
        case "wifi":        return "\uf1eb";
        case "antigravity": return "▲";
        case "terminal":    return "\uf120";
        case "message":     return "\uf075";
        default:            return "\uf075";
        }
    }

    Behavior on color { ColorAnimation { duration: 130 } }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Card Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // App Icon Medallion
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: Qt.rgba(typeColor.r, typeColor.g, typeColor.b, 0.18)
                border.color: Qt.rgba(typeColor.r, typeColor.g, typeColor.b, 0.40)
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: cardRoot.typeGlyph
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    color: cardRoot.typeColor
                }
            }

            // App Name & Date
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

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
                        text: "• " + cardRoot.dateText
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        color: TitanTheme.textSubtle
                    }
                }
            }

            // Group count pill if multiple notifications exist
            Rectangle {
                visible: cardRoot.countVal > 1
                height: 20
                width: groupCountText.implicitWidth + 14
                radius: 10
                color: TitanTheme.bgOneUIPill

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        id: groupCountText
                        text: "+" + cardRoot.countVal
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: TitanTheme.accentBlue
                    }
                    Text {
                        text: cardRoot.expandedVal ? "\uf077" : "\uf078"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        color: TitanTheme.textSubtle
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof notifModel !== "undefined" && notifModel) {
                            notifModel.toggleExpanded(cardRoot.cardIndex);
                        }
                    }
                }
            }

            // Dismiss Button
            Rectangle {
                width: 24
                height: 24
                radius: 12
                color: dismissMa.containsMouse ? TitanTheme.red : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: dismissMa.containsMouse ? "#FFFFFF" : TitanTheme.textSubtle
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
