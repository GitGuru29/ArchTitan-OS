#include "tourcontroller.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QSettings>
#include <QStandardPaths>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QDebug>
#include <QTextStream>

TourController::TourController(QObject *parent)
    : QObject(parent)
{
    m_isLiveMode = QFile::exists("/run/archiso");
    detectHardwareInfo();
    loadPreferences();
}

void TourController::setSoundFxEnabled(bool enabled)
{
    if (m_soundFxEnabled != enabled) {
        m_soundFxEnabled = enabled;
        emit soundFxEnabledChanged();
        savePreferences();
    }
}

void TourController::setShowOnStartup(bool show)
{
    if (m_showOnStartup != show) {
        m_showOnStartup = show;
        emit showOnStartupChanged();
        savePreferences();
    }
}

void TourController::setActiveProfile(const QString &profile)
{
    if (m_activeProfile != profile) {
        m_activeProfile = profile;
        emit activeProfileChanged();
        setPowerProfile(profile);
    }
}

void TourController::playSound(const QString &soundId)
{
    if (!m_soundFxEnabled) return;

    QString soundFile = "/usr/share/sounds/ocean/stereo/button-pressed.oga";
    if (soundId == "click" || soundId == "tap") {
        soundFile = "/usr/share/sounds/ocean/stereo/button-pressed.oga";
    } else if (soundId == "chime" || soundId == "success") {
        soundFile = "/usr/share/sounds/ocean/stereo/bell-window-system.oga";
    } else if (soundId == "launch" || soundId == "warp") {
        soundFile = "/usr/share/sounds/ocean/stereo/desktop-login.oga";
    }

    if (QFile::exists(soundFile)) {
        QProcess::startDetached("pw-play", QStringList() << soundFile);
    } else {
        QProcess::startDetached("canberra-gtk-play", QStringList() << "-i" << "button-pressed");
    }
}

void TourController::launchInstaller()
{
    playSound("launch");
    if (QFile::exists("/usr/local/bin/launch-installer")) {
        QProcess::startDetached("/usr/local/bin/launch-installer", QStringList());
    } else if (QFile::exists("/usr/bin/calamares")) {
        QProcess::startDetached("pkexec", QStringList() << "calamares");
    }
}

void TourController::launchTerminal()
{
    playSound("click");
    if (!QStandardPaths::findExecutable("kitty").isEmpty()) {
        QProcess::startDetached("kitty", QStringList());
    } else if (!QStandardPaths::findExecutable("alacritty").isEmpty()) {
        QProcess::startDetached("alacritty", QStringList());
    } else if (!QStandardPaths::findExecutable("foot").isEmpty()) {
        QProcess::startDetached("foot", QStringList());
    }
}

void TourController::toggleControlCenter()
{
    playSound("click");
    QProcess::startDetached("titan-quicksettings", QStringList() << "--toggle");
}

void TourController::toggleSpotlight()
{
    playSound("click");
    if (!QStandardPaths::findExecutable("titan-spotlight").isEmpty()) {
        QProcess::startDetached("titan-spotlight", QStringList() << "--toggle");
    } else if (!QStandardPaths::findExecutable("titan-menu").isEmpty()) {
        QProcess::startDetached("titan-menu", QStringList() << "--toggle");
    }
}

void TourController::launchWallpaperPicker()
{
    playSound("click");
    if (!QStandardPaths::findExecutable("titan-wallpaper-picker").isEmpty()) {
        QProcess::startDetached("titan-wallpaper-picker", QStringList());
    } else if (!QStandardPaths::findExecutable("titan-wallpaper-picker-ui").isEmpty()) {
        QProcess::startDetached("titan-wallpaper-picker-ui", QStringList());
    }
}

void TourController::launchSettings()
{
    playSound("click");
    if (!QStandardPaths::findExecutable("archtitan-settings").isEmpty()) {
        QProcess::startDetached("archtitan-settings", QStringList());
    }
}

void TourController::testAudio()
{
    playSound("chime");
    if (QFile::exists("/usr/share/sounds/ocean/stereo/bell-window-system.oga")) {
        QProcess::startDetached("pw-play", QStringList() << "/usr/share/sounds/ocean/stereo/bell-window-system.oga");
    } else {
        QProcess::startDetached("canberra-gtk-play", QStringList() << "-i" << "bell-window-system");
    }
}

void TourController::setPowerProfile(const QString &profile)
{
    if (profile == "efficiency") {
        QProcess::startDetached("powerprofilesctl", QStringList() << "set" << "power-saver");
        QProcess::startDetached("titan-hwm", QStringList() << "profile" << "efficiency");
    } else if (profile == "performance") {
        QProcess::startDetached("powerprofilesctl", QStringList() << "set" << "performance");
        QProcess::startDetached("titan-hwm", QStringList() << "profile" << "performance");
    } else {
        QProcess::startDetached("powerprofilesctl", QStringList() << "set" << "balanced");
        QProcess::startDetached("titan-hwm", QStringList() << "profile" << "balanced");
    }
}

void TourController::finishTour(bool dontShowAgain)
{
    playSound("chime");
    if (dontShowAgain) {
        QString configDir = QDir::homePath() + "/.config/archtitan";
        QDir().mkpath(configDir);
        QFile flagFile(configDir + "/.tour-done");
        if (flagFile.open(QIODevice::WriteOnly)) {
            flagFile.write("1\n");
            flagFile.close();
        }
    }
    QGuiApplication::quit();
}

void TourController::closeApp()
{
    playSound("click");
    QGuiApplication::quit();
}

void TourController::detectHardwareInfo()
{
    // CPU
    QFile cpuinfo("/proc/cpuinfo");
    if (cpuinfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuinfo);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("model name", Qt::CaseInsensitive)) {
                int idx = line.indexOf(':');
                if (idx != -1) {
                    m_cpuName = line.mid(idx + 1).trimmed();
                    // Clean up common verbosity
                    m_cpuName = m_cpuName.remove("(R)").remove("(TM)").remove("CPU").simplified();
                    break;
                }
            }
        }
    }

    // RAM
    QFile meminfo("/proc/meminfo");
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&meminfo);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith("MemTotal:", Qt::CaseInsensitive)) {
                QStringList parts = line.split(QRegularExpression("\\s+"));
                if (parts.size() >= 2) {
                    qulonglong kb = parts[1].toULongLong();
                    double gb = static_cast<double>(kb) / (1024.0 * 1024.0);
                    m_ramTotal = QString::asprintf("%.1f GB RAM", gb);
                    break;
                }
            }
        }
    }

    // GPU detection via lspci
    QProcess lspci;
    lspci.start("bash", QStringList() << "-c" << "lspci | grep -iE 'vga|3d|display' | head -n 1");
    if (lspci.waitForFinished(1000)) {
        QString out = QString::fromUtf8(lspci.readAllStandardOutput()).trimmed();
        int idx = out.indexOf(':');
        if (idx != -1) {
            QString gpuStr = out.mid(idx + 1).trimmed();
            // remove bracket codes if any
            int subIdx = gpuStr.indexOf(':');
            if (subIdx != -1) gpuStr = gpuStr.mid(subIdx + 1).trimmed();
            if (!gpuStr.isEmpty()) m_gpuName = gpuStr;
        }
    }
}

void TourController::loadPreferences()
{
    QString confPath = QDir::homePath() + "/.config/archtitan/tour.conf";
    if (QFile::exists(confPath)) {
        QSettings s(confPath, QSettings::IniFormat);
        m_soundFxEnabled = s.value("soundFxEnabled", true).toBool();
        m_showOnStartup = s.value("showOnStartup", true).toBool();
    }
}

void TourController::savePreferences()
{
    QString confPath = QDir::homePath() + "/.config/archtitan/tour.conf";
    QDir().mkpath(QFileInfo(confPath).absolutePath());
    QSettings s(confPath, QSettings::IniFormat);
    s.setValue("soundFxEnabled", m_soundFxEnabled);
    s.setValue("showOnStartup", m_showOnStartup);
}
