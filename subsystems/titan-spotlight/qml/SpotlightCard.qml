import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: cardRoot
    width: 760
    radius: 26

    gradient: Gradient {
        GradientStop {
            position: 0.0
            color: TitanTheme.isDark
                   ? Qt.rgba(TitanTheme.mantle.r, TitanTheme.mantle.g, TitanTheme.mantle.b, 0.62)
                   : Qt.rgba(1, 1, 1, 0.80)
        }
        GradientStop {
            position: 1.0
            color: TitanTheme.isDark
                   ? Qt.rgba(TitanTheme.crust.r, TitanTheme.crust.g, TitanTheme.crust.b, 0.50)
                   : Qt.rgba(1, 1, 1, 0.68)
        }
    }

    border.width: 1
    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.35)

    // Deep 3D Ambient Drop Shadow (Layer 1 - diffuse ground shadow)
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 12
        anchors.bottomMargin: -12
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        radius: cardRoot.radius + 6
        z: -3
        color: Qt.rgba(0, 0, 0, 0.50)
    }

    // Mid 3D Drop Shadow (Layer 2 - closer occluding shadow)
    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 4
        anchors.bottomMargin: -4
        anchors.leftMargin: -2
        anchors.rightMargin: -2
        radius: cardRoot.radius + 2
        z: -2
        color: Qt.rgba(0, 0, 0, 0.38)
    }

    // Outer luminous accent halo
    Rectangle {
        anchors.fill: parent
        anchors.margins: -2
        radius: cardRoot.radius + 2
        z: -1
        color: "transparent"
        border.width: 1.5
        border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.16)
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
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
            GradientStop { position: 0.40; color: Qt.rgba(1, 1, 1, 0.03) }
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
            GradientStop { position: 0.2; color: Qt.rgba(1, 1, 1, 0.20) }
            GradientStop { position: 0.5; color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.55) }
            GradientStop { position: 0.8; color: Qt.rgba(1, 1, 1, 0.20) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Dynamic height calculation
    height: cardColumn.implicitHeight

    Behavior on height {
        NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
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
                               ? Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.28)
                               : (catMouse.containsMouse
                                  ? (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08))
                                  : (TitanTheme.isDark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0, 0, 0, 0.04)))
                        border.width: 1
                        border.color: isActive
                                      ? TitanTheme.accent
                                      : (catMouse.containsMouse
                                         ? Qt.rgba(1, 1, 1, 0.14)
                                         : Qt.rgba(1, 1, 1, 0.06))

                        Behavior on color { ColorAnimation { duration: 100 } }

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
                color: TitanTheme.isDark ? Qt.rgba(0, 0, 0, 0.28) : Qt.rgba(0, 0, 0, 0.05)
                border.width: 0

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
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
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
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
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
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
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
                NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
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
