import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * FocusPill — ArchTitan TitanFocus LayerShell overlay (AnchorTop | AnchorRight).
 * Uses ArchTitan.TitanUI design tokens exclusively (zero hardcoded colours).
 */
Window {
    id: root
    title: "titan-focus"
    width: 348
    height: Math.min(540, Math.max(300, mainCol.implicitHeight + 36))

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false

    property bool pillOpen: false

    function openPill() {
        closeTimer.stop()
        pillOpen = true
        root.visible = true
        root.requestActivate()
    }

    function closePill() {
        pillOpen = false
        closeTimer.start()
    }

    function togglePill() {
        if (pillOpen) closePill()
        else openPill()
    }

    Timer {
        id: closeTimer
        interval: 240
        onTriggered: if (!root.pillOpen) root.visible = false
    }

    Item {
        id: container
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closePill()

        opacity: root.pillOpen ? 1.0 : 0.0
        y: root.pillOpen ? 0 : -12
        Behavior on opacity { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
        Behavior on y { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }

        // ── Frosted glass card ───────────────────────────────────────────────
        Rectangle {
            id: card
            anchors.fill: parent
            radius: TitanTheme.radiusWindow
            color: TitanTheme.glass
            border.width: 1
            border.color: TitanTheme.border

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: card.radius - 1
                color: "transparent"
                border.width: 1
                border.color: TitanTheme.borderSubtle
            }

            ColumnLayout {
                id: mainCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: TitanTheme.space4
                spacing: TitanTheme.space3

                // ── Header ───────────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: TitanTheme.space2

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: focusCtrl.onBreak ? TitanTheme.success
                             : focusCtrl.dndEnabled ? TitanTheme.mauve
                             : focusCtrl.snoozed ? TitanTheme.warning
                             : focusCtrl.ideFocused ? TitanTheme.accent
                             : TitanTheme.teal
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: "TitanFocus"
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeTitle
                            font.weight: TitanTheme.weightBold
                        }

                        Text {
                            text: focusCtrl.statusLabel
                            color: TitanTheme.textLow
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeCaption
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // DND quick badge
                    Rectangle {
                        implicitWidth: dndLbl.implicitWidth + 16
                        implicitHeight: 24
                        radius: 12
                        color: focusCtrl.dndEnabled ? TitanTheme.accentSoft : TitanTheme.bgInset
                        border.width: 1
                        border.color: focusCtrl.dndEnabled ? TitanTheme.accentEdge : TitanTheme.borderSubtle

                        Text {
                            id: dndLbl
                            anchors.centerIn: parent
                            text: focusCtrl.dndEnabled ? "DND ON" : "DND"
                            color: focusCtrl.dndEnabled ? TitanTheme.accent : TitanTheme.textMid
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 10
                            font.weight: TitanTheme.weightSemiBold
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: focusCtrl.toggleDnd()
                        }
                    }
                }

                // ── Focus Ring + Live Metrics ────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 112
                    radius: TitanTheme.radiusCard
                    color: TitanTheme.bgInset
                    border.width: 1
                    border.color: TitanTheme.borderSubtle

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: TitanTheme.space3
                        spacing: TitanTheme.space4

                        Item {
                            width: 84; height: 84

                            TitanArcItem {
                                anchors.fill: parent
                                lineWidth: 6
                                startAngle: -90
                                sweepAngle: Math.max(6, (focusCtrl.onBreak ? focusCtrl.breakProgress : focusCtrl.focusProgress) * 360)
                                color: focusCtrl.onBreak ? TitanTheme.success
                                     : focusCtrl.dndEnabled ? TitanTheme.mauve
                                     : TitanTheme.accent
                                trackColor: TitanTheme.surface1
                                showTrack: true
                                roundCaps: true
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 1

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: focusCtrl.onBreak ? focusCtrl.breakRemainingFormatted : focusCtrl.focusElapsedFormatted
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 15
                                    font.weight: TitanTheme.weightBold
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: focusCtrl.onBreak ? "BREAK" : "FOCUS"
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    font.weight: TitanTheme.weightSemiBold
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Next nudge"
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: focusCtrl.nextNudgeEtaFormatted
                                    color: TitanTheme.textHigh
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    font.weight: TitanTheme.weightSemiBold
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Focus today"
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: focusCtrl.focusMinutesToday + " min"
                                    color: TitanTheme.accent
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    font.weight: TitanTheme.weightSemiBold
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Breaks · Nudges"
                                    color: TitanTheme.textLow
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: focusCtrl.breaksTakenToday + " · " + focusCtrl.nudgesFiredToday
                                    color: TitanTheme.textMid
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: TitanTheme.sizeCaption
                                    font.weight: TitanTheme.weightSemiBold
                                }
                            }
                        }
                    }
                }

                // ── Latest Advisory Banner (only when active) ────────────────
                Rectangle {
                    visible: focusCtrl.lastNudgeTitle.length > 0
                    Layout.fillWidth: true
                    implicitHeight: advisoryCol.implicitHeight + 16
                    radius: TitanTheme.radiusCard
                    color: TitanTheme.accentSofter
                    border.width: 1
                    border.color: TitanTheme.accentEdge

                    ColumnLayout {
                        id: advisoryCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 8
                        spacing: 3

                        Text {
                            text: focusCtrl.lastNudgeTitle
                            color: TitanTheme.textHigh
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: TitanTheme.sizeCaption
                            font.weight: TitanTheme.weightSemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: focusCtrl.lastNudgeBody
                            color: TitanTheme.textMid
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                        }
                    }
                }

                // ── Three Strict Actions: Start Break | Snooze | Dismiss/Reset
                RowLayout {
                    Layout.fillWidth: true
                    spacing: TitanTheme.space2

                    TitanButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        text: focusCtrl.onBreak ? "End Break" : ("Break " + focusCtrl.breakDurationMin + "m")
                        variant: "primary"
                        onClicked: {
                            if (focusCtrl.onBreak) focusCtrl.endBreak()
                            else focusCtrl.startBreakMinutes(focusCtrl.breakDurationMin)
                        }
                    }

                    TitanButton {
                        Layout.fillWidth: true
                        implicitHeight: 32
                        text: "Snooze 15m"
                        variant: "secondary"
                        onClicked: focusCtrl.snoozeMinutes(15)
                    }

                    TitanButton {
                        implicitHeight: 32
                        text: focusCtrl.lastNudgeTitle.length > 0 ? "Dismiss" : "Reset"
                        variant: "ghost"
                        onClicked: {
                            if (focusCtrl.lastNudgeTitle.length > 0) focusCtrl.dismissNudge()
                            else focusCtrl.resetSession()
                        }
                    }
                }
            }
        }
    }
}
