import QtQuick
import QtQuick.Controls
import ArchTitan.TitanUI

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
    readonly property bool liquidGlass: (typeof AppearanceSettings !== "undefined" && AppearanceSettings.glassmorphism !== undefined) ? (AppearanceSettings.glassmorphism !== false) : true

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

    Rectangle {
        id: dropShadow
        anchors.fill: bgCard
        anchors.topMargin: 6
        radius: 12
        color: Qt.rgba(0, 0, 0, 0.38)
        visible: dragArea.drag.active
        z: -1
    }

    Rectangle {
        id: bgCard
        anchors.fill: parent
        radius: 10
        color: windowTile.liquidGlass ? TitanTheme.glassCard : TitanTheme.bg1
        border.color: isFocused || dragArea.containsMouse ? TitanTheme.accentEdge : TitanTheme.borderSubtle
        border.width: isFocused || dragArea.containsMouse ? 1.5 : 1

        Behavior on border.color { ColorAnimation { duration: 150 } }

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

        Rectangle {
            id: winHeaderBar
            visible: winThumbnail.visible
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: 18
            radius: 8
            color: TitanTheme.glass
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
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    color: TitanTheme.textHigh
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, bgCard.width - 45)
                }
            }
        }

        Rectangle {
            id: appBadge
            visible: winThumbnail.visible && tileWidth >= 64 && tileHeight >= 64
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 6
            width: 24
            height: 24
            radius: 6
            color: TitanTheme.glassCard
            border.color: TitanTheme.borderSubtle
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

        Canvas {
            anchors.fill: parent
            visible: !winThumbnail.visible
            opacity: 0.12
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.fillStyle = TitanTheme.textHigh.toString();
                for (var y = 4; y < height - 4; y += 6) {
                    ctx.fillRect(8, y, width - 16, 2);
                }
            }
        }

        Rectangle {
            id: focusIndicator
            visible: isFocused
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.margins: 5
            width: 6
            height: 6
            radius: 3
            color: TitanTheme.accent
            z: 10
        }

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

        Rectangle {
            id: closeBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 16
            height: 16
            radius: 8
            color: closeMouse.containsMouse ? TitanTheme.danger : Qt.rgba(0.05, 0.05, 0.08, 0.55)
            z: 10

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 8
                font.bold: true
                color: closeMouse.containsMouse ? TitanTheme.crust : TitanTheme.textMid
            }

            MouseArea {
                id: closeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: hyprland.closeWindow(windowAddress)
            }
        }

        Rectangle {
            id: titleTooltip
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottomMargin: 4
            width: Math.min(parent.width - 8, titleText.implicitWidth + 12)
            height: 16
            radius: 4
            color: TitanTheme.glassCard
            border.color: TitanTheme.borderSubtle
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
                color: TitanTheme.textHigh
            }
        }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        drag.target: windowTile

        onPressed: hudRoot.isDragging = true

        onReleased: {
            hudRoot.isDragging = false;
            if (hudRoot.pendingClose) hudRoot.closeHud();
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
