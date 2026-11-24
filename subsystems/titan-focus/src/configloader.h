#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QFileSystemWatcher>
#include <cstdint>

namespace titan::focus {

struct FocusConfig {
    // [general]
    int64_t minNudgeGapSec   = 1200; // 20 min global non-critical fatigue floor
    int64_t idleResetSec     = 300;  // 5 min idle resets continuous work timers
    int     focusBlockMin    = 50;
    int     breakDurationMin = 10;
    int     lateNightHour    = 23;
    int     lateNightMinute  = 30;
    int     dailySummaryHour = 18;
    int     dailySummaryMin  = 0;

    // [categories]
    bool catHealth   = true;
    bool catFocus    = true;
    bool catWorkflow = true;
    bool catSystem   = true;
    bool catSummary  = true;

    // [rules]
    bool ruleHydration       = true;
    bool ruleEyeStrain       = true;
    bool rulePosture         = true;
    bool ruleFocusBlock      = true;
    bool ruleSessionCap      = true;
    bool ruleContextThrash   = true;
    bool ruleLongBuild       = true;
    bool ruleThermalPressure = true;
    bool ruleLateNight       = true;
    bool ruleDailySummary    = true;
    bool ruleAgentDone       = false; // opt-in
    bool ruleUncommitted     = false; // opt-in

    // [thresholds]
    int64_t hydrationIntervalSec   = 2700;
    int64_t eyeStrainIntervalSec   = 1200;
    int64_t postureIntervalSec     = 2700;
    int64_t focusBlockSec          = 3000;
    int64_t sessionCap1Sec         = 5400;
    int64_t sessionCap2Sec         = 7200;
    int64_t sessionCap3Sec         = 10800;
    int     contextThrashSwitches  = 18;
    int64_t contextThrashWindowSec = 120;
    int64_t longBuildSec           = 180;
    double  thermalCpuC            = 80.0;
    double  pressureMemPct         = 40.0;
    int64_t uncommittedSec         = 5400;

    // [classifier]
    QStringList lspBinaries  = {QStringLiteral("clangd"), QStringLiteral("ccls"),
                                QStringLiteral("rust-analyzer"), QStringLiteral("tsserver"),
                                QStringLiteral("eslint_d")};
    QStringList buildDaemons = {QStringLiteral("gradle"), QStringLiteral("cargo"),
                                QStringLiteral("webpack"), QStringLiteral("vite"),
                                QStringLiteral("java"), QStringLiteral("cmake"),
                                QStringLiteral("ninja"), QStringLiteral("make")};
    QStringList aiInference  = {QStringLiteral("ollama"), QStringLiteral("llama-server"),
                                QStringLiteral("claude"), QStringLiteral("codex"),
                                QStringLiteral("aider")};
    QStringList knownIdes    = {QStringLiteral("code"), QStringLiteral("code-oss"),
                                QStringLiteral("cursor"), QStringLiteral("zed"),
                                QStringLiteral("windsurf"), QStringLiteral("antigravity"),
                                QStringLiteral("fleet"), QStringLiteral("idea"),
                                QStringLiteral("android-studio"), QStringLiteral("nvim")};
    QStringList meetingApps  = {QStringLiteral("zoom"), QStringLiteral("teams"),
                                QStringLiteral("teams-for-linux"), QStringLiteral("obs"),
                                QStringLiteral("slack"), QStringLiteral("discord")};
};

class ConfigLoader : public QObject {
    Q_OBJECT

public:
    explicit ConfigLoader(QObject *parent = nullptr);

    static QString defaultUserConfigPath();
    static FocusConfig parseToml(const QString &tomlText);
    static QString serializeToml(const FocusConfig &cfg);

    bool load(const QString &path = QString());
    bool save(const FocusConfig &cfg, const QString &path = QString());

    const FocusConfig &config() const { return m_config; }
    QString configPath() const { return m_path; }

signals:
    void configChanged(const titan::focus::FocusConfig &cfg);

private:
    void watchPath(const QString &path);

    FocusConfig m_config;
    QString m_path;
    QFileSystemWatcher m_watcher;
};

} // namespace titan::focus
