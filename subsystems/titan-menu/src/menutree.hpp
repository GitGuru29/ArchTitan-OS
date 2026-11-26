#pragma once

#include <QJsonObject>
#include <QString>
#include <QVector>

namespace titanmenu {

/**
 * One entry in the menu tree.
 *
 * A node is either
 *   - an *action* (has `exec`), run through `/bin/sh -c`, or
 *   - a *group*  (has `children` and/or a `provider`), which drills down.
 *
 * Providers are `@name` strings resolved at open time (e.g. "@themes"), so the
 * list always reflects what is installed right now. A provider's output is
 * appended after the static `children`.
 */
struct MenuNode {
    QString id;
    QString title;
    QString hint;       // one-line description shown under the title
    QString icon;       // Nerd Font glyph
    QString keys;       // display-only shortcut hint, e.g. "Super+Space"
    QString exec;       // shell command (action nodes)
    QString provider;   // "@themes" etc. (group nodes)
    QString requires_;  // executable that must exist for the node to be shown
    int delayMs = 0;    // wait this long after closing the menu before running

    QVector<MenuNode> children;

    bool isGroup() const { return exec.isEmpty(); }
};

/** Parses the menu document. On failure returns false and fills `error`. */
bool parseMenu(const QByteArray &json, MenuNode *root, QString *error);

/** True when the node's `requires` executable (if any) is on PATH. */
bool isAvailable(const MenuNode &node);

} // namespace titanmenu
