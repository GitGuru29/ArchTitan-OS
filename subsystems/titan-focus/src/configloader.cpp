#include "configloader.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>
#include <algorithm>

namespace titan::focus {

namespace {

QString stripComment(const QString &line) {
    bool inQuote = false;
    for (int i = 0; i < line.size(); ++i) {
        const QChar c = line.at(i);
        if (c == QLatin1Char('"') && (i == 0 || line.at(i - 1) != QLatin1Char('\\'))) {
            inQuote = !inQuote;
        } else if (c == QLatin1Char('#') && !inQuote) {
            return line.left(i).trimmed();
        }
    }
    return line.trimmed();
}

bool parseBool(const QString &val, bool fallback) {
    const QString v = val.trimmed().toLower();
    if (v == QLatin1String("true") || v == QLatin1String("1") || v == QLatin1String("yes")) return true;
    if (v == QLatin1String("false") || v == QLatin1String("0") || v == QLatin1String("no")) return false;
    return fallback;
}

int64_t parseInt64(const QString &val, int64_t fallback) {
    bool ok = false;
    const qint64 n = val.trimmed().toLongLong(&ok);
    return ok ? static_cast<int64_t>(n) : fallback;
}

double parseDouble(const QString &val, double fallback) {
    bool ok = false;
    const double d = val.trimmed().toDouble(&ok);
    return ok ? d : fallback;
}

QStringList parseStringArray(const QString &val) {
    QStringList out;
    QString s = val.trimmed();
    if (s.startsWith(QLatin1Char('[')) && s.endsWith(QLatin1Char(']'))) {
        s = s.mid(1, s.size() - 2);
    }
    bool inQuote = false;
    QString current;
    for (int i = 0; i < s.size(); ++i) {
        const QChar c = s.at(i);
        if (c == QLatin1Char('"')) {
            inQuote = !inQuote;
        } else if (c == QLatin1Char(',') && !inQuote) {
            const QString item = current.trimmed();
            if (!item.isEmpty()) out.append(item);
            current.clear();
        } else {
            current.append(c);
        }
    }
    const QString last = current.trimmed();
    if (!last.isEmpty()) out.append(last);
    return out;
}

QString formatStringArray(const QStringList &list) {
    QStringList quoted;
    quoted.reserve(list.size());
    for (const QString &s : list) {
        QString escaped = s;
        escaped.replace(QLatin1Char('"'), QLatin1String("\\\""));
        quoted.append(QLatin1Char('"') + escaped + QLatin1Char('"'));
    }
    return QLatin1Char('[') + quoted.join(QLatin1String(", ")) + QLatin1Char(']');
}

} // namespace

ConfigLoader::ConfigLoader(QObject *parent)
    : QObject(parent) {
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, [this](const QString &changedPath) {
        // Editors often replace files via rename; re-add watch after reloading.
        load(changedPath);
        if (QFile::exists(changedPath) && !m_watcher.files().contains(changedPath)) {
            m_watcher.addPath(changedPath);
        }
    });
}

QString ConfigLoader::defaultUserConfigPath() {
    const QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    const QString base = cfgDir.isEmpty() ? (QDir::homePath() + QStringLiteral("/.config")) : cfgDir;
    return base + QStringLiteral("/titan-focus/focus.toml");
}

FocusConfig ConfigLoader::parseToml(const QString &tomlText) {
    FocusConfig cfg;
    QString section;
    const QStringList lines = tomlText.split(QLatin1Char('\n'));

    for (const QString &rawLine : lines) {
        const QString line = stripComment(rawLine);
        if (line.isEmpty()) continue;

        if (line.startsWith(QLatin1Char('[')) && line.endsWith(QLatin1Char(']'))) {
            section = line.mid(1, line.size() - 2).trimmed().toLower();
            continue;
        }

        const int eq = line.indexOf(QLatin1Char('='));
        if (eq <= 0) continue;

        const QString key = line.left(eq).trimmed().toLower();
        const QString val = line.mid(eq + 1).trimmed();

        if (section == QLatin1String("general")) {
            if (key == QLatin1String("min_nudge_gap_sec"))   cfg.minNudgeGapSec = std::max<int64_t>(60, parseInt64(val, cfg.minNudgeGapSec));
            else if (key == QLatin1String("idle_reset_sec")) cfg.idleResetSec = std::max<int64_t>(30, parseInt64(val, cfg.idleResetSec));
            else if (key == QLatin1String("focus_block_min")) {
                cfg.focusBlockMin = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.focusBlockMin), 5, 180));
                cfg.focusBlockSec = static_cast<int64_t>(cfg.focusBlockMin) * 60;
            }
            else if (key == QLatin1String("break_duration_min"))   cfg.breakDurationMin = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.breakDurationMin), 1, 60));
            else if (key == QLatin1String("late_night_hour"))      cfg.lateNightHour = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.lateNightHour), 0, 23));
            else if (key == QLatin1String("late_night_minute"))    cfg.lateNightMinute = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.lateNightMinute), 0, 59));
            else if (key == QLatin1String("daily_summary_hour"))   cfg.dailySummaryHour = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.dailySummaryHour), 0, 23));
            else if (key == QLatin1String("daily_summary_minute")) cfg.dailySummaryMin = static_cast<int>(std::clamp<int64_t>(parseInt64(val, cfg.dailySummaryMin), 0, 59));
        } else if (section == QLatin1String("categories")) {
            if (key == QLatin1String("health"))        cfg.catHealth = parseBool(val, cfg.catHealth);
            else if (key == QLatin1String("focus"))    cfg.catFocus = parseBool(val, cfg.catFocus);
            else if (key == QLatin1String("workflow")) cfg.catWorkflow = parseBool(val, cfg.catWorkflow);
            else if (key == QLatin1String("system"))   cfg.catSystem = parseBool(val, cfg.catSystem);
            else if (key == QLatin1String("summary"))  cfg.catSummary = parseBool(val, cfg.catSummary);
        } else if (section == QLatin1String("rules")) {
            if (key == QLatin1String("hydration"))             cfg.ruleHydration = parseBool(val, cfg.ruleHydration);
            else if (key == QLatin1String("eye_strain"))       cfg.ruleEyeStrain = parseBool(val, cfg.ruleEyeStrain);
            else if (key == QLatin1String("posture"))          cfg.rulePosture = parseBool(val, cfg.rulePosture);
            else if (key == QLatin1String("focus_block"))      cfg.ruleFocusBlock = parseBool(val, cfg.ruleFocusBlock);
            else if (key == QLatin1String("session_cap"))      cfg.ruleSessionCap = parseBool(val, cfg.ruleSessionCap);
            else if (key == QLatin1String("context_thrash"))   cfg.ruleContextThrash = parseBool(val, cfg.ruleContextThrash);
            else if (key == QLatin1String("long_build"))       cfg.ruleLongBuild = parseBool(val, cfg.ruleLongBuild);
            else if (key == QLatin1String("thermal_pressure")) cfg.ruleThermalPressure = parseBool(val, cfg.ruleThermalPressure);
            else if (key == QLatin1String("late_night"))       cfg.ruleLateNight = parseBool(val, cfg.ruleLateNight);
            else if (key == QLatin1String("daily_summary"))    cfg.ruleDailySummary = parseBool(val, cfg.ruleDailySummary);
            else if (key == QLatin1String("agent_done"))       cfg.ruleAgentDone = parseBool(val, cfg.ruleAgentDone);
            else if (key == QLatin1String("uncommitted"))      cfg.ruleUncommitted = parseBool(val, cfg.ruleUncommitted);
        } else if (section == QLatin1String("thresholds")) {
            if (key == QLatin1String("hydration_interval_sec"))        cfg.hydrationIntervalSec = std::max<int64_t>(60, parseInt64(val, cfg.hydrationIntervalSec));
            else if (key == QLatin1String("eye_strain_interval_sec"))  cfg.eyeStrainIntervalSec = std::max<int64_t>(60, parseInt64(val, cfg.eyeStrainIntervalSec));
            else if (key == QLatin1String("posture_interval_sec"))     cfg.postureIntervalSec = std::max<int64_t>(60, parseInt64(val, cfg.postureIntervalSec));
            else if (key == QLatin1String("focus_block_sec"))          cfg.focusBlockSec = std::max<int64_t>(60, parseInt64(val, cfg.focusBlockSec));
            else if (key == QLatin1String("session_cap_1_sec"))        cfg.sessionCap1Sec = std::max<int64_t>(300, parseInt64(val, cfg.sessionCap1Sec));
            else if (key == QLatin1String("session_cap_2_sec"))        cfg.sessionCap2Sec = std::max<int64_t>(600, parseInt64(val, cfg.sessionCap2Sec));
            else if (key == QLatin1String("session_cap_3_sec"))        cfg.sessionCap3Sec = std::max<int64_t>(900, parseInt64(val, cfg.sessionCap3Sec));
            else if (key == QLatin1String("context_thrash_switches"))  cfg.contextThrashSwitches = static_cast<int>(std::max<int64_t>(3, parseInt64(val, cfg.contextThrashSwitches)));
            else if (key == QLatin1String("context_thrash_window_sec"))cfg.contextThrashWindowSec = std::max<int64_t>(15, parseInt64(val, cfg.contextThrashWindowSec));
            else if (key == QLatin1String("long_build_sec"))           cfg.longBuildSec = std::max<int64_t>(15, parseInt64(val, cfg.longBuildSec));
            else if (key == QLatin1String("thermal_cpu_c"))            cfg.thermalCpuC = std::clamp(parseDouble(val, cfg.thermalCpuC), 50.0, 105.0);
            else if (key == QLatin1String("pressure_mem_pct"))         cfg.pressureMemPct = std::clamp(parseDouble(val, cfg.pressureMemPct), 5.0, 95.0);
            else if (key == QLatin1String("uncommitted_sec"))          cfg.uncommittedSec = std::max<int64_t>(300, parseInt64(val, cfg.uncommittedSec));
        } else if (section == QLatin1String("classifier")) {
            const QStringList arr = parseStringArray(val);
            if (!arr.isEmpty()) {
                if (key == QLatin1String("lsp_binaries"))       cfg.lspBinaries = arr;
                else if (key == QLatin1String("build_daemons")) cfg.buildDaemons = arr;
                else if (key == QLatin1String("ai_inference"))  cfg.aiInference = arr;
                else if (key == QLatin1String("known_ides"))    cfg.knownIdes = arr;
                else if (key == QLatin1String("meeting_apps"))  cfg.meetingApps = arr;
            }
        }
    }

    return cfg;
}

QString ConfigLoader::serializeToml(const FocusConfig &cfg) {
    QString out;
    QTextStream ts(&out);
    auto b = [](bool v) { return v ? "true" : "false"; };

    ts << "# TitanFocus Configuration\n\n";
    ts << "[general]\n";
    ts << "min_nudge_gap_sec = " << cfg.minNudgeGapSec << "\n";
    ts << "idle_reset_sec = " << cfg.idleResetSec << "\n";
    ts << "focus_block_min = " << cfg.focusBlockMin << "\n";
    ts << "break_duration_min = " << cfg.breakDurationMin << "\n";
    ts << "late_night_hour = " << cfg.lateNightHour << "\n";
    ts << "late_night_minute = " << cfg.lateNightMinute << "\n";
    ts << "daily_summary_hour = " << cfg.dailySummaryHour << "\n";
    ts << "daily_summary_minute = " << cfg.dailySummaryMin << "\n\n";

    ts << "[categories]\n";
    ts << "health = " << b(cfg.catHealth) << "\n";
    ts << "focus = " << b(cfg.catFocus) << "\n";
    ts << "workflow = " << b(cfg.catWorkflow) << "\n";
    ts << "system = " << b(cfg.catSystem) << "\n";
    ts << "summary = " << b(cfg.catSummary) << "\n\n";

    ts << "[rules]\n";
    ts << "hydration = " << b(cfg.ruleHydration) << "\n";
    ts << "eye_strain = " << b(cfg.ruleEyeStrain) << "\n";
    ts << "posture = " << b(cfg.rulePosture) << "\n";
    ts << "focus_block = " << b(cfg.ruleFocusBlock) << "\n";
    ts << "session_cap = " << b(cfg.ruleSessionCap) << "\n";
    ts << "context_thrash = " << b(cfg.ruleContextThrash) << "\n";
    ts << "long_build = " << b(cfg.ruleLongBuild) << "\n";
    ts << "thermal_pressure = " << b(cfg.ruleThermalPressure) << "\n";
    ts << "late_night = " << b(cfg.ruleLateNight) << "\n";
    ts << "daily_summary = " << b(cfg.ruleDailySummary) << "\n";
    ts << "agent_done = " << b(cfg.ruleAgentDone) << "\n";
    ts << "uncommitted = " << b(cfg.ruleUncommitted) << "\n\n";

    ts << "[thresholds]\n";
    ts << "hydration_interval_sec = " << cfg.hydrationIntervalSec << "\n";
    ts << "eye_strain_interval_sec = " << cfg.eyeStrainIntervalSec << "\n";
    ts << "posture_interval_sec = " << cfg.postureIntervalSec << "\n";
    ts << "focus_block_sec = " << cfg.focusBlockSec << "\n";
    ts << "session_cap_1_sec = " << cfg.sessionCap1Sec << "\n";
    ts << "session_cap_2_sec = " << cfg.sessionCap2Sec << "\n";
    ts << "session_cap_3_sec = " << cfg.sessionCap3Sec << "\n";
    ts << "context_thrash_switches = " << cfg.contextThrashSwitches << "\n";
    ts << "context_thrash_window_sec = " << cfg.contextThrashWindowSec << "\n";
    ts << "long_build_sec = " << cfg.longBuildSec << "\n";
    ts << "thermal_cpu_c = " << cfg.thermalCpuC << "\n";
    ts << "pressure_mem_pct = " << cfg.pressureMemPct << "\n";
    ts << "uncommitted_sec = " << cfg.uncommittedSec << "\n\n";

    ts << "[classifier]\n";
    ts << "lsp_binaries = " << formatStringArray(cfg.lspBinaries) << "\n";
    ts << "build_daemons = " << formatStringArray(cfg.buildDaemons) << "\n";
    ts << "ai_inference = " << formatStringArray(cfg.aiInference) << "\n";
    ts << "known_ides = " << formatStringArray(cfg.knownIdes) << "\n";
    ts << "meeting_apps = " << formatStringArray(cfg.meetingApps) << "\n";
    return out;
}

bool ConfigLoader::load(const QString &path) {
    QString target = path.isEmpty() ? defaultUserConfigPath() : path;
    if (!QFile::exists(target)) {
        const QString skel = QStringLiteral("/etc/skel/.config/titan-focus/focus.toml");
        if (QFile::exists(skel)) {
            QDir().mkpath(QFileInfo(target).absolutePath());
            QFile::copy(skel, target);
        }
    }

    m_path = target;
    QFile f(target);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        m_config = FocusConfig{};
        emit configChanged(m_config);
        return false;
    }

    m_config = parseToml(QString::fromUtf8(f.readAll()));
    watchPath(target);
    emit configChanged(m_config);
    return true;
}

bool ConfigLoader::save(const FocusConfig &cfg, const QString &path) {
    const QString target = path.isEmpty() ? (m_path.isEmpty() ? defaultUserConfigPath() : m_path) : path;
    QDir().mkpath(QFileInfo(target).absolutePath());

    QFile f(target);
    if (!f.open(QIODevice::WriteOnly | QIODevice::Text | QIODevice::Truncate)) {
        return false;
    }
    f.write(serializeToml(cfg).toUtf8());
    f.close();

    m_config = cfg;
    m_path = target;
    watchPath(target);
    emit configChanged(m_config);
    return true;
}

void ConfigLoader::watchPath(const QString &path) {
    if (!m_watcher.files().isEmpty()) {
        m_watcher.removePaths(m_watcher.files());
    }
    if (QFile::exists(path)) {
        m_watcher.addPath(path);
    }
}

} // namespace titan::focus
