import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * OneUISegmentTab — Samsung One UI 9.0 segmented pill switcher.
 *
 * Smooth sliding pill indicator between "Quick Settings" and "Notifications".
 */
Rectangle {
    id: tabRoot
    Layout.fillWidth: true
    implicitHeight: 44
    radius: 22
    color: TitanTheme.bgOneUICard
    border.color: TitanTheme.borderGlass
    border.width: 1

    property int currentIndex: 0 // 0 = Quick Settings, 1 = Notifications
    property int notifCount: 0
    signal indexChanged(int idx)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Tab 0: Quick Settings ───────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 18
                color: tabRoot.currentIndex === 0 ? TitanTheme.bgActive : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf013" // cogs / sliders
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: tabRoot.currentIndex === 0 ? "#FFFFFF" : TitanTheme.textSubtle
                    }

                    Text {
                        text: "Quick Settings"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: tabRoot.currentIndex === 0 ? "#FFFFFF" : TitanTheme.textSubtle
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tabRoot.currentIndex = 0;
                    tabRoot.indexChanged(0);
                }
            }
        }

        // ── Tab 1: Notifications ────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: 18
                color: tabRoot.currentIndex === 1 ? TitanTheme.bgActive : "transparent"

                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf0f3" // bell
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 13
                        color: tabRoot.currentIndex === 1 ? "#FFFFFF" : TitanTheme.textSubtle
                    }

                    Text {
                        text: "Notifications"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: tabRoot.currentIndex === 1 ? "#FFFFFF" : TitanTheme.textSubtle
                    }

                    // Count Badge
                    Rectangle {
                        visible: tabRoot.notifCount > 0
                        width: Math.max(18, badgeText.implicitWidth + 8)
                        height: 18
                        radius: 9
                        color: tabRoot.currentIndex === 1 ? "#40FFFFFF" : TitanTheme.accentBlue

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: tabRoot.notifCount > 99 ? "99+" : tabRoot.notifCount.toString()
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Bold
                            color: "#FFFFFF"
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    tabRoot.currentIndex = 1;
                    tabRoot.indexChanged(1);
                }
            }
        }
    }
}
