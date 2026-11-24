#pragma once

#include <QList>
#include <QString>
#include <QStringList>
#include <QVariantList>

/**
 * ReleaseManager — release metadata for the "What's New" experience.
 *
 * Highlights are data (data/release-highlights.json, embedded in the binary and
 * overridable at /usr/share/archtitan/release-highlights.json), never hardcoded
 * into QML. The running release comes from /usr/share/archtitan/release.json.
 */
struct ReleaseHighlight
{
    QString releaseVersion;
    QString id;
    QString title;
    QString body;
    QString feature;  ///< optional tour feature id ("Show me")
    QString glyph;    ///< short glyph/badge text for the card visual
    QString key() const { return releaseVersion + QLatin1Char(':') + id; }
};

struct ReleaseInfo
{
    QString version;
    QString title;
    QString tagline;
    QList<ReleaseHighlight> highlights;
};

class ReleaseManager
{
public:
    /// Numeric, dot-separated comparison ("2026.11" < "2026.11.2" < "2026.12").
    /// Non-numeric segments compare as 0. Returns <0, 0, >0.
    static int compareVersions(const QString &a, const QString &b);

    /// Parses release metadata. Returns false (leaving the manager empty) on invalid JSON.
    bool loadMetadata(const QByteArray &json);
    /// Loads metadata from the system override if present, else from `fallbackJson`.
    bool loadDefault(const QByteArray &fallbackJson);

    /// Version of the OS that is running right now.
    QString currentVersion() const { return m_currentVersion; }
    void setCurrentVersion(const QString &v) { m_currentVersion = v; }
    /// Reads /usr/share/archtitan/release.json (or `path`); falls back to the newest known release.
    void detectCurrentVersion(const QString &path = QString());

    const QList<ReleaseInfo> &releases() const { return m_releases; }

    /// Highlights introduced after `lastSeen` (exclusive) up to the current release
    /// (inclusive) that the user has not dismissed. Newest release first.
    QList<ReleaseHighlight> pendingHighlights(const QString &lastSeen,
                                              const QStringList &dismissedKeys) const;

    /// Title/tagline for the newest release that has pending highlights.
    ReleaseInfo headlineRelease(const QString &lastSeen) const;

    static QVariantList toVariantList(const QList<ReleaseHighlight> &list);

private:
    QList<ReleaseInfo> m_releases;
    QString m_currentVersion;
};

