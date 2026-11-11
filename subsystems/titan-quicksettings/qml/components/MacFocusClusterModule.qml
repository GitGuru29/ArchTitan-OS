import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * MacFocusClusterModule — macOS Control Center Top-Right 2x2 Cluster.
 *
 * Matches the 148px height of UnifiedConnectivityModule:
 * - Top (66px): Wide "Focus / Do Not Disturb" card with glowing Indigo Moon medallion
 * - Bottom (74px): Two 1x1 squircle cards side-by-side ("Night Shift" and "Dark Mode")
 */
Item {
    id: focusClusterRoot
    Layout.fillWidth: true
    implicitHeight: 148

    property bool focusActive: true
    readonly property bool nightActive: (typeof nightLightCtrl !== "undefined" && nightLightCtrl) ? nightLightCtrl.active : false
    readonly property bool darkActive: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.themeDark : true

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        // ═════════════════════════════════════════════════════════════════════
        //  TOP (2x1 Wide Card): Focus / Do Not Disturb (66px)
        // ═════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            radius: TitanTheme.radiusCard
            color: focusMa.pressed ? TitanTheme.bgPressed : (focusMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium)
            border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                          ? TitanTheme.accent
                          : (focusMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10

                // Glowing Indigo-Violet Moon Circle
                Rectangle {
                    width: 34
                    height: 34
                    radius: 17
                    color: focusClusterRoot.focusActive ? "#5E5CE6" : Qt.rgba(1, 1, 1, 0.14)
                    border.color: focusClusterRoot.focusActive ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.08)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "\uf186" // moon
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 14
                        color: focusClusterRoot.focusActive ? "#FFFFFF" : TitanTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Focus"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: TitanTheme.textPrimary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        text: focusClusterRoot.focusActive ? "Do Not Disturb" : "Off"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        color: focusClusterRoot.focusActive ? TitanTheme.textSecondary : TitanTheme.textMuted
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }

            MouseArea {
                id: focusMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                    focusClusterRoot.focusActive = !focusClusterRoot.focusActive;
                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                        systemCtrl.toggleFocusMode();
                }
            }
        }

        // ═════════════════════════════════════════════════════════════════════
        //  BOTTOM (Two 1x1 Squircles): Night Shift & Dark Mode (74px)
        // ═════════════════════════════════════════════════════════════════════
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // 1. Night Shift Squircle
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: TitanTheme.radiusCard
                color: nightMa.pressed
                       ? TitanTheme.bgPressed
                       : (focusClusterRoot.nightActive
                          ? Qt.rgba(0.04, 0.52, 1.0, 0.22)
                          : (nightMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium))
                border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                              ? TitanTheme.accent
                              : (focusClusterRoot.nightActive ? TitanTheme.accent : (nightMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline))
                border.width: 1
                scale: nightMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf185" // sun/warmth
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 18
                        color: focusClusterRoot.nightActive ? TitanTheme.accent : "#FFFFFF"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Night Shift"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                }

                MouseArea {
                    id: nightMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                        if (typeof nightLightCtrl !== "undefined" && nightLightCtrl)
                            nightLightCtrl.toggleNightLight();
                    }
                }
            }

            // 2. Dark Mode Squircle
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: TitanTheme.radiusCard
                color: darkMa.pressed
                       ? TitanTheme.bgPressed
                       : (focusClusterRoot.darkActive
                          ? Qt.rgba(1, 1, 1, 0.14)
                          : (darkMa.containsMouse ? TitanTheme.bgTitaniumHover : TitanTheme.bgTitanium))
                border.color: (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode)
                              ? TitanTheme.accent
                              : (darkMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderHairline)
                border.width: 1
                scale: darkMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf042" // contrast moon
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 18
                        color: "#FFFFFF"
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Dark Mode"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                }

                MouseArea {
                    id: darkMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof rootWindow !== "undefined" && rootWindow.inPlaceEditMode) return;
                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                            systemCtrl.themeDark = !systemCtrl.themeDark;
                    }
                }
            }
        }
    }
}

