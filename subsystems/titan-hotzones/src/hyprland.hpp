// titan-hotzones — minimal Hyprland IPC client
//
// Hyprland exposes no pointer-move events, so the daemon polls. Polling via the
// UNIX command socket (rather than spawning `hyprctl` each tick) keeps the idle
// cost within budget. The command socket accepts exactly one request per
// connection and then closes, so each call opens a short-lived socket — this is
// still far cheaper than forking a process per poll.
#pragma once

#include <QPoint>
#include <QString>
#include <vector>

#include "zones.hpp"

namespace titan {

// Absolute path to Hyprland's command socket, or an empty string when
// $HYPRLAND_INSTANCE_SIGNATURE / $XDG_RUNTIME_DIR are not set.
QString hyprCommandSocketPath();

// Send one command to Hyprland and return the reply (trimmed). Returns an
// empty string on any failure.
QString hyprSend(const QString& command, int timeoutMs = 250);

// "x, y" as global cursor coordinates. Returns QPoint(INT_MIN, INT_MIN) on
// failure so callers can distinguish "unknown" from a real (0,0).
QPoint hyprCursorPos();

// All active monitors with their global position and size.
std::vector<Monitor> hyprMonitors();

struct ActiveWindow {
    bool valid = false;
    QString windowClass;
    int fullscreen = 0; // 0 = none, otherwise fullscreen mode bits
};

ActiveWindow hyprActiveWindow();

} // namespace titan
