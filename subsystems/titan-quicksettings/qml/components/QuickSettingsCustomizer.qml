import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../style"

/**
 * QuickSettingsCustomizer — Samsung One UI 9.0 "Edit Quick Panel" customizer.
 *
 * Allows users to show, hide, and manage which quick action buttons and
 * bento cards are displayed in their ArchTitan Quick Settings panel.
 */
ColumnLayout {
    id: customizerRoot
    spacing: 12

    signal doneRequested()

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    readonly property var allActionMap: ({
        "focus":        { key: "focus",        icon: "\uf186", title: "Focus Mode",        desc: "Do not disturb notifications" },
        "dark":         { key: "dark",         icon: "\uf042", title: "Dark Theme",        desc: "Toggle light and dark color scheme" },
        "night":        { key: "night",        icon: "\uf06e", title: "Night Light",       desc: "Warm screen color filter" },
        "mic":          { key: "mic",          icon: "\uf130", title: "Microphone",        desc: "Mute or unmute audio input" },
        "caffeine":     { key: "caffeine",     icon: "\uf0f4", title: "Stay Awake",        desc: "Inhibit screen timeout & suspend" },
        "capture":      { key: "capture",      icon: "\uf030", title: "Screen Capture",    desc: "Region screenshot to clipboard" },
        "record":       { key: "record",       icon: "\uf03d", title: "Screen Record",     desc: "Wayland video screen recording" },
        "colorPick":    { key: "colorPick",    icon: "\uf1fb", title: "Color Picker",      desc: "Hyprpicker hex eyedropper" },
        "gameMode":     { key: "gameMode",     icon: "\uf11b", title: "Game Mode",         desc: "Performance profile & compositor" },
        "clipboard":    { key: "clipboard",    icon: "\uf0ea", title: "Clipboard",         desc: "Cliphist history manager" },
        "virtualInput": { key: "virtualInput", icon: "\uf11c", title: "Virtual Keyboard",  desc: "wvkbd on-screen touch keyboard" },
        "airplane":     { key: "airplane",     icon: "\uf072", title: "Airplane Mode",     desc: "Disable Wi-Fi and Bluetooth" }
    })

    property var orderedActions: {
        var rev = revision;
        var order = (typeof systemCtrl !== "undefined" && systemCtrl)
                    ? systemCtrl.getActionOrder()
                    : ["focus", "dark", "night", "mic", "caffeine", "capture", "record", "colorPick", "gameMode", "clipboard", "virtualInput", "airplane"];
        var list = [];
        for (var i = 0; i < order.length; ++i) {
            var k = order[i];
            if (allActionMap[k]) {
                list.push(allActionMap[k]);
            }
        }
        return list;
    }

    // ── 1. Customizer Header ────────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: headerRow.implicitHeight + 20
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Edit Quick Panel"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 15
                    font.weight: Font.Bold
                    color: TitanTheme.textPrimary
                }

                Text {
                    text: "Customize visible buttons & cards"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textMuted
                }
            }

            // Reset Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: resetMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: TitanTheme.borderGlass
                border.width: 1
                scale: resetMa.pressed ? 0.92 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf0e2" // undo / reset
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: TitanTheme.textMuted
                }

                MouseArea {
                    id: resetMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                            systemCtrl.resetTileVisibility();
                    }
                }
            }

            // Done Button
            Rectangle {
                implicitWidth: doneLabel.implicitWidth + 24
                height: 32
                radius: 16
                color: doneMa.pressed ? Qt.darker(TitanTheme.accent, 1.2) : (doneMa.containsMouse ? Qt.lighter(TitanTheme.accent, 1.1) : TitanTheme.accentBlue)
                border.color: TitanTheme.borderActive
                border.width: 1
                scale: doneMa.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf00c" // checkmark
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 12
                        color: TitanTheme.accentText
                    }

                    Text {
                        id: doneLabel
                        text: "Done"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: TitanTheme.accentText
                    }
                }

                MouseArea {
                    id: doneMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: customizerRoot.doneRequested()
                }
            }
        }
    }

    // ── 2. Action Buttons Section ───────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: actionCol.implicitHeight + 24
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        ColumnLayout {
            id: actionCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: "ACTION BUTTONS"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textSubtle
            }

            // ── Global Icon Size Control ────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 12
                color: TitanTheme.bgInset
                border.color: TitanTheme.borderGlass
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text {
                        text: "Global Size"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }

                    Item { Layout.fillWidth: true }

                    // Segmented pill chips: S (38) | M (48) | L (56) | XL (64)
                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: [
                                { label: "S",  size: 38 },
                                { label: "M",  size: 48 },
                                { label: "L",  size: 56 },
                                { label: "XL", size: 64 }
                            ]

                            delegate: Rectangle {
                                width: 34
                                height: 24
                                radius: 12
                                property bool isSelected: {
                                    var rev = customizerRoot.revision;
                                    var cur = (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.globalIconSize : 48;
                                    return cur === modelData.size;
                                }

                                color: isSelected ? TitanTheme.accent : (chipMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill)
                                border.color: isSelected ? TitanTheme.borderActive : TitanTheme.borderGlass
                                border.width: 1

                                scale: chipMa.pressed ? 0.92 : 1.0
                                Behavior on scale { NumberAnimation { duration: 110 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: parent.isSelected ? "#0F141C" : TitanTheme.textPrimary
                                }

                                MouseArea {
                                    id: chipMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                            systemCtrl.setGlobalIconSize(modelData.size);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // List of toggleable & reorderable action buttons
            Repeater {
                model: customizerRoot.orderedActions

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: itemMa.containsMouse ? TitanTheme.bgHover : "transparent"

                    property bool isTileActive: {
                        if (typeof systemCtrl === "undefined" || !systemCtrl) return true;
                        return (systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible(modelData.key, true);
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 8
                        spacing: 8

                        // ── Reorder Arrows (Move Up / Down) ──────────────────
                        ColumnLayout {
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter

                            // Move Up Arrow
                            Rectangle {
                                width: 22
                                height: 16
                                radius: 8
                                color: upMa.containsMouse ? TitanTheme.bgHover : "transparent"
                                opacity: index > 0 ? 1.0 : 0.25

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf077" // chevron up
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    color: upMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                                }

                                MouseArea {
                                    id: upMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: index > 0
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                            systemCtrl.moveActionOrder(index, index - 1);
                                        }
                                    }
                                }
                            }

                            // Move Down Arrow
                            Rectangle {
                                width: 22
                                height: 16
                                radius: 8
                                color: downMa.containsMouse ? TitanTheme.bgHover : "transparent"
                                opacity: index < customizerRoot.orderedActions.length - 1 ? 1.0 : 0.25

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf078" // chevron down
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    color: downMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                                }

                                MouseArea {
                                    id: downMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: index < customizerRoot.orderedActions.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: index < customizerRoot.orderedActions.length - 1
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                            systemCtrl.moveActionOrder(index, index + 1);
                                        }
                                    }
                                }
                            }
                        }

                        // Icon Medallion
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: isTileActive ? TitanTheme.bgOneUIPill : TitanTheme.bgInset
                            border.color: TitanTheme.borderGlass
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 13
                                color: isTileActive ? TitanTheme.textPrimary : TitanTheme.textSubtle
                            }
                        }

                        // Labels & Click-to-Toggle Area
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: modelData.title
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    color: isTileActive ? TitanTheme.textPrimary : TitanTheme.textMuted
                                }

                                Text {
                                    text: modelData.desc
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: 10
                                    color: TitanTheme.textSubtle
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                                        systemCtrl.setTileVisible(modelData.key, !isTileActive);
                                }
                            }
                        }

                        // Per-Button Custom Size Chip
                        Rectangle {
                            width: 36
                            height: 22
                            radius: 11
                            property string currentSize: {
                                var rev = customizerRoot.revision;
                                return (typeof systemCtrl !== "undefined" && systemCtrl)
                                       ? systemCtrl.getActionSize(modelData.key)
                                       : "default";
                            }
                            property bool isOverridden: currentSize !== "default"

                            color: isOverridden ? Qt.rgba(0, 0.82, 1, 0.22) : (sizeChipMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgInset)
                            border.color: isOverridden ? TitanTheme.accent : TitanTheme.borderGlass
                            border.width: 1

                            scale: sizeChipMa.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 110 } }

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var sz = parent.currentSize.toLowerCase();
                                    if (sz === "small" || sz === "s") return "S";
                                    if (sz === "medium" || sz === "m") return "M";
                                    if (sz === "large" || sz === "l") return "L";
                                    if (sz === "huge" || sz === "xl") return "XL";
                                    return "Def";
                                }
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: parent.isOverridden ? TitanTheme.accent : TitanTheme.textMuted
                            }

                            MouseArea {
                                id: sizeChipMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                        systemCtrl.cycleActionSize(modelData.key);
                                    }
                                }
                            }
                        }

                        // One UI Animated Toggle Switch
                        Rectangle {
                            id: switchTrack
                            width: 42
                            height: 22
                            radius: 11
                            color: isTileActive ? TitanTheme.accentBlue : TitanTheme.bgInset
                            border.color: isTileActive ? TitanTheme.borderActive : TitanTheme.borderGlass
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                x: isTileActive ? (parent.width - width - 3) : 3
                                color: "#FFFFFF"
                                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                                        systemCtrl.setTileVisible(modelData.key, !isTileActive);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── 3. Bento Panels Section ─────────────────────────────────────────────
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 24
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: "BENTO PANELS"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textSubtle
            }

            Repeater {
                model: [
                    { key: "sliders",     icon: "\uf1de", title: "Sliders Bento",      desc: "Display brightness and audio volume" },
                    { key: "deviceMedia", icon: "\uf025", title: "Media Controller",   desc: "Output device & audio player status" },
                    { key: "liquidGlass", icon: "\uf043", title: "Liquid Glass",       desc: "Compositor frosted glass opacity" }
                ]

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: cardMa.containsMouse ? TitanTheme.bgHover : "transparent"

                    property bool isTileActive: {
                        if (typeof systemCtrl === "undefined" || !systemCtrl) return true;
                        return (systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible(modelData.key, true);
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 12

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: isTileActive ? TitanTheme.bgOneUIPill : TitanTheme.bgInset
                            border.color: TitanTheme.borderGlass
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 13
                                color: isTileActive ? TitanTheme.textPrimary : TitanTheme.textSubtle
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.title
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: isTileActive ? TitanTheme.textPrimary : TitanTheme.textMuted
                            }

                            Text {
                                text: modelData.desc
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: TitanTheme.textSubtle
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        Rectangle {
                            width: 42
                            height: 22
                            radius: 11
                            color: isTileActive ? TitanTheme.accentBlue : TitanTheme.bgInset
                            border.color: isTileActive ? TitanTheme.borderActive : TitanTheme.borderGlass
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                anchors.verticalCenter: parent.verticalCenter
                                x: isTileActive ? (parent.width - width - 3) : 3
                                color: "#FFFFFF"
                                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    MouseArea {
                        id: cardMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl)
                                systemCtrl.setTileVisible(modelData.key, !isTileActive);
                        }
                    }
                }
            }
        }
    }

    // ── 4. Panel Layout & Widgets (Move Everything & Add Widgets) ───────────
    Rectangle {
        id: layoutCard
        Layout.fillWidth: true
        implicitHeight: layoutCol.implicitHeight + 24
        radius: TitanTheme.radiusBento
        color: TitanTheme.bgOneUICard
        border.color: TitanTheme.borderGlass
        border.width: 1

        readonly property var sectionMap: ({
            "topRow":       { key: "topRow",       icon: "\uf1eb", title: "Top Row (Dual Square)", desc: "Connectivity + Music Player paired" },
            "connectivity": { key: "connectivity", icon: "\uf1eb", title: "Connectivity Card",     desc: "Wi-Fi, Bluetooth, TitanDrop" },
            "music":        { key: "music",        icon: "\uf001", title: "Music Player Banner",   desc: "Full-width media player banner" },
            "sliders":      { key: "sliders",      icon: "\uf1de", title: "Sliders Bento",          desc: "Display brightness & sound volume" },
            "actions":      { key: "actions",      icon: "\uf009", title: "Floating Action Grid",  desc: "Independent circular action buttons" },
            "liquidGlass":  { key: "liquidGlass",  icon: "\uf043", title: "Liquid Glass",          desc: "Compositor frosted glass opacity" },
            "performance":  { key: "performance",  icon: "\uf2db", title: "Performance Monitor",  desc: "Live CPU & Memory utilization" },
            "battery":      { key: "battery",      icon: "\uf240", title: "Battery & Energy",      desc: "Battery status & power profile" }
        })

        readonly property var activeSections: {
            var rev = customizerRoot.revision;
            var order = (typeof systemCtrl !== "undefined" && systemCtrl)
                        ? systemCtrl.getSectionOrder()
                        : ["topRow", "sliders", "actions", "liquidGlass"];
            var list = [];
            for (var i = 0; i < order.length; ++i) {
                var k = order[i];
                if (sectionMap[k]) list.push(sectionMap[k]);
            }
            return list;
        }

        ColumnLayout {
            id: layoutCol
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Text {
                text: "PANEL LAYOUT ORDER"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textSubtle
            }

            Text {
                text: "Move sections up or down to organize your panel"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                color: TitanTheme.textMuted
            }

            // Section list with Move Up and Move Down
            Repeater {
                model: layoutCard.activeSections

                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 12
                    color: TitanTheme.bgInset

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 8

                        // Move Up / Down controls
                        ColumnLayout {
                            spacing: 1
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                width: 22
                                height: 16
                                radius: 8
                                color: secUpMa.containsMouse ? TitanTheme.bgHover : "transparent"
                                opacity: index > 0 ? 1.0 : 0.25

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf077"
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    color: secUpMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                                }

                                MouseArea {
                                    id: secUpMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: index > 0
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                                            systemCtrl.moveSectionOrder(index, index - 1);
                                    }
                                }
                            }

                            Rectangle {
                                width: 22
                                height: 16
                                radius: 8
                                color: secDownMa.containsMouse ? TitanTheme.bgHover : "transparent"
                                opacity: index < layoutCard.activeSections.length - 1 ? 1.0 : 0.25

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf078"
                                    font.family: TitanTheme.monoFamily
                                    font.pixelSize: 9
                                    color: secDownMa.containsMouse ? TitanTheme.accent : TitanTheme.textMuted
                                }

                                MouseArea {
                                    id: secDownMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: index < layoutCard.activeSections.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: index < layoutCard.activeSections.length - 1
                                    onClicked: {
                                        if (typeof systemCtrl !== "undefined" && systemCtrl)
                                            systemCtrl.moveSectionOrder(index, index + 1);
                                    }
                                }
                            }
                        }

                        // Icon Medallion
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: TitanTheme.bgOneUIPill
                            border.color: TitanTheme.borderGlass
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 13
                                color: TitanTheme.textPrimary
                            }
                        }

                        // Labels
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.title
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: TitanTheme.textPrimary
                            }

                            Text {
                                text: modelData.desc
                                font.family: TitanTheme.fontFamily
                                font.pixelSize: 10
                                color: TitanTheme.textSubtle
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        // Remove / Hide button
                        Rectangle {
                            width: 28
                            height: 28
                            radius: 14
                            color: removeSecMa.containsMouse ? Qt.rgba(0.95, 0.55, 0.66, 0.25) : "transparent"
                            visible: modelData.key !== "actions"

                            Text {
                                anchors.centerIn: parent
                                text: "\uf00d"
                                font.family: TitanTheme.monoFamily
                                font.pixelSize: 10
                                color: removeSecMa.containsMouse ? TitanTheme.red : TitanTheme.textMuted
                            }

                            MouseArea {
                                id: removeSecMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof systemCtrl !== "undefined" && systemCtrl)
                                        systemCtrl.removeSection(modelData.key);
                                }
                            }
                        }
                    }
                }
            }

            // ── Widget Actions & Add Widgets Row ────────────────────────────
            Text {
                text: "ADD & ORGANIZE WIDGETS"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: TitanTheme.textSubtle
                Layout.topMargin: 6
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                // Move Music to Bottom / Separate Music Button
                Rectangle {
                    implicitWidth: musicBtnRow.implicitWidth + 20
                    height: 32
                    radius: 16
                    color: musicBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                    border.color: TitanTheme.borderGlass
                    border.width: 1

                    property bool hasSeparateMusic: {
                        var rev = customizerRoot.revision;
                        var order = (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getSectionOrder() : [];
                        return order.indexOf("music") !== -1;
                    }

                    RowLayout {
                        id: musicBtnRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: parent.parent.hasSeparateMusic ? "\uf066" : "\uf001"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 11
                            color: TitanTheme.accent
                        }

                        Text {
                            text: parent.parent.hasSeparateMusic ? "Pair Music at Top" : "Move Music to Bottom"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }
                    }

                    MouseArea {
                        id: musicBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                if (parent.hasSeparateMusic) {
                                    systemCtrl.mergeTopRow();
                                } else {
                                    systemCtrl.splitTopRow();
                                }
                            }
                        }
                    }
                }

                // Add Performance Monitor Widget
                Rectangle {
                    implicitWidth: perfBtnRow.implicitWidth + 20
                    height: 32
                    radius: 16
                    color: perfBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                    border.color: TitanTheme.borderGlass
                    border.width: 1

                    property bool hasPerf: {
                        var rev = customizerRoot.revision;
                        var order = (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getSectionOrder() : [];
                        return order.indexOf("performance") !== -1;
                    }

                    RowLayout {
                        id: perfBtnRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: parent.parent.hasPerf ? "\uf00d" : "\uf067"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 11
                            color: parent.parent.hasPerf ? TitanTheme.red : TitanTheme.green
                        }

                        Text {
                            text: parent.parent.hasPerf ? "Remove CPU/RAM" : "Add CPU/RAM Monitor"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }
                    }

                    MouseArea {
                        id: perfBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                if (parent.hasPerf) {
                                    systemCtrl.removeSection("performance");
                                } else {
                                    systemCtrl.addSection("performance");
                                }
                            }
                        }
                    }
                }

                // Add Battery & Energy Widget
                Rectangle {
                    implicitWidth: batBtnRow.implicitWidth + 20
                    height: 32
                    radius: 16
                    color: batBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                    border.color: TitanTheme.borderGlass
                    border.width: 1

                    property bool hasBat: {
                        var rev = customizerRoot.revision;
                        var order = (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.getSectionOrder() : [];
                        return order.indexOf("battery") !== -1;
                    }

                    RowLayout {
                        id: batBtnRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: parent.parent.hasBat ? "\uf00d" : "\uf067"
                            font.family: TitanTheme.monoFamily
                            font.pixelSize: 11
                            color: parent.parent.hasBat ? TitanTheme.red : TitanTheme.green
                        }

                        Text {
                            text: parent.parent.hasBat ? "Remove Battery" : "Add Battery Widget"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            color: TitanTheme.textPrimary
                        }
                    }

                    MouseArea {
                        id: batBtnMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof systemCtrl !== "undefined" && systemCtrl) {
                                if (parent.hasBat) {
                                    systemCtrl.removeSection("battery");
                                } else {
                                    systemCtrl.addSection("battery");
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
