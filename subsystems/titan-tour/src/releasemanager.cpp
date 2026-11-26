#include "releasemanager.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QVariantMap>

#include <algorithm>

int ReleaseManager::compareVersions(const QString &a, const QString &b)
{
    const QStringList pa = a.split(QLatin1Char('.'), Qt::SkipEmptyParts);
    const QStringList pb = b.split(QLatin1Char('.'), Qt::SkipEmptyParts);
    const int n = qMax(pa.size(), pb.size());
    for (int i = 0; i < n; ++i) {
        const int va = i < pa.size() ? pa.at(i).toInt() : 0;
        const int vb = i < pb.size() ? pb.at(i).toInt() : 0;
        if (va != vb) return va < vb ? -1 : 1;
    }
    return 0;
}

bool ReleaseManager::loadMetadata(const QByteArray &json)
{
    m_releases.clear();
    QJsonParseError err{};
    const QJsonDocument doc = QJsonDocument::fromJson(json, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject()) return false;

    const QJsonArray rels = doc.object().value(QStringLiteral("releases")).toArray();
    for (const QJsonValue &rv : rels) {
        const QJsonObject ro = rv.toObject();
        ReleaseInfo info;
        info.version = ro.value(QStringLiteral("version")).toString();
        if (info.version.isEmpty()) continue;
        info.title = ro.value(QStringLiteral("title")).toString();
        info.tagline = ro.value(QStringLiteral("tagline")).toString();
        for (const QJsonValue &hv : ro.value(QStringLiteral("highlights")).toArray()) {
            const QJsonObject ho = hv.toObject();
            ReleaseHighlight h;
            h.releaseVersion = info.version;
            h.id = ho.value(QStringLiteral("id")).toString();
            if (h.id.isEmpty()) continue;
            h.title = ho.value(QStringLiteral("title")).toString();
            h.body = ho.value(QStringLiteral("body")).toString();
            h.feature = ho.value(QStringLiteral("feature")).toString();
            h.glyph = ho.value(QStringLiteral("glyph")).toString();
            info.highlights << h;
        }
        m_releases << info;
    }
    std::sort(m_releases.begin(), m_releases.end(), [](const ReleaseInfo &x, const ReleaseInfo &y) {
        return compareVersions(x.version, y.version) > 0;  // newest first
    });
    return true;
}

bool ReleaseManager::loadDefault(const QByteArray &fallbackJson)
{
    QFile sys(QStringLiteral("/usr/share/archtitan/release-highlights.json"));
    if (sys.open(QIODevice::ReadOnly) && loadMetadata(sys.readAll())) return true;
    return loadMetadata(fallbackJson);
}

void ReleaseManager::detectCurrentVersion(const QString &path)
{
    QFile f(path.isEmpty() ? QStringLiteral("/usr/share/archtitan/release.json") : path);
    if (f.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(f.readAll());
        const QString v = doc.object().value(QStringLiteral("version")).toString();
        if (!v.isEmpty()) {
            m_currentVersion = v;
            return;
        }
    }
    m_currentVersion = m_releases.isEmpty() ? QString() : m_releases.first().version;
}

QList<ReleaseHighlight> ReleaseManager::pendingHighlights(const QString &lastSeen,
                                                          const QStringList &dismissedKeys) const
{
    QList<ReleaseHighlight> out;
    for (const ReleaseInfo &rel : m_releases) {
        if (!m_currentVersion.isEmpty() && compareVersions(rel.version, m_currentVersion) > 0) continue;
        if (!lastSeen.isEmpty() && compareVersions(rel.version, lastSeen) <= 0) continue;
        for (const ReleaseHighlight &h : rel.highlights) {
            if (!dismissedKeys.contains(h.key())) out << h;
        }
    }
    return out;
}

ReleaseInfo ReleaseManager::headlineRelease(const QString &lastSeen) const
{
    for (const ReleaseInfo &rel : m_releases) {
        if (!m_currentVersion.isEmpty() && compareVersions(rel.version, m_currentVersion) > 0) continue;
        if (!lastSeen.isEmpty() && compareVersions(rel.version, lastSeen) <= 0) continue;
        return rel;
    }
    return ReleaseInfo{};
}

QVariantList ReleaseManager::toVariantList(const QList<ReleaseHighlight> &list)
{
    QVariantList out;
    for (const ReleaseHighlight &h : list) {
        QVariantMap m;
        m[QStringLiteral("key")] = h.key();
        m[QStringLiteral("id")] = h.id;
        m[QStringLiteral("release")] = h.releaseVersion;
        m[QStringLiteral("title")] = h.title;
        m[QStringLiteral("body")] = h.body;
        m[QStringLiteral("feature")] = h.feature;
        m[QStringLiteral("glyph")] = h.glyph;
        out << m;
    }
    return out;
}

