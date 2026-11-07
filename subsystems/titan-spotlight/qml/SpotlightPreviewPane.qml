import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * SpotlightPreviewPane — Apple Spotlight-style right details preview pane.
 * Shows high-resolution application details, calculation hero results,
 * command previews, and quick actions.
 */
Item {
    id: root

    readonly property var currentItem: (spotlight.results && spotlight.results.length > spotlight.selectedIndex && spotlight.selectedIndex >= 0)
                                      ? spotlight.results[spotlight.selectedIndex]
                                      : null

    // ── 1. Math Calculation Preview ───────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12
        visible: spotlight.hasCalcResult && (!root.currentItem || root.currentItem.type === "calc")

        Item { Layout.fillHeight: true }

        // Calculator Icon
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 64
            height: 64
            radius: 18
            color: TitanTheme.accentSoft
            border.width: 1
            border.color: TitanTheme.accentEdge

            Text {
                anchors.centerIn: parent
                text: "󰃬"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 32
                color: TitanTheme.accent
            }
        }

        // Formula
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: spotlight.calcFormula
            font.family: TitanTheme.fontFamily
            font.pixelSize: 16
            color: TitanTheme.textMid
        }

        // Huge Result
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: spotlight.calcResult
            font.family: TitanTheme.fontFamily
            font.pixelSize: 42
            font.weight: TitanTheme.weightBold
            color: TitanTheme.accent
        }

        Item { Layout.preferredHeight: 8 }

        // Copy Action Button
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: copyRow.implicitWidth + 28
            implicitHeight: 34
            radius: 10
            color: copyMouse.containsMouse ? TitanTheme.accentHover : TitanTheme.accent

            Row {
                id: copyRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Copy to Clipboard"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: TitanTheme.weightSemiBold
                    color: TitanTheme.textOnAccent
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 4
                    color: TitanTheme.alphaColor(TitanTheme.crust, 0.35)
                    Text {
                        anchors.centerIn: parent
                        text: "⏎"
                        font.pixelSize: 10
                        font.bold: true
                        color: TitanTheme.textOnAccent
                    }
                }
            }

            MouseArea {
                id: copyMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: spotlight.copyCalcResult()
            }
        }

        Item { Layout.fillHeight: true }
    }

    // ── 2. Standard Item Details Preview (App / Command / System / Clip) ──
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 10
        visible: !spotlight.hasCalcResult && root.currentItem !== null

        Item { Layout.fillHeight: true }

        // Hero Icon Card
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 76
            height: 76
            radius: 20
            color: TitanTheme.alphaColor(TitanTheme.surface0, 0.70)
            border.width: 1
            border.color: TitanTheme.borderSubtle

            Image {
                anchors.centerIn: parent
                width: 52
                height: 52
                source: root.currentItem && root.currentItem.icon ? ("image://icon/" + root.currentItem.icon) : ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                text: root.currentItem && root.currentItem.type === "command" ? "󰞷" :
                      root.currentItem && root.currentItem.type === "clipboard" ? "󰅍" :
                      root.currentItem && root.currentItem.type === "system" ? "󰒓" : "󰀻"
                font.family: TitanTheme.monoFamily
                font.pixelSize: 34
                color: TitanTheme.accent
                visible: !parent.children[0].visible
            }
        }

        // Title
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width - 24
            text: root.currentItem ? (root.currentItem.title || "") : ""
            font.family: TitanTheme.fontFamily
            font.pixelSize: 19
            font.weight: TitanTheme.weightBold
            color: TitanTheme.textHigh
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        // Subtitle / Description
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width - 24
            text: root.currentItem ? (root.currentItem.subtitle || "") : ""
            font.family: TitanTheme.fontFamily
            font.pixelSize: 12
            color: TitanTheme.textLow
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }

        // Dividing Hairline
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            height: 1
            color: TitanTheme.borderSubtle
        }

        // Metadata Spec Sheet
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Type"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textLow
                    Layout.preferredWidth: 60
                }
                Text {
                    text: root.currentItem ? (root.currentItem.category || (root.currentItem.type || "").toUpperCase()) : ""
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    font.weight: TitanTheme.weightMedium
                    color: TitanTheme.textMid
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: root.currentItem && root.currentItem.command !== undefined && root.currentItem.command !== ""
                Text {
                    text: "Command"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 11
                    color: TitanTheme.textLow
                    Layout.preferredWidth: 60
                }
                Text {
                    text: root.currentItem ? (root.currentItem.command || "") : ""
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    color: TitanTheme.textLow
                    elide: Text.ElideMiddle
                    Layout.fillWidth: true
                }
            }
        }

        Item { Layout.preferredHeight: 6 }

        // Primary Action Pill Button
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: actionRow.implicitWidth + 24
            implicitHeight: 34
            radius: 10
            color: actionMouse.containsMouse ? TitanTheme.accentHover : TitanTheme.accent

            Row {
                id: actionRow
                anchors.centerIn: parent
                spacing: 8
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentItem && root.currentItem.type === "clipboard" ? "Paste Item" :
                          root.currentItem && root.currentItem.type === "command" ? "Run in Terminal" : "Open Application"
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 12
                    font.weight: TitanTheme.weightSemiBold
                    color: TitanTheme.textOnAccent
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 4
                    color: TitanTheme.alphaColor(TitanTheme.crust, 0.35)
                    Text {
                        anchors.centerIn: parent
                        text: "⏎"
                        font.pixelSize: 10
                        font.bold: true
                        color: TitanTheme.textOnAccent
                    }
                }
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: spotlight.activateCurrent()
            }
        }

        Item { Layout.fillHeight: true }
    }
}

