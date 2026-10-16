import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * MeterRow — a labelled percentage with a thin progress track beneath it.
 * The bar colour can be driven by the caller (e.g. green→red by threshold).
 */
Item {
    id: root

    property string label: ""
    property string valueText: ""
    property real   pct: 0.0                    // 0..100
    property color  barColor: TitanTheme.accent

    implicitHeight: 30

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: root.label
                color: TitanTheme.textMid
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeLabel
                font.weight: TitanTheme.weightMedium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.valueText
                color: TitanTheme.textHigh
                font.family: TitanTheme.monoFamily
                font.pixelSize: TitanTheme.sizeLabel
                font.weight: TitanTheme.weightSemiBold
            }
        }

        TitanProgress {
            Layout.fillWidth: true
            implicitHeight: 6
            value: Math.max(0, Math.min(1, root.pct / 100.0))
            fillColor: root.barColor
        }
    }
}
