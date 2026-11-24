#include "focusmonitor.h"

#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

namespace titan::focus {

FocusMonitor::FocusMonitor(QObject *parent)
    : QObject(parent) {
    connect(&m_proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &FocusMonitor::onHyprctlFinished);
}

void FocusMonitor::requestRefresh() {
    if (m_proc.state() != QProcess::NotRunning) return;
    if (QStandardPaths::findExecutable(QStringLiteral("hyprctl")).isEmpty()) return;
    m_proc.start(QStringLiteral("hyprctl"), {QStringLiteral("-j"), QStringLiteral("activewindow")});
}

void FocusMonitor::updateFromSocket(const QString &appClass, const QString &title) {
    m_activeClass = appClass;
    m_activeTitle = title;
    reclassify();
    requestRefresh();
}

void FocusMonitor::onHyprctlFinished(int exitCode, QProcess::ExitStatus status) {
    if (exitCode != 0 || status != QProcess::NormalExit) return;

    const QByteArray raw = m_proc.readAllStandardOutput().trimmed();
    if (raw.isEmpty() || raw == "{}") return;

    const QJsonDocument doc = QJsonDocument::fromJson(raw);
    if (!doc.isObject()) return;

    const QJsonObject obj = doc.object();
    const QString cls = obj.value(QStringLiteral("class")).toString();
    const QString title = obj.value(QStringLiteral("title")).toString();
    if (!cls.isEmpty()) m_activeClass = cls;
    if (!title.isEmpty()) m_activeTitle = title;
    m_activePid = obj.value(QStringLiteral("pid")).toInteger(0);
    m_fullscreen = obj.value(QStringLiteral("fullscreen")).toInt(0) != 0;

    reclassify();
    emit focusStateChanged();
}

void FocusMonitor::reclassify() {
    const QString clsLow   = m_activeClass.toLower();
    const QString titleLow = m_activeTitle.toLower();

    bool ide = false;
    for (const QString &known : m_config.knownIdes) {
        const QString k = known.toLower();
        if (k.isEmpty()) continue;
        if (clsLow == k || clsLow.contains(k)) {
            ide = true;
            break;
        }
    }
    m_ideFocused = ide;

    bool meeting = false;
    for (const QString &app : m_config.meetingApps) {
        const QString a = app.toLower();
        if (!a.isEmpty() && (clsLow == a || clsLow.contains(a))) {
            meeting = true;
            break;
        }
    }
    if (!meeting) {
        if (titleLow.contains(QLatin1String("google meet")) ||
            titleLow.contains(QLatin1String("zoom meeting")) ||
            titleLow.contains(QLatin1String("microsoft teams")) ||
            titleLow.contains(QLatin1String("huddle")) ||
            titleLow.contains(QLatin1String("screen sharing"))) {
            meeting = true;
        }
    }
    m_inMeetingWindow = meeting;
}

} // namespace titan::focus
