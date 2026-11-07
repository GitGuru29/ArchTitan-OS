import QtQuick
import QtQuick.Effects
import ArchTitan.TitanUI

Rectangle {
    id: cardRoot
    width: 760
    radius: 26

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: TitanTheme.isDark
                   ? TitanTheme.alphaColor(TitanTheme.mantle, 0.97)
                   : TitanTheme.alphaColor(TitanTheme.surface0, 0.97)
        }
        GradientStop {
            position: 1.0
            color: TitanTheme.isDark
                   ? TitanTheme.alphaColor(TitanTheme.base, 0.95)
                   : TitanTheme.alphaColor(TitanTheme.mantle, 0.95)
        }
    }

    border.width: 1
    border.color: TitanTheme.border

    // True GPU drop shadow outside perimeter (never paints black inside the glass)
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: TitanTheme.scrim
        shadowBlur: 1.0
        shadowVerticalOffset: 16
        autoPaddingEnabled: true
    }

    // Outer soft accent halo
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: cardRoot.radius + 2
        z: -1
        color: "transparent"
        border.width: 1
        border.color: TitanTheme.alphaColor(TitanTheme.accent, 0.22)
    }

    // 3D Glass Specular Sheen (Curved top-light wash)
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(parent.height * 0.45, 190)
        radius: cardRoot.radius
        z: 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: TitanTheme.stateHover }
            GradientStop { position: 0.40; color: TitanTheme.alphaColor(TitanTheme.surface1, 0.06) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Top Specular Horizon Glint (Faded at edges, authentic glass refraction)
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 48
        height: 1.5
        radius: 1
        z: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.2; color: TitanTheme.stateHover }
            GradientStop { position: 0.5; color: TitanTheme.accentEdge }
            GradientStop { position: 0.8; color: TitanTheme.stateHover }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Dynamic height calculation
    height: cardColumn.implicitHeight

    Behavior on height {
        NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard }
    }

    property alias input: searchInput

    Column {
        id: cardColumn
        width: parent.width
        spacing: 0

        // 1. Search Input + Segmented View Switcher (Grid | Bento | List)
        SpotlightInput {
            id: searchInput
            onEscapePressed: root.closeSpotlight()
            onReturnPressed: spotlight.activateCurrent()
            onUpPressed: spotlight.selectUp()
            onDownPressed: spotlight.selectDown()
            onLeftPressed: spotlight.selectLeft()
            onRightPressed: spotlight.selectRight()
        }

        // 2. Category Filter Bar (Glass Filter Strip)
        Item {
            id: filterStrip
            width: parent.width
            height: !spotlight.isClipboardMode ? 42 : 0
            visible: !spotlight.isClipboardMode
            clip: true

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: [
                        { id: "ALL",    icon: "󰕰", label: "All"    },
                        { id: "APPS",   icon: "󰀻", label: "Apps"   },
                        { id: "DEV",    icon: "󰨞", label: "Dev"    },
                        { id: "SYSTEM", icon: "󰒓", label: "System" },
                        { id: "WEB",    icon: "󰖟", label: "Web"    },
                        { id: "MEDIA",  icon: "󰕧", label: "Media"  }
                    ]

                    delegate: Rectangle {
                        id: catPill
                        required property var modelData
                        readonly property bool isActive: spotlight.activeCategory === modelData.id

                        height: 26
                        width: catRow.implicitWidth + 16
                        radius: 8
                        color: isActive
                               ? TitanTheme.accentSoft
                               : (catMouse.containsMouse
                                  ? TitanTheme.stateHover
                                  : TitanTheme.alphaColor(TitanTheme.surface0, 0.45))
                        border.width: 1
                        border.color: isActive
                                      ? TitanTheme.accent
                                      : (catMouse.containsMouse
                                         ? TitanTheme.borderHover
                                         : TitanTheme.borderSubtle)

                        Behavior on color { ColorAnimation { duration: TitanTheme.durFast } }

                        Row {
                            id: catRow
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: catPill.modelData.icon
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 12
                                color: catPill.isActive ? TitanTheme.accent : TitanTheme.textMid
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: catPill.modelData.label
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 11
                                font.weight: catPill.isActive ? Font.Bold : Font.Medium
                                color: catPill.isActive
                                       ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 1.0) : TitanTheme.textHigh)
                                       : TitanTheme.textMid
                            }
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                spotlight.activeCategory = catPill.modelData.id;
                                searchInput.inputItem.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Right-side Item Count Badge
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                height: 22
                width: countText.implicitWidth + 14
                radius: 7
                color: TitanTheme.stateHover
                border.width: 1
                border.color: TitanTheme.borderSubtle

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: spotlight.results.length + (spotlight.results.length === 1 ? " item" : " items")
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: TitanTheme.textLow
                }
            }
        }

        // 3. Live Calculator Card (if formula detected)
        Item {
            width: parent.width
            height: spotlight.hasCalcResult ? 76 : 0
            visible: spotlight.hasCalcResult
            clip: true

            Behavior on height {
                NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard }
            }

            SpotlightCalcPreview {
                anchors.fill: parent
                anchors.margins: 8
                isSelected: spotlight.selectedIndex === 0 && spotlight.results.length === 0
                onClicked: spotlight.copyCalcResult()
            }
        }

        // 4A. GRID VIEW (4-Column Liquid Glass Launchpad Grid)
        GridView {
            id: resultsGrid
            readonly property bool activeView: !spotlight.isClipboardMode && spotlight.viewMode === "grid" && spotlight.results.length > 0
            visible: activeView
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: activeView
                    ? Math.min(Math.ceil(spotlight.results.length / 4) * cellHeight + 16, 430)
                    : 0
            cellWidth: 184
            cellHeight: 138
            topMargin: 10
            bottomMargin: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: activeView ? spotlight.results : []
            currentIndex: spotlight.selectedIndex

            Connections {
                target: spotlight
                function onSelectedIndexChanged() {
                    if (resultsGrid.activeView) {
                        resultsGrid.currentIndex = spotlight.selectedIndex;
                        resultsGrid.positionViewAtIndex(spotlight.selectedIndex, GridView.Contain);
                    }
                }
            }

            Behavior on height {
                NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard }
            }

            delegate: Item {
                width: resultsGrid.cellWidth
                height: resultsGrid.cellHeight

                SpotlightGridTile {
                    anchors.centerIn: parent
                    modelItem: modelData
                    isSelected: index === spotlight.selectedIndex
                    onHovered: spotlight.selectedIndex = index
                    onActivated: spotlight.activate(index)
                }
            }
        }

        // 4B. BENTO VIEW (2-Column Horizontal Bento Glass Cards)
        GridView {
            id: resultsBento
            readonly property bool activeView: !spotlight.isClipboardMode && spotlight.viewMode === "bento" && spotlight.results.length > 0
            visible: activeView
            width: parent.width - 24
            anchors.horizontalCenter: parent.horizontalCenter
            height: activeView
                    ? Math.min(Math.ceil(spotlight.results.length / 2) * cellHeight + 16, 396)
                    : 0
            cellWidth: 368
            cellHeight: 74
            topMargin: 10
            bottomMargin: 6
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: activeView ? spotlight.results : []
            currentIndex: spotlight.selectedIndex

            Connections {
                target: spotlight
                function onSelectedIndexChanged() {
                    if (resultsBento.activeView) {
                        resultsBento.currentIndex = spotlight.selectedIndex;
                        resultsBento.positionViewAtIndex(spotlight.selectedIndex, GridView.Contain);
                    }
                }
            }

            Behavior on height {
                NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard }
            }

            delegate: Item {
                width: resultsBento.cellWidth
                height: resultsBento.cellHeight

                SpotlightBentoTile {
                    anchors.centerIn: parent
                    modelItem: modelData
                    isSelected: index === spotlight.selectedIndex
                    onHovered: spotlight.selectedIndex = index
                    onActivated: spotlight.activate(index)
                }
            }
        }

        // 4C. LIST VIEW (Full-Width Detailed Glass Rows)
        ListView {
            id: resultsList
            readonly property bool activeView: (spotlight.isClipboardMode || spotlight.viewMode === "list") && spotlight.results.length > 0
            visible: activeView
            width: parent.width
            height: activeView
                    ? Math.min(spotlight.results.length * 57 + 14, 398)
                    : 0
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: activeView ? spotlight.results : []
            currentIndex: spotlight.selectedIndex

            Connections {
                target: spotlight
                function onSelectedIndexChanged() {
                    if (resultsList.activeView) {
                        resultsList.currentIndex = spotlight.selectedIndex;
                        resultsList.positionViewAtIndex(spotlight.selectedIndex, ListView.Contain);
                    }
                }
            }

            Behavior on height {
                NumberAnimation { duration: TitanTheme.durFast; easing.type: TitanTheme.easingStandard }
            }

            spacing: 3
            topMargin: 8
            bottomMargin: 6
            leftMargin: 12
            rightMargin: 12

            delegate: Item {
                width: resultsList.width - 24
                height: 54

                SpotlightResultRow {
                    anchors.fill: parent
                    modelItem: modelData
                    isSelected: index === spotlight.selectedIndex
                    onHovered: spotlight.selectedIndex = index
                    onActivated: spotlight.activate(index)
                }
            }
        }

        // 4D. Empty State
        Item {
            width: parent.width
            height: (spotlight.results.length === 0 && !spotlight.hasCalcResult) ? 110 : 0
            visible: spotlight.results.length === 0 && !spotlight.hasCalcResult
            clip: true

            Column {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "󰍉"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 26
                    color: TitanTheme.textLow
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No matching applications or commands"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: TitanTheme.textMid
                }
            }
        }

        // 5. Footer Hints
        SpotlightFooter {
            id: footer
        }
    }
}
