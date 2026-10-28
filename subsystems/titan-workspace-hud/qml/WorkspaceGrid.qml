import QtQuick
import QtQuick.Layouts

Rectangle {
    id: gridContainer
    width: 1264
    height: 320
    radius: 24
    color: "#F011111B"
    border.color: "#1EFFFFFF"
    border.width: 1

    Grid {
        id: grid
        anchors.centerIn: parent
        columns: 5
        rows: 2
        columnSpacing: 12
        rowSpacing: 12

        Repeater {
            model: hyprland.workspaces
            delegate: WorkspaceCard {
                cardIndex: index
                wsId: modelData.id
                isActive: modelData.active
                winCount: modelData.windowCount
                windowList: modelData.windows
                hasAudio: modelData.hasAudio || false
            }
        }
    }
}
