#include "notifier.h"

#include <spawn.h>
#include <string>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

namespace titan::focus {

Notifier::Notifier(int minBurstIntervalSec)
    : m_minBurstIntervalSec(minBurstIntervalSec) {}

Notifier::~Notifier() {
    reapChildren();
}

void Notifier::reapChildren() {
    for (size_t i = 0; i < m_children.size(); ) {
        const pid_t child = m_children[i];
        if (::waitpid(child, nullptr, WNOHANG) == child) {
            m_children.erase(m_children.begin() + static_cast<long>(i));
        } else {
            ++i;
        }
    }
}

NotifyOutcome Notifier::dispatch(const NudgeEvent &event) {
    reapChildren();

    if (event.urgency == Urgency::Silent) {
        return NotifyOutcome::SilentSkipped;
    }
    if (!m_enabled) {
        return NotifyOutcome::Unavailable;
    }

    const auto now = std::chrono::steady_clock::now();
    if (event.urgency != Urgency::Critical && m_lastDispatch.time_since_epoch().count() != 0) {
        if ((now - m_lastDispatch) < std::chrono::seconds(m_minBurstIntervalSec)) {
            return NotifyOutcome::Coalesced;
        }
    }
    m_lastDispatch = now;

    static const char *kNotifyBins[] = {
        "/usr/bin/notify-send", "/bin/notify-send", "/usr/local/bin/notify-send"
    };
    const char *notifyBin = nullptr;
    for (const char *candidate : kNotifyBins) {
        if (::access(candidate, X_OK) == 0) {
            notifyBin = candidate;
            break;
        }
    }
    if (!notifyBin) {
        return NotifyOutcome::Unavailable;
    }

    const std::string urgencyStr = (event.urgency == Urgency::Critical) ? "critical" : "normal";
    const std::string timeoutStr = (event.urgency == Urgency::Critical) ? "0" : "5000";
    const std::string appName    = "TitanFocus";
    const std::string iconName   = "preferences-system-time";
    const std::string summary    = event.title.toStdString();
    const std::string body       = event.body.toStdString();

    char *argv[] = {
        const_cast<char *>("notify-send"),
        const_cast<char *>("-a"),
        const_cast<char *>(appName.c_str()),
        const_cast<char *>("-i"),
        const_cast<char *>(iconName.c_str()),
        const_cast<char *>("-u"),
        const_cast<char *>(urgencyStr.c_str()),
        const_cast<char *>("-t"),
        const_cast<char *>(timeoutStr.c_str()),
        const_cast<char *>(summary.c_str()),
        const_cast<char *>(body.c_str()),
        nullptr
    };

    pid_t child = 0;
    if (::posix_spawn(&child, notifyBin, nullptr, nullptr, argv, environ) != 0) {
        return NotifyOutcome::Unavailable;
    }

    m_children.push_back(child);
    return NotifyOutcome::Dispatched;
}

} // namespace titan::focus
