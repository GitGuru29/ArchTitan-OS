import QtQuick
import ArchTitan.TitanUI

/* TitanDivider — hairline separator. */
Rectangle {
    property bool vertical: false
    implicitWidth: vertical ? 1 : 100
    implicitHeight: vertical ? 100 : 1
    color: TitanTheme.borderSubtle
}
