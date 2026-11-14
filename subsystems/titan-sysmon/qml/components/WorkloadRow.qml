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

    implicitWidth: 0
    implicitHeight: 46
    Layout.fillWidth: true
    Layout.minimumWidth: 0

    readonly property int wsNum: (root.workload.workspace !== undefined) ? root.workload.workspace : -2
    readonly property int procCount: root.workload.pids || 0
    readonly property string wsText: wsNum > 0 ? ("ws " + wsNum) : (wsNum === 0 ? "special" : "headless")

    readonly property string typeLabel: {
        var t = (root.workload.type || "").toString();
        if (t === "ANDROID_DEV") return "Android";
        if (t === "WEB_DEV")     return "Web";
        if (t === "SYSTEM_DEV")  return "Dev";
        if (t === "AI_TASK")     return "AI";
        if (t === "SERVICE")     return "Service";
        if (t === "VM")          return "VM";
        if (t === "CASUAL")      return "Casual";
        if (t === "NEUTRAL" || root.workload.observed) return "Observed";
        return "Tracked";
    }
    readonly property color typeColor: {
        var t = (root.workload.type || "").toString();
        if (t === "AI_TASK")     return TitanTheme.accent;
        if (t === "WEB_DEV")     return TitanTheme.info;
        if (t === "ANDROID_DEV") return TitanTheme.success;
        if (t === "SYSTEM_DEV")  return TitanTheme.teal;
        if (t === "VM")          return TitanTheme.teal;
        if (t === "SERVICE")     return TitanTheme.warning;
        return TitanTheme.textMid;
    }
    readonly property color stateColor: {
        var s = (root.workload.state || "").toString();
        if (s === "ACTIVE")               return TitanTheme.success;
        if (s === "BACKGROUND_EXECUTING") return TitanTheme.info;
        if (s === "IDLE")                 return TitanTheme.textMid;
        if (s === "AGING")                return TitanTheme.warning;
        if (s === "RECLAIMABLE")          return TitanTheme.danger;
        return TitanTheme.textMid;
    }

    Rectangle {
        anchors.fill: parent
        radius: TitanTheme.radiusMd
        color: TitanTheme.bgInset
        border.width: 1
        border.color: TitanTheme.borderSubtle
        clip: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.min(76, typeText.implicitWidth + 14)
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
                    font.pixelSize: 10
                    font.weight: TitanTheme.weightSemiBold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 1
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: (root.workload.name || "").toString()
                    color: TitanTheme.textHigh
                    elide: Text.ElideMiddle
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: TitanTheme.sizeLabel
                    font.weight: TitanTheme.weightMedium
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: "PID " + (root.workload.pid || 0)
                          + " · " + root.procCount + (root.procCount === 1 ? " proc" : " procs")
                          + " · " + root.wsText
                    color: TitanTheme.textMid
                    elide: Text.ElideRight
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                Layout.minimumWidth: 48
                spacing: 1
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: (root.workload.memMb || 0) + " MB"
                    color: TitanTheme.textHigh
                    font.family: TitanTheme.monoFamily
                    font.pixelSize: 10
                    font.weight: TitanTheme.weightMedium
                }
                Text {
                    Layout.alignment: Qt.AlignRight
                    text: (root.workload.state || "").toString().replace(/_/g, " ").toLowerCase()
                    color: root.stateColor
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: 10
                    font.weight: TitanTheme.weightMedium
                }
            }
        }
    }
}
