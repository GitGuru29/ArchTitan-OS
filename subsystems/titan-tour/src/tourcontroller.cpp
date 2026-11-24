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
{
    m_isLiveMode = QFile::exists(QStringLiteral("/run/archiso"));
    m_kernelVersion = QSysInfo::kernelVersion();

    detectHardwareInfo();
    detectPowerProfile();
    resolveAssets();
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
    } else if (soundId == QLatin1String("chime") || soundId == QLatin1String("success") || soundId == QLatin1String("complete")) {
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

void TourController::launchBrowser()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titanbrowser")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titanbrowser"), QStringList());
    } else if (!QStandardPaths::findExecutable(QStringLiteral("firefox")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("firefox"), QStringList());
    } else {
        QProcess::startDetached(QStringLiteral("xdg-open"), QStringList() << QStringLiteral("https://archtitan.org"));
    }
}

void TourController::launchFileManager()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("dolphin")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("dolphin"), QStringList());
    } else if (!QStandardPaths::findExecutable(QStringLiteral("thunar")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("thunar"), QStringList());
    }
}

void TourController::launchSettings()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("archtitan-settings")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("archtitan-settings"), QStringList());
    }
}

void TourController::toggleControlCenter()
{
    playSound(QStringLiteral("click"));
    QProcess::startDetached(QStringLiteral("titan-quicksettings"), QStringList() << QStringLiteral("--toggle"));
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

void TourController::toggleFocus()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-focus")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-focus"), QStringList() << QStringLiteral("--toggle"));
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

void TourController::applyWallpaper(const QString &path)
{
    if (path.isEmpty() || !QFile::exists(path)) return;
    playSound(QStringLiteral("tap"));
    m_selectedWallpaper = path;
    emit selectedWallpaperChanged();

    if (!QStandardPaths::findExecutable(QStringLiteral("titan-set-wallpaper")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-set-wallpaper"), QStringList() << path);
    } else if (!QStandardPaths::findExecutable(QStringLiteral("swaybg")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("swaybg"), QStringList() << QStringLiteral("-i") << path << QStringLiteral("-m") << QStringLiteral("fill"));
    }
}

void TourController::setPowerProfile(const QString &profile)
{
    QString p = profile.toLower();
    QString targetDaemon = QStringLiteral("balanced");
    QString targetThm = QStringLiteral("balanced");

    if (p.contains(QLatin1String("eco")) || p.contains(QLatin1String("power")) || p.contains(QLatin1String("saver")) || p.contains(QLatin1String("efficiency"))) {
        targetDaemon = QStringLiteral("power-saver");
        targetThm = QStringLiteral("efficiency");
    } else if (p.contains(QLatin1String("perf"))) {
        targetDaemon = QStringLiteral("performance");
        targetThm = QStringLiteral("performance");
    }

    if (!QStandardPaths::findExecutable(QStringLiteral("powerprofilesctl")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("powerprofilesctl"), QStringList() << QStringLiteral("set") << targetDaemon);
    }
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-hwm")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-hwm"), QStringList() << QStringLiteral("profile") << targetThm);
    }
}

void TourController::finishTour(bool dontShowAgain)
{
    playSound(QStringLiteral("complete"));
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

void TourController::detectPowerProfile()
{
    if (!QStandardPaths::findExecutable(QStringLiteral("powerprofilesctl")).isEmpty()) {
        QProcess p;
        p.start(QStringLiteral("powerprofilesctl"), QStringList() << QStringLiteral("get"));
        if (p.waitForFinished(800)) {
            QString out = QString::fromUtf8(p.readAllStandardOutput()).trimmed();
            if (out == QLatin1String("power-saver")) {
                m_activeProfile = QStringLiteral("power-saver");
            } else if (out == QLatin1String("performance")) {
                m_activeProfile = QStringLiteral("performance");
            } else {
                m_activeProfile = QStringLiteral("balanced");
            }
        }
    }
}

void TourController::detectHardwareInfo()
{
    // CPU detection (use readAll() because procfs files report size 0)
    int cpuCores = 0;
    QString detectedCpu;
    QFile cpuinfo(QStringLiteral("/proc/cpuinfo"));
    if (cpuinfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(cpuinfo.readAll()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("processor"), Qt::CaseInsensitive)) {
                cpuCores++;
            } else if (detectedCpu.isEmpty() && line.startsWith(QLatin1String("model name"), Qt::CaseInsensitive)) {
                int idx = line.indexOf(QLatin1Char(':'));
                if (idx != -1) {
                    detectedCpu = line.mid(idx + 1).trimmed();
                    detectedCpu.remove(QStringLiteral("(R)"));
                    detectedCpu.remove(QStringLiteral("(TM)"));
                    detectedCpu.remove(QStringLiteral("11th Gen "));
                    detectedCpu.remove(QStringLiteral("12th Gen "));
                    detectedCpu.remove(QStringLiteral("13th Gen "));
                    detectedCpu.remove(QStringLiteral("14th Gen "));
                    detectedCpu.remove(QStringLiteral("CPU"));
                    int atIdx = detectedCpu.indexOf(QLatin1Char('@'));
                    if (atIdx != -1) {
                        detectedCpu = detectedCpu.left(atIdx).trimmed();
                    }
                    detectedCpu = detectedCpu.simplified();
                }
            }
        }
    }
    if (!detectedCpu.isEmpty()) {
        m_cpuName = cpuCores > 0
            ? QStringLiteral("%1 (%2 Threads)").arg(detectedCpu).arg(cpuCores)
            : detectedCpu;
    }

    // RAM detection
    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(meminfo.readAll()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("MemTotal:"), Qt::CaseInsensitive)) {
                QStringList parts = line.split(QRegularExpression(QStringLiteral("\\s+")));
                if (parts.size() >= 2) {
                    qulonglong kb = parts[1].toULongLong();
                    double gb = static_cast<double>(kb) / (1024.0 * 1024.0);
                    m_ramTotal = QString::asprintf("%.1f GB Unified / DDR", gb);
                    break;
                }
            }
        }
    }

    // GPU detection
    QProcess lspci;
    lspci.start(QStringLiteral("bash"), QStringList() << QStringLiteral("-c") << QStringLiteral("lspci | grep -iE 'vga|3d|display' | head -n 1"));
    if (lspci.waitForFinished(800)) {
        QString out = QString::fromUtf8(lspci.readAllStandardOutput()).trimmed();
        int ctrlIdx = out.indexOf(QLatin1String("controller:"), 0, Qt::CaseInsensitive);
        QString gpuStr = (ctrlIdx != -1) ? out.mid(ctrlIdx + 11).trimmed() : out;
        gpuStr.remove(QRegularExpression(QStringLiteral("\\s*\\(rev [^)]+\\)")));

        // If bracketed marketing name exists (e.g. "Intel Corporation TigerLake-LP GT2 [Iris Xe Graphics]"), extract vendor + bracket
        QRegularExpression bracketRe(QStringLiteral("\\[([^\\]]+)\\]"));
        auto match = bracketRe.match(gpuStr);
        if (match.hasMatch()) {
            QString model = match.captured(1).trimmed();
            if (gpuStr.contains(QLatin1String("Intel"), Qt::CaseInsensitive) && !model.contains(QLatin1String("Intel"), Qt::CaseInsensitive)) {
                m_gpuName = QStringLiteral("Intel ") + model;
            } else if (gpuStr.contains(QLatin1String("NVIDIA"), Qt::CaseInsensitive) && !model.contains(QLatin1String("NVIDIA"), Qt::CaseInsensitive)) {
                m_gpuName = QStringLiteral("NVIDIA ") + model;
            } else if ((gpuStr.contains(QLatin1String("AMD"), Qt::CaseInsensitive) || gpuStr.contains(QLatin1String("ATI"), Qt::CaseInsensitive))
                       && !model.contains(QLatin1String("AMD"), Qt::CaseInsensitive) && !model.contains(QLatin1String("Radeon"), Qt::CaseInsensitive)) {
                m_gpuName = QStringLiteral("AMD ") + model;
            } else {
                m_gpuName = model;
            }
        } else if (!gpuStr.isEmpty()) {
            m_gpuName = gpuStr;
        }
    }

    // OS Release detection
    QFile osRel(QStringLiteral("/etc/os-release"));
    if (osRel.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(osRel.readAll()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("PRETTY_NAME="))) {
                QString val = line.section(QLatin1Char('='), 1).trimmed();
                val.remove(QLatin1Char('"'));
                if (!val.isEmpty()) m_osVersion = val;
                break;
            }
        }
    }

    emit hardwareDetected();
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

    QString bgRoot;
    QStringList bgDirs = {
        QStringLiteral("/usr/share/backgrounds/archtitan"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/share/backgrounds/archtitan"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/share/backgrounds/archtitan"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/share/backgrounds/archtitan")
    };
    for (const QString &d : bgDirs) {
        if (QDir(d).exists()) {
            bgRoot = QFileInfo(d).absoluteFilePath();
            break;
        }
    }

    // Detect currently set wallpaper
    QString currentWpFile = QDir::homePath() + QStringLiteral("/.config/archtitan/wallpaper");
    if (QFile::exists(currentWpFile)) {
        QFile f(currentWpFile);
        if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
            m_selectedWallpaper = QString::fromUtf8(f.readLine()).trimmed();
        }
    }

    if (!bgRoot.isEmpty()) {
        struct WallDef { const char *file; const char *label; const char *tag; };
        static const WallDef defs[] = {
            { "watchtower-mountains-and-forests.jpg",  "Watchtower",      "LANDSCAPE" },
            { "titan-mocha.jpg",                       "Titan Mocha",     "OBSIDIAN"  },
            { "titan-teal.jpg",                        "Titan Teal",      "ACCENT"    },
            { "titan-rosepine.jpg",                    "Rosé Pine",       "VIBRANT"   },
            { "titan-blue.jpg",                        "Deep Blue",       "MINIMAL"   },
            { "1-matte-black.jpg",                     "Matte Black",     "STEALTH"   }
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

    emit wallpapersChanged();
    emit selectedWallpaperChanged();
}

void TourController::loadPreferences()
{
    QString confPath = QDir::homePath() + QStringLiteral("/.config/archtitan/tour.conf");
    if (QFile::exists(confPath)) {
        QSettings s(confPath, QSettings::IniFormat);
        m_soundFxEnabled = s.value(QStringLiteral("soundFxEnabled"), true).toBool();
        m_showOnStartup = s.value(QStringLiteral("showOnStartup"), true).toBool();
    } else {
        // By default on installed systems, check if .tour-done exists
        QString doneFlag = QDir::homePath() + QStringLiteral("/.config/archtitan/.tour-done");
        m_showOnStartup = !QFile::exists(doneFlag);
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
