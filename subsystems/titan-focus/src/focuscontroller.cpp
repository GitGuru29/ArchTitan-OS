#include "focuscontroller.h"

#include <LayerShellQt/window.h>
#include <QDateTime>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQuickWindow>
#include <QScreen>
#include <algorithm>
#include <chrono>
#include <malloc.h>

namespace titan::focus {

FocusController::FocusController(QObject *parent)
    : QObject(parent),
      m_configLoader(this),
      m_sessionMonitor(this),
      m_focusMonitor(this),
      m_notifier(5) {
    connect(&m_configLoader, &ConfigLoader::configChanged, this, [this](const FocusConfig &cfg) {
        m_focusMonitor.setConfig(cfg);
        emit stateChanged();
    });

    connect(&m_sessionMonitor, &SessionMonitor::activeWindowChanged,
            this, [this](const QString &cls, const QString &title) {
        m_focusMonitor.updateFromSocket(cls, title);
        emit stateChanged();
    });

    connect(&m_focusMonitor, &FocusMonitor::focusStateChanged, this, &FocusController::stateChanged);

    connect(&m_tickTimer, &QTimer::timeout, this, &FocusController::onTick);
    connect(&m_pressureTimer, &QTimer::timeout, this, &FocusController::onPressureTick);
    connect(&m_saveTimer, &QTimer::timeout, this, [this]() { m_state.save(); });
}

FocusController::~FocusController() {
    m_state.save();
}

int64_t FocusController::monotonicNowSec() {
    using namespace std::chrono;
    return duration_cast<seconds>(steady_clock::now().time_since_epoch()).count();
}

QString FocusController::formatMmSs(int64_t seconds) {
    if (seconds < 0) seconds = 0;
    const int64_t mins = seconds / 60;
    const int64_t secs = seconds % 60;
    return QStringLiteral("%1:%2")
        .arg(mins, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

void FocusController::start() {
    m_configLoader.load();
    m_focusMonitor.setConfig(m_configLoader.config());
    m_state.load();
    m_lastTickSec = monotonicNowSec();

    m_sessionMonitor.start();
    m_focusMonitor.requestRefresh();

    m_lastProc = ProcSampler::sample(m_configLoader.config());
    m_lastPressure = PressureSampler::sample();

    // Layer 1 timers: 2 s process & rule evaluation, 10 s pressure/thermal, 60 s persistence
    m_tickTimer.start(2000);
    m_pressureTimer.start(10000);
    m_saveTimer.start(60000);

    emit stateChanged();
}

void FocusController::setPillActive(bool active) {
    if (m_pillActive == active) return;
    m_pillActive = active;
    emit pillActiveChanged();
}

void FocusController::setBreakActive(bool active) {
    if (m_breakActive == active) return;
    m_breakActive = active;
    emit breakActiveChanged();
}

bool FocusController::onBreak() const {
    return m_state.isOnBreak(monotonicNowSec());
}

bool FocusController::snoozed() const {
    return m_state.isSnoozed(monotonicNowSec());
}

QString FocusController::activeApp() const {
    if (!m_focusMonitor.activeClass().isEmpty()) return m_focusMonitor.activeClass();
    if (!m_sessionMonitor.activeApp().isEmpty()) return m_sessionMonitor.activeApp();
    return QStringLiteral("Desktop");
}

QString FocusController::statusLabel() const {
    const int64_t now = monotonicNowSec();
    if (m_state.isOnBreak(now)) return QStringLiteral("On Break");
    if (m_state.isDnd()) return QStringLiteral("Do Not Disturb");
    if (m_state.isSnoozed(now)) return QStringLiteral("Snoozed");
    if (m_lastProc.buildActive) return QStringLiteral("Building · ") + m_lastProc.activeBuildProc;
    if (m_focusMonitor.ideFocused()) return QStringLiteral("Deep Focus · ") + activeApp();
    return QStringLiteral("Active Session");
}

double FocusController::focusProgress() const {
    const int64_t target = std::max<int64_t>(60, m_configLoader.config().focusBlockSec);
    const int64_t elapsed = m_focusMonitor.ideFocused() ? m_state.ideDwellSec() : m_state.continuousSessionSec();
    return std::clamp(static_cast<double>(elapsed) / static_cast<double>(target), 0.0, 1.0);
}

double FocusController::breakProgress() const {
    const int64_t rem = m_state.breakRemainingSec(monotonicNowSec());
    if (m_breakTotalSec <= 0 || rem <= 0) return 0.0;
    return std::clamp(1.0 - (static_cast<double>(rem) / static_cast<double>(m_breakTotalSec)), 0.0, 1.0);
}

QString FocusController::focusElapsedFormatted() const {
    const int64_t elapsed = m_focusMonitor.ideFocused() ? m_state.ideDwellSec() : m_state.continuousSessionSec();
    return formatMmSs(elapsed);
}

QString FocusController::nextNudgeEtaFormatted() const {
    const int64_t now = monotonicNowSec();
    SignalSnapshot snap;
    snap.nowSec = now;
    snap.ideFocused = m_focusMonitor.ideFocused();
    const int64_t eta = m_engine.nextNudgeEtaSec(m_configLoader.config(), snap, m_state);
    return formatMmSs(eta);
}

QString FocusController::breakRemainingFormatted() const {
    return formatMmSs(m_state.breakRemainingSec(monotonicNowSec()));
}

void FocusController::togglePill() {
    if (!m_pillActive) {
        setPillActive(true);
    } else {
        emit reqPillToggle();
    }
}

void FocusController::showPill() {
    if (!m_pillActive) {
        setPillActive(true);
    } else {
        emit reqPillShow();
    }
}

void FocusController::hidePill() {
    if (m_pillActive) {
        emit reqPillHide();
    }
}

void FocusController::startBreakMinutes(int minutes) {
    const int mins = std::clamp(minutes > 0 ? minutes : m_configLoader.config().breakDurationMin, 1, 60);
    m_breakTotalSec = mins * 60;
    m_state.startBreak(monotonicNowSec(), m_breakTotalSec);
    m_state.save();
    setBreakActive(true);
    emit stateChanged();
}

void FocusController::endBreak() {
    m_state.endBreak(monotonicNowSec());
    setBreakActive(false);
    trimMemory();
    emit stateChanged();
}

void FocusController::snoozeMinutes(int minutes) {
    const int mins = std::clamp(minutes > 0 ? minutes : 15, 1, 120);
    m_state.snooze(monotonicNowSec(), mins * 60);
    m_state.save();
    emit stateChanged();
}

void FocusController::dismissNudge() {
    m_state.dismissActiveNudge();
    m_state.save();
    emit stateChanged();
}

void FocusController::toggleDnd() {
    m_state.setDnd(!m_state.isDnd());
    emit stateChanged();
}

void FocusController::resetSession() {
    m_state.resetSession(monotonicNowSec());
    setBreakActive(false);
    m_state.save();
    emit stateChanged();
}

void FocusController::trimMemory() {
    malloc_trim(0);
}

void FocusController::registerPillWindow(QObject *obj) {
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (!layer) return;

    layer->setAnchors(LayerShellQt::Window::Anchors(
        LayerShellQt::Window::AnchorTop |
        LayerShellQt::Window::AnchorRight));
    layer->setMargins(QMargins(0, 8, 8, 0));
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setExclusiveZone(0);
    layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
    layer->setScope(QStringLiteral("titan-focus"));
}

void FocusController::registerBreakWindow(QObject *obj) {
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (!layer) return;

    layer->setAnchors(LayerShellQt::Window::Anchors(
        LayerShellQt::Window::AnchorTop));
    layer->setMargins(QMargins(0, 12, 0, 0));
    layer->setLayer(LayerShellQt::Window::LayerOverlay);
    layer->setExclusiveZone(0);
    layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
    layer->setScope(QStringLiteral("titan-focus"));
}

SignalSnapshot FocusController::buildSnapshot(int64_t nowSec) {
    const QDateTime local = QDateTime::currentDateTime();
    SignalSnapshot sig;
    sig.nowSec              = nowSec;
    sig.localHour           = local.time().hour();
    sig.localMinute         = local.time().minute();
    sig.localDateKey        = local.date().toString(Qt::ISODate);
    sig.isIdle              = m_sessionMonitor.isIdle();
    sig.idleDurationSec     = m_sessionMonitor.idleDurationSec(nowSec);
    sig.ideFocused          = m_focusMonitor.ideFocused();
    sig.activeApp           = activeApp();
    sig.activeTitle         = m_focusMonitor.activeTitle();
    sig.windowSwitchesDelta = m_sessionMonitor.takeSwitchDelta();
    sig.inMeeting           = m_focusMonitor.inMeetingWindow() || m_lastProc.meetingProcActive;
    sig.mediaPlaying        = m_lastProc.mediaPlayerRunning && m_focusMonitor.fullscreenActive();
    sig.buildActive         = m_lastProc.buildActive;
    sig.activeBuildProc     = m_lastProc.activeBuildProc;
    sig.agentActive         = m_lastProc.agentActive;
    sig.activeAgentProc     = m_lastProc.activeAgentProc;
    sig.psiMemAvg10         = m_lastPressure.psiMemAvg10;
    sig.cpuTempC            = m_lastPressure.cpuTempC;
    sig.memUsedPct          = m_lastPressure.memUsedPct;
    return sig;
}

void FocusController::onTick() {
    const int64_t now = monotonicNowSec();
    const int64_t dt = (m_lastTickSec > 0 && now >= m_lastTickSec) ? (now - m_lastTickSec) : 2;
    m_lastTickSec = now;

    const auto &cfg = m_configLoader.config();
    m_lastProc = ProcSampler::sample(cfg);

    const SignalSnapshot sig = buildSnapshot(now);
    m_state.advance(sig, dt, cfg.idleResetSec, cfg.contextThrashWindowSec);

    // Auto-close break overlay once scheduled break finishes
    if (m_breakActive && !m_state.isOnBreak(now)) {
        setBreakActive(false);
        trimMemory();
    }

    const auto events = m_engine.evaluate(cfg, sig, m_state);
    for (const auto &ev : events) {
        m_notifier.dispatch(ev);
    }

    emit stateChanged();
}

void FocusController::onPressureTick() {
    m_lastPressure = PressureSampler::sample();
    emit stateChanged();
}

QString FocusController::statusJson() const {
    const int64_t now = monotonicNowSec();
    QJsonObject obj;
    obj.insert(QStringLiteral("status"), statusLabel());
    obj.insert(QStringLiteral("on_break"), m_state.isOnBreak(now));
    obj.insert(QStringLiteral("break_remaining_sec"), static_cast<qint64>(m_state.breakRemainingSec(now)));
    obj.insert(QStringLiteral("dnd"), m_state.isDnd());
    obj.insert(QStringLiteral("snoozed"), m_state.isSnoozed(now));
    obj.insert(QStringLiteral("snooze_remaining_sec"), static_cast<qint64>(m_state.snoozeRemainingSec(now)));
    obj.insert(QStringLiteral("ide_focused"), m_focusMonitor.ideFocused());
    obj.insert(QStringLiteral("active_app"), activeApp());
    obj.insert(QStringLiteral("ide_dwell_sec"), static_cast<qint64>(m_state.ideDwellSec()));
    obj.insert(QStringLiteral("session_sec"), static_cast<qint64>(m_state.continuousSessionSec()));
    obj.insert(QStringLiteral("focus_min_today"), focusMinutesToday());
    obj.insert(QStringLiteral("breaks_today"), breaksTakenToday());
    obj.insert(QStringLiteral("nudges_today"), nudgesFiredToday());
    obj.insert(QStringLiteral("cpu_temp_c"), m_lastPressure.cpuTempC);
    obj.insert(QStringLiteral("mem_psi_10"), m_lastPressure.psiMemAvg10);
    return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

QString FocusController::waybarJson() const {
    const int64_t now = monotonicNowSec();
    QString icon = QStringLiteral("󰔟");
    QString text;
    QString cssClass = QStringLiteral("active");

    if (m_state.isOnBreak(now)) {
        icon = QStringLiteral("󰅶");
        text = icon + QStringLiteral(" ") + breakRemainingFormatted();
        cssClass = QStringLiteral("break");
    } else if (m_state.isDnd()) {
        icon = QStringLiteral("󰂛");
        text = icon + QStringLiteral(" DND");
        cssClass = QStringLiteral("dnd");
    } else if (m_state.isSnoozed(now)) {
        icon = QStringLiteral("󰒲");
        text = icon + QStringLiteral(" ") + formatMmSs(m_state.snoozeRemainingSec(now));
        cssClass = QStringLiteral("snoozed");
    } else {
        const int64_t mins = (m_focusMonitor.ideFocused() ? m_state.ideDwellSec() : m_state.continuousSessionSec()) / 60;
        text = icon + QStringLiteral(" %1m").arg(mins);
        cssClass = m_focusMonitor.ideFocused() ? QStringLiteral("deep-focus") : QStringLiteral("active");
    }

    const QString tooltip = QStringLiteral("TitanFocus · %1\nToday: %2m focus · %3 breaks\nNext nudge ETA: %4\nClick: Toggle panel · Right-click: Snooze 15m")
                                .arg(statusLabel())
                                .arg(focusMinutesToday())
                                .arg(breaksTakenToday())
                                .arg(nextNudgeEtaFormatted());

    QJsonObject obj;
    obj.insert(QStringLiteral("text"), text);
    obj.insert(QStringLiteral("tooltip"), tooltip);
    obj.insert(QStringLiteral("class"), cssClass);
    return QString::fromUtf8(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}

QString FocusController::handleIpcCommand(const QString &command) {
    const QStringList parts = command.trimmed().split(QLatin1Char(' '), Qt::SkipEmptyParts);
    if (parts.isEmpty()) return QStringLiteral("ERR empty");

    const QString verb = parts.at(0).toUpper();
    if (verb == QLatin1String("TOGGLE")) {
        togglePill();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("SHOW")) {
        showPill();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("HIDE")) {
        hidePill();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("SNOOZE")) {
        const int mins = (parts.size() >= 2) ? parts.at(1).toInt() : 15;
        snoozeMinutes(mins);
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("BREAK")) {
        const int mins = (parts.size() >= 2) ? parts.at(1).toInt() : m_configLoader.config().breakDurationMin;
        startBreakMinutes(mins);
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("END_BREAK")) {
        endBreak();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("DISMISS")) {
        dismissNudge();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("DND")) {
        if (parts.size() >= 2) {
            const QString arg = parts.at(1).toLower();
            if (arg == QLatin1String("on") || arg == QLatin1String("1") || arg == QLatin1String("true")) {
                m_state.setDnd(true);
                emit stateChanged();
            } else if (arg == QLatin1String("off") || arg == QLatin1String("0") || arg == QLatin1String("false")) {
                m_state.setDnd(false);
                emit stateChanged();
            } else {
                toggleDnd();
            }
        } else {
            toggleDnd();
        }
        return m_state.isDnd() ? QStringLiteral("DND ON") : QStringLiteral("DND OFF");
    }
    if (verb == QLatin1String("RESET")) {
        resetSession();
        return QStringLiteral("OK");
    }
    if (verb == QLatin1String("STATUS")) {
        return statusJson();
    }
    if (verb == QLatin1String("WAYBAR")) {
        return waybarJson();
    }

    return QStringLiteral("ERR unknown command");
}

} // namespace titan::focus
