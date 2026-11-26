import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI

/**
 * SpotlightCard — macOS App Library Island.
 * Features a top floating search capsule, category filter pill strip, and a 7-column squircle app grid.
 */
Item {
    id: cardRoot
    width: 780
    implicitHeight: topCapsule.height + (mathCapsule.visible ? (mathCapsule.height + 6) : 0) + 6 + mainIsland.height
    height: implicitHeight

    property alias input: topCapsule

    Column {
        anchors.fill: parent
        spacing: 6

        // ── 1. Top Floating Capsule (Search & Applications Header) ─────────────
        SpotlightInput {
            id: topCapsule
            anchors.horizontalCenter: parent.horizontalCenter
            onEscapePressed: root.closeSpotlight()
            onReturnPressed: spotlight.activateCurrent()
            onUpPressed: spotlight.selectUp()
            onDownPressed: spotlight.selectDown()
            onLeftPressed: spotlight.selectLeft()
            onRightPressed: spotlight.selectRight()
        }

        // ── 2. Floating Math Result Capsule (Calculations) ─────────────────────
        Rectangle {
            id: mathCapsule
            anchors.horizontalCenter: parent.horizontalCenter
            width: 380
            height: 40
            radius: 20
            visible: spotlight.hasCalcResult
            color: TitanTheme.isDark ? TitanTheme.alphaColor(TitanTheme.mantle, 0.96)
                                     : TitanTheme.alphaColor(TitanTheme.surface0, 0.96)
            border.width: 1
            border.color: TitanTheme.alphaColor(TitanTheme.accent, 0.50)

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: TitanTheme.scrim
                shadowBlur: 0.8
                shadowVerticalOffset: 6
                autoPaddingEnabled: true
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰪚"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 16
                    color: TitanTheme.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: spotlight.calcFormula + " = " + spotlight.calcResult
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 14
                    font.weight: TitanTheme.weightSemiBold
                    color: "#FFFFFF"
                }

                Item { Layout.fillWidth: true; width: 1; height: 1 }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    height: 22
                    width: copyLabel.implicitWidth + 12
                    radius: 11
                    color: copyMouse.containsMouse ? TitanTheme.accent : TitanTheme.accentSoft
                    border.width: 1
                    border.color: TitanTheme.accentEdge

                    Text {
                        id: copyLabel
                        anchors.centerIn: parent
                        text: "⏎ Copy"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 10
                        font.weight: TitanTheme.weightBold
                        color: copyMouse.containsMouse ? TitanTheme.textOnAccent : TitanTheme.accent
                    }

                    MouseArea {
                        id: copyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: spotlight.copyCalcResult()
                    }
                }
            }
        }

        // ── 3. Main Frosted Bento Island (Applications & Category Strip) ───────
        Rectangle {
            id: mainIsland
            width: parent.width
            height: 460
            radius: 26

            // Deep obsidian frosted glass
            color: TitanTheme.isDark ? TitanTheme.alphaColor(TitanTheme.mantle, 0.94)
                                     : TitanTheme.alphaColor(TitanTheme.surface0, 0.94)
            border.width: 1
            border.color: TitanTheme.borderSubtle

            // Top Specular Horizon Glint
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 60
                height: 1
                radius: 1
                z: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.30) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // GPU Drop Shadow
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: TitanTheme.scrim
                shadowBlur: 1.0
                shadowVerticalOffset: 20
                autoPaddingEnabled: true
            }

            Column {
                anchors.fill: parent
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                spacing: 8

                // ── Category Filter Pills Strip ──────────────────────────────
                Item {
                    id: categoryStrip
                    width: parent.width
                    height: 32

                    Flickable {
                        id: categoryFlick
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        contentWidth: categoryRow.implicitWidth
                        contentHeight: height
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        Row {
                            id: categoryRow
                            spacing: 6
                            height: parent.height
                            x: Math.max(0, (categoryFlick.width - implicitWidth) / 2)

                            Repeater {
                                model: [
                                    { catId: "ALL", label: "All" },
                                    { catId: "UTILITIES", label: "Utilities" },
                                    { catId: "SOCIAL", label: "Social" },
                                    { catId: "PRODUCTIVITY", label: "Productivity & Finance" },
                                    { catId: "ENTERTAINMENT", label: "Entertainment" },
                                    { catId: "INFORMATION", label: "Information & Reading" },
                                    { catId: "CREATIVITY", label: "Creativity" },
                                    { catId: "OTHER", label: "Other" }
                                ]

                                delegate: Rectangle {
                                    id: catPill
                                    readonly property bool isActive: spotlight.activeCategory === modelData.catId
                                    height: 26
                                    width: pillText.implicitWidth + 20
                                    radius: 13
                                    anchors.verticalCenter: parent.verticalCenter

                                    color: isActive
                                           ? Qt.rgba(1, 1, 1, 0.20)
                                           : (pillMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06))

                                    border.width: isActive ? 1 : 0
                                    border.color: Qt.rgba(255, 255, 255, 0.28)

                                    Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

                                    Text {
                                        id: pillText
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: catPill.isActive ? Font.DemiBold : Font.Normal
                                        color: catPill.isActive ? "#FFFFFF" : TitanTheme.textLow
                                    }

                                    MouseArea {
                                        id: pillMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            spotlight.activeCategory = modelData.catId;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 7-Column Applications Grid ───────────────────────────────
                Item {
                    id: gridContainer
                    width: parent.width
                    height: parent.height - categoryStrip.height - 8
                    clip: true

                    GridView {
                        id: appGrid
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        anchors.bottomMargin: 4
                        cellWidth: width / 7
                        cellHeight: 92
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: spotlight.results || []
                        currentIndex: spotlight.selectedIndex

                        Connections {
                            target: spotlight
                            function onSelectedIndexChanged() {
                                if (appGrid.count > 0 && spotlight.selectedIndex >= 0) {
                                    appGrid.currentIndex = spotlight.selectedIndex;
                                    appGrid.positionViewAtIndex(spotlight.selectedIndex, GridView.Contain);
                                }
                            }
                        }

                        delegate: SpotlightGridTile {
                            width: appGrid.cellWidth
                            height: appGrid.cellHeight
                            modelItem: modelData
                            isSelected: index === spotlight.selectedIndex
                            onHovered: spotlight.selectedIndex = index
                            onActivated: spotlight.activate(index)
                        }

                        // Empty State if no apps match
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            visible: (!spotlight.results || spotlight.results.length === 0) && !spotlight.hasCalcResult

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰀻"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 36
                                color: TitanTheme.textLow
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No Applications Found"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 14
                                font.weight: TitanTheme.weightMedium
                                color: TitanTheme.textMid
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Try searching with another term or select 'All'"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 11
                                color: TitanTheme.textLow
                            }
                        }
                    }
                }
            }
        }
    }
}
