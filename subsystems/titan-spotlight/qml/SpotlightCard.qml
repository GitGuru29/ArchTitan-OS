import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import ArchTitan.TitanUI

/**
 * SpotlightCard — Apple Spotlight authentic floating card.
 * Sleek 56px floating pill that expands into a 2-column results list + rich preview pane.
 */
Rectangle {
    id: cardRoot
    width: 700
    radius: 18

    readonly property bool hasContent: spotlight.query.trim().length > 0 ||
                                       spotlight.isClipboardMode ||
                                       spotlight.hasCalcResult ||
                                       (spotlight.results && spotlight.results.length > 0)

    height: hasContent ? (56 + 1 + 380 + 28) : 56
    clip: false

    Behavior on height {
        NumberAnimation {
            duration: TitanTheme.durFast
            easing.type: TitanTheme.easingStandard
        }
    }

    // Frosted obsidian glass backing (97% opacity)
    color: TitanTheme.isDark ? TitanTheme.alphaColor(TitanTheme.mantle, 0.97)
                             : TitanTheme.alphaColor(TitanTheme.surface0, 0.97)
    border.width: 1
    border.color: TitanTheme.border

    // Outer subtle ambient halo
    Rectangle {
        anchors.fill: parent
        anchors.margins: -1
        radius: cardRoot.radius + 1
        z: -1
        color: "transparent"
        border.width: 1
        border.color: TitanTheme.alphaColor(TitanTheme.accent, 0.22)
    }

    // Top Specular Horizon Glint
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 40
        height: 1
        radius: 1
        z: 1
        color: TitanTheme.stateHover
    }

    // True GPU drop shadow
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: TitanTheme.scrim
        shadowBlur: 1.0
        shadowVerticalOffset: 16
        autoPaddingEnabled: true
    }

    property alias input: searchInput

    Column {
        width: parent.width
        spacing: 0

        // 1. Search Header (56px)
        SpotlightInput {
            id: searchInput
            onEscapePressed: root.closeSpotlight()
            onReturnPressed: spotlight.activateCurrent()
            onUpPressed: spotlight.selectPrev()
            onDownPressed: spotlight.selectNext()
        }

        // 2. Dividing Hairline
        Rectangle {
            width: parent.width
            height: 1
            color: TitanTheme.borderSubtle
            visible: cardRoot.hasContent
        }

        // 3. Two-Column Results + Details Area (380px)
        Item {
            width: parent.width
            height: cardRoot.hasContent ? 380 : 0
            visible: cardRoot.hasContent
            clip: true

            Row {
                anchors.fill: parent

                // ── Left Column: Results List (Width: 335px) ──────────────────
                Item {
                    width: 335
                    height: parent.height

                    ListView {
                        id: resultsList
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 2
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: spotlight.results || []
                        currentIndex: spotlight.selectedIndex

                        Connections {
                            target: spotlight
                            function onSelectedIndexChanged() {
                                if (resultsList.count > 0 && spotlight.selectedIndex >= 0) {
                                    resultsList.currentIndex = spotlight.selectedIndex;
                                    resultsList.positionViewAtIndex(spotlight.selectedIndex, ListView.Contain);
                                }
                            }
                        }

                        delegate: SpotlightResultRow {
                            width: resultsList.width
                            modelItem: modelData
                            isSelected: index === spotlight.selectedIndex
                            onHovered: spotlight.selectedIndex = index
                            onActivated: spotlight.activate(index)
                        }

                        // Empty State inside Left Pane
                        Column {
                            anchors.centerIn: parent
                            spacing: 8
                            visible: (!spotlight.results || spotlight.results.length === 0) && !spotlight.hasCalcResult

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰍉"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 26
                                color: TitanTheme.textLow
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No Results Found"
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 13
                                font.weight: TitanTheme.weightMedium
                                color: TitanTheme.textMid
                            }
                        }
                    }
                }

                // ── Vertical Hairline Divider (Width: 1px) ────────────────────
                Rectangle {
                    width: 1
                    height: parent.height
                    color: TitanTheme.borderSubtle
                }

                // ── Right Column: Apple Preview Pane (Remaining Width) ────────
                SpotlightPreviewPane {
                    width: parent.width - 335 - 1
                    height: parent.height
                }
            }
        }

        // 4. Minimalist Footer (28px)
        SpotlightFooter {
            id: footer
            visible: cardRoot.hasContent
        }
    }
}
