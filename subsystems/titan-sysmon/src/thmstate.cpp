#include "thmstate.hpp"

#include <QByteArray>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QVariantMap>

QString ThmReader::defaultPath()
{
    const QString env = QProcessEnvironment::systemEnvironment()
                            .value(QStringLiteral("THM_TELEMETRY_PATH"));
    if (!env.isEmpty())
        return env;
    return QStringLiteral("/run/archtitan/thm-state.json");
}

ThmState ThmReader::read(const QString &path)
{
    ThmState s;

    QFile f(path.isEmpty() ? defaultPath() : path);
    if (!f.open(QIODevice::ReadOnly))
        return s;

    // Guard against catching a torn write: the daemon writes whole-file via
    // rename, so a read failure or empty payload just means "not ready".
    const QByteArray raw = f.readAll();
    if (raw.isEmpty())
        return s;

    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(raw, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
        return s;

    const QJsonObject o = doc.object();
    s.available      = true;
    s.version        = o.value(QStringLiteral("version")).toString();
    s.timestampMs    = static_cast<qint64>(o.value(QStringLiteral("timestamp_ms")).toDouble());
    s.uptimeSeconds  = static_cast<qint64>(o.value(QStringLiteral("uptime_seconds")).toDouble());

    // Pressure is emitted by the daemon as a nested object:
    //   "pressure": { "level", "psi_some_avg10", "psi_full_avg10",
    //                 "mem_used_pct", "mem_total_kb", "mem_available_kb" }
    // Fall back to flat top-level keys for older/alternative producers.
    const QJsonObject pressure = o.value(QStringLiteral("pressure")).toObject();
    const auto pressurePick = [&](const QString &key) -> QJsonValue {
        if (pressure.contains(key))
            return pressure.value(key);
        return o.value(key);
    };
    s.pressureLevel  = pressurePick(QStringLiteral("level")).toString();
    s.psiSome        = pressurePick(QStringLiteral("psi_some_avg10")).toDouble();
    s.psiFull        = pressurePick(QStringLiteral("psi_full_avg10")).toDouble();
    s.memUsedPct     = pressurePick(QStringLiteral("mem_used_pct")).toDouble();
    s.memTotalKb     = static_cast<qint64>(pressurePick(QStringLiteral("mem_total_kb")).toDouble());
    s.memAvailableKb = static_cast<qint64>(pressurePick(QStringLiteral("mem_available_kb")).toDouble());
    s.governor       = o.value(QStringLiteral("governor")).toString();
    s.workloadCount  = o.value(QStringLiteral("workload_count")).toInt();
    s.activeWorkloads = o.value(QStringLiteral("active_workloads")).toInt();
    s.classifiedWorkloads = o.value(QStringLiteral("classified_workloads")).toInt();
    s.observedWorkloads   = o.value(QStringLiteral("observed_workloads")).toInt();

    const QJsonObject cpu = o.value(QStringLiteral("cpu")).toObject();
    s.cpuPsiSome = cpu.value(QStringLiteral("psi_some_avg10")).toDouble();
    s.load1      = cpu.value(QStringLiteral("load1")).toDouble();

    const QJsonObject procs = o.value(QStringLiteral("processes")).toObject();
    s.processesSeen      = procs.value(QStringLiteral("seen")).toInt();
    s.processesProtected = procs.value(QStringLiteral("protected")).toInt();
    s.processesAssigned  = procs.value(QStringLiteral("assigned")).toInt();
    s.processesUnmanaged = procs.value(QStringLiteral("unmanaged")).toInt();
    s.hyprlandConnected  = procs.value(QStringLiteral("hyprland_connected")).toBool();

    const QJsonValue last = o.value(QStringLiteral("last_action"));
    if (last.isObject()) {
        const QJsonObject la = last.toObject();
        s.hasLastAction   = true;
        s.lastAction      = la.value(QStringLiteral("decision")).toString();
        s.lastActionTarget = la.value(QStringLiteral("target")).toString();
        s.lastActionPid   = la.value(QStringLiteral("pid")).toInt();
    }

    const QJsonArray wls = o.value(QStringLiteral("workloads")).toArray();
    for (const QJsonValue &v : wls) {
        if (!v.isObject())
            continue;
        const QJsonObject w = v.toObject();
        QVariantMap m;
        m.insert(QStringLiteral("id"),        w.value(QStringLiteral("id")).toInt());
        m.insert(QStringLiteral("pid"),       w.value(QStringLiteral("pid")).toInt());
        m.insert(QStringLiteral("workspace"), w.value(QStringLiteral("workspace")).toInt());
        m.insert(QStringLiteral("name"),      w.value(QStringLiteral("name")).toString());
        m.insert(QStringLiteral("type"),      w.value(QStringLiteral("type")).toString());
        m.insert(QStringLiteral("state"),     w.value(QStringLiteral("state")).toString());
        m.insert(QStringLiteral("pids"),      w.value(QStringLiteral("pids")).toInt());
        m.insert(QStringLiteral("memMb"),     static_cast<qint64>(w.value(QStringLiteral("mem_mb")).toDouble()));
        m.insert(QStringLiteral("cpuPct"),    w.value(QStringLiteral("cpu_pct")).toDouble());
        m.insert(QStringLiteral("observed"),  w.value(QStringLiteral("observed")).toBool());
        s.workloads.append(m);
    }

    return s;
}
