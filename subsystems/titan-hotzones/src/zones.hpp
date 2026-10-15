// titan-hotzones — zone geometry and the activation state machine
#pragma once

#include <QPoint>
#include <QString>
#include <vector>

#include "config.hpp"

namespace titan {

struct Monitor {
    QString name;
    int x = 0;
    int y = 0;
    int w = 0;
    int h = 0;
};

struct ZoneHit {
    ZoneId id = ZoneId::None;
    int monitorIndex = -1;

    bool operator==(const ZoneHit& o) const {
        return id == o.id && monitorIndex == o.monitorIndex;
    }
};

// Geometry-only: given the cursor position and the monitor layout, which zone
// (if any) is under the pointer, how close the pointer is to the nearest zone,
// and whether it has returned to the inner screen.
class ZoneGeometry {
public:
    void setMonitors(std::vector<Monitor> monitors) { monitors_ = std::move(monitors); }
    const std::vector<Monitor>& monitors() const { return monitors_; }

    void setGeometry(int cornerSize, int edgeLength, int edgeThickness, int exclusionBox) {
        corner_ = cornerSize;
        edgeLength_ = edgeLength;
        edgeThickness_ = edgeThickness;
        exclusionBox_ = exclusionBox;
    }

    ZoneHit hitTest(const QPoint& pos) const;
    // Distance in px from `pos` to the nearest zone rectangle (0 when inside).
    // Returns a large sentinel when there are no monitors.
    int proximity(const QPoint& pos) const;
    // True when `pos` lies inside a monitor and at least `exclusionBox_` px
    // from every edge of that monitor (the "paper trail" inner region).
    bool inInnerRegion(const QPoint& pos) const;

private:
    int monitorIndexAt(const QPoint& pos) const;

    std::vector<Monitor> monitors_;
    int corner_ = 4;
    int edgeLength_ = 140;
    int edgeThickness_ = 4;
    int exclusionBox_ = 64;
};

// The activation state machine from the plan:
//
//   IDLE --pointer enters zone--> ARMED --dwell elapsed--> FIRE --\
//     ^                                                            |
//     |  pointer leaves exclusion box (then cooldown)               |
//     \------------------------------------------------------------/
//
enum class ZoneState { Idle, Armed, Locked };

class ZoneStateMachine {
public:
    ZoneStateMachine() = default;
    void configure(int dwellMs, int cooldownMs) {
        dwellMs_ = dwellMs;
        cooldownMs_ = cooldownMs;
    }

    // Feed one sample. Returns true on the single tick where the armed zone's
    // dwell has elapsed and the action should be invoked.
    bool update(const ZoneHit& hit, bool inInner, qint64 nowMs);

    ZoneState state() const { return state_; }
    ZoneId armedZone() const { return armed_.id; }
    // Fraction [0,1] of the dwell completed for the armed zone, for OSDs.
    double dwellProgress(qint64 nowMs) const;

private:
    ZoneState state_ = ZoneState::Idle;
    ZoneHit armed_{};
    qint64 armedAt_ = 0;
    qint64 lockedAt_ = 0;
    int dwellMs_ = 180;
    int cooldownMs_ = 500;
};

} // namespace titan
