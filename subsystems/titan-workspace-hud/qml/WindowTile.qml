import QtQuick
import QtQuick.Controls

Item {
    id: windowTile
    property string windowAddress: ""
    property string appClass: ""
    property string windowTitle: ""
    property string iconSource: ""
    property string thumbnailSource: ""
    property int tileWidth: 48
    property int tileHeight: 48
    property bool isFocused: false

    width: tileWidth
    height: tileHeight

    scale: dragArea.drag.active ? 1.08 : (dragArea.containsMouse ? 1.02 : 1.0)
    rotation: dragArea.drag.active ? 2.5 : 0.0

    Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }
    Behavior on rotation { NumberAnimation { duration: 180; easing.type: Easing.OutBack } }

    Drag.active: dragArea.drag.active
    Drag.source: windowTile
    Drag.hotSpot.x: width / 2
    Drag.hotSpot.y: height / 2

    // Elevation drop shadow while dragging
    Rectangle {
        id: dropShadow
        anchors.fill: bgCard
        anchors.topMargin: 6
        radius: 12
        color: "#60000000"
        visible: dragArea.drag.active
        z: -1
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 10
        color: "#F0181825"
        border.color: isFocused ? "#00D2FF" : (dragArea.containsMouse ? "#B300D2FF" : "#28FFFFFF")
        border.width: isFocused || dragArea.containsMouse ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

        // Live Window Preview (macOS Mission Control Thumbnail)
        Image {
            id: winThumbnail
            anchors.fill: parent
            anchors.margins: 1
            visible: thumbnailSource !== "" && status === Image.Ready
            source: thumbnailSource !== "" ? thumbnailSource : ""
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            opacity: dragArea.containsMouse ? 0.98 : 0.88
            clip: true
        }

        // Top mini window header bar when thumbnail is visible
        Rectangle {
            id: winHeaderBar
            visible: winThumbnail.visible
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 18
            radius: 8
            color: "#CC11111B"
            z: 5

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Image {
                    width: 12
                    height: 12
                    source: iconSource
                    fillMode: Image.PreserveAspectFit
                }

                Text {
                    text: windowTitle !== "" ? windowTitle : appClass
                    font.family: "Inter, sans-serif"
                    font.pixelSize: 8.5
                    font.weight: Font.Medium
                    color: "#CDD6F4"
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, bgCard.width - 45)
                }
            }
        }

        // Bottom floating app badge when thumbnail is visible (macOS style)
        Rectangle {
            id: appBadge
            visible: winThumbnail.visible && tileWidth >= 64 && tileHeight >= 64
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            width: 24
            height: 24
            radius: 6
            color: "#D9181825"
            border.color: "#33FFFFFF"
            border.width: 1
            z: 8

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                source: iconSource
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
        }

        // Subtle document/code scanline texture (fallback when thumbnail not yet cached)
        Canvas {
            anchors.fill: parent
            visible: !winThumbnail.visible
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

        // Active focused window dot indicator
        Rectangle {
            id: focusIndicator
            visible: isFocused
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 5
            width: 6
            height: 6
            radius: 3
            color: "#00D2FF"
            z: 10
        }

        // Centered App Icon (fallback when thumbnail not yet cached)
        Image {
            id: appIcon
            visible: !winThumbnail.visible
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

        // Floating Title Tooltip on hover
        Rectangle {
            id: titleTooltip
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 4
            width: Math.min(parent.width - 8, titleText.implicitWidth + 12)
            height: 16
            radius: 4
            color: "#E611111B"
            border.color: "#33FFFFFF"
            border.width: 1
            opacity: dragArea.containsMouse && !dragArea.drag.active ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 120 } }
            z: 20

            Text {
                id: titleText
                anchors.centerIn: parent
                width: parent.width - 6
                text: windowTitle
                elide: Text.ElideRight
                font.family: "Inter, sans-serif"
                font.pixelSize: 8
                font.weight: Font.Medium
                color: "#CDD6F4"
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
        }

        onReleased: {
            hudRoot.isDragging = false;
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
