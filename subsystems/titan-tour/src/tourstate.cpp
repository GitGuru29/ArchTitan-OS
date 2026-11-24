#include "tourstate.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QSaveFile>

TourState::TourState(const QString &configDir, QObject *parent)
    : QObject(parent)
    , m_configDir(configDir)
{
}

QString TourState::defaultConfigDir()
{
    return QDir::homePath() + QStringLiteral("/.config/archtitan");
}

QString TourState::statePath() const
{
    return m_configDir + QStringLiteral("/tour-state.json");
}

QString TourState::legacyMarkerPath() const
{
    return m_configDir + QStringLiteral("/.tour-done");
}

static QStringList toStringList(const QJsonValue &v)
{
    QStringList out;
    const QJsonArray arr = v.toArray();
    for (const QJsonValue &item : arr) {
        const QString s = item.toString();
        if (!s.isEmpty() && !out.contains(s)) out << s;
    }
    return out;
}

void TourState::fromJson(const QJsonObject &obj)
{
    m_tourVersion = obj.value(QStringLiteral("tour_version")).toInt(kTourVersion);
    m_welcomeCompleted = obj.value(QStringLiteral("welcome_completed")).toBool(false);
    m_lastSeenRelease = obj.value(QStringLiteral("last_seen_release")).toString();
    m_completedFeatures = toStringList(obj.value(QStringLiteral("completed_features")));
    m_dismissedHighlights = toStringList(obj.value(QStringLiteral("dismissed_release_highlights")));
    m_skipCount = qMax(0, obj.value(QStringLiteral("skip_count")).toInt(0));
}

QJsonObject TourState::toJson() const
{
    QJsonObject obj;
    obj.insert(QStringLiteral("tour_version"), kTourVersion);
    obj.insert(QStringLiteral("welcome_completed"), m_welcomeCompleted);
    obj.insert(QStringLiteral("last_seen_release"), m_lastSeenRelease);
    obj.insert(QStringLiteral("completed_features"), QJsonArray::fromStringList(m_completedFeatures));
    obj.insert(QStringLiteral("dismissed_release_highlights"), QJsonArray::fromStringList(m_dismissedHighlights));
    obj.insert(QStringLiteral("skip_count"), m_skipCount);
    return obj;
}

void TourState::load(const QString &currentRelease)
{
    m_migrated = false;

    QFile f(statePath());
    if (f.open(QIODevice::ReadOnly)) {
        QJsonParseError err{};
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll(), &err);
        if (err.error == QJsonParseError::NoError && doc.isObject()) {
            fromJson(doc.object());
            return;
        }
        // Corrupt state: fall through and rebuild rather than crash-looping.
    }

    // No (usable) state file: migrate the legacy marker if there is one.
    m_welcomeCompleted = false;
    m_lastSeenRelease.clear();
    m_completedFeatures.clear();
    m_dismissedHighlights.clear();
    m_skipCount = 0;

    if (QFile::exists(legacyMarkerPath())) {
        m_welcomeCompleted = true;
        m_lastSeenRelease = currentRelease;  // don't surprise an existing user with "What's New"
        m_migrated = true;
        save();
    }
}

bool TourState::save() const
{
    if (!QDir().mkpath(m_configDir)) return false;
    QSaveFile f(statePath());
    if (!f.open(QIODevice::WriteOnly)) return false;
    f.write(QJsonDocument(toJson()).toJson(QJsonDocument::Indented));
    return f.commit();
}

void TourState::setWelcomeCompleted(bool done)
{
    m_welcomeCompleted = done;
    if (done) {
        // Keep the legacy marker in sync for any external tooling that still reads it.
        QDir().mkpath(m_configDir);
        QFile marker(legacyMarkerPath());
        if (marker.open(QIODevice::WriteOnly)) marker.write("1\n");
    }
}

void TourState::setLastSeenRelease(const QString &release)
{
    m_lastSeenRelease = release;
}

void TourState::markFeatureCompleted(const QString &featureId)
{
    if (!featureId.isEmpty() && !m_completedFeatures.contains(featureId))
        m_completedFeatures << featureId;
}

void TourState::dismissHighlight(const QString &highlightKey)
{
    if (!highlightKey.isEmpty() && !m_dismissedHighlights.contains(highlightKey))
        m_dismissedHighlights << highlightKey;
}

bool TourState::registerSkip()
{
    ++m_skipCount;
    if (m_skipCount >= kMaxSkips) {
        setWelcomeCompleted(true);
        return true;
    }
    return false;
}

void TourState::reset()
{
    m_welcomeCompleted = false;
    m_lastSeenRelease.clear();
    m_completedFeatures.clear();
    m_dismissedHighlights.clear();
    m_skipCount = 0;
    QFile::remove(legacyMarkerPath());
}

