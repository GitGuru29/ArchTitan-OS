#include "systemcontroller.h"
#include <QFile>
#include <QTextStream>
#include <QProcess>
#include <QDir>
#include <QDebug>
#include <QSettings>
#include <QStandardPaths>
#include <QFileSystemWatcher>
#include <QJsonDocument>
#include <QJsonObject>
#include <unistd.h>
#include <pwd.h>

QString SystemController::userName() const
{
    // 1. Check user override in config.ini
    QString configDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings cfg(configDir + "/titan-quicksettings/config.ini", QSettings::IniFormat);
    QString customName = cfg.value("user/name").toString().trimmed();
    if (!customName.isEmpty()) {
        return customName;
    }

    // 2. Check passwd GECOS full name or login username
    struct passwd *pw = getpwuid(getuid());
    if (pw) {
        if (pw->pw_gecos && strlen(pw->pw_gecos) > 0) {
            QString gecos = QString::fromUtf8(pw->pw_gecos).split(',').first().trimmed();
            if (!gecos.isEmpty()) {
                return gecos.split(' ').first();
            }
        }
        if (pw->pw_name && strlen(pw->pw_name) > 0) {
            QString name = QString::fromUtf8(pw->pw_name).trimmed();
            if (!name.isEmpty()) {
                name[0] = name[0].toUpper();
                return name;
            }
        }
    }

    // 3. Check USER environment variable
    QByteArray userEnv = qgetenv("USER");
    if (!userEnv.isEmpty()) {
        QString name = QString::fromUtf8(userEnv).trimmed();
        if (!name.isEmpty()) {
            name[0] = name[0].toUpper();
            return name;
        }
    }

    return QStringLiteral("User");
}

SystemController::SystemController(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_glassApplyTimer(new QTimer(this))
    , m_themeWatcher(new QFileSystemWatcher(this))
{
    m_glassApplyTimer->setSingleShot(true);
    connect(m_glassApplyTimer, &QTimer::timeout, this, [this]() {
        QProcess::startDetached("titan-theme", {"glass", QString::number(m_glassOpacity), "--quiet"});
    });
    updateUptime();
    updateDate();
    updateBrightness();
    updateTheme();
    updateScreenRecording();
    updateAirplaneMode();
    updateStats();

    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    int savedIconSize = settings.value("quicksettings/globalIconSize", 48).toInt();
    if (savedIconSize >= 30 && savedIconSize <= 80) {
        m_globalIconSize = savedIconSize;
    }

    QString themeFile = cfgDir + "/archtitan/theme.json";
    if (QFile::exists(themeFile)) {
        m_themeWatcher->addPath(themeFile);
    } else {
        QDir().mkpath(cfgDir + "/archtitan");
        m_themeWatcher->addPath(cfgDir + "/archtitan");
    }

    auto onThemeChanged = [this, themeFile](const QString &) {
        updateTheme();
        if (!m_themeWatcher->files().contains(themeFile) && QFile::exists(themeFile)) {
            m_themeWatcher->addPath(themeFile);
        }
    };
    connect(m_themeWatcher, &QFileSystemWatcher::fileChanged, this, onThemeChanged);
    connect(m_themeWatcher, &QFileSystemWatcher::directoryChanged, this, onThemeChanged);

    connect(m_timer, &QTimer::timeout, this, [this]() {
        updateUptime();
        updateDate();
        updateBrightness();
        updateTheme();
        updateScreenRecording();
        updateAirplaneMode();
        updateStats();
    });
    m_timer->start(2000); // Check every 2s
}

void SystemController::updateUptime()
{
    QFile file("/proc/uptime");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        double uptimeSeconds = 0;
        in >> uptimeSeconds;
        file.close();

        int totalMinutes = static_cast<int>(uptimeSeconds) / 60;
        int hours = totalMinutes / 60;
        int minutes = totalMinutes % 60;

        QString formatted;
        if (hours > 0) {
            formatted = QString("Up %1h %2m").arg(hours).arg(minutes);
        } else {
            formatted = QString("Up %1m").arg(minutes);
        }

        if (formatted != m_uptime) {
            m_uptime = formatted;
            emit uptimeChanged();
        }
    }
}

void SystemController::updateDate()
{
    QDateTime now = QDateTime::currentDateTime();
    QString formatted = now.toString("dddd, MMMM d") + " • 0 tasks";
    if (formatted != m_currentDateString) {
        m_currentDateString = formatted;
        emit currentDateStringChanged();
    }
}

void SystemController::updateBrightness()
{
    // Aggregate average of all ACPI backlight devices (fallback if the
    // brightnessctl helper is unavailable at invoke time).
    QDir dir("/sys/class/backlight");
    const QStringList entries = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    int acc = 0;
    int count = 0;
    for (const QString &name : entries) {
        QFile cur(dir.filePath(name) + "/brightness");
        QFile max(dir.filePath(name) + "/max_brightness");
        if (!cur.open(QIODevice::ReadOnly | QIODevice::Text) ||
            !max.open(QIODevice::ReadOnly | QIODevice::Text)) {
            cur.close();
            max.close();
            continue;
        }
        const int c = static_cast<int>(cur.readAll().trimmed().toDouble());
        const int m = static_cast<int>(max.readAll().trimmed().toDouble());
        cur.close();
        max.close();
        if (m > 0) {
            acc += static_cast<int>(100.0 * c / m + 0.5);
            ++count;
        }
    }
    if (count > 0) {
        int avg = acc / count;
        if (avg != m_brightness) {
            m_brightness = avg;
            emit brightnessChanged();
        }
    }
}

void SystemController::setBrightness(int value)
{
    value = qBound(0, value, 100);
    if (value != m_brightness) {
        m_brightness = value;
        emit brightnessChanged();
    }
    QProcess::startDetached("brightnessctl", {"set", QString("%1%").arg(value)});
}

void SystemController::setGlassOpacity(int value)
{
    value = qBound(10, value, 95);
    if (value == m_glassOpacity)
        return;

    m_glassOpacity = value;
    emit glassOpacityChanged();

    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QString themeFile = cfgDir + "/archtitan/theme.json";
    QJsonObject rootObj;

    QFile readFile(themeFile);
    if (readFile.open(QIODevice::ReadOnly)) {
        rootObj = QJsonDocument::fromJson(readFile.readAll()).object();
        readFile.close();
    }

    rootObj["glassOpacity"] = std::round((value / 100.0) * 100.0) / 100.0;

    QFile writeFile(themeFile);
    if (writeFile.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        writeFile.write(QJsonDocument(rootObj).toJson(QJsonDocument::Indented));
        writeFile.close();
    }

    if (m_glassApplyTimer) {
        m_glassApplyTimer->start(350);
    }
}

void SystemController::refresh()
{
    updateUptime();
    updateDate();
    updateBrightness();
    updateTheme();
    updateScreenRecording();
    updateAirplaneMode();
    updateStats();
}

void SystemController::setCaffeineActive(bool active)
{
    if (m_caffeineActive != active) {
        m_caffeineActive = active;
        emit caffeineActiveChanged();
    }
    if (active) {
        QProcess::startDetached("systemd-inhibit", {"--what=idle:sleep", "--who=ArchTitan", "--why=Caffeine", "sleep", "infinity"});
    } else {
        QProcess::startDetached("pkill", {"-f", "systemd-inhibit.*ArchTitan"});
    }
}

void SystemController::setThemeDark(bool dark)
{
    if (m_themeDark != dark) {
        m_themeDark = dark;
        emit themeDarkChanged();
    }
    m_themeSwitching = true;
    m_themeSwitchingTime = QDateTime::currentMSecsSinceEpoch();

    // Switch OS theme via ArchTitan central theme engine
    QProcess::startDetached("titan-theme", {"mode", dark ? "dark" : "light"});

    QString scheme = dark ? "prefer-dark" : "prefer-light";
    QString gtkTheme = dark ? "adw-gtk3-dark" : "adw-gtk3";
    QProcess::startDetached("gsettings", {"set", "org.gnome.desktop.interface", "color-scheme", scheme});
    QProcess::startDetached("gsettings", {"set", "org.gnome.desktop.interface", "gtk-theme", gtkTheme});

    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("appearance/colorTheme", dark ? "Dark" : "Light");
    settings.sync();
}

void SystemController::updateTheme()
{
    // If a theme switch is actively in flight, avoid stale reads / race conditions reverting the toggle
    if (m_themeSwitching) {
        if (QDateTime::currentMSecsSinceEpoch() - m_themeSwitchingTime < 4000) {
            QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
            QFile file(cfgDir + "/archtitan/theme.json");
            if (file.open(QIODevice::ReadOnly)) {
                QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
                if (doc.isObject()) {
                    bool dark = doc.object().value("isDark").toBool(true);
                    if (dark == m_themeDark) {
                        m_themeSwitching = false; // Target theme verified on disk
                    }
                    if (doc.object().contains("glassOpacity")) {
                        int g = static_cast<int>(std::round(doc.object().value("glassOpacity").toDouble(0.35) * 100.0));
                        g = qBound(10, g, 95);
                        if (m_glassOpacity != g) {
                            m_glassOpacity = g;
                            emit glassOpacityChanged();
                        }
                    }
                }
            }
            return;
        } else {
            m_themeSwitching = false; // Transition grace period elapsed
        }
    }

    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QFile file(cfgDir + "/archtitan/theme.json");
    if (file.open(QIODevice::ReadOnly)) {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isObject()) {
            bool dark = doc.object().value("isDark").toBool(true);
            if (m_themeDark != dark) {
                m_themeDark = dark;
                emit themeDarkChanged();
            }
            if (doc.object().contains("glassOpacity")) {
                int g = static_cast<int>(std::round(doc.object().value("glassOpacity").toDouble(0.35) * 100.0));
                g = qBound(10, g, 95);
                if (m_glassOpacity != g) {
                    m_glassOpacity = g;
                    emit glassOpacityChanged();
                }
            }
            return;
        }
    }

    QProcess proc;
    proc.start("gsettings", {"get", "org.gnome.desktop.interface", "color-scheme"});
    if (proc.waitForFinished(300)) {
        QString out = proc.readAllStandardOutput().trimmed();
        if (out.contains("prefer-light")) {
            if (m_themeDark != false) {
                m_themeDark = false;
                emit themeDarkChanged();
            }
        } else if (out.contains("prefer-dark")) {
            if (m_themeDark != true) {
                m_themeDark = true;
                emit themeDarkChanged();
            }
        }
    }
}

void SystemController::setVisualizerActive(bool active)
{
    if (m_visualizerActive != active) {
        m_visualizerActive = active;
        emit visualizerActiveChanged();
    }
}

void SystemController::setGameModeActive(bool active)
{
    if (m_gameModeActive != active) {
        m_gameModeActive = active;
        emit gameModeActiveChanged();
    }
    if (active) {
        QProcess::startDetached("hyprctl", {
            "--batch",
            "keyword animations:enabled 0; keyword decoration:drop_shadow 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 0"
        });
    } else {
        QProcess::startDetached("hyprctl", {"reload"});
    }
}

void SystemController::setVpnActive(bool active)
{
    if (m_vpnActive != active) {
        m_vpnActive = active;
        emit vpnActiveChanged();
    }
}

void SystemController::toggleScreenRecording()
{
    if (m_screenRecordingActive) {
        QProcess::startDetached("killall", {"-SIGINT", "wf-recorder"});
        m_screenRecordingActive = false;
        emit screenRecordingActiveChanged();

        QProcess::startDetached("notify-send", {
            "-a", "ArchTitan",
            "-i", "media-record",
            "Screen Recording Saved",
            "Video saved to ~/Videos"
        });
    } else {
        QString videoDir = QDir::homePath() + "/Videos";
        QDir().mkpath(videoDir);

        QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss");
        QString filename = videoDir + "/recording_" + timestamp + ".mp4";

        QProcess::startDetached("wf-recorder", {"-f", filename});
        m_screenRecordingActive = true;
        emit screenRecordingActiveChanged();

        QProcess::startDetached("notify-send", {
            "-a", "ArchTitan",
            "-i", "media-record",
            "Screen Recording Started",
            "Click Screen Record again to stop and save"
        });
    }
}

void SystemController::updateScreenRecording()
{
    QProcess proc;
    proc.start("pgrep", {"-x", "wf-recorder"});
    if (proc.waitForFinished(200)) {
        bool active = (proc.exitCode() == 0);
        if (active != m_screenRecordingActive) {
            m_screenRecordingActive = active;
            emit screenRecordingActiveChanged();
        }
    }
}

void SystemController::setAirplaneMode(bool active)
{
    if (m_airplaneMode != active) {
        m_airplaneMode = active;
        emit airplaneModeChanged();
    }
    if (active) {
        QProcess::startDetached("rfkill", {"block", "all"});
    } else {
        QProcess::startDetached("rfkill", {"unblock", "all"});
    }
}

void SystemController::toggleAirplaneMode()
{
    setAirplaneMode(!m_airplaneMode);
}

void SystemController::updateAirplaneMode()
{
    QProcess proc;
    proc.start("bash", {"-c", "rfkill list | grep -i 'Soft blocked: yes'"});
    if (proc.waitForFinished(300)) {
        QString out = proc.readAllStandardOutput().trimmed();
        bool active = !out.isEmpty();
        if (active != m_airplaneMode) {
            m_airplaneMode = active;
            emit airplaneModeChanged();
        }
    }
}

void SystemController::openClipboard()
{
    QProcess::startDetached("titan-spotlight", {"--clipboard"});
}

void SystemController::openSettings()
{
    // Launch ArchTitan Settings with graceful fallbacks
    QProcess::startDetached("bash", {"-c", "archtitan-settings || gnome-control-center || systemsettings || xfce4-settings-manager"});
}

void SystemController::openPowerMenu()
{
    QProcess::startDetached("titan-powermenu", {});
}

void SystemController::lockSession()
{
    QProcess::startDetached("bash", {"-c", "pidof hyprlock || hyprlock || swaylock -f -c 11111b || loginctl lock-session"});
}

void SystemController::suspendSession()
{
    QProcess::startDetached("bash", {"-c", "systemctl suspend -i || loginctl suspend || sudo systemctl suspend -i"});
}

void SystemController::logoutSession()
{
    // Gracefully exit Hyprland session and return to SDDM login screen
    QProcess::startDetached("bash", {"-c", "hyprctl dispatch exit || pkill -u \"$USER\" -x Hyprland || killall -u \"$USER\" Hyprland || loginctl terminate-session \"${XDG_SESSION_ID}\" || loginctl terminate-user \"$USER\""});
}

void SystemController::rebootSystem()
{
    QProcess::startDetached("bash", {"-c", "systemctl reboot -i || loginctl reboot || sudo reboot || reboot"});
}

void SystemController::poweroffSystem()
{
    QProcess::startDetached("bash", {"-c", "systemctl poweroff -i || loginctl poweroff || sudo poweroff || poweroff"});
}

void SystemController::takeScreenshot()
{
    QProcess::startDetached("bash", {"-c", "grim -g \"$(slurp)\" - | wl-copy"});
}

void SystemController::pickColor()
{
    QProcess::startDetached("hyprpicker", {"-a"});
}

void SystemController::toggleVirtualKeyboard()
{
    QProcess::startDetached("bash", {"-c", "pkill wvkbd || wvkbd-mobintl &"});
}

void SystemController::openMediaWidget()
{
    QProcess::startDetached("titan-bar-media", {});
}

bool SystemController::getTileVisible(const QString &tileKey, bool defaultVal) const
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    return settings.value("quicksettings/" + tileKey, defaultVal).toBool();
}

void SystemController::setTileVisible(const QString &tileKey, bool visible)
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("quicksettings/" + tileKey, visible);
    settings.sync();
    m_tileVisibilityRevision++;
    emit tileVisibilityChanged();
}

void SystemController::resetTileVisibility()
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.remove("quicksettings");
    settings.sync();
    m_tileVisibilityRevision++;
    emit tileVisibilityChanged();
}

QStringList SystemController::getActionOrder() const
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    const QStringList defaultOrder = {
        "focus", "dark", "night", "mic",
        "caffeine", "capture", "record", "colorPick",
        "gameMode", "clipboard", "virtualInput", "airplane"
    };
    QVariant val = settings.value("quicksettings/actionOrder");
    if (!val.isValid()) {
        val = settings.value("quicksettings/actionorder");
    }
    if (!val.isValid()) {
        return defaultOrder;
    }

    QStringList rawList;
    if (val.typeId() == QMetaType::QStringList) {
        rawList = val.toStringList();
        // If single string item contains commas, split it
        if (rawList.size() == 1 && rawList.first().contains(',')) {
            rawList = rawList.first().split(',', Qt::SkipEmptyParts);
        }
    } else {
        rawList = val.toString().split(',', Qt::SkipEmptyParts);
    }

    QStringList result;
    for (QString k : rawList) {
        k = k.remove('"').remove('\'').trimmed();
        if (defaultOrder.contains(k) && !result.contains(k)) {
            result.append(k);
        }
    }

    for (const QString &key : defaultOrder) {
        if (!result.contains(key)) {
            result.append(key);
        }
    }
    return result;
}

void SystemController::setActionOrder(const QStringList &order)
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("quicksettings/actionOrder", order.join(","));
    settings.sync();
    m_tileVisibilityRevision++;
    emit tileVisibilityChanged();
}

void SystemController::moveActionOrder(int fromIndex, int toIndex)
{
    QStringList order = getActionOrder();
    if (fromIndex < 0 || fromIndex >= order.size() || toIndex < 0 || toIndex >= order.size() || fromIndex == toIndex) {
        return;
    }
    order.move(fromIndex, toIndex);
    setActionOrder(order);
}

void SystemController::setGlobalIconSize(int size)
{
    size = qBound(32, size, 72);
    if (m_globalIconSize != size) {
        m_globalIconSize = size;
        QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
        QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
        settings.setValue("quicksettings/globalIconSize", m_globalIconSize);
        settings.sync();
        m_tileVisibilityRevision++;
        emit iconSizesChanged();
        emit tileVisibilityChanged();
    }
}

QString SystemController::getActionSize(const QString &key) const
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    return settings.value("quicksettings/actionSize_" + key, "default").toString();
}

void SystemController::setActionSize(const QString &key, const QString &size)
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("quicksettings/actionSize_" + key, size);
    settings.sync();
    m_tileVisibilityRevision++;
    emit iconSizesChanged();
    emit tileVisibilityChanged();
}

int SystemController::getEffectiveActionSize(const QString &key) const
{
    QString sz = getActionSize(key).toLower();
    if (sz == "small" || sz == "s") return 38;
    if (sz == "medium" || sz == "m") return 48;
    if (sz == "large" || sz == "l") return 56;
    if (sz == "huge" || sz == "xl") return 64;
    bool ok = false;
    int n = sz.toInt(&ok);
    if (ok && n >= 30 && n <= 80) return n;
    return m_globalIconSize;
}

void SystemController::cycleActionSize(const QString &key)
{
    QString cur = getActionSize(key).toLower();
    QString next = "default";
    if (cur == "default") next = "large";
    else if (cur == "large") next = "huge";
    else if (cur == "huge") next = "small";
    else if (cur == "small") next = "medium";
    else if (cur == "medium") next = "default";
    setActionSize(key, next);
}

void SystemController::updateStats()
{
    bool changed = false;

    // 1. CPU Usage via /proc/stat
    QFile statFile("/proc/stat");
    if (statFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray line = statFile.readLine();
        statFile.close();
        if (line.startsWith("cpu ")) {
            QList<QByteArray> parts = line.simplified().split(' ');
            if (parts.size() >= 5) {
                unsigned long long user = parts[1].toULongLong();
                unsigned long long nice = parts[2].toULongLong();
                unsigned long long system = parts[3].toULongLong();
                unsigned long long idle = parts[4].toULongLong();
                unsigned long long iowait = (parts.size() > 5) ? parts[5].toULongLong() : 0;
                unsigned long long irq = (parts.size() > 6) ? parts[6].toULongLong() : 0;
                unsigned long long softirq = (parts.size() > 7) ? parts[7].toULongLong() : 0;
                unsigned long long steal = (parts.size() > 8) ? parts[8].toULongLong() : 0;

                unsigned long long totalIdle = idle + iowait;
                unsigned long long total = user + nice + system + totalIdle + irq + softirq + steal;

                if (m_prevCpuTotal > 0 && total > m_prevCpuTotal) {
                    unsigned long long diffTotal = total - m_prevCpuTotal;
                    unsigned long long diffIdle = totalIdle - m_prevCpuIdle;
                    if (diffTotal > 0) {
                        int usage = static_cast<int>(100 * (diffTotal - diffIdle) / diffTotal);
                        usage = qBound(0, usage, 100);
                        if (usage != m_cpuUsage) {
                            m_cpuUsage = usage;
                            changed = true;
                        }
                    }
                }
                m_prevCpuIdle = totalIdle;
                m_prevCpuTotal = total;
            }
        }
    }

    // 2. RAM Usage via /proc/meminfo
    QFile memFile("/proc/meminfo");
    if (memFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        unsigned long long memTotal = 0;
        unsigned long long memAvailable = 0;
        const QByteArray all = memFile.readAll();
        memFile.close();
        for (const QByteArray &line : all.split('\n')) {
            if (line.startsWith("MemTotal:")) {
                auto parts = line.simplified().split(' ');
                if (parts.size() >= 2) memTotal = parts[1].toULongLong();
            } else if (line.startsWith("MemAvailable:")) {
                auto parts = line.simplified().split(' ');
                if (parts.size() >= 2) {
                    memAvailable = parts[1].toULongLong();
                    break;
                }
            }
        }
        if (memTotal > 0) {
            int ram = static_cast<int>(100 * (memTotal - memAvailable) / memTotal);
            ram = qBound(0, ram, 100);
            if (ram != m_ramUsage) {
                m_ramUsage = ram;
                changed = true;
            }
        }
    }

    // 3. Battery via /sys/class/power_supply/
    QDir powerDir("/sys/class/power_supply");
    QStringList bats = powerDir.entryList({"BAT*", "battery*"}, QDir::Dirs | QDir::NoDotAndDotDot);
    if (!bats.isEmpty()) {
        if (!m_hasBattery) {
            m_hasBattery = true;
            changed = true;
        }
        QString batPath = powerDir.absoluteFilePath(bats.first());
        QFile capFile(batPath + "/capacity");
        if (capFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            int cap = capFile.readAll().trimmed().toInt();
            cap = qBound(0, cap, 100);
            capFile.close();
            if (cap != m_batteryPercent) {
                m_batteryPercent = cap;
                changed = true;
            }
        }
        QFile statusFile(batPath + "/status");
        if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QString st = QString::fromUtf8(statusFile.readAll()).trimmed();
            statusFile.close();
            bool charging = (st == "Charging");
            if (charging != m_batteryCharging) {
                m_batteryCharging = charging;
                changed = true;
            }
        }
    } else {
        if (m_hasBattery) {
            m_hasBattery = false;
            changed = true;
        }
    }

    if (changed) {
        emit statsChanged();
    }
}

QStringList SystemController::getSectionOrder() const
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    const QStringList defaultOrder = {
        "topRow", "sliders", "actions", "liquidGlass"
    };
    QVariant val = settings.value("quicksettings/sectionOrder");
    if (!val.isValid()) {
        val = settings.value("quicksettings/sectionorder");
    }
    if (!val.isValid()) {
        return defaultOrder;
    }

    QStringList rawList;
    if (val.typeId() == QMetaType::QStringList) {
        rawList = val.toStringList();
        if (rawList.size() == 1 && rawList.first().contains(',')) {
            rawList = rawList.first().split(',', Qt::SkipEmptyParts);
        }
    } else {
        rawList = val.toString().split(',', Qt::SkipEmptyParts);
    }

    QStringList result;
    const QStringList validSections = {
        "topRow", "connectivity", "music", "sliders", "actions", "liquidGlass", "performance", "battery"
    };
    for (QString s : rawList) {
        s = s.remove('"').remove('\'').trimmed();
        if (validSections.contains(s) && !result.contains(s)) {
            result.append(s);
        }
    }

    if (result.isEmpty()) {
        return defaultOrder;
    }
    return result;
}

void SystemController::setSectionOrder(const QStringList &order)
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("quicksettings/sectionOrder", order.join(","));
    settings.sync();
    m_tileVisibilityRevision++;
    emit tileVisibilityChanged();
}

void SystemController::moveSectionOrder(int fromIndex, int toIndex)
{
    QStringList order = getSectionOrder();
    if (fromIndex < 0 || fromIndex >= order.size() || toIndex < 0 || toIndex >= order.size() || fromIndex == toIndex) {
        return;
    }
    order.move(fromIndex, toIndex);
    setSectionOrder(order);
}

void SystemController::addSection(const QString &sectionKey)
{
    QStringList order = getSectionOrder();
    if (!order.contains(sectionKey)) {
        order.append(sectionKey);
        setSectionOrder(order);
    }
}

void SystemController::removeSection(const QString &sectionKey)
{
    QStringList order = getSectionOrder();
    if (order.contains(sectionKey)) {
        order.removeAll(sectionKey);
        setSectionOrder(order);
    }
}

void SystemController::splitTopRow()
{
    QStringList order = getSectionOrder();
    int idx = order.indexOf("topRow");
    if (idx != -1) {
        order.removeAt(idx);
        order.insert(idx, "connectivity");
        order.append("music"); // Moves music player to bottom
        setSectionOrder(order);
        setWidgetSize("music", "expanded");
    }
}

void SystemController::mergeTopRow()
{
    QStringList order = getSectionOrder();
    order.removeAll("connectivity");
    order.removeAll("music");
    order.prepend("topRow");
    setSectionOrder(order);
    setWidgetSize("music", "compact");
}

QString SystemController::getWidgetSize(const QString &widgetKey, const QString &defaultSize) const
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    return settings.value("quicksettings/widgetSize_" + widgetKey, defaultSize).toString();
}

void SystemController::setWidgetSize(const QString &widgetKey, const QString &size)
{
    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
    QSettings settings(cfgDir + "/archtitan/settings.ini", QSettings::IniFormat);
    settings.setValue("quicksettings/widgetSize_" + widgetKey, size);
    settings.sync();
    m_tileVisibilityRevision++;
    emit tileVisibilityChanged();
}

void SystemController::toggleWidgetSize(const QString &widgetKey)
{
    QString cur = getWidgetSize(widgetKey, "compact");
    setWidgetSize(widgetKey, (cur == "compact") ? "expanded" : "compact");
}
