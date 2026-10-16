import QtQuick
import QtQuick.Layouts
import ArchTitan.TitanUI

/**
 * WorkloadRow — one THM v3 workload: name, type badge, state and RSS memory.
 * `workload` is a QVariantMap from ThmReader.
 */
Item {
    id: root

    property var workload: ({})

    implicitHeight: 42

    readonly property string typeLabel: {
        var t = (root.workload.type || "").toString();
        if (t === "ANDROID_DEV") return "Android";
        if (t === "WEB_DEV")     return "Web";
        if (t === "SYSTEM_DEV")  return "Dev";
        if (t === "AI_TASK")     return "AI";
        if (t === "SERVICE")     return "Service";
        if (t === "VM")          return "VM";
        if (t === "CASUAL")      return "Casual";
        return "—";
    }
    readonly property color typeColor: {
        var t = (root.workload.type || "").toString();
        if (t === "AI_TASK")     return TitanTheme.mauve;
        if (t === "WEB_DEV")     return TitanTheme.info;
        if (t === "ANDROID_DEV") return TitanTheme.success;
        if (t === "SYSTEM_DEV")  return TitanTheme.teal;
        if (t === "VM")          return TitanTheme.peach;
        if (t === "SERVICE")     return TitanTheme.warning;
        return TitanTheme.textMid;
    }
    readonly property color stateColor: {
        var s = (root.workload.state || "").toString();
        if (s === "ACTIVE")               return TitanTheme.success;
        if (s === "BACKGROUND_EXECUTING") return TitanTheme.info;
        if (s === "IDLE")                 return TitanTheme.textLow;
        if (s === "AGING")                return TitanTheme.warning;
        if (s === "RECLAIMABLE")          return TitanTheme.danger;
        return TitanTheme.textLow;
    }

    Rectangle {
        anchors.fill: parent
        radius: TitanTheme.radiusMd
        color: TitanTheme.bgInset
        border.width: 1
        border.color: TitanTheme.borderSubtle

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: typeText.implicitWidth + 14
                implicitHeight: 20
                radius: 7
                color: Qt.rgba(root.typeColor.r, root.typeColor.g, root.typeColor.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(root.typeColor.r, root.typeColor.g, root.typeColor.b, 0.35)
                Text {
                    id: typeText
                    anchors.centerIn: parent
                    text: root.typeLabel
                    color: root.typeColor
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: TitanTheme.weightSemiBold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text {
                    Layout.fillWidth: true
                    text: (root.workload.name || "").toString()
                    color: TitanTheme.textHigh
                    elide: Text.ElideMiddle
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: TitanTheme.sizeLabel
                }
                Text {
                    text: "PID " + (root.workload.pid || 0)
                          + " · " + (root.workload.pids || 0) + " procs"
                          + " · ws " + (root.workload.workspace || 0)
                    color: TitanTheme.textLow
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 0
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: (root.workload.memMb || 0) + " MB"
                    color: TitanTheme.textMid
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: (root.workload.state || "").toString().replace(/_/g, " ").toLowerCase()
                    color: root.stateColor
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 9
                    font.weight: TitanTheme.weightMedium
                }
            }
        }
    }
}
