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
    , m_themeWatcher(new QFileSystemWatcher(this))
{
    updateUptime();
    updateDate();
    updateBrightness();
    updateTheme();
    updateScreenRecording();
    updateAirplaneMode();

    QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation);
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
    });
    m_timer->start(3000); // Check every 3s
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

void SystemController::refresh()
{
    updateUptime();
    updateDate();
    updateBrightness();
    updateTheme();
    updateScreenRecording();
    updateAirplaneMode();
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
    QProcess::startDetached("bash", {"-c", "cliphist list | rofi -dmenu -p 'Clipboard' | cliphist decode | wl-copy"});
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
