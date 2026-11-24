#pragma once

#include <QObject>
#include <malloc.h>

class ShellController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool spotlightActive READ spotlightActive WRITE setSpotlightActive NOTIFY spotlightActiveChanged)
    Q_PROPERTY(bool quicksettingsActive READ quicksettingsActive WRITE setQuicksettingsActive NOTIFY quicksettingsActiveChanged)
    Q_PROPERTY(bool sysmonActive READ sysmonActive WRITE setSysmonActive NOTIFY sysmonActiveChanged)
    Q_PROPERTY(bool menuActive READ menuActive WRITE setMenuActive NOTIFY menuActiveChanged)
    Q_PROPERTY(bool workspaceHudActive READ workspaceHudActive WRITE setWorkspaceHudActive NOTIFY workspaceHudActiveChanged)

    Q_PROPERTY(bool pendingClipboard READ pendingClipboard WRITE setPendingClipboard NOTIFY pendingClipboardChanged)
    Q_PROPERTY(bool pendingQsNotifs READ pendingQsNotifs WRITE setPendingQsNotifs NOTIFY pendingQsNotifsChanged)
    Q_PROPERTY(bool pendingQsWifi READ pendingQsWifi WRITE setPendingQsWifi NOTIFY pendingQsWifiChanged)

public:
    explicit ShellController(QObject *parent = nullptr);

    bool spotlightActive() const { return m_spotlightActive; }
    bool quicksettingsActive() const { return m_quicksettingsActive; }
    bool sysmonActive() const { return m_sysmonActive; }
    bool menuActive() const { return m_menuActive; }
    bool workspaceHudActive() const { return m_workspaceHudActive; }

    bool pendingClipboard() const { return m_pendingClipboard; }
    void setPendingClipboard(bool v) { if (m_pendingClipboard != v) { m_pendingClipboard = v; emit pendingClipboardChanged(); } }

    bool pendingQsNotifs() const { return m_pendingQsNotifs; }
    void setPendingQsNotifs(bool v) { if (m_pendingQsNotifs != v) { m_pendingQsNotifs = v; emit pendingQsNotifsChanged(); } }

    bool pendingQsWifi() const { return m_pendingQsWifi; }
    void setPendingQsWifi(bool v) { if (m_pendingQsWifi != v) { m_pendingQsWifi = v; emit pendingQsWifiChanged(); } }

    void setSpotlightActive(bool active);
    void setQuicksettingsActive(bool active);
    void setSysmonActive(bool active);
    void setMenuActive(bool active);
    void setWorkspaceHudActive(bool active);

    Q_INVOKABLE void trimMemory() { malloc_trim(0); }

    Q_INVOKABLE void registerSpotlightWindow(QObject *window);
    Q_INVOKABLE void registerQuicksettingsWindow(QObject *window);
    Q_INVOKABLE void registerSysmonWindow(QObject *window);
    Q_INVOKABLE void registerMenuWindow(QObject *window);
    Q_INVOKABLE void registerWorkspaceHudWindow(QObject *window);

public slots:
    void toggleSpotlight();
    void showSpotlight();
    void hideSpotlight();
    void showSpotlightClipboard();

    void toggleQuicksettings();
    void showQuicksettings();
    void hideQuicksettings();
    void showQuicksettingsWifi();
    void showQuicksettingsNotifs();

    void toggleSysmon();
    void showSysmon();
    void hideSysmon();

    void toggleMenu();
    void showMenu();
    void hideMenu();

    void toggleWorkspaceHud();
    void showWorkspaceHud();
    void hideWorkspaceHud();

signals:
    void spotlightActiveChanged();
    void quicksettingsActiveChanged();
    void sysmonActiveChanged();
    void menuActiveChanged();
    void workspaceHudActiveChanged();

    void pendingClipboardChanged();
    void pendingQsNotifsChanged();
    void pendingQsWifiChanged();

    // Direct event signals for open instances
    void reqSpotlightToggle();
    void reqSpotlightShow();
    void reqSpotlightHide();
    void reqSpotlightClipboard();

    void reqQuicksettingsToggle();
    void reqQuicksettingsShow();
    void reqQuicksettingsHide();
    void reqQuicksettingsWifi();
    void reqQuicksettingsNotifs();

    void reqSysmonToggle();
    void reqSysmonShow();
    void reqSysmonHide();

    void reqMenuToggle();
    void reqMenuShow();
    void reqMenuHide();

    void reqWorkspaceHudToggle();
    void reqWorkspaceHudShow();
    void reqWorkspaceHudHide();

private:
    bool m_spotlightActive = false;
    bool m_quicksettingsActive = false;
    bool m_sysmonActive = false;
    bool m_menuActive = false;
    bool m_workspaceHudActive = false;

    bool m_pendingClipboard = false;
    bool m_pendingQsNotifs = false;
    bool m_pendingQsWifi = false;
};
