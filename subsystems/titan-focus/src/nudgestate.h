#pragma once

#include <QString>
#include <cstdint>
#include <deque>
#include <unordered_map>

namespace titan::focus {

struct SignalSnapshot {
    int64_t nowSec = 0;           // monotonic clock seconds
    int     localHour = 12;       // wall-clock local hour (0..23)
    int     localMinute = 0;      // wall-clock local minute (0..59)
    QString localDateKey;         // YYYY-MM-DD for daily rollover

    // Session & Focus
    bool    isIdle = false;
    int64_t idleDurationSec = 0;
    bool    ideFocused = false;
    QString activeApp;
    QString activeTitle;
    int     windowSwitchesDelta = 0; // switches observed since last tick

    // Suppression context
    bool    inMeeting = false;
    bool    mediaPlaying = false;

    // Process signals
    bool    buildActive = false;
    QString activeBuildProc;
    bool    agentActive = false;
    QString activeAgentProc;
    bool    gitDirty = false;
    QString gitDirtyRepo;

    // System signals
    double  psiMemAvg10 = 0.0;    // 0..100 %
    double  cpuTempC = 0.0;       // Celsius
    double  memUsedPct = 0.0;     // 0..100 %
};

struct DailyTally {
    QString dateKey;
    int64_t focusSeconds = 0;
    int64_t sessionSeconds = 0;
    int     breaksTaken = 0;
    int     nudgesFired = 0;
    int     nudgesSnoozed = 0;
    int     nudgesDismissed = 0;
};

class NudgeState {
public:
    static QString defaultStatePath();

    bool load(const QString &path = QString());
    bool save(const QString &path = QString()) const;

    void advance(const SignalSnapshot &sig, int64_t dtSec, int64_t idleResetSec, int64_t thrashWindowSec);

    void startBreak(int64_t nowSec, int durationSec);
    void endBreak(int64_t nowSec);
    void snooze(int64_t nowSec, int durationSec);
    void dismissActiveNudge();
    void setDnd(bool enabled);
    void resetSession(int64_t nowSec);

    // State queries
    bool    isOnBreak(int64_t nowSec) const { return m_breakUntilSec > nowSec; }
    int64_t breakRemainingSec(int64_t nowSec) const { return m_breakUntilSec > nowSec ? (m_breakUntilSec - nowSec) : 0; }
    bool    isSnoozed(int64_t nowSec) const { return m_snoozeUntilSec > nowSec; }
    int64_t snoozeRemainingSec(int64_t nowSec) const { return m_snoozeUntilSec > nowSec ? (m_snoozeUntilSec - nowSec) : 0; }
    bool    isDnd() const { return m_dndEnabled; }

    int64_t continuousSessionSec() const { return m_continuousSessionSec; }
    int64_t screenFocusSec() const { return m_screenFocusSec; }
    int64_t ideDwellSec() const { return m_ideDwellSec; }
    int64_t buildActiveSec() const { return m_buildActiveSec; }
    int64_t gitDirtySec() const { return m_gitDirtySec; }
    int     recentWindowSwitches() const { return static_cast<int>(m_switchTimestamps.size()); }
    bool    agentJustFinished() const { return m_agentJustFinished; }
    QString lastAgentName() const { return m_lastAgentName; }
    int     sessionCapStage() const { return m_sessionCapStage; }
    void    setSessionCapStage(int stage) { m_sessionCapStage = stage; }

    // Cooldown & fatigue tracking
    int64_t lastRuleFireSec(const QString &ruleId) const;
    void    recordRuleFire(const QString &ruleId, int64_t nowSec, bool isCritical, bool isSilent);
    int64_t lastNonCriticalNudgeSec() const { return m_lastNonCriticalNudgeSec; }

    bool    dailySummaryFiredToday() const { return m_dailySummaryFired; }
    void    markDailySummaryFired() { m_dailySummaryFired = true; }
    bool    lateNightFiredToday() const { return m_lateNightFired; }
    void    markLateNightFired() { m_lateNightFired = true; }

    void    resetIdeDwell() { m_ideDwellSec = 0; }
    void    resetEyeStrainTimer() { m_eyeStrainElapsedSec = 0; }
    int64_t eyeStrainElapsedSec() const { return m_eyeStrainElapsedSec; }
    void    resetHydrationTimer() { m_hydrationElapsedSec = 0; }
    int64_t hydrationElapsedSec() const { return m_hydrationElapsedSec; }
    void    resetPostureTimer() { m_postureElapsedSec = 0; }
    int64_t postureElapsedSec() const { return m_postureElapsedSec; }

    const DailyTally &tally() const { return m_tally; }
    QString lastNudgeRule() const { return m_lastNudgeRule; }
    QString lastNudgeTitle() const { return m_lastNudgeTitle; }
    QString lastNudgeBody() const { return m_lastNudgeBody; }
    void    setLastNudgeDetails(const QString &ruleId, const QString &title, const QString &body);

private:
    void rolloverIfNewDay(const QString &dateKey);

    DailyTally m_tally;

    int64_t m_continuousSessionSec = 0;
    int64_t m_screenFocusSec       = 0;
    int64_t m_ideDwellSec          = 0;
    int64_t m_hydrationElapsedSec  = 0;
    int64_t m_eyeStrainElapsedSec  = 0;
    int64_t m_postureElapsedSec    = 0;
    int64_t m_buildActiveSec       = 0;
    int64_t m_gitDirtySec          = 0;

    bool    m_prevAgentActive   = false;
    bool    m_agentJustFinished = false;
    QString m_lastAgentName;

    int64_t m_breakUntilSec           = 0;
    int64_t m_snoozeUntilSec          = 0;
    bool    m_dndEnabled              = false;
    int64_t m_lastNonCriticalNudgeSec = -1000000;
    int     m_sessionCapStage         = 0;
    bool    m_dailySummaryFired       = false;
    bool    m_lateNightFired          = false;

    std::deque<int64_t> m_switchTimestamps;
    std::unordered_map<std::string, int64_t> m_ruleLastFire;

    QString m_lastNudgeRule;
    QString m_lastNudgeTitle;
    QString m_lastNudgeBody;
};

} // namespace titan::focus
