import QtQuick
import QtQuick.Window
import ArchTitan.TitanUI

Window {
    id: root

    width: Screen.width
    height: Screen.height

    flags: Qt.FramelessWindowHint
    color: "transparent"
    visible: false
    title: "titan-spotlight"

    property bool spotlightOpen: false

    function openSpotlight() {
        spotlightOpen = true;
        visible = true;
        requestActivate();
        Qt.callLater(function () {
            card.input.inputItem.forceActiveFocus();
        });
    }

    function closeSpotlight() {
        spotlightOpen = false;
        closeTimer.restart();
    }

    function toggleSpotlight() {
        if (spotlightOpen) closeSpotlight();
        else openSpotlight();
    }

    Timer {
        id: closeTimer
        interval: 150
        onTriggered: {
            if (!root.spotlightOpen) {
                root.visible = false;
            }
        }
    }

    // Scrim (click-away background)
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.48)
        opacity: root.spotlightOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 130; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeSpotlight()
        }
    }

    // Spotlight Floating Liquid Glass Card
    SpotlightCard {
        id: card
        width: 760
        x: (parent.width - width) / 2
        y: parent.height * 0.14

        opacity: root.spotlightOpen ? 1.0 : 0.0
        scale: root.spotlightOpen ? 1.0 : 0.96
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 160; easing.type: Easing.OutBack }
        }

        // Prevent click events from reaching scrim
        MouseArea {
            anchors.fill: parent
            z: -1
            preventStealing: true
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeSpotlight()
    }
}
