// titan-hotzones — zone geometry and the activation state machine
#include "zones.hpp"

#include <algorithm>
#include <cmath>
#include <limits>

namespace titan {
namespace {

struct Rect {
    int x = 0;
    int y = 0;
    int w = 0;
    int h = 0;
};

Rect zoneRect(const Monitor& m, ZoneId id, int corner, int edgeLen, int edgeThk) {
    const int midY = m.y + m.h / 2 - edgeLen / 2;
    const int midX = m.x + m.w / 2 - edgeLen / 2;
    switch (id) {
        case ZoneId::TopLeft:      return {m.x,                 m.y,                 corner, corner};
        case ZoneId::TopRight:     return {m.x + m.w - corner,  m.y,                 corner, corner};
        case ZoneId::BottomLeft:   return {m.x,                 m.y + m.h - corner,  corner, corner};
        case ZoneId::BottomRight:  return {m.x + m.w - corner,  m.y + m.h - corner,  corner, corner};
        case ZoneId::LeftCenter:   return {m.x,                 midY,                edgeThk, edgeLen};
        case ZoneId::RightCenter:  return {m.x + m.w - edgeThk, midY,                edgeThk, edgeLen};
        case ZoneId::BottomCenter: return {midX,                m.y + m.h - edgeThk, edgeLen, edgeThk};
        case ZoneId::None:
        default:                   return {};
    }
}

bool contains(const Rect& r, const QPoint& p) {
    return p.x() >= r.x && p.x() < r.x + r.w &&
           p.y() >= r.y && p.y() < r.y + r.h;
}

// Euclidean distance from a point to the nearest edge of a rectangle.
double distanceToRect(const Rect& r, const QPoint& p) {
    const int dx = std::max({r.x - p.x(), 0, p.x() - (r.x + r.w - 1)});
    const int dy = std::max({r.y - p.y(), 0, p.y() - (r.y + r.h - 1)});
    return std::hypot(static_cast<double>(dx), static_cast<double>(dy));
}

constexpr ZoneId kOrder[kZoneCount] = {
    ZoneId::TopLeft, ZoneId::TopRight, ZoneId::BottomLeft, ZoneId::BottomRight,
    ZoneId::LeftCenter, ZoneId::RightCenter, ZoneId::BottomCenter,
};

} // namespace

int ZoneGeometry::monitorIndexAt(const QPoint& pos) const {
    for (int i = 0; i < static_cast<int>(monitors_.size()); ++i) {
        const Monitor& m = monitors_[i];
        if (pos.x() >= m.x && pos.x() < m.x + m.w &&
            pos.y() >= m.y && pos.y() < m.y + m.h)
            return i;
    }
    return -1;
}

ZoneHit ZoneGeometry::hitTest(const QPoint& pos) const {
    // Prefer the monitor the pointer is actually on, so an offset layout with a
    // touching neighbour cannot steal a corner.
    const int preferred = monitorIndexAt(pos);
    if (preferred >= 0) {
        const Monitor& m = monitors_[preferred];
        for (const ZoneId id : kOrder) {
            if (contains(zoneRect(m, id, corner_, edgeLength_, edgeThickness_), pos))
                return {id, preferred};
        }
    }
    for (int i = 0; i < static_cast<int>(monitors_.size()); ++i) {
        if (i == preferred) continue;
        const Monitor& m = monitors_[i];
        for (const ZoneId id : kOrder) {
            if (contains(zoneRect(m, id, corner_, edgeLength_, edgeThickness_), pos))
                return {id, i};
        }
    }
    return {};
}

int ZoneGeometry::proximity(const QPoint& pos) const {
    if (monitors_.empty()) return std::numeric_limits<int>::max();
    double best = std::numeric_limits<double>::max();
    for (const Monitor& m : monitors_) {
        for (const ZoneId id : kOrder) {
            best = std::min(best, distanceToRect(
                zoneRect(m, id, corner_, edgeLength_, edgeThickness_), pos));
        }
    }
    return static_cast<int>(std::lround(best));
}

bool ZoneGeometry::inInnerRegion(const QPoint& pos) const {
    const int i = monitorIndexAt(pos);
    if (i < 0) return false;
    const Monitor& m = monitors_[i];
    const int dist = std::min({pos.x() - m.x,
                               m.x + m.w - 1 - pos.x(),
                               pos.y() - m.y,
                               m.y + m.h - 1 - pos.y()});
    return dist >= exclusionBox_;
}

bool ZoneStateMachine::update(const ZoneHit& hit, bool inInner, qint64 nowMs) {
    if (state_ == ZoneState::Locked) {
        if (inInner && nowMs - lockedAt_ >= cooldownMs_)
            state_ = ZoneState::Idle;
        return false;
    }

    if (hit.id == ZoneId::None) {
        state_ = ZoneState::Idle;
        return false;
    }

    if (state_ == ZoneState::Idle) {
        state_ = ZoneState::Armed;
        armed_ = hit;
        armedAt_ = nowMs;
        return false;
    }

    // Armed.
    if (!(hit == armed_)) {
        // Moved to a different zone before dwelling: restart the dwell there.
        armed_ = hit;
        armedAt_ = nowMs;
        return false;
    }

    if (nowMs - armedAt_ >= dwellMs_) {
        state_ = ZoneState::Locked;
        lockedAt_ = nowMs;
        return true;
    }
    return false;
}

double ZoneStateMachine::dwellProgress(qint64 nowMs) const {
    if (state_ != ZoneState::Armed || dwellMs_ <= 0) return 0.0;
    const double p = static_cast<double>(nowMs - armedAt_) / dwellMs_;
    return std::clamp(p, 0.0, 1.0);
}

} // namespace titan
