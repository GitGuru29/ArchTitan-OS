#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QProcess>

class TourController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLiveMode READ isLiveMode CONSTANT)
    Q_PROPERTY(bool soundFxEnabled READ soundFxEnabled WRITE setSoundFxEnabled NOTIFY soundFxEnabledChanged)
    Q_PROPERTY(bool showOnStartup READ showOnStartup WRITE setShowOnStartup NOTIFY showOnStartupChanged)
    Q_PROPERTY(QString cpuName READ cpuName NOTIFY hardwareDetected)
    Q_PROPERTY(QString ramTotal READ ramTotal NOTIFY hardwareDetected)
    Q_PROPERTY(QString gpuName READ gpuName NOTIFY hardwareDetected)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString osVersion READ osVersion CONSTANT)
    Q_PROPERTY(QString logoUrl READ logoUrl CONSTANT)
    Q_PROPERTY(QVariantList wallpapers READ wallpapers NOTIFY wallpapersChanged)
    Q_PROPERTY(QString selectedWallpaper READ selectedWallpaper NOTIFY selectedWallpaperChanged)
    Q_PROPERTY(QString activeProfile READ activeProfile WRITE setActiveProfile NOTIFY activeProfileChanged)

public:
    explicit TourController(QObject *parent = nullptr);

    bool isLiveMode() const { return m_isLiveMode; }
    bool soundFxEnabled() const { return m_soundFxEnabled; }
    void setSoundFxEnabled(bool enabled);

    bool showOnStartup() const { return m_showOnStartup; }
    void setShowOnStartup(bool show);

    QString cpuName() const { return m_cpuName; }
    QString ramTotal() const { return m_ramTotal; }
    QString gpuName() const { return m_gpuName; }
    QString kernelVersion() const { return m_kernelVersion; }
    QString osVersion() const { return m_osVersion; }
    QString logoUrl() const { return m_logoUrl; }
    QVariantList wallpapers() const { return m_wallpapers; }
    QString selectedWallpaper() const { return m_selectedWallpaper; }

    QString activeProfile() const { return m_activeProfile; }
    void setActiveProfile(const QString &profile);

    Q_INVOKABLE void playSound(const QString &soundId);
    Q_INVOKABLE void launchInstaller();
    Q_INVOKABLE void launchTerminal();
    Q_INVOKABLE void launchBrowser();
    Q_INVOKABLE void launchFileManager();
    Q_INVOKABLE void launchSettings();
    Q_INVOKABLE void toggleControlCenter();
    Q_INVOKABLE void toggleSpotlight();
    Q_INVOKABLE void toggleSysmon();
    Q_INVOKABLE void toggleFocus();
    Q_INVOKABLE void toggleMenu();
    Q_INVOKABLE void applyWallpaper(const QString &path);
    Q_INVOKABLE void setPowerProfile(const QString &profile);
    Q_INVOKABLE void finishTour(bool dontShowAgain);
    Q_INVOKABLE void closeApp();

signals:
    void soundFxEnabledChanged();
    void showOnStartupChanged();
    void activeProfileChanged();
    void selectedWallpaperChanged();
    void wallpapersChanged();
    void hardwareDetected();

private:
    void detectHardwareInfo();
    void resolveAssets();
    void loadPreferences();
    void savePreferences();
    void detectPowerProfile();

    bool m_isLiveMode{false};
    bool m_soundFxEnabled{true};
    bool m_showOnStartup{true};
    QString m_cpuName{"Intel / AMD Processor"};
    QString m_ramTotal{"16.0 GB"};
    QString m_gpuName{"Hardware Accelerated GPU"};
    QString m_kernelVersion{"Linux Zen"};
    QString m_osVersion{"ArchTitan 2026.11"};
    QString m_logoUrl;
    QVariantList m_wallpapers;
    QString m_selectedWallpaper;
    QString m_activeProfile{"balanced"};
};
