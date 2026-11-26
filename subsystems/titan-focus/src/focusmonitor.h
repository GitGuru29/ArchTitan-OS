#pragma once

#include "configloader.h"

#include <QObject>
#include <QProcess>
#include <QString>

namespace titan::focus {

/**
 * FocusMonitor — asynchronous active-window inspector via `hyprctl -j activewindow`.
 *
 * Classifies whether the focused window belongs to `known_ides`, detects
 * fullscreen media / meeting titles, and captures the focused PID.
 * Never blocks the event loop.
 */
class FocusMonitor : public QObject {
    Q_OBJECT

public:
    explicit FocusMonitor(QObject *parent = nullptr);

    void setConfig(const FocusConfig &cfg) { m_config = cfg; reclassify(); }
    void requestRefresh();
    void updateFromSocket(const QString &appClass, const QString &title);

    QString activeClass() const { return m_activeClass; }
    QString activeTitle() const { return m_activeTitle; }
    qint64  activePid() const { return m_activePid; }
    bool    ideFocused() const { return m_ideFocused; }
    bool    inMeetingWindow() const { return m_inMeetingWindow; }
    bool    fullscreenActive() const { return m_fullscreen; }

signals:
    void focusStateChanged();

private:
    void onHyprctlFinished(int exitCode, QProcess::ExitStatus status);
    void reclassify();

    FocusConfig m_config;
    QProcess    m_proc;
    QString     m_activeClass;
    QString     m_activeTitle;
    qint64      m_activePid = 0;
    bool        m_fullscreen = false;
    bool        m_ideFocused = false;
    bool        m_inMeetingWindow = false;
};

} // namespace titan::focus
