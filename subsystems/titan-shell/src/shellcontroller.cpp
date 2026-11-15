#include "shellcontroller.h"

#include <QQuickWindow>
#include <QGuiApplication>
#include <QScreen>
#include <LayerShellQt/window.h>
#include <iostream>

ShellController::ShellController(QObject *parent)
    : QObject(parent)
{
}

void ShellController::setSpotlightActive(bool active)
{
    if (m_spotlightActive != active) {
        m_spotlightActive = active;
        emit spotlightActiveChanged();
        if (!active) trimMemory();
    }
}

void ShellController::setQuicksettingsActive(bool active)
{
    if (m_quicksettingsActive != active) {
        m_quicksettingsActive = active;
        emit quicksettingsActiveChanged();
        if (!active) trimMemory();
    }
}

void ShellController::setSysmonActive(bool active)
{
    if (m_sysmonActive != active) {
        m_sysmonActive = active;
        emit sysmonActiveChanged();
        if (!active) trimMemory();
    }
}

void ShellController::setMenuActive(bool active)
{
    if (m_menuActive != active) {
        m_menuActive = active;
        emit menuActiveChanged();
        if (!active) trimMemory();
    }
}

void ShellController::setWorkspaceHudActive(bool active)
{
    if (m_workspaceHudActive != active) {
        m_workspaceHudActive = active;
        emit workspaceHudActiveChanged();
        if (!active) trimMemory();
    }
}

void ShellController::toggleSpotlight()
{
    if (!m_spotlightActive) {
        setPendingClipboard(false);
        setSpotlightActive(true);
    } else {
        emit reqSpotlightToggle();
    }
}

void ShellController::showSpotlight()
{
    if (!m_spotlightActive) {
        setPendingClipboard(false);
        setSpotlightActive(true);
    } else {
        emit reqSpotlightShow();
    }
}

void ShellController::hideSpotlight()
{
    if (m_spotlightActive) {
        emit reqSpotlightHide();
    }
}

void ShellController::showSpotlightClipboard()
{
    setPendingClipboard(true);
    if (!m_spotlightActive) {
        setSpotlightActive(true);
    } else {
        emit reqSpotlightClipboard();
    }
}

void ShellController::toggleQuicksettings()
{
    if (!m_quicksettingsActive) {
        setPendingQsNotifs(false);
        setPendingQsWifi(false);
        setQuicksettingsActive(true);
    } else {
        emit reqQuicksettingsToggle();
    }
}

void ShellController::showQuicksettings()
{
    if (!m_quicksettingsActive) {
        setPendingQsNotifs(false);
        setPendingQsWifi(false);
        setQuicksettingsActive(true);
    } else {
        emit reqQuicksettingsShow();
    }
}

void ShellController::hideQuicksettings()
{
    if (m_quicksettingsActive) {
        emit reqQuicksettingsHide();
    }
}

void ShellController::showQuicksettingsWifi()
{
    setPendingQsWifi(true);
    if (!m_quicksettingsActive) {
        setQuicksettingsActive(true);
    } else {
        emit reqQuicksettingsWifi();
    }
}

void ShellController::showQuicksettingsNotifs()
{
    setPendingQsNotifs(true);
    if (!m_quicksettingsActive) {
        setQuicksettingsActive(true);
    } else {
        emit reqQuicksettingsNotifs();
    }
}

void ShellController::toggleSysmon()
{
    if (!m_sysmonActive) {
        setSysmonActive(true);
    } else {
        emit reqSysmonToggle();
    }
}

void ShellController::showSysmon()
{
    if (!m_sysmonActive) {
        setSysmonActive(true);
    } else {
        emit reqSysmonShow();
    }
}

void ShellController::hideSysmon()
{
    if (m_sysmonActive) {
        emit reqSysmonHide();
    }
}

void ShellController::toggleMenu()
{
    if (!m_menuActive) {
        setMenuActive(true);
    } else {
        emit reqMenuToggle();
    }
}

void ShellController::showMenu()
{
    if (!m_menuActive) {
        setMenuActive(true);
    } else {
        emit reqMenuShow();
    }
}

void ShellController::hideMenu()
{
    if (m_menuActive) {
        emit reqMenuHide();
    }
}

void ShellController::toggleWorkspaceHud()
{
    if (!m_workspaceHudActive) {
        setWorkspaceHudActive(true);
    } else {
        emit reqWorkspaceHudToggle();
    }
}

void ShellController::showWorkspaceHud()
{
    if (!m_workspaceHudActive) {
        setWorkspaceHudActive(true);
    } else {
        emit reqWorkspaceHudShow();
    }
}

void ShellController::hideWorkspaceHud()
{
    if (m_workspaceHudActive) {
        emit reqWorkspaceHudHide();
    }
}

void ShellController::registerSpotlightWindow(QObject *obj)
{
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (layer) {
        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight |
            LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom));
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setExclusiveZone(-1);
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
        layer->setScope(QStringLiteral("titan-spotlight"));
    }
}

void ShellController::registerQuicksettingsWindow(QObject *obj)
{
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (layer) {
        int screenHeight = QGuiApplication::primaryScreen()
                               ? QGuiApplication::primaryScreen()->geometry().height()
                               : 1080;
        int availHeight = QGuiApplication::primaryScreen()
                              ? QGuiApplication::primaryScreen()->availableGeometry().height()
                              : screenHeight;

        int topMargin = 40;
        int bottomMargin = 12;
        int rightMargin = 12;
        int panelWidth = 450;
        int targetHeight = qMax(480, availHeight - topMargin - bottomMargin);

        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorTop |
            LayerShellQt::Window::AnchorRight |
            LayerShellQt::Window::AnchorBottom
        ));
        layer->setMargins(QMargins(0, topMargin, rightMargin, bottomMargin));
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setExclusiveZone(0);
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
        layer->setScope(QStringLiteral("titan-quicksettings"));

        window->setWidth(panelWidth);
        window->setHeight(targetHeight);
    }
}

void ShellController::registerSysmonWindow(QObject *obj)
{
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (layer) {
        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorLeft |
            LayerShellQt::Window::AnchorTop |
            LayerShellQt::Window::AnchorBottom));
        layer->setMargins(QMargins(0, 48, 0, 16));
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setExclusiveZone(0);
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
        layer->setScope(QStringLiteral("titan-sysmon"));
        window->setWidth(420);
    }
}

void ShellController::registerMenuWindow(QObject *obj)
{
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    auto *layer = LayerShellQt::Window::get(window);
    if (layer) {
        layer->setAnchors(LayerShellQt::Window::Anchors(
            LayerShellQt::Window::AnchorLeft | LayerShellQt::Window::AnchorRight |
            LayerShellQt::Window::AnchorTop | LayerShellQt::Window::AnchorBottom));
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setExclusiveZone(-1);
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityExclusive);
        layer->setScope(QStringLiteral("titan-menu"));
    }
}

void ShellController::registerWorkspaceHudWindow(QObject *obj)
{
    auto *window = qobject_cast<QQuickWindow *>(obj);
    if (!window) return;
    window->setWidth(1264);
    window->setHeight(320);
    auto *layer = LayerShellQt::Window::get(window);
    if (layer) {
        layer->setLayer(LayerShellQt::Window::LayerOverlay);
        layer->setAnchors(LayerShellQt::Window::Anchors(LayerShellQt::Window::AnchorTop));
        layer->setMargins(QMargins(0, 110, 0, 0));
        layer->setKeyboardInteractivity(LayerShellQt::Window::KeyboardInteractivityOnDemand);
        layer->setScope(QStringLiteral("titan-workspace-hud"));
    }
}
