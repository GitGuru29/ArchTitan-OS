import QtQuick

import "../style"

/**
 * FocusRing — the accent outline drawn around whichever control currently
 * holds keyboard focus.
 *
 * Declare it as the last child of a focusable rectangle-shaped control; the
 * ring sizes itself to that parent and only becomes visible while the parent
 * has active focus. Centralising it here keeps the look identical across the
 * header buttons, tool tiles, and the power menu cards.
 */
Rectangle {
    anchors.fill: parent
    anchors.margins: 1

    radius: parent.radius !== undefined ? parent.radius : height / 2
    color: "transparent"
    border.color: TitanTheme.accent
    border.width: 2
    visible: parent.activeFocus
}
