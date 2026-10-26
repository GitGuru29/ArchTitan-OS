import QtQuick
import QtQuick.Controls

Item {
    id: windowTile
    property string windowAddress: ""
    property string appClass: ""
    property string windowTitle: ""
    property string iconSource: ""
    property int tileWidth: 48
    property int tileHeight: 48

    width: tileWidth
    height: tileHeight

    Drag.active: dragArea.drag.active
    Drag.source: windowTile
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 10
        color: "#F0181825"
        border.color: dragArea.containsMouse ? "#B300D2FF" : "#28FFFFFF"
        border.width: dragArea.containsMouse ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        // Subtle document/code scanline texture
        Canvas {
            anchors.fill: parent
            opacity: 0.12
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = "#FFFFFF";
                for (var y = 4; y < height - 4; y += 6) {
                    ctx.fillRect(8, y, width - 16, 2);
                }
            }
        }

        // Centered App Icon
        Image {
            id: appIcon
            anchors.centerIn: parent
            width: tileWidth >= 64 && tileHeight >= 64 ? 40 : 28
            height: width
            source: iconSource
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
        }

        // Close window button in top-right
        Rectangle {
            id: closeBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 16
            height: 16
            radius: 8
            color: closeMouse.containsMouse ? "#F38BA8" : "#20FFFFFF"
            z: 10

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 8
                font.bold: true
                color: closeMouse.containsMouse ? "#11111B" : "#A0CDD6F4"
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    hyprland.closeWindow(windowAddress);
                }
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag.target: windowTile

        onPressed: {
            hudRoot.isDragging = true;
            windowTile.scale = 1.05;
        }

        onReleased: {
            hudRoot.isDragging = false;
            windowTile.scale = 1.0;
            if (hudRoot.pendingClose) {
                hudRoot.closeHud();
            }
        }

        onClicked: {
            hyprland.focusWindow(windowAddress);
            hudRoot.closeHud();
        }
    }

    states: [
        State {
            when: windowTile.Drag.active
            ParentChange { target: windowTile; parent: hudRoot }
            AnchorChanges { target: windowTile; anchors.horizontalCenter: undefined; anchors.verticalCenter: undefined }
        }
    ]
}
