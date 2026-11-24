#pragma once

#include <QJsonObject>
#include <QObject>
#include <QString>
#include <QStringList>

/**
 * TourState — version-aware persistent state for Titan Tour.
 *
 * Lives in <configDir>/tour-state.json. Replaces the single `.tour-done`
 * marker: an existing marker is migrated on first load (the user has already
 * seen the welcome experience, so they are not shown it again).
 *
 *   {
 *     "tour_version": 2,
 *     "welcome_completed": true,
 *     "last_seen_release": "2026.11",
 *     "completed_features": ["spotlight", "workspace"],
 *     "dismissed_release_highlights": ["2026.11:titan-shell"],
 *     "skip_count": 0
 *   }
 */
class TourState : public QObject
{
    Q_OBJECT

public:
    static constexpr int kTourVersion = 2;
    /// "Skip for now" is honoured this many times; after that the welcome is
    /// treated as seen so the tour never nags on every login.
    static constexpr int kMaxSkips = 2;

    explicit TourState(const QString &configDir, QObject *parent = nullptr);

    static QString defaultConfigDir();

    QString statePath() const;
    QString legacyMarkerPath() const;

    /// Loads state from disk. When no state exists but the legacy `.tour-done`
    /// marker does, state is migrated (welcome completed, release acknowledged
    /// as `currentRelease`) and written back immediately.
    void load(const QString &currentRelease);
    bool save() const;

    int tourVersion() const { return m_tourVersion; }
    bool welcomeCompleted() const { return m_welcomeCompleted; }
    QString lastSeenRelease() const { return m_lastSeenRelease; }
    QStringList completedFeatures() const { return m_completedFeatures; }
    QStringList dismissedHighlights() const { return m_dismissedHighlights; }
    int skipCount() const { return m_skipCount; }
    bool migratedFromLegacy() const { return m_migrated; }

    void setWelcomeCompleted(bool done);
    void setLastSeenRelease(const QString &release);
    void markFeatureCompleted(const QString &featureId);
    void dismissHighlight(const QString &highlightKey);
    /// Records a "Skip for now"; returns true when the skip budget is spent and
    /// the welcome was therefore marked completed.
    bool registerSkip();
    void reset();

    QJsonObject toJson() const;
    void fromJson(const QJsonObject &obj);

private:
    QString m_configDir;
    int m_tourVersion{kTourVersion};
    bool m_welcomeCompleted{false};
    QString m_lastSeenRelease;
    QStringList m_completedFeatures;
    QStringList m_dismissedHighlights;
    int m_skipCount{0};
    bool m_migrated{false};
};

