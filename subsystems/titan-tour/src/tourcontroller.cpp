#include "tourcontroller.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QUrl>
#include <QVariantMap>
#include <QSettings>
#include <QStandardPaths>
#include <QCoreApplication>
#include <QGuiApplication>
#include <QRegularExpression>
#include <QSysInfo>
#include <QTextStream>

TourController::TourController(QObject *parent)
    : QObject(parent)
    , m_telemetryTimer(new QTimer(this))
{
    m_isLiveMode = QFile::exists(QStringLiteral("/run/archiso"));
    m_kernelVersion = QSysInfo::kernelVersion();

    for (int i = 0; i < 36; ++i) {
        m_cpuHistory.append(0.15);
    }

    detectHardwareInfo();
    resolveAssets();
    loadPreferences();
    pollTelemetry();

    connect(m_telemetryTimer, &QTimer::timeout, this, &TourController::pollTelemetry);
    m_telemetryTimer->start(800);
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
        playSound(QStringLiteral("tap"));
        setPowerProfile(profile);
    }
}

void TourController::playSound(const QString &soundId)
{
    if (!m_soundFxEnabled) return;

    QString soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/button-pressed.oga");
    if (soundId == QLatin1String("click") || soundId == QLatin1String("tap")) {
        soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/button-pressed.oga");
    } else if (soundId == QLatin1String("chime") || soundId == QLatin1String("success")) {
        soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/bell-window-system.oga");
    } else if (soundId == QLatin1String("launch") || soundId == QLatin1String("warp")) {
        soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/desktop-login.oga");
    }

    if (QFile::exists(soundFile)) {
        QProcess::startDetached(QStringLiteral("pw-play"), QStringList() << soundFile);
    } else {
        QProcess::startDetached(QStringLiteral("canberra-gtk-play"), QStringList() << QStringLiteral("-i") << QStringLiteral("button-pressed"));
    }
}

void TourController::launchInstaller()
{
    playSound(QStringLiteral("launch"));
    if (QFile::exists(QStringLiteral("/usr/local/bin/launch-installer"))) {
        QProcess::startDetached(QStringLiteral("/usr/local/bin/launch-installer"), QStringList());
    } else if (QFile::exists(QStringLiteral("/usr/bin/calamares"))) {
        QProcess::startDetached(QStringLiteral("pkexec"), QStringList() << QStringLiteral("calamares"));
    }
}

void TourController::launchTerminal()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("kitty")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("kitty"), QStringList());
    } else if (!QStandardPaths::findExecutable(QStringLiteral("alacritty")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("alacritty"), QStringList());
    } else if (!QStandardPaths::findExecutable(QStringLiteral("foot")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("foot"), QStringList());
    }
}

void TourController::toggleControlCenter()
{
    playSound(QStringLiteral("click"));
    QProcess::startDetached(QStringLiteral("titan-quicksettings"), QStringList() << QStringLiteral("--toggle"));
}

void TourController::openNotifications()
{
    playSound(QStringLiteral("click"));
    QProcess::startDetached(QStringLiteral("titan-quicksettings"), QStringList() << QStringLiteral("--notifications"));
}

void TourController::toggleSpotlight()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-spotlight")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-spotlight"), QStringList() << QStringLiteral("--toggle"));
    } else if (!QStandardPaths::findExecutable(QStringLiteral("titan-menu")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-menu"), QStringList() << QStringLiteral("--toggle"));
    }
}

void TourController::toggleSysmon()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-sysmon")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-sysmon"), QStringList() << QStringLiteral("--toggle"));
    }
}

void TourController::toggleMenu()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-menu")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-menu"), QStringList() << QStringLiteral("--toggle"));
    } else {
        toggleSpotlight();
    }
}

void TourController::toggleWorkspaceHud()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-workspace-hud")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-workspace-hud"), QStringList() << QStringLiteral("--toggle"));
    }
}

void TourController::toggleMediaHud()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-media-hud")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-media-hud"), QStringList() << QStringLiteral("--toggle"));
    }
}

void TourController::launchWallpaperPicker()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-wallpaper-picker")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-wallpaper-picker"), QStringList());
    } else if (!QStandardPaths::findExecutable(QStringLiteral("titan-wallpaper-picker-ui")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-wallpaper-picker-ui"), QStringList());
    }
}

void TourController::applyWallpaper(const QString &path)
{
    if (path.isEmpty() || !QFile::exists(path)) return;
    playSound(QStringLiteral("tap"));
    m_selectedWallpaper = path;
    emit selectedWallpaperChanged();

    if (!QStandardPaths::findExecutable(QStringLiteral("titan-set-wallpaper")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-set-wallpaper"), QStringList() << path);
    } else if (!QStandardPaths::findExecutable(QStringLiteral("swww")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("swww"),
                                QStringList() << QStringLiteral("img") << path
                                              << QStringLiteral("--transition-type") << QStringLiteral("grow")
                                              << QStringLiteral("--transition-duration") << QStringLiteral("0.8"));
    }
}

void TourController::launchSettings()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("archtitan-settings")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("archtitan-settings"), QStringList());
    }
}

void TourController::testAudio()
{
    playSound(QStringLiteral("chime"));
}

void TourController::setPowerProfile(const QString &profile)
{
    if (profile == QLatin1String("efficiency")) {
        QProcess::startDetached(QStringLiteral("powerprofilesctl"), QStringList() << QStringLiteral("set") << QStringLiteral("power-saver"));
        QProcess::startDetached(QStringLiteral("titan-hwm"), QStringList() << QStringLiteral("profile") << QStringLiteral("efficiency"));
    } else if (profile == QLatin1String("performance")) {
        QProcess::startDetached(QStringLiteral("powerprofilesctl"), QStringList() << QStringLiteral("set") << QStringLiteral("performance"));
        QProcess::startDetached(QStringLiteral("titan-hwm"), QStringList() << QStringLiteral("profile") << QStringLiteral("performance"));
    } else {
        QProcess::startDetached(QStringLiteral("powerprofilesctl"), QStringList() << QStringLiteral("set") << QStringLiteral("balanced"));
        QProcess::startDetached(QStringLiteral("titan-hwm"), QStringList() << QStringLiteral("profile") << QStringLiteral("balanced"));
    }
}

void TourController::finishTour(bool dontShowAgain)
{
    playSound(QStringLiteral("chime"));
    QString configDir = QDir::homePath() + QStringLiteral("/.config/archtitan");
    QDir().mkpath(configDir);
    QString flagPath = configDir + QStringLiteral("/.tour-done");
    if (dontShowAgain) {
        QFile flagFile(flagPath);
        if (flagFile.open(QIODevice::WriteOnly)) {
            flagFile.write("1\n");
            flagFile.close();
        }
    } else {
        QFile::remove(flagPath);
    }
    QGuiApplication::quit();
}

void TourController::closeApp()
{
    playSound(QStringLiteral("click"));
    QGuiApplication::quit();
}

void TourController::pollTelemetry()
{
    // 1. CPU Load from /proc/stat
    QFile statFile(QStringLiteral("/proc/stat"));
    if (statFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString line = QString::fromUtf8(statFile.readLine()).trimmed();
        if (line.startsWith(QLatin1String("cpu "))) {
            QStringList parts = line.split(QRegularExpression(QStringLiteral("\\s+")));
            if (parts.size() >= 8) {
                qulonglong user = parts[1].toULongLong();
                qulonglong nice = parts[2].toULongLong();
                qulonglong system = parts[3].toULongLong();
                qulonglong idle = parts[4].toULongLong();
                qulonglong iowait = parts[5].toULongLong();
                qulonglong irq = parts[6].toULongLong();
                qulonglong softirq = parts[7].toULongLong();

                qulonglong idleAll = idle + iowait;
                qulonglong total = user + nice + system + idleAll + irq + softirq;

                if (m_prevTotal > 0 && total > m_prevTotal) {
                    qulonglong totalDiff = total - m_prevTotal;
                    qulonglong idleDiff = idleAll - m_prevIdle;
                    m_cpuUsage = qBound(0.02, static_cast<qreal>(totalDiff - idleDiff) / static_cast<qreal>(totalDiff), 1.0);
                }
                m_prevTotal = total;
                m_prevIdle = idleAll;
            }
        }
    }

    if (m_cpuHistory.size() >= 36) {
        m_cpuHistory.removeFirst();
    }
    m_cpuHistory.append(m_cpuUsage);

    // 2. RAM Usage from /proc/meminfo
    QFile memFile(QStringLiteral("/proc/meminfo"));
    if (memFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qulonglong memTotal = 0;
        qulonglong memAvail = 0;
        QTextStream in(&memFile);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(QLatin1String("MemTotal:"))) {
                memTotal = line.split(QRegularExpression(QStringLiteral("\\s+"))).value(1).toULongLong();
            } else if (line.startsWith(QLatin1String("MemAvailable:"))) {
                memAvail = line.split(QRegularExpression(QStringLiteral("\\s+"))).value(1).toULongLong();
                break;
            }
        }
        if (memTotal > 0) {
            m_ramUsage = qBound(0.05, static_cast<qreal>(memTotal - memAvail) / static_cast<qreal>(memTotal), 1.0);
        }
    }

    // 3. Thermal Zone
    for (int i = 0; i < 6; ++i) {
        QFile tempFile(QStringLiteral("/sys/class/thermal/thermal_zone%1/temp").arg(i));
        if (tempFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
            int raw = QString::fromUtf8(tempFile.readAll()).trimmed().toInt();
            if (raw > 15000 && raw < 120000) {
                m_cpuTemp = raw / 1000;
                break;
            }
        }
    }

    // 4. PSI Memory Pressure (/proc/pressure/memory)
    QFile psiFile(QStringLiteral("/proc/pressure/memory"));
    if (psiFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QString line = QString::fromUtf8(psiFile.readLine());
        QRegularExpression re(QStringLiteral("avg10=([0-9.]+)"));
        auto match = re.match(line);
        if (match.hasMatch()) {
            m_psiMemory = match.captured(1).toDouble();
        }
    }

    emit telemetryChanged();
}

void TourController::detectHardwareInfo()
{
    QFile cpuinfo(QStringLiteral("/proc/cpuinfo"));
    if (cpuinfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&cpuinfo);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(QLatin1String("model name"), Qt::CaseInsensitive)) {
                int idx = line.indexOf(QLatin1Char(':'));
                if (idx != -1) {
                    m_cpuName = line.mid(idx + 1).trimmed();
                    m_cpuName = m_cpuName.remove(QStringLiteral("(R)"))
                                         .remove(QStringLiteral("(TM)"))
                                         .remove(QStringLiteral("CPU"))
                                         .simplified();
                    break;
                }
            }
        }
    }

    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&meminfo);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.startsWith(QLatin1String("MemTotal:"), Qt::CaseInsensitive)) {
                QStringList parts = line.split(QRegularExpression(QStringLiteral("\\s+")));
                if (parts.size() >= 2) {
                    qulonglong kb = parts[1].toULongLong();
                    double gb = static_cast<double>(kb) / (1024.0 * 1024.0);
                    m_ramTotal = QString::asprintf("%.1f GB", gb);
                    break;
                }
            }
        }
    }

    QProcess lspci;
    lspci.start(QStringLiteral("bash"), QStringList() << QStringLiteral("-c") << QStringLiteral("lspci | grep -iE 'vga|3d|display' | head -n 1"));
    if (lspci.waitForFinished(1000)) {
        QString out = QString::fromUtf8(lspci.readAllStandardOutput()).trimmed();
        int idx = out.indexOf(QLatin1Char(':'));
        if (idx != -1) {
            QString gpuStr = out.mid(idx + 1).trimmed();
            int subIdx = gpuStr.indexOf(QLatin1Char(':'));
            if (subIdx != -1) gpuStr = gpuStr.mid(subIdx + 1).trimmed();
            if (!gpuStr.isEmpty()) m_gpuName = gpuStr;
        }
    }
}

void TourController::resolveAssets()
{
    QStringList logoCandidates = {
        QStringLiteral("/usr/share/pixmaps/archtitan-reticle-logo.png"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/share/pixmaps/archtitan-reticle-logo.png"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/share/pixmaps/archtitan-reticle-logo.png"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/share/pixmaps/archtitan-reticle-logo.png")
    };
    for (const QString &cand : logoCandidates) {
        if (QFile::exists(cand)) {
            m_logoUrl = QUrl::fromLocalFile(QFileInfo(cand).absoluteFilePath()).toString();
            break;
        }
    }

    QStringList bgDirs = {
        QStringLiteral("/usr/share/backgrounds/archtitan"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/share/backgrounds/archtitan"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/share/backgrounds/archtitan"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/share/backgrounds/archtitan")
    };

    QString bgRoot;
    for (const QString &d : bgDirs) {
        if (QDir(d).exists()) {
            bgRoot = QFileInfo(d).absoluteFilePath();
            break;
        }
    }

    if (!bgRoot.isEmpty()) {
        struct WallDef { const char *file; const char *label; const char *tag; };
        static const WallDef defs[] = {
            { "wallpaper.png",                         "Titan Core",      "SAPPHIRE" },
            { "titan-tokyonight.jpg",                  "Tokyo Night",     "CYBER" },
            { "titan-mocha.jpg",                       "Catppuccin Mocha","OBSIDIAN" },
            { "1-nord.png",                            "Arctic Nord",     "GLACIER" },
            { "watchtower-mountains-and-forests.jpg",  "Watchtower",      "HORIZON" },
            { "titan-dracula.jpg",                     "Dracula Noir",    "NEON" }
        };

        for (const auto &w : defs) {
            QString fullPath = bgRoot + QLatin1Char('/') + QString::fromUtf8(w.file);
            if (QFile::exists(fullPath)) {
                QVariantMap item;
                item[QStringLiteral("name")] = QString::fromUtf8(w.label);
                item[QStringLiteral("tag")]  = QString::fromUtf8(w.tag);
                item[QStringLiteral("path")] = fullPath;
                item[QStringLiteral("url")]  = QUrl::fromLocalFile(fullPath).toString();
                m_wallpapers.append(item);
                if (m_selectedWallpaper.isEmpty()) {
                    m_selectedWallpaper = fullPath;
                }
            }
        }
    }
}

void TourController::loadPreferences()
{
    QString confPath = QDir::homePath() + QStringLiteral("/.config/archtitan/tour.conf");
    if (QFile::exists(confPath)) {
        QSettings s(confPath, QSettings::IniFormat);
        m_soundFxEnabled = s.value(QStringLiteral("soundFxEnabled"), true).toBool();
        m_showOnStartup = s.value(QStringLiteral("showOnStartup"), true).toBool();
    }
}

void TourController::savePreferences()
{
    QString confPath = QDir::homePath() + QStringLiteral("/.config/archtitan/tour.conf");
    QDir().mkpath(QFileInfo(confPath).absolutePath());
    QSettings s(confPath, QSettings::IniFormat);
    s.setValue(QStringLiteral("soundFxEnabled"), m_soundFxEnabled);
    s.setValue(QStringLiteral("showOnStartup"), m_showOnStartup);
}
