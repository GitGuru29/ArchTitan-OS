#pragma once

#include <QString>
#include <QVariantList>

/**
 * ThmReader — reads the Titan Hardware Manager v3 telemetry snapshot.
 *
 * THM v3 publishes an atomic JSON file (tmp + rename) at
 * /run/archtitan/thm-state.json roughly once per second. This reader turns it
 * into a flat struct plus a QVariantList of workload maps for the QML layer.
 *
 * The reader is pure and stateless: a missing/short/partial file simply yields
 * `available == false`, so the UI can degrade gracefully when the daemon is not
 * running (e.g. non-root sessions, units not yet started).
 */
struct ThmState
{
    bool     available       = false;
    QString  version;
    qint64   timestampMs     = 0;
    qint64   uptimeSeconds   = 0;
    QString  pressureLevel;              // NORMAL / ELEVATED / ... (daemon vocabulary)
    double   psiSome         = 0.0;      // /proc/pressure/memory some avg10
    double   psiFull         = 0.0;      // /proc/pressure/memory full avg10
    double   memUsedPct      = 0.0;
    qint64   memTotalKb      = 0;
    qint64   memAvailableKb  = 0;
    QString  governor;                   // powersave / schedutil / performance
    int      workloadCount   = 0;
    int      activeWorkloads = 0;
    int      classifiedWorkloads = 0;    // non-observed (enforcement-eligible)
    int      observedWorkloads   = 0;    // telemetry-only
    double   cpuPsiSome      = 0.0;      // /proc/pressure/cpu some avg10
    double   load1           = 0.0;
    int      processesSeen      = 0;
    int      processesProtected = 0;
    int      processesAssigned  = 0;
    int      processesUnmanaged = 0;
    bool     hyprlandConnected  = false;
    bool     hasLastAction   = false;
    QString  lastAction;                 // e.g. THROTTLE / FREEZE / RECLAIM
    QString  lastActionTarget;
    int      lastActionPid   = 0;
    QVariantList workloads;              // maps: id,pid,workspace,name,type,state,pids,memMb
};

class ThmReader
{
public:
    /// Default snapshot location; honours THM_TELEMETRY_PATH env override.
    static QString defaultPath();

    /// Parse the snapshot at `path` (empty → defaultPath()).
    static ThmState read(const QString &path = QString());
};
