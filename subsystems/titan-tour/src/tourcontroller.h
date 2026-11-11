#pragma once

#include <QObject>
#include <QString>
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

    QString activeProfile() const { return m_activeProfile; }
    void setActiveProfile(const QString &profile);

    Q_INVOKABLE void playSound(const QString &soundId);
    Q_INVOKABLE void launchInstaller();
    Q_INVOKABLE void launchTerminal();
    Q_INVOKABLE void toggleControlCenter();
    Q_INVOKABLE void toggleSpotlight();
    Q_INVOKABLE void launchWallpaperPicker();
    Q_INVOKABLE void launchSettings();
    Q_INVOKABLE void testAudio();
    Q_INVOKABLE void setPowerProfile(const QString &profile);
    Q_INVOKABLE void finishTour(bool dontShowAgain);
    Q_INVOKABLE void closeApp();

signals:
    void soundFxEnabledChanged();
    void showOnStartupChanged();
    void activeProfileChanged();

private:
    void detectHardwareInfo();
    void loadPreferences();
    void savePreferences();

    bool m_isLiveMode{false};
    bool m_soundFxEnabled{true};
    bool m_showOnStartup{true};
    QString m_cpuName{"Intel / AMD Processor"};
    QString m_ramTotal{"16 GB RAM"};
    QString m_gpuName{"Accelerated Graphics"};
    QString m_activeProfile{"balanced"};
};

