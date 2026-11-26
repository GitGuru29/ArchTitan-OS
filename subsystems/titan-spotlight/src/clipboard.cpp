#include "clipboard.h"

#include <QProcess>
#include <QStringList>

QList<ClipboardEntry> ClipboardManager::getRecent(int limit)
{
    QList<ClipboardEntry> list;
    QProcess proc;
    proc.start(QStringLiteral("cliphist"), {QStringLiteral("list")});
    if (!proc.waitForFinished(400)) {
        proc.kill();
        return list;
    }

    const QString output = QString::fromUtf8(proc.readAllStandardOutput());
    const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);

    for (const QString &line : lines) {
        if (line.trimmed().isEmpty()) continue;
        ClipboardEntry entry;
        entry.rawLine = line;

        // cliphist line format is: "<id>\t<content preview>"
        int tabIdx = line.indexOf(QLatin1Char('\t'));
        if (tabIdx >= 0) {
            entry.preview = line.mid(tabIdx + 1).trimmed();
        } else {
            entry.preview = line.trimmed();
        }

        list.append(entry);
        if (list.size() >= limit) break;
    }

    return list;
}

bool ClipboardManager::selectEntry(const QString &rawLine)
{
    // decode and write to wl-copy
    QProcess decodeProc;
    decodeProc.setStandardOutputProcess(new QProcess()); // dummy, we pipe manually
    
    // Using shell pipeline:
    QString cmd = QStringLiteral("echo -n \"%1\" | cliphist decode | wl-copy").arg(QString(rawLine).replace(QLatin1Char('"'), QStringLiteral("\\\"")));
    return QProcess::startDetached(QStringLiteral("bash"), {QStringLiteral("-c"), cmd});
}
