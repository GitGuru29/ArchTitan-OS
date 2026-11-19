#pragma once

#include "ruleengine.h"

#include <chrono>
#include <sys/types.h>
#include <vector>

namespace titan::focus {

enum class NotifyOutcome {
    Dispatched,
    Coalesced,
    SilentSkipped,
    Unavailable
};

/**
 * Notifier — dispatches desktop nudges via `notify-send` using posix_spawn().
 *
 * Modeled directly on titan-hwm-v3/policy/reclaim_engine.cpp:
 * - Explicit argv array: zero shell, zero quoting/injection hazards
 * - Burst coalescing with minimum interval guard
 * - Non-blocking waitpid(WNOHANG) child reaping so zombies never accumulate
 * - Routes cleanly to whichever daemon owns org.freedesktop.Notifications
 *   (titan-shell NotificationServer or SwayNC).
 */
class Notifier {
public:
    explicit Notifier(int minBurstIntervalSec = 5);
    ~Notifier();

    NotifyOutcome dispatch(const NudgeEvent &event);
    void reapChildren();

    void setEnabled(bool enabled) { m_enabled = enabled; }
    bool enabled() const { return m_enabled; }

private:
    bool m_enabled = true;
    int  m_minBurstIntervalSec = 5;
    std::chrono::steady_clock::time_point m_lastDispatch{};
    std::vector<pid_t> m_children;
};

} // namespace titan::focus
