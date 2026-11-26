#include "nudgestate.h"

#include <QDate>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace titan::focus {

QString NudgeState::defaultStatePath() {
    const QString home = QDir::homePath();
    return home + QStringLiteral("/.local/state/titan-focus/daily.json");
}

bool NudgeState::load(const QString &path) {
    const QString target = path.isEmpty() ? defaultStatePath() : path;
    QFile f(target);
    if (!f.open(QIODevice::ReadOnly)) return false;

    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return false;

    const QJsonObject obj = doc.object();
    const QString today = QDate::currentDate().toString(Qt::ISODate);
    if (obj.value(QStringLiteral("date")).toString() != today) {
        m_tally = DailyTally{};
        m_tally.dateKey = today;
        return true;
    }

    m_tally.dateKey         = today;
    m_tally.focusSeconds    = obj.value(QStringLiteral("focus_seconds")).toInteger(0);
    m_tally.sessionSeconds  = obj.value(QStringLiteral("session_seconds")).toInteger(0);
    m_tally.breaksTaken     = obj.value(QStringLiteral("breaks_taken")).toInt(0);
    m_tally.nudgesFired     = obj.value(QStringLiteral("nudges_fired")).toInt(0);
    m_tally.nudgesSnoozed   = obj.value(QStringLiteral("nudges_snoozed")).toInt(0);
    m_tally.nudgesDismissed = obj.value(QStringLiteral("nudges_dismissed")).toInt(0);
    m_dailySummaryFired     = obj.value(QStringLiteral("daily_summary_fired")).toBool(false);
    m_lateNightFired        = obj.value(QStringLiteral("late_night_fired")).toBool(false);
    return true;
}

bool NudgeState::save(const QString &path) const {
    const QString target = path.isEmpty() ? defaultStatePath() : path;
    QDir().mkpath(QFileInfo(target).absolutePath());

    QJsonObject obj;
    obj.insert(QStringLiteral("date"), m_tally.dateKey.isEmpty()
                                           ? QDate::currentDate().toString(Qt::ISODate)
                                           : m_tally.dateKey);
    obj.insert(QStringLiteral("focus_seconds"), static_cast<qint64>(m_tally.focusSeconds));
    obj.insert(QStringLiteral("session_seconds"), static_cast<qint64>(m_tally.sessionSeconds));
    obj.insert(QStringLiteral("breaks_taken"), m_tally.breaksTaken);
    obj.insert(QStringLiteral("nudges_fired"), m_tally.nudgesFired);
    obj.insert(QStringLiteral("nudges_snoozed"), m_tally.nudgesSnoozed);
    obj.insert(QStringLiteral("nudges_dismissed"), m_tally.nudgesDismissed);
    obj.insert(QStringLiteral("daily_summary_fired"), m_dailySummaryFired);
    obj.insert(QStringLiteral("late_night_fired"), m_lateNightFired);

    const QString tmp = target + QStringLiteral(".tmp");
    QFile f(tmp);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Truncate)) return false;
    f.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
    f.close();
    QFile::remove(target);
    return QFile::rename(tmp, target);
}

void NudgeState::rolloverIfNewDay(const QString &dateKey) {
    if (dateKey.isEmpty()) return;
    if (m_tally.dateKey.isEmpty()) {
        m_tally.dateKey = dateKey;
        return;
    }
    if (m_tally.dateKey != dateKey) {
        m_tally = DailyTally{};
        m_tally.dateKey = dateKey;
        m_dailySummaryFired = false;
        m_lateNightFired = false;
    }
}

void NudgeState::advance(const SignalSnapshot &sig, int64_t dtSec, int64_t idleResetSec, int64_t thrashWindowSec) {
    if (dtSec < 0) dtSec = 0;
    rolloverIfNewDay(sig.localDateKey);

    // Track agent completion edge: active -> inactive
    m_agentJustFinished = false;
    if (sig.agentActive) {
        m_prevAgentActive = true;
        if (!sig.activeAgentProc.isEmpty()) m_lastAgentName = sig.activeAgentProc;
    } else if (m_prevAgentActive) {
        m_prevAgentActive = false;
        m_agentJustFinished = true;
    }

    // Track build persistence
    if (sig.buildActive) {
        m_buildActiveSec += dtSec;
    } else {
        m_buildActiveSec = 0;
    }

    // Track git-dirty persistence
    if (sig.gitDirty) {
        m_gitDirtySec += dtSec;
    } else {
        m_gitDirtySec = 0;
    }

    // Track sliding window of window switches
    for (int i = 0; i < sig.windowSwitchesDelta; ++i) {
        m_switchTimestamps.push_back(sig.nowSec);
    }
    while (!m_switchTimestamps.empty() && (sig.nowSec - m_switchTimestamps.front()) > thrashWindowSec) {
        m_switchTimestamps.pop_front();
    }

    // If on scheduled break or idle beyond reset threshold, reset continuous timers
    if (isOnBreak(sig.nowSec) || (sig.isIdle && sig.idleDurationSec >= idleResetSec)) {
        m_continuousSessionSec = 0;
        m_screenFocusSec = 0;
        m_ideDwellSec = 0;
        m_eyeStrainElapsedSec = 0;
        m_postureElapsedSec = 0;
        m_sessionCapStage = 0;
        return;
    }

    // Active engagement
    if (!sig.isIdle) {
        m_continuousSessionSec += dtSec;
        m_screenFocusSec += dtSec;
        m_hydrationElapsedSec += dtSec;
        m_eyeStrainElapsedSec += dtSec;
        m_postureElapsedSec += dtSec;
        m_tally.sessionSeconds += dtSec;

        if (sig.ideFocused) {
            m_ideDwellSec += dtSec;
            m_tally.focusSeconds += dtSec;
        } else {
            // Focus block requires continuity: switching away from IDE resets dwell timer.
            m_ideDwellSec = 0;
        }
    }
}

void NudgeState::startBreak(int64_t nowSec, int durationSec) {
    if (durationSec <= 0) durationSec = 600;
    m_breakUntilSec = nowSec + durationSec;
    m_continuousSessionSec = 0;
    m_screenFocusSec = 0;
    m_ideDwellSec = 0;
    m_eyeStrainElapsedSec = 0;
    m_postureElapsedSec = 0;
    m_sessionCapStage = 0;
    m_tally.breaksTaken++;
}

void NudgeState::endBreak(int64_t nowSec) {
    Q_UNUSED(nowSec);
    m_breakUntilSec = 0;
}

void NudgeState::snooze(int64_t nowSec, int durationSec) {
    if (durationSec <= 0) durationSec = 900;
    m_snoozeUntilSec = nowSec + durationSec;
    m_tally.nudgesSnoozed++;
}

void NudgeState::dismissActiveNudge() {
    m_tally.nudgesDismissed++;
    m_lastNudgeRule.clear();
    m_lastNudgeTitle.clear();
    m_lastNudgeBody.clear();
}

void NudgeState::setDnd(bool enabled) {
    m_dndEnabled = enabled;
}

void NudgeState::resetSession(int64_t nowSec) {
    Q_UNUSED(nowSec);
    m_continuousSessionSec = 0;
    m_screenFocusSec = 0;
    m_ideDwellSec = 0;
    m_hydrationElapsedSec = 0;
    m_eyeStrainElapsedSec = 0;
    m_postureElapsedSec = 0;
    m_buildActiveSec = 0;
    m_gitDirtySec = 0;
    m_sessionCapStage = 0;
    m_breakUntilSec = 0;
    m_snoozeUntilSec = 0;
    m_switchTimestamps.clear();
    m_ruleLastFire.clear();
    m_lastNonCriticalNudgeSec = -1000000;
}

int64_t NudgeState::lastRuleFireSec(const QString &ruleId) const {
    const auto it = m_ruleLastFire.find(ruleId.toStdString());
    return (it == m_ruleLastFire.end()) ? -1000000 : it->second;
}

void NudgeState::recordRuleFire(const QString &ruleId, int64_t nowSec, bool isCritical, bool isSilent) {
    m_ruleLastFire[ruleId.toStdString()] = nowSec;
    if (!isSilent) {
        m_tally.nudgesFired++;
        if (!isCritical) {
            m_lastNonCriticalNudgeSec = nowSec;
        }
    }
}

void NudgeState::setLastNudgeDetails(const QString &ruleId, const QString &title, const QString &body) {
    m_lastNudgeRule = ruleId;
    m_lastNudgeTitle = title;
    m_lastNudgeBody = body;
}

} // namespace titan::focus
