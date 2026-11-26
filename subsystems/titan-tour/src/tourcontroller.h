#pragma once

#include <QObject>
#include <QRectF>
#include <QSize>
#include <QString>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

#include "featureadapter.h"
#include "releasemanager.h"
#include "tourstate.h"

class TourController : public QObject
{
    Q_OBJECT

    // Mode & navigation
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentStepChanged)
    Q_PROPERTY(int totalSteps READ totalSteps NOTIFY stepsChanged)
    Q_PROPERTY(QVariantList steps READ steps NOTIFY stepsChanged)
    Q_PROPERTY(QVariantMap currentStep READ currentStep NOTIFY currentStepChanged)
    Q_PROPERTY(QVariantMap welcomeData READ welcomeData CONSTANT)
    Q_PROPERTY(QString currentScene READ currentScene NOTIFY currentStepChanged)
    Q_PROPERTY(QString currentFeatureId READ currentFeatureId NOTIFY currentStepChanged)
    Q_PROPERTY(qreal progress READ progress NOTIFY currentStepChanged)
    Q_PROPERTY(bool reducedMotion READ reducedMotion WRITE setReducedMotion NOTIFY reducedMotionChanged)

    // Environment & branding
    Q_PROPERTY(bool isLiveMode READ isLiveMode CONSTANT)
    Q_PROPERTY(bool soundFxEnabled READ soundFxEnabled WRITE setSoundFxEnabled NOTIFY soundFxEnabledChanged)
    Q_PROPERTY(QString logoUrl READ logoUrl CONSTANT)
    Q_PROPERTY(QString activeWallpaperUrl READ activeWallpaperUrl NOTIFY previewChanged)

    // Live Spotlight & feature adapter state
    Q_PROPERTY(bool liveFeatureOpen READ liveFeatureOpen NOTIFY liveFeatureChanged)
    Q_PROPERTY(bool featureTried READ featureTried NOTIFY liveFeatureChanged)
    Q_PROPERTY(QRectF spotlightRect READ spotlightRect NOTIFY liveFeatureChanged)
    Q_PROPERTY(bool hasMediaPlayer READ hasMediaPlayer NOTIFY liveFeatureChanged)

    // Live hardware & THM telemetry (Step 07)
    Q_PROPERTY(QString cpuName READ cpuName NOTIFY hardwareDetected)
    Q_PROPERTY(QString ramTotal READ ramTotal NOTIFY hardwareDetected)
    Q_PROPERTY(QString gpuName READ gpuName NOTIFY hardwareDetected)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString osVersion READ osVersion CONSTANT)
    Q_PROPERTY(qreal cpuUsage READ cpuUsage NOTIFY telemetryChanged)
    Q_PROPERTY(qreal ramUsage READ ramUsage NOTIFY telemetryChanged)
    Q_PROPERTY(int cpuTemp READ cpuTemp NOTIFY telemetryChanged)
    Q_PROPERTY(qreal psiCpu READ psiCpu NOTIFY telemetryChanged)
    Q_PROPERTY(qreal psiMemory READ psiMemory NOTIFY telemetryChanged)
    Q_PROPERTY(int thmWorkloads READ thmWorkloads NOTIFY telemetryChanged)
    Q_PROPERTY(QString thmSliceSummary READ thmSliceSummary NOTIFY telemetryChanged)
    Q_PROPERTY(QString activeProfile READ activeProfile WRITE setActiveProfile NOTIFY activeProfileChanged)

    // Personalization & non-destructive preview (Step 09)
    Q_PROPERTY(QVariantList themes READ themes NOTIFY themesChanged)
    Q_PROPERTY(QVariantList wallpapers READ wallpapers NOTIFY wallpapersChanged)
    Q_PROPERTY(QString installedThemeId READ installedThemeId NOTIFY previewChanged)
    Q_PROPERTY(QString previewThemeId READ previewThemeId NOTIFY previewChanged)
    Q_PROPERTY(QString previewThemeName READ previewThemeName NOTIFY previewChanged)
    Q_PROPERTY(QString previewAccent READ previewAccent NOTIFY previewChanged)
    Q_PROPERTY(QString previewAccent2 READ previewAccent2 NOTIFY previewChanged)
    Q_PROPERTY(QString previewWallpaper READ previewWallpaper NOTIFY previewChanged)
    Q_PROPERTY(bool themeModifiedInPreview READ themeModifiedInPreview NOTIFY previewChanged)
    Q_PROPERTY(bool themeAppliedFeedback READ themeAppliedFeedback NOTIFY previewChanged)

    // What's New mode
    Q_PROPERTY(QString releaseVersion READ releaseVersion NOTIFY releaseChanged)
    Q_PROPERTY(QString releaseTitle READ releaseTitle NOTIFY releaseChanged)
    Q_PROPERTY(QString releaseTagline READ releaseTagline NOTIFY releaseChanged)
    Q_PROPERTY(QVariantList releaseHighlights READ releaseHighlights NOTIFY releaseChanged)

public:
    explicit TourController(QObject *parent = nullptr);
    ~TourController() override;

    /// Returns false if `--autostart` determines nothing needs to be shown.
    bool configureSession(const QString &requestedMode,
                          const QString &requestedStep,
                          bool autostart,
                          bool force);

    QString mode() const { return m_mode; }
    void setMode(const QString &mode);

    int currentIndex() const { return m_currentIndex; }
    void setCurrentIndex(int index);
    int totalSteps() const { return m_steps.size(); }
    QVariantList steps() const { return m_steps; }
    QVariantMap currentStep() const;
    QVariantMap welcomeData() const { return m_welcomeData; }
    QString currentScene() const;
    QString currentFeatureId() const;
    qreal progress() const;

    bool reducedMotion() const { return m_reducedMotion; }
    void setReducedMotion(bool on);

    bool isLiveMode() const { return m_isLiveMode; }
    bool soundFxEnabled() const { return m_soundFxEnabled; }
    void setSoundFxEnabled(bool enabled);

    QString logoUrl() const { return m_logoUrl; }
    QString activeWallpaperUrl() const;

    bool liveFeatureOpen() const { return m_liveFeatureOpen; }
    bool featureTried() const { return m_adapter.tried(); }
    QRectF spotlightRect() const { return m_adapter.rect(); }
    bool hasMediaPlayer() const { return m_adapter.hasMediaPlayer(); }

    QString cpuName() const { return m_cpuName; }
    QString ramTotal() const { return m_ramTotal; }
    QString gpuName() const { return m_gpuName; }
    QString kernelVersion() const { return m_kernelVersion; }
    QString osVersion() const { return m_osVersion; }
    qreal cpuUsage() const { return m_cpuUsage; }
    qreal ramUsage() const { return m_ramUsage; }
    int cpuTemp() const { return m_cpuTemp; }
    qreal psiCpu() const { return m_psiCpu; }
    qreal psiMemory() const { return m_psiMemory; }
    int thmWorkloads() const { return m_thmWorkloads; }
    QString thmSliceSummary() const { return m_thmSliceSummary; }
    QString activeProfile() const { return m_activeProfile; }
    void setActiveProfile(const QString &profile);

    QVariantList themes() const { return m_themes; }
    QVariantList wallpapers() const { return m_wallpapers; }
    QString installedThemeId() const { return m_installedThemeId; }
    QString previewThemeId() const { return m_previewThemeId; }
    QString previewThemeName() const { return m_previewThemeName; }
    QString previewAccent() const { return m_previewAccent; }
    QString previewAccent2() const { return m_previewAccent2; }
    QString previewWallpaper() const { return m_previewWallpaper; }
    bool themeModifiedInPreview() const {
        return m_previewThemeId != m_installedThemeId || m_previewWallpaper != m_installedWallpaper;
    }
    bool themeAppliedFeedback() const { return m_themeAppliedFeedback; }

    QString releaseVersion() const { return m_releaseInfo.version; }
    QString releaseTitle() const { return m_releaseInfo.title; }
    QString releaseTagline() const { return m_releaseInfo.tagline; }
    QVariantList releaseHighlights() const { return m_releaseHighlights; }

    FeatureAdapter *adapter() { return &m_adapter; }
    TourState *state() { return &m_state; }

    // QML Navigation & Actions
    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void goToStep(int index);
    Q_INVOKABLE bool goToStepId(const QString &stepId);
    Q_INVOKABLE void skipFeature();
    Q_INVOKABLE void skipForNow();
    Q_INVOKABLE void restartTour();
    Q_INVOKABLE void finishTour();
    Q_INVOKABLE void acknowledgeWhatsNew();
    Q_INVOKABLE void jumpToFeatureFromWhatsNew(const QString &featureId);

    // Live feature spotlight controls
    Q_INVOKABLE void updateViewportSize(int width, int height);
    Q_INVOKABLE void activateLiveFeature();
    Q_INVOKABLE void dismissLiveFeature();
    Q_INVOKABLE void toggleLiveFeature();
    Q_INVOKABLE bool isFeatureAvailable(const QString &featureId) const;

    // Preview & personalization (Step 09)
    Q_INVOKABLE void selectPreviewTheme(const QString &themeId);
    Q_INVOKABLE void selectPreviewWallpaper(const QString &wallpaperPath);
    Q_INVOKABLE void resetPreviewToInstalled();
    Q_INVOKABLE void applyPreviewChoice();

    // Direct OS app launchers
    Q_INVOKABLE void launchSettings();
    Q_INVOKABLE void launchWallpaperPicker();
    Q_INVOKABLE void launchInstaller();
    Q_INVOKABLE void playSound(const QString &soundId);

signals:
    void modeChanged();
    void stepsChanged();
    void currentStepChanged();
    void reducedMotionChanged();
    void soundFxEnabledChanged();
    void liveFeatureChanged();
    void hardwareDetected();
    void telemetryChanged();
    void activeProfileChanged();
    void themesChanged();
    void wallpapersChanged();
    void previewChanged();
    void releaseChanged();

private slots:
    void sampleTelemetry();

private:
    void loadDataFiles();
    void detectHardwareInfo();
    void detectPowerProfile();
    void resolveAssetsAndThemes();
    void onStepEntered();
    void setPowerProfileInternal(const QString &profile);

    TourState m_state;
    FeatureAdapter m_adapter;
    ReleaseManager m_releases;

    QString m_mode{QStringLiteral("welcome")};
    QVariantList m_steps;
    QVariantMap m_welcomeData;
    int m_currentIndex{0};
    bool m_reducedMotion{false};
    bool m_isLiveMode{false};
    bool m_soundFxEnabled{true};
    bool m_liveFeatureOpen{false};
    QSize m_viewport{1920, 1080};

    QString m_logoUrl;
    QString m_cpuName{QStringLiteral("x86_64 Multi-Core Processor")};
    QString m_ramTotal{QStringLiteral("16.0 GB DDR")};
    QString m_gpuName{QStringLiteral("Wayland Accelerated GPU")};
    QString m_kernelVersion;
    QString m_osVersion{QStringLiteral("ArchTitan 2.0")};

    qreal m_cpuUsage{0.14};
    qreal m_ramUsage{0.28};
    int m_cpuTemp{42};
    qreal m_psiCpu{0.0};
    qreal m_psiMemory{0.0};
    int m_thmWorkloads{12};
    QString m_thmSliceSummary{QStringLiteral("latency · active · background")};
    QString m_activeProfile{QStringLiteral("balanced")};
    qulonglong m_prevIdle{0};
    qulonglong m_prevTotal{0};
    QTimer m_telemetryTimer;

    QVariantList m_themes;
    QVariantList m_wallpapers;
    QString m_installedThemeId{QStringLiteral("archtitan")};
    QString m_installedWallpaper;
    QString m_previewThemeId{QStringLiteral("archtitan")};
    QString m_previewThemeName{QStringLiteral("ArchTitan Signature")};
    QString m_previewAccent{QStringLiteral("#00D2FF")};
    QString m_previewAccent2{QStringLiteral("#0284C7")};
    QString m_previewWallpaper;
    bool m_themeAppliedFeedback{false};

    ReleaseInfo m_releaseInfo;
    QVariantList m_releaseHighlights;
};
