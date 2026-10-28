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
        interval: 140
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
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: root.spotlightOpen ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeSpotlight()
        }
    }

    // Spotlight Floating Card
    SpotlightCard {
        id: card
        width: 700
        x: (parent.width - width) / 2
        y: parent.height * 0.18

        opacity: root.spotlightOpen ? 1.0 : 0.0
        scale: root.spotlightOpen ? 1.0 : 0.965
        transformOrigin: Item.Top

        Behavior on opacity {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on scale {
            NumberAnimation { duration: 140; easing.type: Easing.OutBack }
        }

        // Prevent click events from reaching scrim
        MouseArea {
            anchors.fill: parent
            preventStealing: true
            propagateComposedEvents: true
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.closeSpotlight()
    }
}
