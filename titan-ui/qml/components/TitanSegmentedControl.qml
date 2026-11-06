import QtQuick
import ArchTitan.TitanUI

/* TitanSegmentedControl — desktop mode and category switcher with a sliding active thumb. */
Rectangle {
    id: root

    property var model: []
    property int currentIndex: 0

    signal selected(int index, string label)

    implicitWidth: row.implicitWidth + TitanTheme.space1 * 2
    implicitHeight: 34
    radius: TitanTheme.radiusControl
    color: TitanTheme.bgInset
    border.width: 1
    border.color: TitanTheme.borderSubtle

    // Sliding active indicator thumb
    Rectangle {
        id: thumb
        y: TitanTheme.space1 / 2
        height: root.height - TitanTheme.space1
        radius: TitanTheme.radiusControl - 2
        color: TitanTheme.surface0
        border.width: 1
        border.color: TitanTheme.borderHover

        // Calculate target x and width based on current index
        readonly property Item activeItem: row.children[root.currentIndex] || null
        x: activeItem ? activeItem.x + TitanTheme.space1 : TitanTheme.space1
        width: activeItem ? activeItem.width : 0
        visible: root.model && root.model.length > 0

        Behavior on x { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
        Behavior on width { NumberAnimation { duration: TitanTheme.durBase; easing.type: TitanTheme.easingStandard } }
    }

    Row {
        id: row
        x: TitanTheme.space1
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: root.model
            delegate: Rectangle {
                id: segItem
                height: root.height - TitanTheme.space1
                width: segLabel.implicitWidth + TitanTheme.space3 * 2
                color: "transparent"

                Text {
                    id: segLabel
                    anchors.centerIn: parent
                    text: modelData
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeBody
                    font.weight: root.currentIndex === index ? TitanTheme.weightSemiBold : TitanTheme.weightRegular
                    color: root.currentIndex === index ? TitanTheme.textHigh : segHover.hovered ? TitanTheme.textMid : TitanTheme.textLow
                }

                HoverHandler { id: segHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        root.currentIndex = index
                        root.selected(index, modelData)
                    }
                }
            }
        }
    }
}
