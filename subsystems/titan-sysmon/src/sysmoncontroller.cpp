#include "sysmoncontroller.hpp"

#include <QByteArray>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QStorageInfo>
#include <QStringList>

#include <algorithm>
#include <cctype>

namespace {

QString readText(const QString &path, int maxBytes = 4096)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(f.read(maxBytes)).trimmed();
}

bool readDouble(const QString &path, double &out)
{
    const QString s = readText(path, 64);
    if (s.isEmpty())
        return false;
    bool ok = false;
    const double v = s.toDouble(&ok);
    if (ok)
        out = v;
    return ok;
}

double clampPct(double v)
{
    return std::clamp(v, 0.0, 100.0);
}

} // namespace

SysmonController::SysmonController(GpuModel *gpuModel, QObject *parent)
    : QObject(parent)
    , m_gpuModel(gpuModel)
{
    connect(&m_timer, &QTimer::timeout, this, &SysmonController::sample);
    m_timer.setInterval(1000);
    m_timer.start();
    sample(); // prime CPU deltas + first paint
}

void SysmonController::setInterval(int ms)
{
    m_timer.setInterval(std::max(250, ms));
}

// ── Public computed helpers ──────────────────────────────────────────────────
QString SysmonController::tempStatus() const
{
    if (!hasAnyTemp())
        return {};
    const double t = m_highestTemp;
    if (t >= 85.0) return QStringLiteral("Critical");
    if (t >= 70.0) return QStringLiteral("Hot");
    if (t >= 50.0) return QStringLiteral("Warm");
    return QStringLiteral("Cool");
}

// ── History helper ───────────────────────────────────────────────────────────
void SysmonController::pushHistory(QVariantList &list, double value)
{
    list.append(clampPct(value) / 100.0);
    while (list.size() > kHistory)
        list.removeFirst();
}

// ── Main sample ──────────────────────────────────────────────────────────────
void SysmonController::sample()
{
    sampleCpu();
    sampleMemory();
    sampleThermal();
    sampleStorage();
    sampleGpu();
    sampleThm();

    m_ready = true;
    emit updated();
}

// ── CPU ──────────────────────────────────────────────────────────────────────
void SysmonController::sampleCpu()
{
    QFile stat(QStringLiteral("/proc/stat"));
    if (stat.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QList<QByteArray> lines = stat.readAll().split('\n');
        QVector<qulonglong> coreTotals;
        QVector<qulonglong> coreIdles;
        qulonglong total = 0, idle = 0;

        for (const QByteArray &raw : lines) {
            if (!raw.startsWith("cpu"))
                break;
            const QList<QByteArray> parts = raw.simplified().split(' ');
            // parts[0] = "cpu" or "cpuN"; parts[1..] = time fields
            const QByteArray label = parts.value(0);
            if (label.size() > 3 && !isdigit(static_cast<unsigned char>(label.at(3))))
                continue;
            qulonglong sum = 0;
            qulonglong idleTicks = 0;
            // Fields after label: user nice system idle iowait irq softirq steal ...
            for (int i = 1; i < parts.size(); ++i) {
                const qulonglong v = parts.at(i).toULongLong();
                sum += v;
                if (i == 4 || i == 5) // idle + iowait
                    idleTicks += v;
            }
            if (label == "cpu") {
                total = sum;
                idle = idleTicks;
            } else {
                coreTotals.append(sum);
                coreIdles.append(idleTicks);
            }
        }

        if (m_cpuCores == 0 && !coreTotals.isEmpty()) {
            m_cpuCores = coreTotals.size();
            m_prevCpuTotal = coreTotals;
            m_prevCpuIdle  = coreIdles;
        }

        if (m_cpuSeeded) {
            const qulonglong dt = total - m_prevTotal;
            const qulonglong di = idle - m_prevIdle;
            if (dt > 0)
                m_cpuUsage = clampPct(100.0 * (1.0 - static_cast<double>(di) / static_cast<double>(dt)));

            QVariantList cores;
            const int n = std::min(coreTotals.size(), m_prevCpuTotal.size());
            for (int i = 0; i < n; ++i) {
                const qulonglong cdt = coreTotals.at(i) - m_prevCpuTotal.at(i);
                const qulonglong cdi = coreIdles.at(i) - m_prevCpuIdle.at(i);
                cores.append(cdt > 0
                                 ? clampPct(100.0 * (1.0 - static_cast<double>(cdi) / static_cast<double>(cdt)))
                                 : 0.0);
            }
            m_cpuCoreUsage = cores;
            if (coreTotals.size() == m_prevCpuTotal.size()) {
                m_prevCpuTotal = coreTotals;
                m_prevCpuIdle  = coreIdles;
            }
        }
        m_prevTotal = total;
        m_prevIdle  = idle;
        m_cpuSeeded = true;
    }

    // Model name
    if (m_cpuModel.isEmpty()) {
        QFile info(QStringLiteral("/proc/cpuinfo"));
        if (info.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QList<QByteArray> lines = info.readAll().split('\n');
            for (const QByteArray &l : lines) {
                if (l.startsWith("model name")) {
                    m_cpuModel = QString::fromUtf8(l).section(':', 1).trimmed();
                    break;
                }
                if (l.trimmed().isEmpty())
                    break;
            }
        }
        if (m_cpuModel.isEmpty())
            m_cpuModel = QStringLiteral("CPU");
    }

    // Frequency (average scaling_cur_freq across cores)
    QDir cpuDir(QStringLiteral("/sys/devices/system/cpu"));
    const QStringList cores = cpuDir.entryList({QStringLiteral("cpu[0-9]*")},
                                               QDir::Dirs | QDir::NoDotAndDotDot);
    double freqSum = 0.0;
    int freqCount = 0;
    double maxFreq = 0.0;
    for (const QString &c : cores) {
        double khz = 0.0;
        if (readDouble(cpuDir.filePath(c + "/cpufreq/scaling_cur_freq"), khz) && khz > 0.0) {
            freqSum += khz / 1000.0; // MHz
            ++freqCount;
        }
        double mx = 0.0;
        if (readDouble(cpuDir.filePath(c + "/cpufreq/cpuinfo_max_freq"), mx))
            maxFreq = std::max(maxFreq, mx / 1000.0);
    }
    m_cpuFreqMhz = freqCount > 0 ? freqSum / freqCount : 0.0;
    if (maxFreq > 0.0)
        m_cpuMaxFreqMhz = maxFreq;

    // Load average
    const QString load = readText(QStringLiteral("/proc/loadavg"), 128);
    if (!load.isEmpty()) {
        const QStringList p = load.split(' ', Qt::SkipEmptyParts);
        if (p.size() >= 3)
            m_loadAvg = p.at(0) + "  " + p.at(1) + "  " + p.at(2);
    }

    pushHistory(m_cpuHistory, m_cpuUsage);
}

// ── Memory ───────────────────────────────────────────────────────────────────
void SysmonController::sampleMemory()
{
    QFile f(QStringLiteral("/proc/meminfo"));
    qlonglong totalKb = 0, availKb = 0, swapTotalKb = 0, swapFreeKb = 0;
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QList<QByteArray> lines = f.readAll().split('\n');
        for (const QByteArray &l : lines) {
            if (l.startsWith("MemTotal:"))          totalKb     = l.mid(9).trimmed().split(' ').value(0).toLongLong();
            else if (l.startsWith("MemAvailable:")) availKb     = l.mid(13).trimmed().split(' ').value(0).toLongLong();
            else if (l.startsWith("SwapTotal:"))    swapTotalKb = l.mid(10).trimmed().split(' ').value(0).toLongLong();
            else if (l.startsWith("SwapFree:"))     swapFreeKb  = l.mid(9).trimmed().split(' ').value(0).toLongLong();
        }
    }
    if (totalKb > 0) {
        const qlonglong usedKb = totalKb - availKb;
        m_ramTotalGb = totalKb / 1024.0 / 1024.0;
        m_ramUsedGb  = usedKb / 1024.0 / 1024.0;
        m_ramUsedPct = clampPct(100.0 * static_cast<double>(usedKb) / static_cast<double>(totalKb));
    }
    if (swapTotalKb > 0) {
        const qlonglong usedKb = swapTotalKb - swapFreeKb;
        m_swapTotalGb = swapTotalKb / 1024.0 / 1024.0;
        m_swapUsedGb  = usedKb / 1024.0 / 1024.0;
        m_swapUsedPct = clampPct(100.0 * static_cast<double>(usedKb) / static_cast<double>(swapTotalKb));
    }

    // PSI memory pressure (some avg10, %)
    const QString psi = readText(QStringLiteral("/proc/pressure/memory"), 256);
    if (!psi.isEmpty()) {
        for (const QString &tok : psi.split(' ', Qt::SkipEmptyParts)) {
            if (tok.startsWith("avg10=")) {
                m_memPressure = clampPct(tok.mid(6).toDouble());
                break;
            }
        }
    }

    // Provisional level (refined by THM in sampleThm when available)
    if (m_memPressure >= 40.0)      m_pressureLevel = QStringLiteral("CRITICAL");
    else if (m_memPressure >= 20.0) m_pressureLevel = QStringLiteral("HIGH");
    else if (m_memPressure >= 5.0)  m_pressureLevel = QStringLiteral("ELEVATED");
    else                            m_pressureLevel = QStringLiteral("NORMAL");

    pushHistory(m_ramHistory, m_ramUsedPct);
}

// ── Thermals ─────────────────────────────────────────────────────────────────
void SysmonController::sampleThermal()
{
    bool hasCpu = false, hasGpu = false, hasFan = false;
    double cpuT = 0.0, gpuT = 0.0, maxT = 0.0;
    int fan = 0;

    QDir hw(QStringLiteral("/sys/class/hwmon"));
    const QStringList chips = hw.entryList({QStringLiteral("hwmon*")},
                                           QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &chip : chips) {
        const QString chipPath = hw.filePath(chip);
        const QString name = readText(chipPath + "/name", 64);

        QDir d(chipPath);
        const QStringList temps = d.entryList({QStringLiteral("temp*_input")}, QDir::Files);
        double chipMax = 0.0;
        for (const QString &t : temps) {
            double milli = 0.0;
            if (!readDouble(chipPath + "/" + t, milli))
                continue;
            const double c = milli / 1000.0;
            if (c <= 0.0 || c > 150.0)
                continue;
            chipMax = std::max(chipMax, c);
            maxT = std::max(maxT, c);
        }

        if (name == QLatin1String("coretemp") || name == QLatin1String("k10temp") ||
            name == QLatin1String("zenpower") || name == QLatin1String("cpu_thermal")) {
            if (chipMax > 0.0) {
                cpuT = std::max(cpuT, chipMax);
                hasCpu = true;
            }
        } else if (name == QLatin1String("amdgpu") || name == QLatin1String("nouveau") ||
                   name == QLatin1String("radeon")) {
            if (chipMax > 0.0) {
                gpuT = std::max(gpuT, chipMax);
                hasGpu = true;
            }
        }

        const QStringList fans = d.entryList({QStringLiteral("fan*_input")}, QDir::Files);
        for (const QString &fn : fans) {
            double rpm = 0.0;
            if (readDouble(chipPath + "/" + fn, rpm) && rpm > 0.0) {
                fan = std::max(fan, static_cast<int>(rpm));
                hasFan = true;
            }
        }
    }

    // Fallback: thermal zones (ACPI) for max temp when hwmon yielded nothing.
    if (maxT <= 0.0) {
        QDir tz(QStringLiteral("/sys/class/thermal"));
        const QStringList zones = tz.entryList({QStringLiteral("thermal_zone*")},
                                               QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &z : zones) {
            double milli = 0.0;
            if (readDouble(tz.filePath(z + "/temp"), milli)) {
                const double c = milli / 1000.0;
                if (c > 0.0 && c <= 150.0)
                    maxT = std::max(maxT, c);
            }
        }
    }

    m_hasCpuTemp = hasCpu;
    m_cpuTemp    = cpuT;
    m_hasGpuTemp = hasGpu;
    m_gpuTemp    = gpuT;
    m_hasFan     = hasFan;
    m_fanRpm     = fan;

    if (maxT <= 0.0)
        maxT = std::max(cpuT, gpuT);
    m_highestTemp = maxT;

    if (m_hasCpuTemp)
        pushHistory(m_tempHistory, m_cpuTemp);
    else if (m_highestTemp > 0.0)
        pushHistory(m_tempHistory, m_highestTemp);
}

// ── Storage ──────────────────────────────────────────────────────────────────
void SysmonController::sampleStorage()
{
    QStorageInfo root(QStringLiteral("/"));
    if (root.isValid() && root.bytesTotal() > 0) {
        const double totalGb = root.bytesTotal() / 1024.0 / 1024.0 / 1024.0;
        const double freeGb  = root.bytesAvailable() / 1024.0 / 1024.0 / 1024.0;
        m_diskTotalGb = totalGb;
        m_diskFreeGb  = freeGb;
        m_diskUsedGb  = totalGb - freeGb;
        m_diskUsedPct = totalGb > 0.0 ? clampPct(100.0 * m_diskUsedGb / totalGb) : 0.0;
        const QString dev = QFileInfo(root.device()).fileName(); // e.g. nvme0n1p2
        if (!dev.isEmpty())
            m_diskName = dev;
    }

    // Throughput from /proc/diskstats deltas for the root block device.
    const QString devName = m_diskName.isEmpty()
                                ? QString()
                                : QFileInfo(m_diskName).fileName();
    if (!devName.isEmpty()) {
        QFile ds(QStringLiteral("/proc/diskstats"));
        if (ds.open(QIODevice::ReadOnly | QIODevice::Text)) {
            const QList<QByteArray> lines = ds.readAll().split('\n');
            for (const QByteArray &l : lines) {
                const QList<QByteArray> p = l.simplified().split(' ');
                if (p.size() < 10 || p.at(2) != devName.toUtf8())
                    continue;
                const qulonglong sectorsRead  = p.at(5).toULongLong();
                const qulonglong sectorsWrite = p.at(9).toULongLong();
                if (m_diskSeeded) {
                    const qulonglong dr = sectorsRead  - m_prevDiskReadSectors;
                    const qulonglong dw = sectorsWrite - m_prevDiskWriteSectors;
                    m_diskReadMbs  = dr * 512.0 / 1024.0 / 1024.0;
                    m_diskWriteMbs = dw * 512.0 / 1024.0 / 1024.0;
                }
                m_prevDiskReadSectors  = sectorsRead;
                m_prevDiskWriteSectors = sectorsWrite;
                m_diskSeeded = true;
                break;
            }
        }
    }
}

// ── GPU ──────────────────────────────────────────────────────────────────────
void SysmonController::sampleGpu()
{
    QVector<GpuInfo> gpus;
    bool nvidiaSeen = false;

    // NVIDIA via nvidia-smi (index,name,util,mem.used,mem.total,temp)
    QProcess smi;
    smi.start(QStringLiteral("nvidia-smi"),
              {QStringLiteral("--query-gpu=index,name,utilization.gpu,memory.used,memory.total,temperature.gpu"),
               QStringLiteral("--format=csv,noheader,nounits")});
    if (smi.waitForFinished(1500) && smi.exitStatus() == QProcess::NormalExit && smi.exitCode() == 0) {
        const QString out = QString::fromUtf8(smi.readAllStandardOutput()).trimmed();
        for (const QString &line : out.split('\n', Qt::SkipEmptyParts)) {
            const QStringList cols = line.split(',');
            if (cols.size() < 6)
                continue;
            GpuInfo g;
            g.name    = cols.at(1).trimmed();
            g.vendor  = QStringLiteral("NVIDIA");
            g.util    = clampPct(cols.at(2).trimmed().toDouble());
            g.hasMem  = true;
            g.memUsedMb  = cols.at(3).trimmed().toLongLong();
            g.memTotalMb = cols.at(4).trimmed().toLongLong();
            bool ok = false;
            const double t = cols.at(5).trimmed().toDouble(&ok);
            if (ok && t > 0.0) {
                g.hasTemp = true;
                g.temp = t;
            }
            gpus.append(g);
            nvidiaSeen = true;
        }
    }

    // AMD / Intel via DRM sysfs
    QDir drm(QStringLiteral("/sys/class/drm"));
    const QStringList cards = drm.entryList({QStringLiteral("card[0-9]*")},
                                            QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &card : cards) {
        const QString devPath = drm.filePath(card) + "/device";
        if (!QFileInfo::exists(devPath))
            continue;

        double util = 0.0;
        const bool hasUtil = readDouble(devPath + "/gpu_busy_percent", util);

        const QString vendorHex = readText(devPath + "/vendor", 32);
        const bool isNvidia = vendorHex.endsWith(QLatin1String("10de"), Qt::CaseInsensitive);
        const bool isAmd    = vendorHex.endsWith(QLatin1String("1002"), Qt::CaseInsensitive);
        const bool isIntel  = vendorHex.endsWith(QLatin1String("8086"), Qt::CaseInsensitive);

        if (isNvidia && nvidiaSeen)
            continue; // already enumerated via nvidia-smi

        GpuInfo g;
        g.vendor = isAmd ? QStringLiteral("AMD")
                 : isIntel ? QStringLiteral("Intel")
                 : isNvidia ? QStringLiteral("NVIDIA")
                 : QStringLiteral("GPU");

        QString niceName = readText(devPath + "/product_name", 128);
        if (niceName.isEmpty())
            niceName = readText(devPath + "/uevent", 512);
        // Extract a human-ish label if product_name was absent.
        if (niceName.contains(QLatin1String("PCI_ID=")))
            niceName.clear();
        g.name = niceName.isEmpty() ? (g.vendor + QStringLiteral(" GPU")) : niceName;

        if (hasUtil)
            g.util = clampPct(util);

        double vramUsed = 0.0, vramTotal = 0.0;
        if (readDouble(devPath + "/mem_info_vram_used", vramUsed) &&
            readDouble(devPath + "/mem_info_vram_total", vramTotal) && vramTotal > 0.0) {
            g.hasMem     = true;
            g.memUsedMb  = static_cast<qint64>(vramUsed / 1024.0 / 1024.0);
            g.memTotalMb = static_cast<qint64>(vramTotal / 1024.0 / 1024.0);
        }

        QDir hwd(devPath + "/hwmon");
        const QStringList hm = hwd.entryList({QStringLiteral("hwmon*")},
                                             QDir::Dirs | QDir::NoDotAndDotDot);
        if (!hm.isEmpty()) {
            double milli = 0.0;
            if (readDouble(hwd.filePath(hm.first() + "/temp1_input"), milli) && milli > 0.0) {
                g.hasTemp = true;
                g.temp = milli / 1000.0;
            }
        }

        if (hasUtil || g.hasMem || g.hasTemp)
            gpus.append(g);
    }

    m_gpuModel->setGpus(gpus);

    // Fold the GPU temperature into the thermals view if hwmon missed it.
    if (!m_hasGpuTemp) {
        for (const GpuInfo &g : gpus) {
            if (g.hasTemp) {
                m_gpuTemp = g.temp;
                m_hasGpuTemp = true;
                m_highestTemp = std::max(m_highestTemp, g.temp);
                break;
            }
        }
    }
}

// ── THM v3 ───────────────────────────────────────────────────────────────────
void SysmonController::sampleThm()
{
    m_thm = ThmReader::read();

    // THM is authoritative for the pressure label when present.
    if (m_thm.available && !m_thm.pressureLevel.isEmpty())
        m_pressureLevel = m_thm.pressureLevel.toUpper();

    pushHistory(m_thmPressureHistory, m_memPressure);
}
