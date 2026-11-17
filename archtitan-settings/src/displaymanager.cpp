#include "displaymanager.h"
#include <QProcess>
#include <QFile>
#include <QDir>
#include <QTextStream>
#include <QTimer>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>

DisplayManager::DisplayManager(QObject *parent) : QObject(parent) {
    m_resolution = QStringLiteral("1920x1080");
    m_refreshRate = 60.0;
    m_scaleFactor = 1.0;
    m_brightness = 80;

    // Fast sysfs read for brightness
    QFile bf(findBacklightPath() + "/brightness");
    QFile mf(findBacklightPath() + "/max_brightness");
    if (bf.open(QIODevice::ReadOnly) && mf.open(QIODevice::ReadOnly)) {
        int cur = QTextStream(&bf).readLine().toInt();
        int max = QTextStream(&mf).readLine().toInt();
        if (max > 0) m_brightness = cur * 100 / max;
    }

    // Defer hyprctl query so constructor finishes in < 1ms
    QTimer::singleShot(50, this, [this]() {
        QProcess p;
        p.start("bash", {"-c", "hyprctl monitors -j 2>/dev/null"});
        if (p.waitForFinished(500)) {
            const QByteArray out = p.readAllStandardOutput().trimmed();
            const QJsonDocument doc = QJsonDocument::fromJson(out);
            if (doc.isArray() && !doc.array().isEmpty()) {
                const QJsonObject mon = doc.array().first().toObject();
                int w = mon.value("width").toInt(1920);
                int h = mon.value("height").toInt(1080);
                m_resolution = QString("%1x%2").arg(w).arg(h);
                emit resolutionChanged();

                double rr = mon.value("refreshRate").toDouble(60.0);
                if (rr >= 1.0) {
                    m_refreshRate = rr;
                    emit refreshRateChanged();
                }

                double s = mon.value("scale").toDouble(1.0);
                if (s >= 0.5 && s <= 3.0) {
                    m_scaleFactor = s;
                    emit scaleFactorChanged();
                }
            }
        }
        m_initialized = true;
    });
}

QString DisplayManager::findBacklightPath() const {
    QDir dir("/sys/class/backlight");
    QStringList entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    if (!entries.isEmpty()) return "/sys/class/backlight/" + entries.first();
    return "/sys/class/backlight/intel_backlight";
}

int DisplayManager::maxBrightness() const {
    QFile f(findBacklightPath() + "/max_brightness");
    if (f.open(QIODevice::ReadOnly)) return QTextStream(&f).readLine().toInt();
    return 255;
}

int DisplayManager::brightness() const { return m_brightness; }
void DisplayManager::setBrightness(int v) {
    v = qBound(0, v, 100);
    if (m_brightness == v) return;
    m_brightness = v;
    // Try brightnessctl first, fall back to xrandr/wlr-randr
    int raw = v * maxBrightness() / 100;
    QProcess::startDetached("bash", {"-c", QString("brightnessctl set %1 2>/dev/null || wlr-randr --output $(wlr-randr | head -1 | awk '{print $1}') --brightness %2").arg(raw).arg(v / 100.0)});
    emit brightnessChanged();
}

int DisplayManager::nightLightTemp() const { return m_nightLightTemp; }
void DisplayManager::setNightLightTemp(int v) {
    v = qBound(1000, v, 6500);
    if (m_nightLightTemp == v) return;
    m_nightLightTemp = v;
    if (m_nightLightEnabled)
        QProcess::startDetached("wlsunset", {"-T", QString::number(v)});
    emit nightLightTempChanged();
}

bool DisplayManager::nightLightEnabled() const { return m_nightLightEnabled; }
void DisplayManager::setNightLightEnabled(bool v) {
    if (m_nightLightEnabled == v) return;
    m_nightLightEnabled = v;
    if (v) QProcess::startDetached("wlsunset", {"-T", QString::number(m_nightLightTemp)});
    else   QProcess::startDetached("pkill", {"wlsunset"});
    emit nightLightEnabledChanged();
}

QString DisplayManager::resolution() const { return m_resolution; }
double DisplayManager::refreshRate() const { return m_refreshRate; }
double DisplayManager::scaleFactor() const { return m_scaleFactor; }
void DisplayManager::setScaleFactor(double v) {
    if (qFuzzyCompare(m_scaleFactor, v)) return;
    m_scaleFactor = v;
    // Only apply via hyprctl when user explicitly changes the value,
    // not during the initial QML binding on startup.
    if (m_initialized) {
        QProcess::startDetached("bash", {"-c", QString("hyprctl keyword monitor ,preferred,auto,%1").arg(v)});
    }
    emit scaleFactorChanged();
}
