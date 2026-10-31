#include "appindexer.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QSettings>
#include <QStandardPaths>
#include <QRegularExpression>
#include <algorithm>

AppIndexer::AppIndexer()
{
    scan();
}

QString AppIndexer::cleanExec(const QString &rawExec)
{
    QString res = rawExec.trimmed();
    // Strip standard field codes (%f, %F, %u, %U, %d, %D, %n, %N, %i, %c, %k, %v, %m)
    static const QRegularExpression fieldCodeRx(QStringLiteral(R"(%[a-zA-Z])"));
    res.remove(fieldCodeRx);
    return res.trimmed();
}

void AppIndexer::parseDesktopFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return;
    }

    bool inDesktopEntry = false;
    AppEntry entry;
    entry.id = QFileInfo(path).fileName();
    entry.desktopFilePath = path;

    bool noDisplay = false;
    bool hidden = false;
    bool isApplication = false;

    while (!file.atEnd()) {
        QString line = QString::fromUtf8(file.readLine()).trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#'))) continue;

        if (line.startsWith(QLatin1Char('['))) {
            if (line == QStringLiteral("[Desktop Entry]")) {
                inDesktopEntry = true;
            } else {
                inDesktopEntry = false;
            }
            continue;
        }

        if (!inDesktopEntry) continue;

        int eqIdx = line.indexOf(QLatin1Char('='));
        if (eqIdx <= 0) continue;

        QString key = line.left(eqIdx).trimmed();
        QString val = line.mid(eqIdx + 1).trimmed();

        if (key == QStringLiteral("Type")) {
            if (val == QStringLiteral("Application")) isApplication = true;
        } else if (key == QStringLiteral("NoDisplay")) {
            if (val.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0) noDisplay = true;
        } else if (key == QStringLiteral("Hidden")) {
            if (val.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0) hidden = true;
        } else if (key == QStringLiteral("Name") && entry.name.isEmpty()) {
            entry.name = val;
        } else if (key == QStringLiteral("GenericName") && entry.genericName.isEmpty()) {
            entry.genericName = val;
        } else if (key == QStringLiteral("Comment") && entry.comment.isEmpty()) {
            entry.comment = val;
        } else if (key == QStringLiteral("Icon") && entry.icon.isEmpty()) {
            entry.icon = val;
        } else if (key == QStringLiteral("Exec") && entry.exec.isEmpty()) {
            entry.exec = cleanExec(val);
        } else if (key == QStringLiteral("Terminal")) {
            entry.terminal = (val.compare(QStringLiteral("true"), Qt::CaseInsensitive) == 0);
        } else if (key == QStringLiteral("Categories")) {
            entry.categories = val.split(QLatin1Char(';'), Qt::SkipEmptyParts);
        } else if (key == QStringLiteral("Keywords")) {
            entry.keywords = val.split(QLatin1Char(';'), Qt::SkipEmptyParts);
        }
    }

    if (!isApplication || noDisplay || hidden || entry.name.isEmpty() || entry.exec.isEmpty()) {
        return;
    }

    // Default icon fallback if empty
    if (entry.icon.isEmpty()) {
        entry.icon = QStringLiteral("application-x-executable");
    }

    // Prevent duplicate entries (user apps override system apps)
    for (int i = 0; i < m_apps.size(); ++i) {
        if (m_apps[i].id == entry.id || m_apps[i].name.compare(entry.name, Qt::CaseInsensitive) == 0) {
            return;
        }
    }

    m_apps.append(entry);
}

void AppIndexer::scan()
{
    m_apps.clear();

    QStringList searchDirs;
    searchDirs << QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    searchDirs << QStringLiteral("/usr/local/share/applications");
    searchDirs << QStringLiteral("/usr/share/applications");

    for (const QString &dirPath : searchDirs) {
        QDir dir(dirPath);
        if (!dir.exists()) continue;

        const QStringList entries = dir.entryList({QStringLiteral("*.desktop")}, QDir::Files | QDir::Readable);
        for (const QString &entry : entries) {
            parseDesktopFile(dir.absoluteFilePath(entry));
        }
    }

    auto appPriority = [](const AppEntry &a) -> int {
        const QString n = a.name.toLower();
        const QString ex = a.exec.toLower();
        if (n.contains(QStringLiteral("titan")) || ex.contains(QStringLiteral("titan")) || ex.contains(QStringLiteral("archtitan"))) return 0;
        if (n.contains(QStringLiteral("kitty")) || n.contains(QStringLiteral("terminal"))) return 1;
        if (n.contains(QStringLiteral("antigravity")) || n.contains(QStringLiteral("code")) || n.contains(QStringLiteral("studio"))) return 2;
        if (n.contains(QStringLiteral("browser")) || n.contains(QStringLiteral("chrome")) || n.contains(QStringLiteral("firefox")) || n.contains(QStringLiteral("brave"))) return 3;
        if (n.contains(QStringLiteral("files")) || n.contains(QStringLiteral("ranger")) || n.contains(QStringLiteral("thunar")) || n.contains(QStringLiteral("dolphin"))) return 4;
        if (n.contains(QStringLiteral("settings")) || n.contains(QStringLiteral("monitor")) || n.contains(QStringLiteral("btop"))) return 5;
        return 10;
    };

    std::sort(m_apps.begin(), m_apps.end(), [&appPriority](const AppEntry &a, const AppEntry &b) {
        int pa = appPriority(a);
        int pb = appPriority(b);
        if (pa != pb) return pa < pb;
        return a.name.compare(b.name, Qt::CaseInsensitive) < 0;
    });
}

QList<SearchResult> AppIndexer::search(const QString &query, int limit) const
{
    QList<SearchResult> results;
    QString q = query.trimmed().toLower();

    if (q.isEmpty()) {
        // Return popular/priority default apps
        for (const auto &app : m_apps) {
            SearchResult r;
            r.entry = app;
            r.score = 100;
            results.append(r);
            if (results.size() >= limit) break;
        }
        return results;
    }

    for (const auto &app : m_apps) {
        QString nameLower = app.name.toLower();
        QString genLower = app.genericName.toLower();
        QString commLower = app.comment.toLower();
        QString execLower = app.exec.toLower();

        int score = 0;

        if (nameLower == q) {
            score = 2000;
        } else if (nameLower.startsWith(q)) {
            score = 1200 - (nameLower.length() - q.length()) * 2;
        } else if (nameLower.contains(QLatin1Char(' ') + q) || nameLower.contains(QLatin1Char('-') + q)) {
            score = 900;
        } else if (nameLower.contains(q)) {
            score = 650;
        } else if (!genLower.isEmpty() && genLower.startsWith(q)) {
            score = 500;
        } else if (!genLower.isEmpty() && genLower.contains(q)) {
            score = 400;
        } else {
            bool kwMatch = false;
            for (const QString &kw : app.keywords) {
                if (kw.toLower().contains(q)) {
                    score = 350;
                    kwMatch = true;
                    break;
                }
            }
            if (!kwMatch) {
                if (execLower.startsWith(q)) {
                    score = 300;
                } else if (commLower.contains(q)) {
                    score = 200;
                }
            }
        }

        if (score > 0) {
            SearchResult sr;
            sr.entry = app;
            sr.score = score;
            results.append(sr);
        }
    }

    std::sort(results.begin(), results.end(), [](const SearchResult &a, const SearchResult &b) {
        if (a.score != b.score) return a.score > b.score;
        return a.entry.name.compare(b.entry.name, Qt::CaseInsensitive) < 0;
    });

    if (results.size() > limit) {
        results = results.mid(0, limit);
    }

    return results;
}
