import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * NotificationCard — grouped notification row.
 *
 * Color-coded per source icon type, expands to reveal full text, and exposes
 * a dismiss affordance on hover.  Pure view: all mutations happen through
 * notifServer slots.
 */
Rectangle {
    id: cardRoot
    width: parent ? parent.width : 390
    height: expanded ? 126 : 72
    radius: TitanTheme.radiusControl

    property var modelItem: (typeof modelData !== "undefined") ? modelData : null
    property int cardIndex: (typeof index !== "undefined") ? index : 0

    readonly property string appNameStr: (modelItem && modelItem.appName) ? modelItem.appName : "Notification"
    readonly property string dateStrVal: (modelItem && modelItem.dateStr) ? modelItem.dateStr : ""
    readonly property int countVal: (modelItem && modelItem.count) ? modelItem.count : 1
    readonly property string primaryTextStr: (modelItem && modelItem.primaryText) ? modelItem.primaryText : ""
    readonly property string secondaryTextStr: (modelItem && modelItem.secondaryText) ? modelItem.secondaryText : ""
    readonly property string iconTypeStr: (modelItem && modelItem.iconType) ? modelItem.iconType : ""
    property bool expanded: modelItem ? (modelItem.expanded || false) : false

    readonly property color typeColor: {
        switch (iconTypeStr) {
        case "wifi":        return TitanTheme.teal;
        case "antigravity": return TitanTheme.accent;
        case "terminal":    return TitanTheme.green;
        case "message":     return TitanTheme.yellow;
        default:            return TitanTheme.lavender;
        }
    }

    property string typeGlyph: {
        switch (iconTypeStr) {
        case "wifi":        return "\uf1eb";         // wifi
        case "antigravity": return "▲";
        case "terminal":    return "\uf120";         // terminal
        case "message":     return "\uf075";         // comment
        default:            return "\uf075";
        }
    }

    color: cardMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgSurfaceAlt
    border.color: cardMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderSubtle
    border.width: 1

    Behavior on color { ColorAnimation { duration: 130 } }
    Behavior on height {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    // Color accent blade
    Rectangle {
        width: 3
        height: parent.height - 16
        radius: 1.5
        x: 8
        anchors.verticalCenter: parent.verticalCenter
        color: cardRoot.typeColor
        opacity: cardMa.containsMouse ? 1.0 : 0.7
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 12
        anchors.topMargin: 10
        anchors.bottomMargin: 10
        spacing: 10

        // App icon medallion
        Rectangle {
            width: 36; height: 36; radius: 18
            color: Qt.rgba(typeColor.r, typeColor.g, typeColor.b, 0.14)
            border.color: Qt.rgba(typeColor.r, typeColor.g, typeColor.b, 0.45)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: cardRoot.typeGlyph
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                font.bold: cardRoot.iconTypeStr === "antigravity"
                color: cardRoot.typeColor
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Content column
        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            // Header: app, date, count
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: cardRoot.appNameStr
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeSmall
                    font.weight: Font.DemiBold
                    color: TitanTheme.textSecondary
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: cardRoot.dateStrVal
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    color: TitanTheme.textSubtle
                }

                // Count + chevron pill
                Rectangle {
                    height: 20
                    width: countText.implicitWidth + 16
                    radius: 10
                    color: cardMa.containsMouse ? TitanTheme.bgPressed : TitanTheme.bgInset

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            id: countText
                            text: cardRoot.countVal.toLocaleString()
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: TitanTheme.textSecondary
                        }
                        Text {
                            text: cardRoot.expanded ? "\uf077" : "\uf078"  // chevron up / down
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                            color: TitanTheme.textMuted
                        }
                    }
                }
            }

            // Primary line
            Text {
                text: cardRoot.primaryTextStr
                Layout.fillWidth: true
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeBody
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
                elide: Text.ElideRight
            }

            // Secondary line
            Text {
                text: cardRoot.secondaryTextStr
                Layout.fillWidth: true
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeSmall
                color: TitanTheme.textMuted
                elide: cardRoot.expanded ? Text.ElideNone : Text.ElideRight
                wrapMode: cardRoot.expanded ? Text.Wrap : Text.NoWrap
                maximumLineCount: cardRoot.expanded ? 3 : 1
                clip: true
            }
        }

        // Dismiss
        Item {
            width: 24; height: 24
            visible: cardMa.containsMouse

            Rectangle {
                width: 22; height: 22; radius: 11
                color: dismissMa.containsMouse ? TitanTheme.red : "transparent"
                anchors.centerIn: parent

                Text {
                    anchors.centerIn: parent
                    text: "\uf00d"   // times
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: dismissMa.containsMouse ? TitanTheme.accentText : TitanTheme.textMuted
                }
            }
            MouseArea {
                id: dismissMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (typeof notifServer !== "undefined" && notifServer) notifServer.dismissAt(cardRoot.cardIndex)
            }
            Accessible.role: Accessible.Button
            Accessible.name: "Dismiss"
        }
    }

    MouseArea {
        id: cardMa
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onClicked: if (typeof notifServer !== "undefined" && notifServer) notifServer.toggleExpanded(cardRoot.cardIndex)
    }

    Accessible.role: Accessible.Button
    Accessible.name: appNameStr
}