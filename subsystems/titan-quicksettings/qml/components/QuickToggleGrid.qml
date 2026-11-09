import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * QuickToggleGrid — Modular, Reorderable & Resizable Bento Grid.
 *
 * Architecture:
 * - Independent floating Action Circles (zero enclosing borders)
 * - Dedicated tactile "[ ✎ Edit Controls ]" button
 * - Dynamic Section Layout Engine: sections can be reordered (e.g. music to bottom)
 * - Support for new widgets: System Performance Monitor and Battery Health
 */
ColumnLayout {
    id: bentoRoot
    Layout.fillWidth: true
    spacing: 12

    property int revision: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.tileVisibilityRevision : 0

    readonly property var sectionOrder: {
        var rev = revision;
        return (typeof systemCtrl !== "undefined" && systemCtrl)
               ? systemCtrl.getSectionOrder()
               : ["topRow", "sliders", "actions", "liquidGlass"];
    }

    // ── Modular Section Repeater ────────────────────────────────────────────
    Repeater {
        model: bentoRoot.sectionOrder

        delegate: Loader {
            Layout.fillWidth: true
            sourceComponent: {
                if (modelData === "topRow") return topRowComponent;
                if (modelData === "connectivity") return connectivityComponent;
                if (modelData === "music") return musicComponent;
                if (modelData === "sliders") return slidersComponent;
                if (modelData === "actions") return actionsComponent;
                if (modelData === "liquidGlass") return liquidGlassComponent;
                if (modelData === "performance") return performanceComponent;
                if (modelData === "battery") return batteryComponent;
                return null;
            }
        }
    }

    // ═════════════════════════════════════════════════════════════════════════
    //  SECTION COMPONENTS
    // ═════════════════════════════════════════════════════════════════════════

    // 1. Dual Squares: Connectivity + Music (Paired Side-by-Side)
    Component {
        id: topRowComponent
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            SquareConnectivityWidget {
                Layout.fillWidth: true
                onOpenWifiRequested: {
                    if (typeof rootWindow !== "undefined" && rootWindow) {
                        rootWindow.showWifiPage = true;
                    }
                }
            }

            SquareMusicWidget {
                Layout.fillWidth: true
                visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("deviceMedia", true))
            }
        }
    }

    // 2. Connectivity Widget (Independent Row)
    Component {
        id: connectivityComponent
        RowLayout {
            Layout.fillWidth: true
            SquareConnectivityWidget {
                Layout.fillWidth: true
                onOpenWifiRequested: {
                    if (typeof rootWindow !== "undefined" && rootWindow) {
                        rootWindow.showWifiPage = true;
                    }
                }
            }
        }
    }

    // 3. Music Player (Independent Row — Luxury Full-Width Banner)
    Component {
        id: musicComponent
        BannerMusicWidget {
            Layout.fillWidth: true
        }
    }

    // 4. Sliders Bento: Display Brightness + Sound Volume
    Component {
        id: slidersComponent
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10
            visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("sliders", true))

            // Display Brightness Pebble Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: displayCol.implicitHeight + 20
                radius: TitanTheme.radiusCard // 24px super-round
                color: TitanTheme.bgOneUICard
                border.color: TitanTheme.borderGlass
                border.width: 1
                clip: true

                ColumnLayout {
                    id: displayCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    OneUISlider {
                        title: "Display"
                        iconGlyph: "\uf185" // sun
                        from: 0
                        to: 100
                        value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.brightness : 80
                        fillAccent: TitanTheme.accent
                        onChanged: (v) => {
                            if (typeof systemCtrl !== "undefined" && systemCtrl) systemCtrl.setBrightness(v)
                        }
                    }
                }
            }

            // Sound Volume Pebble Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: soundCol.implicitHeight + 20
                radius: TitanTheme.radiusCard // 24px super-round
                color: TitanTheme.bgOneUICard
                border.color: TitanTheme.borderGlass
                border.width: 1
                clip: true

                ColumnLayout {
                    id: soundCol
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    OneUISlider {
                        title: "Sound"
                        iconGlyph: {
                            if (muted) return "\uf026";
                            if (value <= 30) return "\uf027";
                            return "\uf028";
                        }
                        from: 0
                        to: 100
                        value: (typeof audioCtrl !== "undefined" && audioCtrl) ? audioCtrl.sinkVolume : 60
                        muted: typeof audioCtrl !== "undefined" && audioCtrl && audioCtrl.sinkMuted
                        fillAccent: TitanTheme.accent
                        onChanged: (v) => {
                            if (typeof audioCtrl !== "undefined" && audioCtrl) audioCtrl.setVolume(v)
                        }
                    }
                }
            }
        }
    }

    // 5. Floating Independent Action Buttons (NO Outer Box) + Edit Controls Button
    Component {
        id: actionsComponent
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            // Circular Action Grid floating directly on the glass surface
            CircularActionGrid {
                id: actionGrid
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
            }

            // ── Centered Tactile "Edit Controls" Capsule Button ─────────────
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: editBtnRow.implicitWidth + 24
                height: 30
                radius: 15
                color: editBtnMa.containsMouse ? TitanTheme.bgHover : TitanTheme.bgOneUIPill
                border.color: editBtnMa.containsMouse ? TitanTheme.borderHover : TitanTheme.borderGlass
                border.width: 1
                scale: editBtnMa.pressed ? 0.94 : 1.0
                Behavior on scale { NumberAnimation { duration: 110 } }

                RowLayout {
                    id: editBtnRow
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "\uf044" // edit
                        font.family: TitanTheme.monoFamily
                        font.pixelSize: 11
                        color: TitanTheme.textPrimary
                    }

                    Text {
                        text: "Edit Controls"
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: TitanTheme.textPrimary
                    }
                }

                MouseArea {
                    id: editBtnMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof rootWindow !== "undefined" && rootWindow) {
                            rootWindow.editMode = true;
                        }
                    }
                }
            }
        }
    }

    // 6. Liquid Glass Opacity Bento Card
    Component {
        id: liquidGlassComponent
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: glassCol.implicitHeight + 20
            radius: TitanTheme.radiusCard // 24px super-round
            color: TitanTheme.bgOneUICard
            border.color: TitanTheme.borderGlass
            border.width: 1
            clip: true
            visible: (typeof systemCtrl === "undefined" || !systemCtrl) || ((systemCtrl.tileVisibilityRevision >= 0) && systemCtrl.getTileVisible("liquidGlass", true))

            ColumnLayout {
                id: glassCol
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                OneUISlider {
                    title: "Liquid Glass"
                    iconGlyph: "\uf043" // water droplet
                    from: 10
                    to: 95
                    value: (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.glassOpacity : 35
                    suffix: "%"
                    fillAccent: TitanTheme.cyan
                    onChanged: (v) => {
                        if (typeof systemCtrl !== "undefined" && systemCtrl) {
                            if (typeof systemCtrl.setGlassOpacity === "function") {
                                systemCtrl.setGlassOpacity(v)
                            } else {
                                systemCtrl.glassOpacity = v
                            }
                        }
                    }
                }
            }
        }
    }

    // 7. System Performance Monitor Widget
    Component {
        id: performanceComponent
        PerformanceWidget {
            Layout.fillWidth: true
        }
    }

    // 8. Battery Health & Power Profile Widget
    Component {
        id: batteryComponent
        BatteryWidget {
            Layout.fillWidth: true
        }
    }
}
