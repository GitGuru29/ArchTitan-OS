#pragma once

#include "configloader.h"
#include "nudgestate.h"

#include <QString>
#include <cstdint>
#include <vector>

namespace titan::focus {

enum class Urgency {
    Silent,   // Overlay & log only; never spawns desktop toast
    Normal,   // Auto-dismiss (5 s), subject to global 20-min fatigue floor
    Critical  // Persistent, requires acknowledgement; bypasses non-critical floor
};

struct NudgeEvent {
    QString ruleId;
    QString category;
    Urgency urgency = Urgency::Normal;
    QString title;
    QString body;
    int     suggestedBreakSec = 0;
};

class RuleEngine {
public:
    std::vector<NudgeEvent> evaluate(const FocusConfig &cfg,
                                     const SignalSnapshot &sig,
                                     NudgeState &state) const;

    // Estimate seconds until next scheduled focus/health milestone (for overlay ETA).
    int64_t nextNudgeEtaSec(const FocusConfig &cfg,
                            const SignalSnapshot &sig,
                            const NudgeState &state) const;
};

} // namespace titan::focus
