#pragma once

#include <QString>
#include <QStringList>
#include <QList>

struct AppEntry {
    QString id;
    QString name;
    QString genericName;
    QString comment;
    QString exec;
    QString icon;
    QStringList categories;
    QStringList keywords;
    bool terminal = false;
    QString desktopFilePath;
};

struct SearchResult {
    AppEntry entry;
    int score = 0;
};

class AppIndexer {
public:
    AppIndexer();

    void scan();
    QList<AppEntry> applications() const { return m_apps; }
    QList<SearchResult> search(const QString &query, int limit = 15) const;

private:
    void parseDesktopFile(const QString &path);
    static QString cleanExec(const QString &rawExec);

    QList<AppEntry> m_apps;
};
