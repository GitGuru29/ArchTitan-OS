#include "tourcontroller.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcess>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QSysInfo>
#include <QUrl>

TourController::TourController(QObject *parent)
    : QObject(parent)
    , m_state(TourState::defaultConfigDir(), this)
    , m_adapter(this)
{
    m_isLiveMode = QFile::exists(QStringLiteral("/run/archiso"));
    m_kernelVersion = QSysInfo::kernelVersion();

    connect(&m_adapter, &FeatureAdapter::visibleChanged, this, &TourController::liveFeatureChanged);
    connect(&m_adapter, &FeatureAdapter::rectChanged, this, &TourController::liveFeatureChanged);
    connect(&m_adapter, &FeatureAdapter::triedChanged, this, [this]() {
        if (m_adapter.tried()) {
            const QString fid = currentFeatureId();
            if (!fid.isEmpty()) {
                m_state.markFeatureCompleted(fid);
                m_state.save();
            }
        }
        emit liveFeatureChanged();
    });

    loadDataFiles();
    detectHardwareInfo();
    detectPowerProfile();
    resolveAssetsAndThemes();

    m_state.load(m_releases.currentVersion());

    connect(&m_telemetryTimer, &QTimer::timeout, this, &TourController::sampleTelemetry);
    m_telemetryTimer.setInterval(1200);
    sampleTelemetry();
    m_telemetryTimer.start();
}

TourController::~TourController()
{
    m_telemetryTimer.stop();
    m_adapter.stopWatching();
    m_adapter.closeAll();
}

bool TourController::configureSession(const QString &requestedMode,
                                      const QString &requestedStep,
                                      bool autostart,
                                      bool force)
{
    const QString currRel = m_releases.currentVersion();
    const QList<ReleaseHighlight> pending =
        m_releases.pendingHighlights(m_state.lastSeenRelease(), m_state.dismissedHighlights());

    if (!requestedStep.isEmpty()) {
        setMode(QStringLiteral("replay"));
        goToStepId(requestedStep);
        return true;
    }

    if (!requestedMode.isEmpty()) {
        const QString m = requestedMode.toLower().trimmed();
        if (m == QLatin1String("whats-new") || m == QLatin1String("whatsnew")) {
            setMode(QStringLiteral("whats-new"));
            return true;
        }
        if (m == QLatin1String("replay")) {
            setMode(QStringLiteral("replay"));
            return true;
        }
        setMode(QStringLiteral("welcome"));
        return true;
    }

    if (autostart && !force) {
        if (m_isLiveMode) {
            setMode(QStringLiteral("welcome"));
            return true;
        }
        if (!m_state.welcomeCompleted()) {
            setMode(QStringLiteral("welcome"));
            return true;
        }
        if (!pending.isEmpty()) {
            setMode(QStringLiteral("whats-new"));
            return true;
        }
        return false;
    }

    setMode(m_state.welcomeCompleted() && !force ? QStringLiteral("replay")
                                                 : QStringLiteral("welcome"));
    Q_UNUSED(currRel);
    return true;
}

void TourController::setMode(const QString &mode)
{
    const QString norm = (mode == QLatin1String("whats-new") || mode == QLatin1String("replay"))
        ? mode
        : QStringLiteral("welcome");
    if (m_mode != norm) {
        m_mode = norm;
        emit modeChanged();
    }
    emit currentStepChanged();
}

void TourController::setCurrentIndex(int index)
{
    goToStep(index);
}

QVariantMap TourController::currentStep() const
{
    if (m_currentIndex >= 0 && m_currentIndex < m_steps.size()) {
        return m_steps.at(m_currentIndex).toMap();
    }
    return QVariantMap{};
}

QString TourController::currentScene() const
{
    if (m_mode == QLatin1String("whats-new")) {
        return QStringLiteral("whats-new");
    }
    const QVariantMap step = currentStep();
    return step.value(QStringLiteral("scene"), QStringLiteral("welcome")).toString();
}

QString TourController::currentFeatureId() const
{
    const QVariantMap step = currentStep();
    return step.value(QStringLiteral("feature")).toString();
}

qreal TourController::progress() const
{
    if (m_steps.size() <= 1) return 1.0;
    return qBound(0.0, qreal(m_currentIndex) / qreal(m_steps.size() - 1), 1.0);
}

void TourController::setReducedMotion(bool on)
{
    if (m_reducedMotion != on) {
        m_reducedMotion = on;
        emit reducedMotionChanged();
    }
}

void TourController::setSoundFxEnabled(bool enabled)
{
    if (m_soundFxEnabled != enabled) {
        m_soundFxEnabled = enabled;
        emit soundFxEnabledChanged();
    }
}

QString TourController::activeWallpaperUrl() const
{
    if (!m_previewWallpaper.isEmpty() && QFile::exists(m_previewWallpaper)) {
        return QUrl::fromLocalFile(m_previewWallpaper).toString();
    }
    if (!m_wallpapers.isEmpty()) {
        return m_wallpapers.first().toMap().value(QStringLiteral("url")).toString();
    }
    return QString();
}

void TourController::setActiveProfile(const QString &profile)
{
    if (m_activeProfile != profile) {
        m_activeProfile = profile;
        emit activeProfileChanged();
        playSound(QStringLiteral("tap"));
        setPowerProfileInternal(profile);
    }
}

void TourController::next()
{
    if (m_mode == QLatin1String("whats-new")) {
        acknowledgeWhatsNew();
        return;
    }
    if (m_currentIndex + 1 < m_steps.size()) {
        playSound(QStringLiteral("tap"));
        goToStep(m_currentIndex + 1);
    } else {
        finishTour();
    }
}

void TourController::previous()
{
    if (m_mode == QLatin1String("whats-new")) return;
    if (m_currentIndex > 0) {
        playSound(QStringLiteral("tap"));
        goToStep(m_currentIndex - 1);
    }
}

void TourController::goToStep(int index)
{
    if (m_steps.isEmpty()) return;
    const int bounded = qBound(0, index, int(m_steps.size()) - 1);

    // Close any live feature that was opened on the previous step
    const QString prevFeature = currentFeatureId();
    if (m_liveFeatureOpen && !prevFeature.isEmpty()) {
        m_adapter.close(prevFeature);
        m_liveFeatureOpen = false;
    }
    m_adapter.stopWatching();

    m_currentIndex = bounded;
    onStepEntered();
    emit currentStepChanged();
    emit liveFeatureChanged();
}

bool TourController::goToStepId(const QString &stepId)
{
    const QString target = stepId.trimmed().toLower();
    for (int i = 0; i < m_steps.size(); ++i) {
        const QVariantMap s = m_steps.at(i).toMap();
        if (s.value(QStringLiteral("id")).toString().toLower() == target ||
            s.value(QStringLiteral("feature")).toString().toLower() == target) {
            goToStep(i);
            return true;
        }
    }
    return false;
}

void TourController::skipFeature()
{
    dismissLiveFeature();
    next();
}

void TourController::skipForNow()
{
    playSound(QStringLiteral("click"));
    dismissLiveFeature();
    m_adapter.closeAll();
    if (!m_isLiveMode) {
        m_state.registerSkip();
        m_state.save();
    }
    QGuiApplication::quit();
}

void TourController::restartTour()
{
    playSound(QStringLiteral("tap"));
    dismissLiveFeature();
    setMode(QStringLiteral("replay"));
    goToStep(0);
}

void TourController::finishTour()
{
    playSound(QStringLiteral("complete"));
    dismissLiveFeature();
    m_adapter.closeAll();
    m_state.setWelcomeCompleted(true);
    if (!m_releases.currentVersion().isEmpty()) {
        m_state.setLastSeenRelease(m_releases.currentVersion());
    }
    m_state.save();
    QGuiApplication::quit();
}

void TourController::acknowledgeWhatsNew()
{
    playSound(QStringLiteral("complete"));
    for (const QVariant &v : m_releaseHighlights) {
        const QString key = v.toMap().value(QStringLiteral("key")).toString();
        if (!key.isEmpty()) m_state.dismissHighlight(key);
    }
    if (!m_releases.currentVersion().isEmpty()) {
        m_state.setLastSeenRelease(m_releases.currentVersion());
    }
    m_state.save();
    QGuiApplication::quit();
}

void TourController::jumpToFeatureFromWhatsNew(const QString &featureId)
{
    playSound(QStringLiteral("tap"));
    setMode(QStringLiteral("replay"));
    if (!goToStepId(featureId)) {
        goToStep(0);
    }
}

void TourController::updateViewportSize(int width, int height)
{
    if (width > 0 && height > 0) {
        m_viewport = QSize(width, height);
    }
}

void TourController::activateLiveFeature()
{
    const QString fid = currentFeatureId();
    if (fid.isEmpty()) return;

    playSound(QStringLiteral("launch"));
    m_liveFeatureOpen = true;
    m_adapter.watch(fid, m_viewport);
    m_adapter.open(fid);
    m_state.markFeatureCompleted(fid);
    m_state.save();
    emit liveFeatureChanged();
}

void TourController::dismissLiveFeature()
{
    const QString fid = currentFeatureId();
    if (!fid.isEmpty() && m_liveFeatureOpen) {
        m_adapter.close(fid);
    }
    m_liveFeatureOpen = false;
    m_adapter.stopWatching();
    emit liveFeatureChanged();
}

void TourController::toggleLiveFeature()
{
    if (m_liveFeatureOpen) {
        dismissLiveFeature();
    } else {
        activateLiveFeature();
    }
}

bool TourController::isFeatureAvailable(const QString &featureId) const
{
    if (featureId.isEmpty()) return true;
    return m_adapter.isAvailable(featureId);
}

void TourController::selectPreviewTheme(const QString &themeId)
{
    for (const QVariant &v : m_themes) {
        const QVariantMap t = v.toMap();
        if (t.value(QStringLiteral("id")).toString() == themeId) {
            playSound(QStringLiteral("tap"));
            m_previewThemeId = themeId;
            m_previewThemeName = t.value(QStringLiteral("name")).toString();
            m_previewAccent = t.value(QStringLiteral("accent")).toString();
            m_previewAccent2 = t.value(QStringLiteral("accent2")).toString();
            const QString wp = t.value(QStringLiteral("wallpaper")).toString();
            if (!wp.isEmpty() && QFile::exists(wp)) {
                m_previewWallpaper = wp;
            }
            m_themeAppliedFeedback = false;
            emit previewChanged();
            return;
        }
    }
}

void TourController::selectPreviewWallpaper(const QString &wallpaperPath)
{
    if (wallpaperPath.isEmpty() || !QFile::exists(wallpaperPath)) return;
    playSound(QStringLiteral("tap"));
    m_previewWallpaper = wallpaperPath;
    m_themeAppliedFeedback = false;
    emit previewChanged();
}

void TourController::resetPreviewToInstalled()
{
    playSound(QStringLiteral("tap"));
    selectPreviewTheme(m_installedThemeId);
    if (!m_installedWallpaper.isEmpty()) {
        m_previewWallpaper = m_installedWallpaper;
    }
    m_themeAppliedFeedback = false;
    emit previewChanged();
}

void TourController::applyPreviewChoice()
{
    playSound(QStringLiteral("complete"));
    if (!m_previewThemeId.isEmpty()) {
        const QString themeBin = QStandardPaths::findExecutable(QStringLiteral("titan-theme"));
        if (!themeBin.isEmpty()) {
            QProcess::startDetached(themeBin, {QStringLiteral("set"), m_previewThemeId});
        } else if (QFileInfo::exists(QStringLiteral("/usr/local/bin/titan-theme"))) {
            QProcess::startDetached(QStringLiteral("/usr/local/bin/titan-theme"),
                                    {QStringLiteral("set"), m_previewThemeId});
        }
        m_installedThemeId = m_previewThemeId;
    }
    if (!m_previewWallpaper.isEmpty() && QFile::exists(m_previewWallpaper)) {
        const QString wpBin = QStandardPaths::findExecutable(QStringLiteral("titan-set-wallpaper"));
        if (!wpBin.isEmpty()) {
            QProcess::startDetached(wpBin, {m_previewWallpaper});
        } else if (QFileInfo::exists(QStringLiteral("/usr/local/bin/titan-set-wallpaper"))) {
            QProcess::startDetached(QStringLiteral("/usr/local/bin/titan-set-wallpaper"),
                                    {m_previewWallpaper});
        }
        m_installedWallpaper = m_previewWallpaper;
    }
    m_state.markFeatureCompleted(QStringLiteral("personalize"));
    m_state.save();
    m_themeAppliedFeedback = true;
    emit previewChanged();
}

void TourController::launchSettings()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("archtitan-settings")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("archtitan-settings"), {});
    } else if (QFileInfo::exists(QStringLiteral("/usr/local/bin/archtitan-settings"))) {
        QProcess::startDetached(QStringLiteral("/usr/local/bin/archtitan-settings"), {});
    }
}

void TourController::launchWallpaperPicker()
{
    playSound(QStringLiteral("click"));
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-wallpaper-picker")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-wallpaper-picker"), {});
    } else if (QFileInfo::exists(QStringLiteral("/usr/local/bin/titan-wallpaper-picker"))) {
        QProcess::startDetached(QStringLiteral("/usr/local/bin/titan-wallpaper-picker"), {});
    }
}

void TourController::launchInstaller()
{
    playSound(QStringLiteral("launch"));
    if (QFile::exists(QStringLiteral("/usr/local/bin/launch-installer"))) {
        QProcess::startDetached(QStringLiteral("/usr/local/bin/launch-installer"), {});
    } else if (QFile::exists(QStringLiteral("/usr/bin/calamares"))) {
        QProcess::startDetached(QStringLiteral("pkexec"), {QStringLiteral("calamares")});
    }
}

void TourController::playSound(const QString &soundId)
{
    if (!m_soundFxEnabled) return;

    QString soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/button-pressed.oga");
    if (soundId == QLatin1String("chime") || soundId == QLatin1String("complete")) {
        soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/bell-window-system.oga");
    } else if (soundId == QLatin1String("launch") || soundId == QLatin1String("startup")) {
        soundFile = QStringLiteral("/usr/share/sounds/ocean/stereo/desktop-login.oga");
    }

    if (QFile::exists(soundFile) && !QStandardPaths::findExecutable(QStringLiteral("pw-play")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("pw-play"), {soundFile});
    }
}

void TourController::onStepEntered()
{
    const QString fid = currentFeatureId();
    if (!fid.isEmpty()) {
        m_adapter.watch(fid, m_viewport);
    }
    if (fid == QLatin1String("sysmon")) {
        sampleTelemetry();
    }
}

void TourController::loadDataFiles()
{
    // 1. Welcome copy
    QFile wf(QStringLiteral(":/data/welcome.json"));
    if (wf.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(wf.readAll());
        if (doc.isObject()) m_welcomeData = doc.object().toVariantMap();
    }

    // 2. Guided steps (skipping any feature whose binary does not exist)
    m_steps.clear();
    QFile ff(QStringLiteral(":/data/features.json"));
    if (ff.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(ff.readAll());
        const QJsonArray arr = doc.object().value(QStringLiteral("steps")).toArray();
        int displayIdx = 1;
        for (const QJsonValue &v : arr) {
            QVariantMap item = v.toObject().toVariantMap();
            const QString fid = item.value(QStringLiteral("feature")).toString();
            if (!fid.isEmpty() && !m_adapter.hasFeature(fid)) {
                continue;
            }
            item[QStringLiteral("index")] = displayIdx++;
            m_steps.append(item);
        }
    }

    // 3. Release highlights ("What's New")
    QFile rf(QStringLiteral(":/data/release-highlights.json"));
    const QByteArray fallbackRel = rf.open(QIODevice::ReadOnly) ? rf.readAll() : QByteArray();
    m_releases.loadDefault(fallbackRel);
    m_releases.detectCurrentVersion();

    const QList<ReleaseHighlight> list = m_releases.pendingHighlights(QString(), {});
    m_releaseInfo = m_releases.headlineRelease(QString());
    m_releaseHighlights = ReleaseManager::toVariantList(list);
}

void TourController::sampleTelemetry()
{
    // CPU utilization delta from /proc/stat
    QFile statFile(QStringLiteral("/proc/stat"));
    if (statFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QByteArray firstLine = statFile.readLine();
        const QList<QByteArray> parts = firstLine.simplified().split(' ');
        if (parts.size() >= 5 && parts.at(0) == "cpu") {
            qulonglong user = parts.at(1).toULongLong();
            qulonglong nice = parts.at(2).toULongLong();
            qulonglong system = parts.at(3).toULongLong();
            qulonglong idle = parts.at(4).toULongLong();
            qulonglong iowait = parts.size() > 5 ? parts.at(5).toULongLong() : 0;
            qulonglong irq = parts.size() > 6 ? parts.at(6).toULongLong() : 0;
            qulonglong softirq = parts.size() > 7 ? parts.at(7).toULongLong() : 0;

            qulonglong idleAll = idle + iowait;
            qulonglong total = user + nice + system + idleAll + irq + softirq;
            if (m_prevTotal > 0 && total > m_prevTotal) {
                const double totalDelta = double(total - m_prevTotal);
                const double idleDelta = double(idleAll - m_prevIdle);
                m_cpuUsage = qBound(0.02, (totalDelta - idleDelta) / totalDelta, 1.0);
            }
            m_prevTotal = total;
            m_prevIdle = idleAll;
        }
    }

    // Memory usage from /proc/meminfo
    QFile memFile(QStringLiteral("/proc/meminfo"));
    if (memFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qulonglong memTotal = 0;
        qulonglong memAvail = 0;
        const QList<QByteArray> lines = memFile.readAll().split('\n');
        for (const QByteArray &line : lines) {
            if (line.startsWith("MemTotal:")) {
                memTotal = line.simplified().split(' ').value(1).toULongLong();
            } else if (line.startsWith("MemAvailable:")) {
                memAvail = line.simplified().split(' ').value(1).toULongLong();
            }
        }
        if (memTotal > 0 && memAvail <= memTotal) {
            m_ramUsage = qBound(0.05, double(memTotal - memAvail) / double(memTotal), 0.99);
        }
    }

    // Thermal zone
    QFile tempFile(QStringLiteral("/sys/class/thermal/thermal_zone0/temp"));
    if (tempFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const int milli = tempFile.readAll().trimmed().toInt();
        if (milli > 1000) m_cpuTemp = milli / 1000;
    }

    // PSI CPU & Memory pressure (avg10)
    auto readPsiAvg10 = [](const QString &path) -> qreal {
        QFile f(path);
        if (!f.open(QIODevice::ReadOnly | QIODevice::Text)) return 0.0;
        const QString line = QString::fromUtf8(f.readLine());
        const QRegularExpression re(QStringLiteral("avg10=([0-9]+\\.?[0-9]*)"));
        const auto m = re.match(line);
        return m.hasMatch() ? m.captured(1).toDouble() : 0.0;
    };
    m_psiCpu = readPsiAvg10(QStringLiteral("/proc/pressure/cpu"));
    m_psiMemory = readPsiAvg10(QStringLiteral("/proc/pressure/memory"));

    // THM v3.4 live state (/run/archtitan/thm-state.json)
    QFile thmFile(QStringLiteral("/run/archtitan/thm-state.json"));
    if (thmFile.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(thmFile.readAll());
        if (doc.isObject()) {
            const QJsonObject o = doc.object();
            if (o.contains(QStringLiteral("classified_workloads"))) {
                m_thmWorkloads = o.value(QStringLiteral("classified_workloads")).toInt(m_thmWorkloads);
            } else if (o.contains(QStringLiteral("workloads"))) {
                m_thmWorkloads = o.value(QStringLiteral("workloads")).toArray().size();
            }
        }
    }

    emit telemetryChanged();
}

void TourController::detectHardwareInfo()
{
    int cpuCores = 0;
    QString detectedCpu;
    QFile cpuinfo(QStringLiteral("/proc/cpuinfo"));
    if (cpuinfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(cpuinfo.readAll()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("processor"), Qt::CaseInsensitive)) {
                cpuCores++;
            } else if (detectedCpu.isEmpty() &&
                       line.startsWith(QLatin1String("model name"), Qt::CaseInsensitive)) {
                const int idx = line.indexOf(QLatin1Char(':'));
                if (idx != -1) {
                    detectedCpu = line.mid(idx + 1).trimmed();
                    detectedCpu.remove(QStringLiteral("(R)"));
                    detectedCpu.remove(QStringLiteral("(TM)"));
                    detectedCpu.remove(QStringLiteral("CPU"));
                    const int atIdx = detectedCpu.indexOf(QLatin1Char('@'));
                    if (atIdx != -1) detectedCpu = detectedCpu.left(atIdx).trimmed();
                    detectedCpu = detectedCpu.simplified();
                }
            }
        }
    }
    if (!detectedCpu.isEmpty()) {
        m_cpuName = cpuCores > 0
            ? QStringLiteral("%1 · %2 Threads").arg(detectedCpu).arg(cpuCores)
            : detectedCpu;
    }

    QFile meminfo(QStringLiteral("/proc/meminfo"));
    if (meminfo.open(QIODevice::ReadOnly | QIODevice::Text)) {
        const QStringList lines = QString::fromUtf8(meminfo.readAll()).split(QLatin1Char('\n'));
        for (const QString &line : lines) {
            if (line.startsWith(QLatin1String("MemTotal:"), Qt::CaseInsensitive)) {
                const QStringList parts = line.split(QRegularExpression(QStringLiteral("\\s+")));
                if (parts.size() >= 2) {
                    const double gb = double(parts[1].toULongLong()) / (1024.0 * 1024.0);
                    m_ramTotal = QString::asprintf("%.1f GB RAM", gb);
                    break;
                }
            }
        }
    }

    emit hardwareDetected();
}

void TourController::detectPowerProfile()
{
    if (!QStandardPaths::findExecutable(QStringLiteral("powerprofilesctl")).isEmpty()) {
        QProcess p;
        p.start(QStringLiteral("powerprofilesctl"), {QStringLiteral("get")});
        if (p.waitForFinished(500)) {
            const QString out = QString::fromUtf8(p.readAllStandardOutput()).trimmed();
            if (!out.isEmpty()) m_activeProfile = out;
        }
    }
}

void TourController::setPowerProfileInternal(const QString &profile)
{
    const QString p = profile.toLower();
    QString targetDaemon = QStringLiteral("balanced");
    QString targetThm = QStringLiteral("balanced");
    if (p.contains(QLatin1String("saver")) || p.contains(QLatin1String("efficiency"))) {
        targetDaemon = QStringLiteral("power-saver");
        targetThm = QStringLiteral("efficiency");
    } else if (p.contains(QLatin1String("perf"))) {
        targetDaemon = QStringLiteral("performance");
        targetThm = QStringLiteral("performance");
    }
    if (!QStandardPaths::findExecutable(QStringLiteral("powerprofilesctl")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("powerprofilesctl"),
                                {QStringLiteral("set"), targetDaemon});
    }
    if (!QStandardPaths::findExecutable(QStringLiteral("titan-hwm")).isEmpty()) {
        QProcess::startDetached(QStringLiteral("titan-hwm"),
                                {QStringLiteral("profile"), targetThm});
    }
}

void TourController::resolveAssetsAndThemes()
{
    const QStringList logoCandidates = {
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
    const QStringList bgDirs = {
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

    auto resolveWpPath = [&bgRoot](const QString &rawPath) -> QString {
        if (rawPath.isEmpty()) return QString();
        if (QFile::exists(rawPath)) return QFileInfo(rawPath).absoluteFilePath();
        if (!bgRoot.isEmpty()) {
            const QString candidate = bgRoot + QLatin1Char('/') + QFileInfo(rawPath).fileName();
            if (QFile::exists(candidate)) return candidate;
        }
        return QString();
    };

    // Detect user's currently installed theme
    const QString userThemePath = QDir::homePath() + QStringLiteral("/.config/archtitan/theme.json");
    if (QFile::exists(userThemePath)) {
        QFile f(userThemePath);
        if (f.open(QIODevice::ReadOnly)) {
            const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
            const QString id = o.value(QStringLiteral("id")).toString();
            if (!id.isEmpty()) m_installedThemeId = id;
            const QString wp = resolveWpPath(o.value(QStringLiteral("wallpaper")).toString());
            if (!wp.isEmpty()) m_installedWallpaper = wp;
        }
    }

    // Load all curated themes
    QString themesDir;
    const QStringList themeDirs = {
        QStringLiteral("/usr/share/archtitan/themes"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/share/archtitan/themes"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../../airootfs/usr/share/archtitan/themes"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../../airootfs/usr/share/archtitan/themes")
    };
    for (const QString &d : themeDirs) {
        if (QDir(d).exists()) {
            themesDir = QFileInfo(d).absoluteFilePath();
            break;
        }
    }

    m_themes.clear();
    if (!themesDir.isEmpty()) {
        const QStringList order = {
            QStringLiteral("archtitan"),
            QStringLiteral("mocha"),
            QStringLiteral("tokyonight"),
            QStringLiteral("nord"),
            QStringLiteral("dracula"),
            QStringLiteral("kanagawa"),
            QStringLiteral("rosepine"),
            QStringLiteral("everforest"),
            QStringLiteral("gruvbox"),
            QStringLiteral("latte")
        };
        for (const QString &tid : order) {
            const QString path = themesDir + QLatin1Char('/') + tid + QStringLiteral(".json");
            QFile f(path);
            if (!f.open(QIODevice::ReadOnly)) continue;
            const QJsonObject o = QJsonDocument::fromJson(f.readAll()).object();
            const QJsonObject pal = o.value(QStringLiteral("palette")).toObject();
            const QString wp = resolveWpPath(o.value(QStringLiteral("wallpaper")).toString());
            QVariantMap t;
            t[QStringLiteral("id")] = o.value(QStringLiteral("id")).toString(tid);
            t[QStringLiteral("name")] = o.value(QStringLiteral("name")).toString(tid);
            t[QStringLiteral("isDark")] = o.value(QStringLiteral("isDark")).toBool(true);
            t[QStringLiteral("accent")] = o.value(QStringLiteral("accent")).toString();
            t[QStringLiteral("accent2")] = o.value(QStringLiteral("accent2")).toString();
            t[QStringLiteral("base")] = pal.value(QStringLiteral("base")).toString();
            t[QStringLiteral("mantle")] = pal.value(QStringLiteral("mantle")).toString();
            t[QStringLiteral("textHigh")] = pal.value(QStringLiteral("textHigh")).toString();
            t[QStringLiteral("wallpaper")] = wp;
            t[QStringLiteral("wallpaperUrl")] = wp.isEmpty() ? QString() : QUrl::fromLocalFile(wp).toString();
            m_themes.append(t);
        }
    }

    // Load wallpapers
    m_wallpapers.clear();
    if (!bgRoot.isEmpty()) {
        struct WallDef { const char *file; const char *label; const char *tag; };
        static const WallDef defs[] = {
            { "wallpaper.png",                         "ArchTitan Obsidian", "SIGNATURE" },
            { "titan-mocha.jpg",                       "Catppuccin Mocha",   "MOCHA"     },
            { "titan-tokyonight.jpg",                  "Tokyo Night",        "CYBER"     },
            { "1-nord.png",                            "Arctic Nord",        "FROST"     },
            { "titan-dracula.jpg",                     "Dracula Spires",     "GOTHIC"    },
            { "titan-kanagawa.jpg",                    "Kanagawa Wave",      "MIDNIGHT"  },
            { "titan-rosepine.jpg",                    "Rosé Pine",          "VELVET"    },
            { "titan-everforest.jpg",                  "Everforest Mist",    "ALPINE"    },
            { "watchtower-mountains-and-forests.jpg",  "Watchtower Peaks",   "HORIZON"   }
        };
        for (const auto &w : defs) {
            const QString fullPath = bgRoot + QLatin1Char('/') + QString::fromUtf8(w.file);
            if (QFile::exists(fullPath)) {
                QVariantMap item;
                item[QStringLiteral("name")] = QString::fromUtf8(w.label);
                item[QStringLiteral("tag")] = QString::fromUtf8(w.tag);
                item[QStringLiteral("path")] = fullPath;
                item[QStringLiteral("url")] = QUrl::fromLocalFile(fullPath).toString();
                m_wallpapers.append(item);
                if (m_installedWallpaper.isEmpty()) {
                    m_installedWallpaper = fullPath;
                }
            }
        }
    }

    selectPreviewTheme(m_installedThemeId);
    if (!m_installedWallpaper.isEmpty()) {
        m_previewWallpaper = m_installedWallpaper;
    }

    emit themesChanged();
    emit wallpapersChanged();
    emit previewChanged();
}
