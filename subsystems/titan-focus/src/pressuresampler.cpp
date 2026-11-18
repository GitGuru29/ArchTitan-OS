#include "pressuresampler.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>

#include <algorithm>
#include <cstring>
#include <dirent.h>
#include <fstream>
#include <string>

namespace titan::focus {

namespace {

double readPsiMemAvg10() {
    std::ifstream f("/proc/pressure/memory");
    if (!f.is_open()) return 0.0;

    std::string line;
    while (std::getline(f, line)) {
        if (line.rfind("some ", 0) == 0) {
            const size_t pos = line.find("avg10=");
            if (pos != std::string::npos) {
                try {
                    return std::stod(line.substr(pos + 6));
                } catch (...) {
                    return 0.0;
                }
            }
        }
    }
    return 0.0;
}

double readMemUsedPct() {
    std::ifstream f("/proc/meminfo");
    if (!f.is_open()) return 0.0;

    double totalKb = 0.0;
    double availKb = 0.0;
    std::string key;
    double val = 0.0;
    std::string unit;

    while (f >> key >> val) {
        std::getline(f, unit);
        if (key == "MemTotal:") totalKb = val;
        else if (key == "MemAvailable:") availKb = val;
        if (totalKb > 0.0 && availKb > 0.0) break;
    }

    if (totalKb <= 0.0) return 0.0;
    return std::clamp(((totalKb - availKb) / totalKb) * 100.0, 0.0, 100.0);
}

double readCpuTempC() {
    double maxTemp = 0.0;
    DIR *dir = ::opendir("/sys/class/thermal");
    if (!dir) return 0.0;

    while (struct dirent *ent = ::readdir(dir)) {
        if (std::strncmp(ent->d_name, "thermal_zone", 12) != 0) continue;

        const std::string base = std::string("/sys/class/thermal/") + ent->d_name;
        std::ifstream tf(base + "/type");
        std::string type;
        if (tf.is_open()) std::getline(tf, type);

        // Prefer CPU / x86_pkg_temp / k10temp / acpitz zones
        const bool likelyCpu =
            type.find("x86_pkg") != std::string::npos ||
            type.find("TCPU") != std::string::npos ||
            type.find("cpu") != std::string::npos ||
            type.find("CPU") != std::string::npos ||
            type.find("acpitz") != std::string::npos ||
            type.find("k10temp") != std::string::npos ||
            type.find("coretemp") != std::string::npos;

        if (!likelyCpu && !type.empty()) continue;

        std::ifstream vf(base + "/temp");
        long milliC = 0;
        if (vf >> milliC && milliC > 0 && milliC < 150000) {
            maxTemp = std::max(maxTemp, static_cast<double>(milliC) / 1000.0);
        }
    }
    ::closedir(dir);
    return maxTemp;
}

void enrichFromThmState(PressureSample &out) {
    QFile f(QStringLiteral("/run/archtitan/thm-state.json"));
    if (!f.open(QIODevice::ReadOnly)) return;

    const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject()) return;

    const QJsonObject obj = doc.object();
    const double thmTemp = obj.value(QStringLiteral("cpu_temp_c")).toDouble(0.0);
    if (thmTemp > 0.0 && out.cpuTempC <= 0.0) {
        out.cpuTempC = thmTemp;
    }
    const double thmPsi = obj.value(QStringLiteral("mem_psi_some10")).toDouble(0.0);
    if (thmPsi > 0.0 && out.psiMemAvg10 <= 0.0) {
        out.psiMemAvg10 = thmPsi;
    }
}

} // namespace

PressureSample PressureSampler::sample() {
    PressureSample s;
    s.psiMemAvg10 = readPsiMemAvg10();
    s.memUsedPct  = readMemUsedPct();
    s.cpuTempC    = readCpuTempC();
    enrichFromThmState(s);
    return s;
}

} // namespace titan::focus
