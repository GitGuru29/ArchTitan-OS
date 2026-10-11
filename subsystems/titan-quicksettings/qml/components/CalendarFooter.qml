import QtQuick
import QtQuick.Layouts
import "../style"

/**
 * CalendarFooter — collapseable current-month calendar.
 *
 * Collapsed it is a slim "date • tasks" strip; expanded it becomes a real
 * mini-month grid with weekday headings and the current day highlighted.
 * Pure view-layer: month math runs in JavaScript against Date().
 */

Rectangle {
    id: calFooterRoot
    Layout.fillWidth: true
    Layout.preferredHeight: contentHeight
    radius: TitanTheme.radiusCard
    color: TitanTheme.bgSurface
    border.color: TitanTheme.borderSubtle
    border.width: 1

    property bool expanded: false
    property int contentHeight: 40
    Behavior on contentHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    readonly property date today: new Date()
    readonly property int currentMonth: today.getMonth()
    readonly property int currentYear: today.getFullYear()
    readonly property int daysInMonth: new Date(currentYear, currentMonth + 1, 0).getDate()
    // Monday-first offset: getDay() 0=Sun..6=Sat → Mon=0, Sun=6
    readonly property int firstOffset: (new Date(currentYear, currentMonth, 1).getDay() + 6) % 7

    readonly property string taskLine: {
        var base = (typeof systemCtrl !== "undefined" && systemCtrl) ? systemCtrl.currentDateString : "";
        var i = base.indexOf("•");
        return (i >= 0) ? base.substring(i + 1).trim() : "0 tasks";
    }

    function toggle() {
        expanded = !expanded;
        contentHeight = expanded ? 262 : 40;
    }

    function dayNumberFor(col, row) {
        var cell = row * 7 + col;
        var day = cell - firstOffset + 1;
        if (day < 1 || day > daysInMonth) return 0;
        return day;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        anchors.topMargin: 8
        anchors.bottomMargin: 12
        spacing: 8

        // ── Header row (always visible, click to toggle) ─────────────────────
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            spacing: 8

            Text {
                text: "\uf133"   // calendar
                font.family: TitanTheme.fontFamily
                font.pixelSize: 14
                color: TitanTheme.textSubtle
            }

            Text {
                Layout.fillWidth: true
                text: (typeof systemCtrl !== "undefined" && systemCtrl)
                      ? systemCtrl.currentDateString
                      : today.toLocaleDateString(Qt.locale(), "dddd, MMMM d") + " • 0 tasks"
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeSmall
                font.weight: Font.DemiBold
                color: TitanTheme.textSecondary
                elide: Text.ElideRight
            }

            Text {
                text: expanded ? "\uf0d7" : "\uf0d8"   // square-caret down / up
                font.family: TitanTheme.fontFamily
                font.pixelSize: 12
                color: TitanTheme.textSubtle
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: calFooterRoot.toggle()
            }
        }

        // ── Mini calendar (expanded) ─────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: calFooterRoot.expanded

            // Month title
            Text {
                text: today.toLocaleDateString(Qt.locale(), "MMMM yyyy").toUpperCase()
                Layout.alignment: Qt.AlignHCenter
                font.family: TitanTheme.fontFamily
                font.pixelSize: TitanTheme.sizeCaption
                font.weight: Font.Bold
                font.letterSpacing: 1.4
                color: TitanTheme.textMuted
            }

            // Weekday headings
            RowLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 16
                        text: modelData
                        font.family: TitanTheme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                        color: TitanTheme.textSubtle
                    }
                }
            }

            // Day grid: 6 weeks x 7 columns
            Repeater {
                model: 6
                delegate: RowLayout {
                    id: weekRow
                    property int rowIndex: index
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        model: 7
                            delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 24
                                property int dayNumber: calFooterRoot.dayNumberFor(index, weekRow.rowIndex)
                                property bool isToday: dayNumber > 0
                                                       && dayNumber === calFooterRoot.today.getDate()
                                                       && calFooterRoot.currentMonth === calFooterRoot.today.getMonth()
                                property bool weekend: index >= 5

                                radius: 8
                                color: {
                                    if (isToday) return TitanTheme.accent;
                                    if (ma.containsMouse && dayNumber > 0) return TitanTheme.bgHover;
                                    return "transparent";
                                }

                                Behavior on color { ColorAnimation { duration: 110 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: dayNumber > 0 ? dayNumber : ""
                                    font.family: TitanTheme.fontFamily
                                    font.pixelSize: TitanTheme.sizeSmall
                                    font.weight: isToday ? Font.Bold : Font.Normal
                                    color: isToday ? TitanTheme.accentText
                                                   : (weekend ? TitanTheme.textSubtle : TitanTheme.textSecondary)
                                }

                                MouseArea {
                                    id: ma
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                }
                        }
                    }
                }
            }

            // Task summary row
            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                Rectangle { width: 3; height: 12; radius: 1.5; color: TitanTheme.accent; Layout.preferredHeight: 12 }
                Text {
                    text: calFooterRoot.taskLine
                    font.family: TitanTheme.fontFamily
                    font.pixelSize: TitanTheme.sizeSmall
                    color: TitanTheme.textMuted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }
        }
    }
}