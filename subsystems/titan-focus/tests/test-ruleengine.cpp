#include "configloader.h"
#include "nudgestate.h"
#include "pressuresampler.h"
#include "procsampler.h"
#include "ruleengine.h"
#include "sessionmonitor.h"

#include <QCoreApplication>
#include <iostream>
#include <string>

using namespace titan::focus;

namespace {

int g_failures = 0;

void check(bool cond, const char *name) {
    if (cond) {
        std::cout << "[PASS] " << name << "\n";
    } else {
        std::cerr << "[FAIL] " << name << "\n";
        g_failures++;
    }
}

bool hasRule(const std::vector<NudgeEvent> &events, const char *id) {
    for (const auto &ev : events) {
        if (ev.ruleId == QLatin1String(id)) return true;
    }
    return false;
}

SignalSnapshot makeSig(int64_t nowSec) {
    SignalSnapshot s;
    s.nowSec = nowSec;
    s.localHour = 14;
    s.localMinute = 0;
    s.localDateKey = QStringLiteral("2026-11-18");
    return s;
}

} // namespace

int main(int argc, char *argv[]) {
    QCoreApplication app(argc, argv);

    // 1. TOML parse + serialize round-trip
    {
        const QString sample = QStringLiteral(
            "[general]\nmin_nudge_gap_sec = 900\nfocus_block_min = 45\n"
            "[categories]\nhealth = false\n"
            "[rules]\nagent_done = true\nuncommitted = false\n"
            "[classifier]\nknown_ides = [\"cursor\", \"zed\"]\n");
        const FocusConfig parsed = ConfigLoader::parseToml(sample);
        check(parsed.minNudgeGapSec == 900, "toml_min_nudge_gap");
        check(parsed.focusBlockMin == 45 && parsed.focusBlockSec == 2700, "toml_focus_block_min");
        check(!parsed.catHealth, "toml_category_toggle");
        check(parsed.ruleAgentDone && !parsed.ruleUncommitted, "toml_optin_rules");
        check(parsed.knownIdes.size() == 2 && parsed.knownIdes.contains(QStringLiteral("zed")), "toml_classifier_array");

        const FocusConfig roundtrip = ConfigLoader::parseToml(ConfigLoader::serializeToml(parsed));
        check(roundtrip.minNudgeGapSec == 900 && !roundtrip.catHealth && roundtrip.ruleAgentDone, "toml_roundtrip");
    }

    // 2. Global 20-minute non-critical fatigue floor enforced across distinct rules
    {
        FocusConfig cfg;
        NudgeState state;
        RuleEngine eng;

        // Advance 20 min continuous active session (eye_strain ready)
        SignalSnapshot sig = makeSig(1200);
        state.advance(sig, 1200, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev1 = eng.evaluate(cfg, sig, state);
        check(hasRule(ev1, "eye_strain"), "eye_strain_fires_at_20m");

        // 5 minutes later, trigger long_build (3+ min) -> MUST be blocked by 20-min fatigue floor
        sig = makeSig(1500);
        sig.buildActive = true;
        sig.activeBuildProc = QStringLiteral("cargo");
        state.advance(sig, 300, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev2 = eng.evaluate(cfg, sig, state);
        check(ev2.empty(), "fatigue_floor_blocks_second_non_critical_within_20m");

        // At +20 min after eye_strain (now = 2400), long_build is allowed
        sig = makeSig(2400);
        sig.buildActive = true;
        sig.activeBuildProc = QStringLiteral("cargo");
        state.advance(sig, 900, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev3 = eng.evaluate(cfg, sig, state);
        check(hasRule(ev3, "long_build"), "long_build_fires_after_fatigue_floor_clears");
    }

    // 3. suppress_when: meeting or media playback suppresses non-critical nudges
    {
        FocusConfig cfg;
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(3000);
        sig.inMeeting = true;
        state.advance(sig, 3000, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev = eng.evaluate(cfg, sig, state);
        check(ev.empty(), "meeting_suppresses_non_critical_nudges");

        sig.inMeeting = false;
        sig.mediaPlaying = true;
        ev = eng.evaluate(cfg, sig, state);
        check(ev.empty(), "media_suppresses_non_critical_nudges");
    }

    // 4. focus_block requires IDE continuity (switching away resets dwell timer)
    {
        FocusConfig cfg;
        cfg.catHealth = false; // isolate focus_block
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(2000);
        sig.ideFocused = true;
        sig.activeApp = QStringLiteral("cursor");
        state.advance(sig, 2000, cfg.idleResetSec, cfg.contextThrashWindowSec);
        check(state.ideDwellSec() == 2000, "ide_dwell_accumulates");

        // Switch away to browser -> resets dwell
        sig = makeSig(2010);
        sig.ideFocused = false;
        sig.activeApp = QStringLiteral("firefox");
        state.advance(sig, 10, cfg.idleResetSec, cfg.contextThrashWindowSec);
        check(state.ideDwellSec() == 0, "ide_dwell_resets_on_switch_away");

        // Continuous 50 min in IDE triggers focus_block
        sig = makeSig(5010);
        sig.ideFocused = true;
        sig.activeApp = QStringLiteral("cursor");
        state.advance(sig, 3000, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev = eng.evaluate(cfg, sig, state);
        check(hasRule(ev, "focus_block"), "focus_block_fires_after_50m_continuous_ide");
    }

    // 5. Critical thermal_pressure bypasses non-critical fatigue floor
    {
        FocusConfig cfg;
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(1200);
        state.advance(sig, 1200, cfg.idleResetSec, cfg.contextThrashWindowSec);
        eng.evaluate(cfg, sig, state); // consumes fatigue floor

        sig = makeSig(1260);
        sig.cpuTempC = 85.0;
        auto ev = eng.evaluate(cfg, sig, state);
        check(hasRule(ev, "thermal_pressure") && ev.front().urgency == Urgency::Critical,
              "critical_thermal_bypasses_fatigue_floor");
    }

    // 6. context_thrash detection
    {
        FocusConfig cfg;
        cfg.catHealth = false;
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(500);
        sig.windowSwitchesDelta = 20;
        state.advance(sig, 10, cfg.idleResetSec, cfg.contextThrashWindowSec);
        auto ev = eng.evaluate(cfg, sig, state);
        check(hasRule(ev, "context_thrash"), "context_thrash_fires_on_rapid_switching");
    }

    // 7. Opt-in rules: agent_done & uncommitted disabled by default, fire when enabled
    {
        FocusConfig cfg;
        cfg.catHealth = false;
        cfg.catFocus = false;
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(100);
        sig.agentActive = true;
        sig.activeAgentProc = QStringLiteral("ollama");
        state.advance(sig, 10, cfg.idleResetSec, cfg.contextThrashWindowSec);

        sig = makeSig(120);
        sig.agentActive = false;
        state.advance(sig, 20, cfg.idleResetSec, cfg.contextThrashWindowSec);
        check(eng.evaluate(cfg, sig, state).empty(), "agent_done_disabled_by_default");

        cfg.ruleAgentDone = true;
        auto ev = eng.evaluate(cfg, sig, state);
        check(hasRule(ev, "agent_done"), "agent_done_fires_when_opted_in");
    }

    // 8. Silent rules: late_night and daily_summary fire silently without blocking non-critical floor
    {
        FocusConfig cfg;
        NudgeState state;
        RuleEngine eng;

        SignalSnapshot sig = makeSig(100);
        sig.localHour = 23;
        sig.localMinute = 45;
        auto ev = eng.evaluate(cfg, sig, state);
        check(hasRule(ev, "late_night") && hasRule(ev, "daily_summary"), "silent_late_night_and_daily_summary_fire");
        check(state.tally().nudgesFired == 0, "silent_rules_do_not_increment_visible_nudges");
    }

    // 9. Break + Snooze + DND state transitions
    {
        FocusConfig cfg;
        NudgeState state;
        RuleEngine eng;

        state.startBreak(1000, 600);
        check(state.isOnBreak(1200) && state.breakRemainingSec(1200) == 400, "break_countdown_active");
        check(state.tally().breaksTaken == 1, "break_increments_tally");

        SignalSnapshot sig = makeSig(1200);
        sig.cpuTempC = 90.0;
        check(eng.evaluate(cfg, sig, state).empty(), "no_nudges_during_break");

        state.endBreak(1200);
        state.snooze(1200, 900);
        check(state.isSnoozed(1500) && state.tally().nudgesSnoozed == 1, "snooze_active_and_tallied");
    }

    // 10. SessionMonitor socket2 line parsing
    {
        SessionMonitor mon;
        mon.processEventLine(QStringLiteral("activewindow>>code,main.cpp"), 100);
        mon.processEventLine(QStringLiteral("activewindow>>kitty,zsh"), 105);
        mon.processEventLine(QStringLiteral("workspace>>2"), 106);
        check(mon.activeApp() == QLatin1String("kitty"), "sessionmonitor_activewindow_parse");
        check(mon.takeSwitchDelta() == 2, "sessionmonitor_switch_delta_counted");

        mon.processEventLine(QStringLiteral("idle>>1"), 200);
        check(mon.isIdle() && mon.idleDurationSec(250) == 50, "sessionmonitor_idle_tracking");
    }

    // 11. Live POSIX samplers smoke check (/proc and /proc/pressure)
    {
        FocusConfig cfg;
        const ProcSample ps = ProcSampler::sample(cfg);
        const PressureSample prs = PressureSampler::sample();
        check(prs.memUsedPct >= 0.0 && prs.memUsedPct <= 100.0, "pressuresampler_mem_range");
        (void)ps;
    }

    if (g_failures == 0) {
        std::cout << "\nALL TITAN-FOCUS UNIT TESTS PASSED.\n";
        return 0;
    }
    std::cerr << "\n" << g_failures << " TEST(S) FAILED.\n";
    return 1;
}
