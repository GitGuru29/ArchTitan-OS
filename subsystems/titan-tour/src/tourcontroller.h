#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QTimer>
#include <QProcess>

class TourController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLiveMode READ isLiveMode CONSTANT)
    Q_PROPERTY(bool soundFxEnabled READ soundFxEnabled WRITE setSoundFxEnabled NOTIFY soundFxEnabledChanged)
    Q_PROPERTY(bool showOnStartup READ showOnStartup WRITE setShowOnStartup NOTIFY showOnStartupChanged)
    Q_PROPERTY(QString cpuName READ cpuName CONSTANT)
    Q_PROPERTY(QString ramTotal READ ramTotal CONSTANT)
    Q_PROPERTY(QString gpuName READ gpuName CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString logoUrl READ logoUrl CONSTANT)
    Q_PROPERTY(QVariantList wallpapers READ wallpapers CONSTANT)
    Q_PROPERTY(QString selectedWallpaper READ selectedWallpaper NOTIFY selectedWallpaperChanged)
    Q_PROPERTY(QString activeProfile READ activeProfile WRITE setActiveProfile NOTIFY activeProfileChanged)

    // Live telemetry properties (0.0 .. 1.0)
    Q_PROPERTY(qreal cpuUsage READ cpuUsage NOTIFY telemetryChanged)
    Q_PROPERTY(qreal ramUsage READ ramUsage NOTIFY telemetryChanged)
    Q_PROPERTY(int cpuTemp READ cpuTemp NOTIFY telemetryChanged)
    Q_PROPERTY(qreal psiMemory READ psiMemory NOTIFY telemetryChanged)
    Q_PROPERTY(QVariantList cpuHistory READ cpuHistory NOTIFY telemetryChanged)

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
    QString logoUrl() const { return m_logoUrl; }
    QVariantList wallpapers() const { return m_wallpapers; }
    QString selectedWallpaper() const { return m_selectedWallpaper; }

    QString activeProfile() const { return m_activeProfile; }
    void setActiveProfile(const QString &profile);

    qreal cpuUsage() const { return m_cpuUsage; }
    qreal ramUsage() const { return m_ramUsage; }
    int cpuTemp() const { return m_cpuTemp; }
    qreal psiMemory() const { return m_psiMemory; }
    QVariantList cpuHistory() const { return m_cpuHistory; }

    Q_INVOKABLE void playSound(const QString &soundId);
    Q_INVOKABLE void launchInstaller();
    Q_INVOKABLE void launchTerminal();
    Q_INVOKABLE void toggleControlCenter();
    Q_INVOKABLE void toggleSpotlight();
    Q_INVOKABLE void toggleSysmon();
    Q_INVOKABLE void toggleMenu();
    Q_INVOKABLE void launchWallpaperPicker();
    Q_INVOKABLE void applyWallpaper(const QString &path);
    Q_INVOKABLE void launchSettings();
    Q_INVOKABLE void testAudio();
    Q_INVOKABLE void setPowerProfile(const QString &profile);
    Q_INVOKABLE void finishTour(bool dontShowAgain);
    Q_INVOKABLE void closeApp();

signals:
    void soundFxEnabledChanged();
    void showOnStartupChanged();
    void activeProfileChanged();
    void selectedWallpaperChanged();
    void telemetryChanged();

private slots:
    void pollTelemetry();

private:
    void detectHardwareInfo();
    void resolveAssets();
    void loadPreferences();
    void savePreferences();

    bool m_isLiveMode{false};
    bool m_soundFxEnabled{true};
    bool m_showOnStartup{true};
    QString m_cpuName{"AMD / Intel x86_64"};
    QString m_ramTotal{"16.0 GB"};
    QString m_gpuName{"Wayland Accelerated GPU"};
    QString m_kernelVersion{"Linux Zen"};
    QString m_logoUrl;
    QVariantList m_wallpapers;
    QString m_selectedWallpaper;
    QString m_activeProfile{"balanced"};

    qreal m_cpuUsage{0.18};
    qreal m_ramUsage{0.34};
    int m_cpuTemp{44};
    qreal m_psiMemory{0.0};
    QVariantList m_cpuHistory;
    qulonglong m_prevIdle{0};
    qulonglong m_prevTotal{0};
    QTimer *m_telemetryTimer{nullptr};
};
