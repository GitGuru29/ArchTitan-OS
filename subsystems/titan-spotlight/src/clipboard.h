#pragma once

#include <QString>
#include <QStringList>

struct ClipboardEntry {
    QString rawLine;
    QString preview;
};

class ClipboardManager {
public:
    static QList<ClipboardEntry> getRecent(int limit = 20);
    static bool selectEntry(const QString &rawLine);
};
