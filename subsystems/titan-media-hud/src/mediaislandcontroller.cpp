#include "mediaislandcontroller.h"
#include <QDebug>

MediaIslandController::MediaIslandController(QObject *parent)
    : QObject(parent)
{
    // Auto-hide timer for auto-popup mode (show briefly on track change)
    m_autoHideTimer.setSingleShot(true);
    m_autoHideTimer.setInterval(4000); // 4 seconds
    connect(&m_autoHideTimer, &QTimer::timeout, this, [this]() {
        if (m_state == Compact || m_state == Expanded) {
            dismiss();
        }
    });

    // Debounce timer to prevent repeated auto-popups from rapid metadata changes
    m_debounceTimer.setSingleShot(true);
    m_debounceTimer.setInterval(800);

    // Safety fallback timer to prevent state lockups if QML animations are interrupted
    m_stateSafetyTimer.setSingleShot(true);
    m_stateSafetyTimer.setInterval(600);
    connect(&m_stateSafetyTimer, &QTimer::timeout, this, [this]() {
        if (m_state == Opening) {
            setState(Compact);
        } else if (m_state == Closing) {
            setState(Hidden);
        }
    });
}

void MediaIslandController::setState(State newState)
{
    if (m_state == newState) return;
    m_state = newState;
    emit stateChanged();
}

void MediaIslandController::toggle()
{
    m_autoHideTimer.stop();
    if (m_state == Hidden || m_state == Closing) {
        setState(Opening);
        m_stateSafetyTimer.start();
        emit requestOpen();
    } else {
        setState(Closing);
        m_stateSafetyTimer.start();
        emit requestClose();
    }
}

void MediaIslandController::dismiss()
{
    m_autoHideTimer.stop();
    if (m_state != Hidden) {
        setState(Closing);
        m_stateSafetyTimer.start();
        emit requestClose();
    }
}

void MediaIslandController::expand()
{
    if (m_state == Compact) {
        m_autoHideTimer.stop();
        setState(Expanding);
        emit requestExpand();
    }
}

void MediaIslandController::collapse()
{
    if (m_state == Expanded) {
        setState(Collapsing);
        emit requestCollapse();
    }
}

void MediaIslandController::onOpenAnimationFinished()
{
    m_stateSafetyTimer.stop();
    if (m_state == Opening) {
        setState(Compact);
    }
}

void MediaIslandController::onCloseAnimationFinished()
{
    m_stateSafetyTimer.stop();
    if (m_state == Closing) {
        setState(Hidden);
    }
}

void MediaIslandController::onExpandAnimationFinished()
{
    if (m_state == Expanding) {
        setState(Expanded);
    }
}

void MediaIslandController::onCollapseAnimationFinished()
{
    if (m_state == Collapsing) {
        setState(Compact);
    }
}

void MediaIslandController::autoPopup()
{
    if (!m_autoPopupEnabled) return;
    if (m_state != Hidden) return; // Don't interrupt if already visible

    // Debounce: ignore if we just popped up recently
    if (m_debounceTimer.isActive()) return;
    m_debounceTimer.start();

    setState(Opening);
    m_stateSafetyTimer.start();
    emit requestOpen();

    // Auto-hide after 4 seconds
    m_autoHideTimer.start();
}

void MediaIslandController::setAutoPopupEnabled(bool enabled)
{
    if (m_autoPopupEnabled == enabled) return;
    m_autoPopupEnabled = enabled;
    emit autoPopupEnabledChanged();
}
