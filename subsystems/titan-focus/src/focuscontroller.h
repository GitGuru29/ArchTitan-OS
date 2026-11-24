#pragma once

#include "configloader.h"
#include "focusmonitor.h"
#include "notifier.h"
#include "nudgestate.h"
#include "pressuresampler.h"
#include "procsampler.h"
#include "ruleengine.h"
#include "sessionmonitor.h"

#include <QObject>
#include <QTimer>
#include <QString>

namespace titan::focus {

/**
 * FocusController — main daemon coordinator + QML bridge.
 *
 * Uses lazy overlay activation (`pillActive` / `breakActive`) paired with
 * `malloc_trim(0)` when overlays close, keeping idle daemon memory minimal.
 */
class FocusController : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool    pillActive              READ pillActive              WRITE setPillActive  NOTIFY pillActiveChanged)
    Q_PROPERTY(bool    breakActive             READ breakActive             WRITE setBreakActive NOTIFY breakActiveChanged)
    Q_PROPERTY(bool    onBreak                 READ onBreak                 NOTIFY stateChanged)
    Q_PROPERTY(bool    dndEnabled              READ dndEnabled              NOTIFY stateChanged)
    Q_PROPERTY(bool    snoozed                 READ snoozed                 NOTIFY stateChanged)
    Q_PROPERTY(bool    ideFocused              READ ideFocused              NOTIFY stateChanged)
    Q_PROPERTY(bool    buildActive             READ buildActive             NOTIFY stateChanged)
    Q_PROPERTY(QString activeApp               READ activeApp               NOTIFY stateChanged)
    Q_PROPERTY(QString statusLabel             READ statusLabel             NOTIFY stateChanged)
    Q_PROPERTY(double  focusProgress           READ focusProgress           NOTIFY stateChanged)
    Q_PROPERTY(double  breakProgress           READ breakProgress           NOTIFY stateChanged)
    Q_PROPERTY(QString focusElapsedFormatted   READ focusElapsedFormatted   NOTIFY stateChanged)
    Q_PROPERTY(QString nextNudgeEtaFormatted   READ nextNudgeEtaFormatted   NOTIFY stateChanged)
    Q_PROPERTY(QString breakRemainingFormatted READ breakRemainingFormatted NOTIFY stateChanged)
    Q_PROPERTY(int     focusMinutesToday       READ focusMinutesToday       NOTIFY stateChanged)
    Q_PROPERTY(int     breaksTakenToday        READ breaksTakenToday        NOTIFY stateChanged)
    Q_PROPERTY(int     nudgesFiredToday        READ nudgesFiredToday        NOTIFY stateChanged)
    Q_PROPERTY(QString lastNudgeTitle          READ lastNudgeTitle          NOTIFY stateChanged)
    Q_PROPERTY(QString lastNudgeBody           READ lastNudgeBody           NOTIFY stateChanged)
    Q_PROPERTY(double  cpuTempC                READ cpuTempC                NOTIFY stateChanged)
    Q_PROPERTY(double  memUsedPct              READ memUsedPct              NOTIFY stateChanged)
    Q_PROPERTY(int     breakDurationMin        READ breakDurationMin        NOTIFY stateChanged)

public:
    explicit FocusController(QObject *parent = nullptr);
    ~FocusController() override;

    void start();
    QString handleIpcCommand(const QString &command);

    // Properties
    bool    pillActive() const { return m_pillActive; }
    void    setPillActive(bool active);
    bool    breakActive() const { return m_breakActive; }
    void    setBreakActive(bool active);

    bool    onBreak() const;
    bool    dndEnabled() const { return m_state.isDnd(); }
    bool    snoozed() const;
    bool    ideFocused() const { return m_focusMonitor.ideFocused(); }
    bool    buildActive() const { return m_lastProc.buildActive; }
    QString activeApp() const;
    QString statusLabel() const;
    double  focusProgress() const;
    double  breakProgress() const;
    QString focusElapsedFormatted() const;
    QString nextNudgeEtaFormatted() const;
    QString breakRemainingFormatted() const;
    int     focusMinutesToday() const { return static_cast<int>(m_state.tally().focusSeconds / 60); }
    int     breaksTakenToday() const { return m_state.tally().breaksTaken; }
    int     nudgesFiredToday() const { return m_state.tally().nudgesFired; }
    QString lastNudgeTitle() const { return m_state.lastNudgeTitle(); }
    QString lastNudgeBody() const { return m_state.lastNudgeBody(); }
    double  cpuTempC() const { return m_lastPressure.cpuTempC; }
    double  memUsedPct() const { return m_lastPressure.memUsedPct; }
    int     breakDurationMin() const { return m_configLoader.config().breakDurationMin; }

    // QML / IPC invokables
    Q_INVOKABLE void togglePill();
    Q_INVOKABLE void showPill();
    Q_INVOKABLE void hidePill();
    Q_INVOKABLE void startBreakMinutes(int minutes);
    Q_INVOKABLE void endBreak();
    Q_INVOKABLE void snoozeMinutes(int minutes);
    Q_INVOKABLE void dismissNudge();
    Q_INVOKABLE void toggleDnd();
    Q_INVOKABLE void resetSession();
    Q_INVOKABLE void trimMemory();

    Q_INVOKABLE void registerPillWindow(QObject *window);
    Q_INVOKABLE void registerBreakWindow(QObject *window);

    QString statusJson() const;
    QString waybarJson() const;

signals:
    void pillActiveChanged();
    void breakActiveChanged();
    void reqPillToggle();
    void reqPillShow();
    void reqPillHide();
    void stateChanged();

private:
    void onTick();
    void onPressureTick();
    SignalSnapshot buildSnapshot(int64_t nowSec);
    static int64_t monotonicNowSec();
    static QString formatMmSs(int64_t seconds);

    ConfigLoader   m_configLoader;
    SessionMonitor m_sessionMonitor;
    FocusMonitor   m_focusMonitor;
    NudgeState     m_state;
    RuleEngine     m_engine;
    Notifier       m_notifier;

    ProcSample     m_lastProc;
    PressureSample m_lastPressure;
    int64_t        m_lastTickSec = 0;
    int            m_breakTotalSec = 600;

    bool m_pillActive = false;
    bool m_breakActive = false;

    QTimer m_tickTimer;
    QTimer m_pressureTimer;
    QTimer m_saveTimer;
};

} // namespace titan::focus
