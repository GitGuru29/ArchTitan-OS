#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVector>

#include "gpumodel.hpp"
#include "thmstate.hpp"

/**
 * SysmonController — samples system telemetry once a second and exposes it to QML.
 *
 * Data sources (all zero-dependency, no privileged helpers):
 *   CPU      /proc/stat deltas, /proc/cpuinfo, cpufreq scaling_cur_freq
 *   Memory   /proc/meminfo, /proc/pressure/memory (PSI)
 *   Storage  QStorageInfo("/") + /proc/diskstats deltas
 *   Thermal  /sys/class/hwmon/* (coretemp/k10temp/zenpower/acpitz/amdgpu)
 *   GPU      nvidia-smi (NVIDIA) + DRM sysfs (AMD/Intel)
 *   THM      /run/archtitan/thm-state.json (Titan Hardware Manager v3)
 *
 * Every property notifies through a single `updated()` signal (1 Hz), which is
 * cheap and lets QML re-evaluate all bindings together. Sparkline histories keep
 * the last `kHistory` samples as normalised 0..1 doubles.
 */
class SysmonController : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool ready READ ready NOTIFY updated)

    // ── CPU ──────────────────────────────────────────────────────────────
    Q_PROPERTY(QString cpuModel READ cpuModel NOTIFY updated)
    Q_PROPERTY(double cpuUsage READ cpuUsage NOTIFY updated)
    Q_PROPERTY(int cpuCores READ cpuCores NOTIFY updated)
    Q_PROPERTY(QVariantList cpuCoreUsage READ cpuCoreUsage NOTIFY updated)
    Q_PROPERTY(double cpuFreqMhz READ cpuFreqMhz NOTIFY updated)
    Q_PROPERTY(double cpuMaxFreqMhz READ cpuMaxFreqMhz NOTIFY updated)
    Q_PROPERTY(QString loadAvg READ loadAvg NOTIFY updated)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY updated)

    // ── Memory ───────────────────────────────────────────────────────────
    Q_PROPERTY(double ramUsedPct READ ramUsedPct NOTIFY updated)
    Q_PROPERTY(double ramUsedGb READ ramUsedGb NOTIFY updated)
    Q_PROPERTY(double ramTotalGb READ ramTotalGb NOTIFY updated)
    Q_PROPERTY(bool hasSwap READ hasSwap NOTIFY updated)
    Q_PROPERTY(double swapUsedPct READ swapUsedPct NOTIFY updated)
    Q_PROPERTY(double swapUsedGb READ swapUsedGb NOTIFY updated)
    Q_PROPERTY(double swapTotalGb READ swapTotalGb NOTIFY updated)
    Q_PROPERTY(double memPressure READ memPressure NOTIFY updated)
    Q_PROPERTY(QString pressureLevel READ pressureLevel NOTIFY updated)
    Q_PROPERTY(QVariantList ramHistory READ ramHistory NOTIFY updated)

    // ── Thermals ─────────────────────────────────────────────────────────
    Q_PROPERTY(bool hasCpuTemp READ hasCpuTemp NOTIFY updated)
    Q_PROPERTY(double cpuTemp READ cpuTemp NOTIFY updated)
    Q_PROPERTY(bool hasGpuTemp READ hasGpuTemp NOTIFY updated)
    Q_PROPERTY(double gpuTemp READ gpuTemp NOTIFY updated)
    Q_PROPERTY(bool hasAnyTemp READ hasAnyTemp NOTIFY updated)
    Q_PROPERTY(double highestTemp READ highestTemp NOTIFY updated)
    Q_PROPERTY(QString tempStatus READ tempStatus NOTIFY updated)
    Q_PROPERTY(bool hasFan READ hasFan NOTIFY updated)
    Q_PROPERTY(int fanRpm READ fanRpm NOTIFY updated)
    Q_PROPERTY(QVariantList tempHistory READ tempHistory NOTIFY updated)

    // ── Storage ──────────────────────────────────────────────────────────
    Q_PROPERTY(QString diskName READ diskName NOTIFY updated)
    Q_PROPERTY(double diskUsedPct READ diskUsedPct NOTIFY updated)
    Q_PROPERTY(double diskUsedGb READ diskUsedGb NOTIFY updated)
    Q_PROPERTY(double diskTotalGb READ diskTotalGb NOTIFY updated)
    Q_PROPERTY(double diskFreeGb READ diskFreeGb NOTIFY updated)
    Q_PROPERTY(double diskReadMbs READ diskReadMbs NOTIFY updated)
    Q_PROPERTY(double diskWriteMbs READ diskWriteMbs NOTIFY updated)

    // ── THM v3 ───────────────────────────────────────────────────────────
    Q_PROPERTY(bool thmAvailable READ thmAvailable NOTIFY updated)
    Q_PROPERTY(QString thmVersion READ thmVersion NOTIFY updated)
    Q_PROPERTY(QString thmPressure READ thmPressure NOTIFY updated)
    Q_PROPERTY(QString thmGovernor READ thmGovernor NOTIFY updated)
    Q_PROPERTY(int thmWorkloadCount READ thmWorkloadCount NOTIFY updated)
    Q_PROPERTY(int thmActiveWorkloads READ thmActiveWorkloads NOTIFY updated)
    Q_PROPERTY(QString thmLastAction READ thmLastAction NOTIFY updated)
    Q_PROPERTY(QString thmLastActionTarget READ thmLastActionTarget NOTIFY updated)
    Q_PROPERTY(QVariantList thmWorkloads READ thmWorkloads NOTIFY updated)
    Q_PROPERTY(QVariantList thmPressureHistory READ thmPressureHistory NOTIFY updated)

public:
    explicit SysmonController(GpuModel *gpuModel, QObject *parent = nullptr);

    /// Sampling period in milliseconds (default 1000).
    Q_INVOKABLE void setInterval(int ms);

    // CPU
    bool ready() const { return m_ready; }
    QString cpuModel() const { return m_cpuModel; }
    double cpuUsage() const { return m_cpuUsage; }
    int cpuCores() const { return m_cpuCores; }
    QVariantList cpuCoreUsage() const { return m_cpuCoreUsage; }
    double cpuFreqMhz() const { return m_cpuFreqMhz; }
    double cpuMaxFreqMhz() const { return m_cpuMaxFreqMhz; }
    QString loadAvg() const { return m_loadAvg; }
    QVariantList cpuHistory() const { return m_cpuHistory; }

    // Memory
    double ramUsedPct() const { return m_ramUsedPct; }
    double ramUsedGb() const { return m_ramUsedGb; }
    double ramTotalGb() const { return m_ramTotalGb; }
    bool hasSwap() const { return m_swapTotalGb > 0.05; }
    double swapUsedPct() const { return m_swapUsedPct; }
    double swapUsedGb() const { return m_swapUsedGb; }
    double swapTotalGb() const { return m_swapTotalGb; }
    double memPressure() const { return m_memPressure; }
    QString pressureLevel() const { return m_pressureLevel; }
    QVariantList ramHistory() const { return m_ramHistory; }

    // Thermals
    bool hasCpuTemp() const { return m_hasCpuTemp; }
    double cpuTemp() const { return m_cpuTemp; }
    bool hasGpuTemp() const { return m_hasGpuTemp; }
    double gpuTemp() const { return m_gpuTemp; }
    bool hasAnyTemp() const { return m_hasCpuTemp || m_hasGpuTemp; }
    double highestTemp() const { return m_highestTemp; }
    QString tempStatus() const;
    bool hasFan() const { return m_hasFan; }
    int fanRpm() const { return m_fanRpm; }
    QVariantList tempHistory() const { return m_tempHistory; }

    // Storage
    QString diskName() const { return m_diskName; }
    double diskUsedPct() const { return m_diskUsedPct; }
    double diskUsedGb() const { return m_diskUsedGb; }
    double diskTotalGb() const { return m_diskTotalGb; }
    double diskFreeGb() const { return m_diskFreeGb; }
    double diskReadMbs() const { return m_diskReadMbs; }
    double diskWriteMbs() const { return m_diskWriteMbs; }

    // THM v3
    bool thmAvailable() const { return m_thm.available; }
    QString thmVersion() const { return m_thm.version; }
    QString thmPressure() const { return m_thm.pressureLevel; }
    QString thmGovernor() const { return m_thm.governor; }
    int thmWorkloadCount() const { return m_thm.workloadCount; }
    int thmActiveWorkloads() const { return m_thm.activeWorkloads; }
    int thmClassifiedWorkloads() const { return m_thm.classifiedWorkloads; }
    int thmObservedWorkloads() const { return m_thm.observedWorkloads; }
    int thmProcessesSeen() const { return m_thm.processesSeen; }
    int thmProcessesUnmanaged() const { return m_thm.processesUnmanaged; }
    bool thmHyprlandConnected() const { return m_thm.hyprlandConnected; }
    double thmCpuPsi() const { return m_thm.cpuPsiSome; }
    double thmLoad1() const { return m_thm.load1; }
    QString thmLastAction() const { return m_thm.lastAction; }
    QString thmLastActionTarget() const { return m_thm.lastActionTarget; }
    QVariantList thmWorkloads() const { return m_thm.workloads; }
    QVariantList thmPressureHistory() const { return m_thmPressureHistory; }

signals:
    void updated();

private slots:
    void sample();

private:
    static constexpr int kHistory = 60;

    void sampleCpu();
    void sampleMemory();
    void sampleThermal();
    void sampleStorage();
    void sampleGpu();
    void sampleThm();

    void pushHistory(QVariantList &list, double value);

    GpuModel *m_gpuModel = nullptr;
    QTimer    m_timer;
    bool      m_ready = false;

    // CPU accumulators
    QString m_cpuModel;
    double  m_cpuUsage = 0.0;
    int     m_cpuCores = 0;
    QVariantList m_cpuCoreUsage;
    double  m_cpuFreqMhz = 0.0;
    double  m_cpuMaxFreqMhz = 0.0;
    QString m_loadAvg;
    QVector<qulonglong> m_prevCpuTotal;
    QVector<qulonglong> m_prevCpuIdle;
    qulonglong m_prevTotal = 0;
    qulonglong m_prevIdle  = 0;
    bool m_cpuSeeded = false;
    QVariantList m_cpuHistory;

    // Memory
    double m_ramUsedPct = 0.0;
    double m_ramUsedGb  = 0.0;
    double m_ramTotalGb = 0.0;
    double m_swapUsedPct = 0.0;
    double m_swapUsedGb  = 0.0;
    double m_swapTotalGb = 0.0;
    double m_memPressure = 0.0;
    QString m_pressureLevel;
    QVariantList m_ramHistory;

    // Thermals
    bool   m_hasCpuTemp = false;
    bool   m_hasGpuTemp = false;
    double m_cpuTemp = 0.0;
    double m_gpuTemp = 0.0;
    double m_highestTemp = 0.0;
    bool   m_hasFan = false;
    int    m_fanRpm = 0;
    QVariantList m_tempHistory;

    // Storage
    QString m_diskName;
    double m_diskUsedPct = 0.0;
    double m_diskUsedGb  = 0.0;
    double m_diskTotalGb = 0.0;
    double m_diskFreeGb  = 0.0;
    double m_diskReadMbs = 0.0;
    double m_diskWriteMbs = 0.0;
    qulonglong m_prevDiskReadSectors = 0;
    qulonglong m_prevDiskWriteSectors = 0;
    bool m_diskSeeded = false;

    // THM
    ThmState m_thm;
    QVariantList m_thmPressureHistory;
};
