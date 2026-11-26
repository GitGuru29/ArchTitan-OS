#include "ruleengine.h"

#include <algorithm>
#include <limits>

namespace titan::focus {

namespace {

bool cooldownElapsed(const NudgeState &state, const QString &ruleId, int64_t nowSec, int64_t cooldownSec) {
    return (nowSec - state.lastRuleFireSec(ruleId)) >= cooldownSec;
}

bool fatigueFloorElapsed(const NudgeState &state, int64_t nowSec, int64_t minGapSec) {
    return (nowSec - state.lastNonCriticalNudgeSec()) >= minGapSec;
}

} // namespace

std::vector<NudgeEvent> RuleEngine::evaluate(const FocusConfig &cfg,
                                             const SignalSnapshot &sig,
                                             NudgeState &state) const {
    std::vector<NudgeEvent> out;
    const int64_t now = sig.nowSec;

    // During a scheduled break, do not fire any nudges.
    if (state.isOnBreak(now)) {
        return out;
    }

    const bool suppressedByUser    = state.isDnd() || state.isSnoozed(now);
    const bool suppressedByContext = sig.inMeeting || sig.mediaPlaying;
    const bool suppressNonCritical = suppressedByUser || suppressedByContext || sig.isIdle;

    auto tryEmit = [&](const NudgeEvent &ev, int64_t cooldownSec, bool bypassContextSuppress = false) -> bool {
        if (!cooldownElapsed(state, ev.ruleId, now, cooldownSec)) {
            return false;
        }
        if (ev.urgency == Urgency::Silent) {
            state.recordRuleFire(ev.ruleId, now, false, true);
            state.setLastNudgeDetails(ev.ruleId, ev.title, ev.body);
            out.push_back(ev);
            return true;
        }
        if (ev.urgency == Urgency::Critical) {
            // Critical advisories still respect explicit user DND/snooze? Only snooze; thermal/180m cap warn if not snoozed.
            if (state.isSnoozed(now)) return false;
            state.recordRuleFire(ev.ruleId, now, true, false);
            state.setLastNudgeDetails(ev.ruleId, ev.title, ev.body);
            out.push_back(ev);
            return true;
        }
        // Normal urgency: enforce global fatigue floor + suppression gates
        if (suppressedByUser || sig.isIdle) return false;
        if (!bypassContextSuppress && suppressedByContext) return false;
        if (!fatigueFloorElapsed(state, now, cfg.minNudgeGapSec)) return false;

        state.recordRuleFire(ev.ruleId, now, false, false);
        state.setLastNudgeDetails(ev.ruleId, ev.title, ev.body);
        out.push_back(ev);
        return true;
    };

    // ── 1. thermal_pressure (system, critical advisory — never throttles) ───
    if (cfg.catSystem && cfg.ruleThermalPressure) {
        const bool hotCpu = sig.cpuTempC >= cfg.thermalCpuC && sig.cpuTempC > 0.0;
        const bool highMemPsi = sig.psiMemAvg10 >= cfg.pressureMemPct;
        if (hotCpu || highMemPsi) {
            QString detail;
            if (hotCpu && highMemPsi) {
                detail = QStringLiteral("CPU at %1°C and memory pressure at %2%. Consider pausing heavy jobs.")
                             .arg(qRound(sig.cpuTempC))
                             .arg(qRound(sig.psiMemAvg10));
            } else if (hotCpu) {
                detail = QStringLiteral("CPU temperature reached %1°C. Advisory only — titan-hwm manages limits.")
                             .arg(qRound(sig.cpuTempC));
            } else {
                detail = QStringLiteral("Memory PSI reached %1%. Consider closing unused tabs or builds.")
                             .arg(qRound(sig.psiMemAvg10));
            }
            tryEmit(NudgeEvent{
                QStringLiteral("thermal_pressure"),
                QStringLiteral("system"),
                Urgency::Critical,
                QStringLiteral("System Thermal / Memory Advisory"),
                detail,
                0
            }, 600);
        }
    }

    // ── 2. session_cap (focus, escalating 90 / 120 / 180 min) ───────────────
    if (cfg.catFocus && cfg.ruleSessionCap && !sig.isIdle) {
        const int64_t sess = state.continuousSessionSec();
        if (sess >= cfg.sessionCap3Sec && state.sessionCapStage() < 3) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("session_cap"),
                    QStringLiteral("focus"),
                    Urgency::Critical,
                    QStringLiteral("3-Hour Continuous Session"),
                    QStringLiteral("You have worked continuously for %1 min. Take a real 10–15 min break.")
                        .arg(sess / 60),
                    cfg.breakDurationMin * 60
                }, 1800)) {
                state.setSessionCapStage(3);
            }
        } else if (sess >= cfg.sessionCap2Sec && state.sessionCapStage() < 2) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("session_cap"),
                    QStringLiteral("focus"),
                    Urgency::Normal,
                    QStringLiteral("2-Hour Work Milestone"),
                    QStringLiteral("120 minutes without a full break. Step away briefly to keep sharpness high."),
                    cfg.breakDurationMin * 60
                }, 1200)) {
                state.setSessionCapStage(2);
            }
        } else if (sess >= cfg.sessionCap1Sec && state.sessionCapStage() < 1) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("session_cap"),
                    QStringLiteral("focus"),
                    Urgency::Normal,
                    QStringLiteral("90-Minute Ultradian Cycle"),
                    QStringLiteral("Great deep work block. A short stretch now resets focus for the next cycle."),
                    cfg.breakDurationMin * 60
                }, 1200)) {
                state.setSessionCapStage(1);
            }
        }
    }

    // ── 3. focus_block (focus, 50/10 Pomodoro in known IDEs) ────────────────
    if (cfg.catFocus && cfg.ruleFocusBlock && !suppressNonCritical) {
        if (sig.ideFocused && state.ideDwellSec() >= cfg.focusBlockSec) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("focus_block"),
                    QStringLiteral("focus"),
                    Urgency::Normal,
                    QStringLiteral("Focus Block Complete (%1 min)").arg(cfg.focusBlockSec / 60),
                    QStringLiteral("Solid continuous coding in %1. Take a %2-minute break to recharge.")
                        .arg(sig.activeApp.isEmpty() ? QStringLiteral("your IDE") : sig.activeApp)
                        .arg(cfg.breakDurationMin),
                    cfg.breakDurationMin * 60
                }, 600)) {
                state.resetIdeDwell();
            }
        }
    }

    // ── 4. long_build (workflow, build daemon > 3 min) ──────────────────────
    if (cfg.catWorkflow && cfg.ruleLongBuild && !suppressNonCritical) {
        if (sig.buildActive && state.buildActiveSec() >= cfg.longBuildSec) {
            tryEmit(NudgeEvent{
                QStringLiteral("long_build"),
                QStringLiteral("workflow"),
                Urgency::Normal,
                QStringLiteral("Long Build Running (%1)").arg(
                    sig.activeBuildProc.isEmpty() ? QStringLiteral("build") : sig.activeBuildProc),
                QStringLiteral("Build has been active for %1 min — good moment to rest your eyes or grab water.")
                    .arg(state.buildActiveSec() / 60),
                120
            }, 900);
        }
    }

    // ── 5. agent_done (workflow, opt-in) ────────────────────────────────────
    if (cfg.catWorkflow && cfg.ruleAgentDone && !suppressNonCritical) {
        if (state.agentJustFinished()) {
            tryEmit(NudgeEvent{
                QStringLiteral("agent_done"),
                QStringLiteral("workflow"),
                Urgency::Normal,
                QStringLiteral("AI Agent Completed (%1)").arg(
                    state.lastAgentName().isEmpty() ? QStringLiteral("agent") : state.lastAgentName()),
                QStringLiteral("The background agent process exited. Ready to review the diff."),
                0
            }, 300);
        }
    }

    // ── 6. uncommitted (workflow, opt-in) ───────────────────────────────────
    if (cfg.catWorkflow && cfg.ruleUncommitted && !suppressNonCritical) {
        if (sig.gitDirty && state.gitDirtySec() >= cfg.uncommittedSec) {
            tryEmit(NudgeEvent{
                QStringLiteral("uncommitted"),
                QStringLiteral("workflow"),
                Urgency::Normal,
                QStringLiteral("Uncommitted Changes (%1 min)").arg(state.gitDirtySec() / 60),
                QStringLiteral("Working tree%1 has had uncommitted changes for over %2 min. Consider checkpointing.")
                    .arg(sig.gitDirtyRepo.isEmpty() ? QString() : (QStringLiteral(" in ") + sig.gitDirtyRepo))
                    .arg(cfg.uncommittedSec / 60),
                0
            }, 1800);
        }
    }

    // ── 7. context_thrash (focus, > N window switches in M sec) ─────────────
    if (cfg.catFocus && cfg.ruleContextThrash && !suppressNonCritical) {
        if (state.recentWindowSwitches() >= cfg.contextThrashSwitches) {
            tryEmit(NudgeEvent{
                QStringLiteral("context_thrash"),
                QStringLiteral("focus"),
                Urgency::Normal,
                QStringLiteral("High Context Switching Detected"),
                QStringLiteral("%1 window switches in the last %2s. Pick one task for the next 15 minutes.")
                    .arg(state.recentWindowSwitches())
                    .arg(cfg.contextThrashWindowSec),
                0
            }, 1200);
        }
    }

    // ── 8. hydration (health, suppressed during media playback) ─────────────
    if (cfg.catHealth && cfg.ruleHydration && !suppressNonCritical) {
        if (state.hydrationElapsedSec() >= cfg.hydrationIntervalSec) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("hydration"),
                    QStringLiteral("health"),
                    Urgency::Normal,
                    QStringLiteral("Hydration Check"),
                    QStringLiteral("Take a quick sip of water to keep focus steady."),
                    0
                }, cfg.hydrationIntervalSec)) {
                state.resetHydrationTimer();
            }
        }
    }

    // ── 9. eye_strain (health, 20-20-20 cadence) ────────────────────────────
    if (cfg.catHealth && cfg.ruleEyeStrain && !suppressNonCritical) {
        if (state.eyeStrainElapsedSec() >= cfg.eyeStrainIntervalSec) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("eye_strain"),
                    QStringLiteral("health"),
                    Urgency::Normal,
                    QStringLiteral("20-20-20 Eye Break"),
                    QStringLiteral("Look at something 20 feet away for 20 seconds to relax eye strain."),
                    20
                }, cfg.eyeStrainIntervalSec)) {
                state.resetEyeStrainTimer();
            }
        }
    }

    // ── 10. posture (health, lowest priority tier) ──────────────────────────
    if (cfg.catHealth && cfg.rulePosture && !suppressNonCritical) {
        if (state.postureElapsedSec() >= cfg.postureIntervalSec) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("posture"),
                    QStringLiteral("health"),
                    Urgency::Normal,
                    QStringLiteral("Posture Reset"),
                    QStringLiteral("Drop your shoulders, unclench your jaw, and straighten your back."),
                    0
                }, cfg.postureIntervalSec)) {
                state.resetPostureTimer();
            }
        }
    }

    // ── 11. late_night (health, silent tier by default) ─────────────────────
    if (cfg.catHealth && cfg.ruleLateNight && !state.lateNightFiredToday()) {
        const int curMinOfDay = sig.localHour * 60 + sig.localMinute;
        const int cutMinOfDay = cfg.lateNightHour * 60 + cfg.lateNightMinute;
        if (curMinOfDay >= cutMinOfDay) {
            if (tryEmit(NudgeEvent{
                    QStringLiteral("late_night"),
                    QStringLiteral("health"),
                    Urgency::Silent,
                    QStringLiteral("Late Night Wind-Down"),
                    QStringLiteral("It is past %1:%2 — consider wrapping up and saving your work.")
                        .arg(cfg.lateNightHour, 2, 10, QLatin1Char('0'))
                        .arg(cfg.lateNightMinute, 2, 10, QLatin1Char('0')),
                    0
                }, 43200)) {
                state.markLateNightFired();
            }
        }
    }

    // ── 12. daily_summary (summary, once per day at configured hour) ────────
    if (cfg.catSummary && cfg.ruleDailySummary && !state.dailySummaryFiredToday()) {
        const int curMinOfDay = sig.localHour * 60 + sig.localMinute;
        const int sumMinOfDay = cfg.dailySummaryHour * 60 + cfg.dailySummaryMin;
        if (curMinOfDay >= sumMinOfDay) {
            const auto &t = state.tally();
            if (tryEmit(NudgeEvent{
                    QStringLiteral("daily_summary"),
                    QStringLiteral("summary"),
                    Urgency::Silent,
                    QStringLiteral("Daily Focus Summary"),
                    QStringLiteral("Focus: %1 min · Breaks: %2 · Snoozed: %3 · Dismissed: %4")
                        .arg(t.focusSeconds / 60)
                        .arg(t.breaksTaken)
                        .arg(t.nudgesSnoozed)
                        .arg(t.nudgesDismissed),
                    0
                }, 43200)) {
                state.markDailySummaryFired();
            }
        }
    }

    return out;
}

int64_t RuleEngine::nextNudgeEtaSec(const FocusConfig &cfg,
                                    const SignalSnapshot &sig,
                                    const NudgeState &state) const {
    if (state.isOnBreak(sig.nowSec)) {
        return state.breakRemainingSec(sig.nowSec);
    }

    int64_t best = std::numeric_limits<int64_t>::max();
    auto consider = [&](int64_t remaining) {
        best = std::min(best, std::max<int64_t>(0, remaining));
    };

    if (cfg.catFocus && cfg.ruleFocusBlock && sig.ideFocused) {
        consider(cfg.focusBlockSec - state.ideDwellSec());
    }
    if (cfg.catHealth && cfg.ruleEyeStrain) {
        consider(cfg.eyeStrainIntervalSec - state.eyeStrainElapsedSec());
    }
    if (cfg.catHealth && cfg.ruleHydration) {
        consider(cfg.hydrationIntervalSec - state.hydrationElapsedSec());
    }

    if (best == std::numeric_limits<int64_t>::max()) {
        return cfg.focusBlockSec;
    }

    // Respect global non-critical fatigue floor
    const int64_t sinceLast = sig.nowSec - state.lastNonCriticalNudgeSec();
    if (sinceLast < cfg.minNudgeGapSec) {
        best = std::max(best, cfg.minNudgeGapSec - sinceLast);
    }
    if (state.isSnoozed(sig.nowSec)) {
        best = std::max(best, state.snoozeRemainingSec(sig.nowSec));
    }
    return best;
}

} // namespace titan::focus
