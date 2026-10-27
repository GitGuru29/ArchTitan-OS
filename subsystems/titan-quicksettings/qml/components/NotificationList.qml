import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../style"

/**
 * NotificationList — Samsung One UI 9.0 Notification Center & Media Hub.
 *
 * Header with "Clear all", embedded Live Media Output card, and high-performance
 * notification list with bottom expander.
 */
ColumnLayout {
    id: notifRoot
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: 12

    // ── 1. Notifications Header ─────────────────────────────────────────────
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36

        Text {
            text: "Notifications"
            font.family: TitanTheme.fontFamily
            font.pixelSize: 20
            font.weight: Font.Bold
            color: TitanTheme.textPrimary
        }

        Item { Layout.fillWidth: true }

        // Clear all capsule button
        Rectangle {
            width: 72
            height: 28
            radius: 14
            visible: (typeof notifModel !== "undefined" && notifModel && notifModel.totalCount > 0)
            color: clearMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
            border.color: TitanTheme.borderGlass
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Clear all"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: clearMa.containsMouse ? TitanTheme.red : TitanTheme.textPrimary
            }

            MouseArea {
                id: clearMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof notifServer !== "undefined" && notifServer)
                        notifServer.clearAll()
                }
            }
        }
    }

    // ── 2. Live Media Output Card (One UI Signature Card) ───────────────────
    Rectangle {
        Layout.fillWidth: true
        height: 64
        radius: 18
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1
        clip: true

        // Top specular edge highlight (macOS glass bevel)
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 1
            radius: parent.radius
            color: TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.45)
            z: 2
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 12

            // Visualizer / Album Icon Medallion
            Rectangle {
                width: 38
                height: 38
                radius: 12
                clip: true
                color: TitanTheme.accent
                border.color: TitanTheme.borderActive
                border.width: 1

                // Glass specular shine on album medallion
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height * 0.48
                    radius: parent.radius
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.27) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf001" // music glyph
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 16
                    color: TitanTheme.accentText
                }
            }

            // Track & App Info
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Media output"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Now playing • ArchTitan Theme"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            // Playback Controls
            RowLayout {
                spacing: 8

                // Play / Pause
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    scale: playMa.pressed ? 0.90 : (playMa.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    color: playMa.containsMouse ? TitanTheme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf04c" // pause
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: TitanTheme.textPrimary
                    }

                    MouseArea {
                        id: playMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof audioCtrl !== "undefined" && audioCtrl)
                                audioCtrl.toggleMute()
                        }
                    }
                }

                // Next Track
                Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    scale: nextMa.pressed ? 0.90 : (nextMa.containsMouse ? 1.08 : 1.0)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    color: nextMa.containsMouse ? TitanTheme.bgHover : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf051" // next
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: TitanTheme.textPrimary
                    }

                    MouseArea {
                        id: nextMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.openMediaWidget()
                        }
                    }
                }
            }
        }
    }

    // ── 3. Notification Feed ListView ───────────────────────────────────────
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        ListView {
            id: notifListView
            anchors.fill: parent
            spacing: 8
            clip: true
            reuseItems: true
            cacheBuffer: 160
            model: (typeof notifModel !== "undefined" && notifModel) ? notifModel : null

            delegate: OneUINotificationCard {
                width: notifListView.width
                cardIndex: index
                appNameText: model.appName
                summaryText: model.summary
                bodyText: model.body
                dateText: model.dateStr
                iconTypeVal: model.iconType
                countVal: model.itemCount
                expandedVal: model.isExpanded
                subItemsList: model.subItems
            }

            ScrollBar.vertical: ScrollBar {
                id: vBar
                width: 4
                policy: ScrollBar.AsNeeded
                interactive: true
                anchors.right: parent.right
                anchors.rightMargin: 1

                contentItem: Rectangle {
                    radius: 2
                    color: vBar.active ? TitanTheme.accentBlue : TitanTheme.bgOneUIPill
                    opacity: vBar.active ? 1.0 : 0.8
                }
                background: Rectangle {
                    radius: 2
                    color: "transparent"
                }
            }

            // Empty state
            Rectangle {
                anchors.centerIn: parent
                width: parent.width - 24
                height: 110
                radius: TitanTheme.radiusCard
                color: TitanTheme.bgOneUICard
                border.color: TitanTheme.borderGlass
                border.width: 1
                visible: notifListView.count === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: "\uf0f3" // bell
                        Layout.alignment: Qt.AlignHCenter
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 24
                        color: TitanTheme.textSubtle
                    }

                    Text {
                        text: "You're all caught up"
                        Layout.alignment: Qt.AlignHCenter
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: TitanTheme.textSecondary
                    }

                    Text {
                        text: "No pending notifications"
                        Layout.alignment: Qt.AlignHCenter
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        color: TitanTheme.textSubtle
                    }
                }
            }
        }
    }
}