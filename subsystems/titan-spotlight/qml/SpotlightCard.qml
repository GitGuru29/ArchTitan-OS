import QtQuick
import ArchTitan.TitanUI

Rectangle {
    id: cardRoot
    width: 700
    radius: 22

    color: TitanTheme.isDark ? "#E611111B" : "#F2FFFFFF"
    border.width: 1
    border.color: Qt.rgba(TitanTheme.accent.r, TitanTheme.accent.g, TitanTheme.accent.b, 0.45)

    // Dynamic height calculation
    height: cardColumn.implicitHeight

    Behavior on height {
        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
    }

    property alias input: searchInput

    Column {
        id: cardColumn
        width: parent.width
        spacing: 0

        // Search Input
        SpotlightInput {
            id: searchInput
            onEscapePressed: root.closeSpotlight()
            onReturnPressed: spotlight.activateCurrent()
            onUpPressed: spotlight.selectPrev()
            onDownPressed: spotlight.selectNext()
        }

        // Divider
        Rectangle {
            width: parent.width
            height: 1
            color: Qt.rgba(255, 255, 255, 0.08)
            visible: spotlight.hasCalcResult || spotlight.results.length > 0
        }

        // Live Calculator Card (if formula detected)
        Item {
            width: parent.width
            height: spotlight.hasCalcResult ? 74 : 0
            visible: spotlight.hasCalcResult
            clip: true

            Behavior on height {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            SpotlightCalcPreview {
                anchors.fill: parent
                anchors.margins: 6
                isSelected: spotlight.selectedIndex === 0 && spotlight.results.length === 0
                onClicked: spotlight.copyCalcResult()
            }
        }

        // Results List
        ListView {
            id: resultsList
            width: parent.width
            height: Math.min(spotlight.results.length * 54 + (spotlight.results.length > 0 ? 12 : 0), 380)
            clip: true
            model: spotlight.results
            currentIndex: spotlight.selectedIndex

            onCurrentIndexChanged: {
                if (spotlight.selectedIndex !== currentIndex) {
                    spotlight.selectedIndex = currentIndex;
                }
            }

            Behavior on height {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            spacing: 2
            topMargin: 6
            bottomMargin: 6
            leftMargin: 8
            rightMargin: 8

            delegate: SpotlightResultRow {
                width: resultsList.width - 16
                modelItem: modelData
                isSelected: index === spotlight.selectedIndex
                onActivated: spotlight.activate(index)
            }
        }

        // Footer Hints
        SpotlightFooter {
            id: footer
        }
    }
}
