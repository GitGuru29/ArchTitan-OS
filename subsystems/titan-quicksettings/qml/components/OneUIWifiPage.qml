import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../style"

/**
 * OneUIWifiPage — Samsung One UI 9.0 Wi-Fi Selection Subpage.
 *
 * Provides live scanning, network signal bars, security status,
 * inline password authentication, and 1-click connect/disconnect.
 */
Rectangle {
    id: wifiPageRoot
    radius: TitanTheme.radiusWindow
    color: TitanTheme.bgMenu
    border.color: TitanTheme.borderGlass
    border.width: 1
    clip: true

    signal closeRequested()

    property string selectedSsid: ""
    property bool showPasswordText: false

    onVisibleChanged: {
        if (visible) {
            selectedSsid = "";
            showPasswordText = false;
            if (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled) {
                networkCtrl.scanNetworks();
            }
        }
    }

    // Smooth entry transition
    opacity: visible ? 1.0 : 0.0
    scale: visible ? 1.0 : 0.95
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.15 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        // ── 1. Header Bar: Back Button, Title, Rescan, Master Toggle ──────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Back Button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: backMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: backMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "\uf060" // Arrow left
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 14
                    color: TitanTheme.textPrimary
                }

                MouseArea {
                    id: backMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiPageRoot.closeRequested()
                }
            }

            // Title
            Text {
                text: "Wi-Fi"
                font.family: TitanTheme.fontFamily
                font.pixelSize: 18
                font.weight: Font.Bold
                color: TitanTheme.textPrimary
                Layout.fillWidth: true
            }

            // Rescan / Refresh Button
            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 18
                color: rescanMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: rescanMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1
                visible: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : false

                Text {
                    id: scanIcon
                    anchors.centerIn: parent
                    text: "\uf021" // Sync / Refresh
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 13
                    color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isScanning)
                           ? TitanTheme.accent : TitanTheme.textSecondary

                    NumberAnimation on rotation {
                        running: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.isScanning : false
                        from: 0
                        to: 360
                        duration: 1000
                        loops: Animation.Infinite
                    }
                }

                MouseArea {
                    id: rescanMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof networkCtrl !== "undefined" && networkCtrl)
                            networkCtrl.scanNetworks()
                    }
                }
            }

            // Master On/Off Switch Pill
            Rectangle {
                Layout.preferredWidth: 54
                Layout.preferredHeight: 30
                radius: 15
                color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled)
                       ? TitanTheme.accent : TitanTheme.bgOneUIPill
                border.color: TitanTheme.borderGlass
                border.width: 1

                Behavior on color { ColorAnimation { duration: 150 } }

                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    x: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.wifiEnabled) ? parent.width - width - 3 : 3

                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof networkCtrl !== "undefined" && networkCtrl)
                            networkCtrl.toggleWifi()
                    }
                }
            }
        }

        // ── Status Banner (Connecting / Info / Error) ────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: TitanTheme.radiusBento
            color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isConnecting)
                   ? Qt.rgba(0, 0.82, 1, 0.15) : Qt.rgba(0.95, 0.55, 0.66, 0.15)
            border.color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isConnecting)
                          ? TitanTheme.accent : TitanTheme.red
            border.width: 1
            visible: (typeof networkCtrl !== "undefined" && networkCtrl)
                     && (networkCtrl.isConnecting || (networkCtrl.statusMessage !== "" && !networkCtrl.statusMessage.startsWith("Connected to")))

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    text: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isConnecting) ? "\uf110" : "\uf071"
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 12
                    color: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isConnecting) ? TitanTheme.accent : TitanTheme.red

                    NumberAnimation on rotation {
                        running: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.isConnecting : false
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                    }
                }

                Text {
                    text: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.statusMessage : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    color: TitanTheme.textPrimary
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // ── 2. Body View: Disabled State vs Available Networks ───────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // State A: Wi-Fi Disabled
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 14
                visible: (typeof networkCtrl !== "undefined" && networkCtrl) ? !networkCtrl.wifiEnabled : false

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 72
                    height: 72
                    radius: 36
                    color: TitanTheme.bgOneUIPill

                    Text {
                        anchors.centerIn: parent
                        text: "\uf1eb"
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 32
                        color: TitanTheme.textMuted
                    }
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: "Wi-Fi is turned off"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    color: TitanTheme.textSecondary
                }

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 120
                    height: 36
                    radius: 18
                    color: TitanTheme.accent

                    Text {
                        anchors.centerIn: parent
                        text: "Turn On"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        font.weight: Font.Bold
                        color: "#FFFFFF"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (typeof networkCtrl !== "undefined" && networkCtrl)
                                networkCtrl.toggleWifi()
                        }
                    }
                }
            }

            // State B: Wi-Fi Enabled (List of Networks)
            ScrollView {
                anchors.fill: parent
                clip: true
                visible: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiEnabled : true

                ColumnLayout {
                    width: parent.width
                    spacing: 12

                    // ── Active Connected Card ────────────────────────────────
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.connected : false

                        Text {
                            text: "CONNECTED NETWORK"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: TitanTheme.textMuted
                            anchors.leftMargin: 4
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            radius: TitanTheme.radiusBento
                            color: TitanTheme.bgOneUICard
                            border.color: TitanTheme.accent
                            border.width: 1.5

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Rectangle {
                                    width: 38
                                    height: 38
                                    radius: 19
                                    color: Qt.rgba(0, 0.82, 1, 0.20)

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf1eb"
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 16
                                        color: TitanTheme.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.ssid : ""
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: TitanTheme.textPrimary
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: "Connected · Active"
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 11
                                        color: TitanTheme.green
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 76
                                    Layout.preferredHeight: 28
                                    radius: 14
                                    color: disMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                                    border.color: disMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Disconnect"
                                        font.family: TitanTheme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: TitanTheme.textSecondary
                                    }

                                    MouseArea {
                                        id: disMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof networkCtrl !== "undefined" && networkCtrl)
                                                networkCtrl.disconnectNetwork()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Available Networks Header ────────────────────────────
                    RowLayout {
                        Layout.fillWidth: true
                        anchors.topMargin: 4

                        Text {
                            text: "AVAILABLE NETWORKS"
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: TitanTheme.textMuted
                            Layout.fillWidth: true
                        }

                        Text {
                            text: (typeof networkCtrl !== "undefined" && networkCtrl && networkCtrl.isScanning) ? "Scanning..." : ""
                            font.family: TitanTheme.fontFamily
                            font.pixelSize: 10
                            color: TitanTheme.accent
                        }
                    }

                    // ── Network List View ────────────────────────────────────
                    ListView {
                        id: networkListView
                        Layout.fillWidth: true
                        implicitHeight: contentHeight
                        interactive: false
                        spacing: 6
                        model: (typeof networkCtrl !== "undefined" && networkCtrl) ? networkCtrl.wifiList : []

                        delegate: Rectangle {
                            id: delegateCard
                            width: networkListView.width
                            implicitHeight: isExpanded ? cardCol.implicitHeight + 16 : 52
                            radius: TitanTheme.radiusBento
                            color: itemMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUICard
                            border.color: modelData.inUse ? TitanTheme.accent : (itemMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass)
                            border.width: modelData.inUse ? 1.5 : 1
                            clip: true

                            property bool isExpanded: wifiPageRoot.selectedSsid === modelData.ssid && !modelData.inUse

                            Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                            ColumnLayout {
                                id: cardCol
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 10
                                spacing: 8

                                // Main Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    // Signal Icon
                                    Text {
                                        text: "\uf1eb"
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 14
                                        color: modelData.inUse ? TitanTheme.accent : (modelData.signal > 50 ? TitanTheme.textPrimary : TitanTheme.textMuted)
                                    }

                                    // SSID Name
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.ssid
                                            font.family: TitanTheme.fontFamily
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            color: modelData.inUse ? TitanTheme.accent : TitanTheme.textPrimary
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: modelData.inUse ? "Connected" : (modelData.signal + "% signal" + (modelData.security ? " · " + modelData.security : ""))
                                            font.family: TitanTheme.fontFamily
                                            font.pixelSize: 10
                                            color: modelData.inUse ? TitanTheme.green : TitanTheme.textSubtle
                                        }
                                    }

                                    // Lock Icon
                                    Text {
                                        text: "\uf023" // Lock
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 12
                                        color: TitanTheme.textMuted
                                        visible: modelData.isProtected && !modelData.inUse
                                    }

                                    // Checkmark
                                    Text {
                                        text: "\uf00c" // Checkmark
                                        font.family: TitanTheme.monoFamily
                                        font.pixelSize: 13
                                        color: TitanTheme.green
                                        visible: modelData.inUse
                                    }
                                }

                                // ── Expandable Password Input Box ────────────────────
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: delegateCard.isExpanded

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 38
                                        radius: 10
                                        color: TitanTheme.bgOneUIPill
                                        border.color: passField.activeFocus ? TitanTheme.accent : TitanTheme.borderGlass
                                        border.width: passField.activeFocus ? 1.5 : 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 8

                                            TextInput {
                                                id: passField
                                                Layout.fillWidth: true
                                                font.family: TitanTheme.fontFamily
                                                font.pixelSize: 12
                                                color: TitanTheme.textPrimary
                                                echoMode: wifiPageRoot.showPasswordText ? TextInput.Normal : TextInput.Password
                                                clip: true

                                                Text {
                                                    text: "Enter Wi-Fi password..."
                                                    font.family: TitanTheme.fontFamily
                                                    font.pixelSize: 12
                                                    color: TitanTheme.textMuted
                                                    visible: !passField.text && !passField.activeFocus
                                                }

                                                Keys.onReturnPressed: doConnect()
                                                Keys.onEnterPressed: doConnect()
                                            }

                                            Text {
                                                text: wifiPageRoot.showPasswordText ? "\uf070" : "\uf06e" // Eye / eye-slash
                                                font.family: TitanTheme.monoFamily
                                                font.pixelSize: 13
                                                color: eyeMa.containsMouse ? TitanTheme.textPrimary : TitanTheme.textMuted

                                                MouseArea {
                                                    id: eyeMa
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: wifiPageRoot.showPasswordText = !wifiPageRoot.showPasswordText
                                                }
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Item { Layout.fillWidth: true }

                                        Rectangle {
                                            Layout.preferredWidth: 64
                                            Layout.preferredHeight: 28
                                            radius: 14
                                            color: cancelMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Cancel"
                                                font.family: TitanTheme.fontFamily
                                                font.pixelSize: 11
                                                color: TitanTheme.textSecondary
                                            }

                                            MouseArea {
                                                id: cancelMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: wifiPageRoot.selectedSsid = ""
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 76
                                            Layout.preferredHeight: 28
                                            radius: 14
                                            color: TitanTheme.accent

                                            Text {
                                                anchors.centerIn: parent
                                                text: "Connect"
                                                font.family: TitanTheme.fontFamily
                                                font.pixelSize: 11
                                                font.weight: Font.Bold
                                                color: "#FFFFFF"
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: doConnect()
                                            }
                                        }
                                    }
                                }

                                function doConnect() {
                                    if (typeof networkCtrl !== "undefined" && networkCtrl) {
                                        networkCtrl.connectToNetwork(modelData.ssid, passField.text);
                                        wifiPageRoot.selectedSsid = "";
                                    }
                                }
                            }

                            MouseArea {
                                id: itemMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !delegateCard.isExpanded
                                onClicked: {
                                    if (modelData.inUse)
                                        return;
                                    if (modelData.isProtected) {
                                        wifiPageRoot.selectedSsid = modelData.ssid;
                                    } else {
                                        if (typeof networkCtrl !== "undefined" && networkCtrl)
                                            networkCtrl.connectToNetwork(modelData.ssid, "");
                                    }
                                }
                            }
                        }
                    }

                    // Empty networks state
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "No networks found. Try refreshing."
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 12
                        color: TitanTheme.textMuted
                        visible: networkListView.count === 0 && (typeof networkCtrl !== "undefined" && networkCtrl && !networkCtrl.isScanning)
                    }
                }
            }
        }
    }
}
