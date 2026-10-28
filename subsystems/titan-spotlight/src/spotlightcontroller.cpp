#include "spotlightcontroller.h"
#include "clipboard.h"

#include <QProcess>
#include <QGuiApplication>
#include <QClipboard>
#include <QRegularExpression>
#include <QUrl>

SpotlightController::SpotlightController(QObject *parent)
    : QObject(parent)
{
    // Define standard ArchTitan system quick actions
    auto addSysAction = [this](const QString &title, const QString &subtitle, const QString &icon, const QString &command, const QString &keywords) {
        QVariantMap item;
        item[QStringLiteral("type")] = QStringLiteral("system");
        item[QStringLiteral("title")] = title;
        item[QStringLiteral("subtitle")] = subtitle;
        item[QStringLiteral("icon")] = icon;
        item[QStringLiteral("command")] = command;
        item[QStringLiteral("keywords")] = keywords;
        item[QStringLiteral("category")] = QStringLiteral("SYSTEM");
        m_systemActions.append(item);
    };

    addSysAction(QStringLiteral("Lock Screen"), QStringLiteral("Lock current Wayland session"), QStringLiteral("system-lock-screen"), QStringLiteral("hyprlock || swaylock -f -c 0b0e14"), QStringLiteral("lock session security"));
    addSysAction(QStringLiteral("Sleep / Suspend"), QStringLiteral("Suspend machine into low-power sleep"), QStringLiteral("system-suspend"), QStringLiteral("systemctl suspend -i"), QStringLiteral("sleep suspend standby"));
    addSysAction(QStringLiteral("Restart System"), QStringLiteral("Safely reboot ArchTitan OS"), QStringLiteral("system-reboot"), QStringLiteral("systemctl reboot -i"), QStringLiteral("reboot restart reset"));
    addSysAction(QStringLiteral("Shut Down"), QStringLiteral("Power off system completely"), QStringLiteral("system-shutdown"), QStringLiteral("systemctl poweroff -i"), QStringLiteral("shutdown poweroff turn off"));
    addSysAction(QStringLiteral("ArchTitan Settings"), QStringLiteral("System preferences, display, themes & hardware"), QStringLiteral("preferences-system"), QStringLiteral("archtitan-settings"), QStringLiteral("settings control panel display theme display"));
    addSysAction(QStringLiteral("Take Screenshot"), QStringLiteral("Interactive area snip with annotation"), QStringLiteral("applets-screenshooter"), QStringLiteral("titan-screenshot --area"), QStringLiteral("screenshot snip capture screen grim"));
    addSysAction(QStringLiteral("Task Manager"), QStringLiteral("Monitor processes, CPU, memory and GPU (btop)"), QStringLiteral("utilities-system-monitor"), QStringLiteral("kitty -e btop"), QStringLiteral("btop htop task manager monitor processes cpu"));
    addSysAction(QStringLiteral("File Manager"), QStringLiteral("Browse filesystem with Ranger"), QStringLiteral("system-file-manager"), QStringLiteral("kitty -e ranger"), QStringLiteral("files ranger explore directories home"));
    addSysAction(QStringLiteral("Volume Mixer"), QStringLiteral("Audio levels and PipeWire devices"), QStringLiteral("audio-volume-high"), QStringLiteral("pavucontrol"), QStringLiteral("volume audio sound mixer pavucontrol"));

    updateResults();
}

void SpotlightController::setQuery(const QString &q)
{
    if (m_query == q) return;
    m_query = q;
    emit queryChanged();
    updateResults();
}

void SpotlightController::setSelectedIndex(int idx)
{
    if (idx < 0) idx = 0;
    if (idx >= m_results.size() && !m_results.isEmpty()) {
        idx = m_results.size() - 1;
    }
    if (m_selectedIndex != idx) {
        m_selectedIndex = idx;
        emit selectedIndexChanged();
    }
}

void SpotlightController::setClipboardMode(bool enabled)
{
    if (m_isClipboardMode != enabled) {
        m_isClipboardMode = enabled;
        emit clipboardModeChanged();
        updateResults();
    }
}

void SpotlightController::selectNext()
{
    if (m_results.isEmpty()) return;
    setSelectedIndex((m_selectedIndex + 1) % m_results.size());
}

void SpotlightController::selectPrev()
{
    if (m_results.isEmpty()) return;
    setSelectedIndex((m_selectedIndex - 1 + m_results.size()) % m_results.size());
}

void SpotlightController::reset()
{
    m_query.clear();
    m_isClipboardMode = false;
    m_selectedIndex = 0;
    m_calcResult = CalcResult();
    emit queryChanged();
    emit calcResultChanged();
    emit clipboardModeChanged();
    updateResults();
}

void SpotlightController::refreshApps()
{
    m_indexer.scan();
    updateResults();
}

void SpotlightController::updateResults()
{
    m_results.clear();

    const QString trimmed = m_query.trimmed();

    // 1. Math calculation check (Mac Spotlight feature)
    CalcResult newCalc = SpotlightCalculator::evaluate(trimmed);
    if (newCalc.valid != m_calcResult.valid || newCalc.formattedResult != m_calcResult.formattedResult) {
        m_calcResult = newCalc;
        emit calcResultChanged();
    }

    // 2. Clipboard mode check
    if (m_isClipboardMode || trimmed.startsWith(QStringLiteral("@clip"), Qt::CaseInsensitive)) {
        QString filter = trimmed;
        if (filter.startsWith(QStringLiteral("@clip"), Qt::CaseInsensitive)) {
            filter = filter.mid(5).trimmed();
        }
        QList<ClipboardEntry> clips = ClipboardManager::getRecent(30);
        for (const auto &c : clips) {
            if (!filter.isEmpty() && !c.preview.contains(filter, Qt::CaseInsensitive)) {
                continue;
            }
            QVariantMap item;
            item[QStringLiteral("type")] = QStringLiteral("clipboard");
            item[QStringLiteral("title")] = c.preview;
            item[QStringLiteral("subtitle")] = QStringLiteral("Copied item • Press ⏎ to paste");
            item[QStringLiteral("icon")] = QStringLiteral("edit-paste");
            item[QStringLiteral("rawLine")] = c.rawLine;
            item[QStringLiteral("category")] = QStringLiteral("CLIPBOARD");
            m_results.append(item);
        }
        setSelectedIndex(0);
        emit resultsChanged();
        return;
    }

    // 3. Command execution (starts with > or $)
    if (trimmed.startsWith(QLatin1Char('>')) || trimmed.startsWith(QLatin1Char('$'))) {
        QString cmd = trimmed.mid(1).trimmed();
        if (!cmd.isEmpty()) {
            QVariantMap item;
            item[QStringLiteral("type")] = QStringLiteral("command");
            item[QStringLiteral("title")] = QStringLiteral("Run '%1' in Terminal").arg(cmd);
            item[QStringLiteral("subtitle")] = QStringLiteral("Execute command in Kitty terminal");
            item[QStringLiteral("icon")] = QStringLiteral("utilities-terminal");
            item[QStringLiteral("command")] = cmd;
            item[QStringLiteral("category")] = QStringLiteral("COMMAND");
            m_results.append(item);
        }
    }

    // 4. Search Applications
    QList<SearchResult> appResults = m_indexer.search(trimmed, 15);
    for (const auto &res : appResults) {
        QVariantMap item;
        item[QStringLiteral("type")] = QStringLiteral("app");
        item[QStringLiteral("title")] = res.entry.name;
        QString sub = res.entry.genericName;
        if (sub.isEmpty()) sub = res.entry.comment;
        if (sub.isEmpty() && !res.entry.categories.isEmpty()) sub = res.entry.categories.first();
        if (sub.isEmpty()) sub = QStringLiteral("Application");
        item[QStringLiteral("subtitle")] = sub;
        item[QStringLiteral("icon")] = res.entry.icon;
        item[QStringLiteral("exec")] = res.entry.exec;
        item[QStringLiteral("terminal")] = res.entry.terminal;
        item[QStringLiteral("category")] = QStringLiteral("APPLICATIONS");
        m_results.append(item);
    }

    // 5. System Quick Actions
    if (!trimmed.isEmpty()) {
        for (const auto &sys : m_systemActions) {
            QString title = sys.value(QStringLiteral("title")).toString();
            QString kw = sys.value(QStringLiteral("keywords")).toString();
            if (title.contains(trimmed, Qt::CaseInsensitive) || kw.contains(trimmed, Qt::CaseInsensitive)) {
                m_results.append(sys);
            }
        }
    } else {
        // When query is empty, append a few essential actions at the end
        for (int i = 0; i < qMin(4, m_systemActions.size()); ++i) {
            m_results.append(m_systemActions[i]);
        }
    }

    // 6. Web Search fallback
    if (!trimmed.isEmpty() && !m_calcResult.valid) {
        QVariantMap webItem;
        webItem[QStringLiteral("type")] = QStringLiteral("web");
        webItem[QStringLiteral("title")] = QStringLiteral("Search DuckDuckGo for '%1'").arg(trimmed);
        webItem[QStringLiteral("subtitle")] = QStringLiteral("Open web search in Titan Browser");
        webItem[QStringLiteral("icon")] = QStringLiteral("applications-internet");
        webItem[QStringLiteral("query")] = trimmed;
        webItem[QStringLiteral("category")] = QStringLiteral("WEB");
        m_results.append(webItem);
    }

    setSelectedIndex(0);
    emit resultsChanged();
}

void SpotlightController::copyCalcResult()
{
    if (!m_calcResult.valid) return;
    QProcess::startDetached(QStringLiteral("bash"), {QStringLiteral("-c"),
        QStringLiteral("printf '%s' '%1' | wl-copy").arg(m_calcResult.formattedResult)});
    emit closeRequested();
}

void SpotlightController::activateCurrent()
{
    if (m_calcResult.valid && m_selectedIndex == 0 && (m_results.isEmpty() || m_query.trimmed().contains(QRegularExpression(R"(^[\d\s\+\-\*\/\^\%\(\)\.]+$)")))) {
        copyCalcResult();
        return;
    }
    if (m_selectedIndex >= 0 && m_selectedIndex < m_results.size()) {
        activate(m_selectedIndex);
    }
}

void SpotlightController::activate(int index)
{
    if (index < 0 || index >= m_results.size()) return;
    QVariantMap item = m_results.at(index).toMap();
    executeAction(item);
    emit closeRequested();
}

void SpotlightController::executeAction(const QVariantMap &item)
{
    const QString type = item.value(QStringLiteral("type")).toString();

    if (type == QStringLiteral("app")) {
        QString exec = item.value(QStringLiteral("exec")).toString();
        bool isTerminal = item.value(QStringLiteral("terminal")).toBool();

        if (isTerminal) {
            QProcess::startDetached(QStringLiteral("titan-exec-hook"), {QStringLiteral("kitty"), QStringLiteral("-e"), QStringLiteral("sh"), QStringLiteral("-c"), exec});
        } else {
            // Launch through titan-exec-hook wrapper to preserve sandboxing & THM profiles
            QString cmd = QStringLiteral("titan-exec-hook %1").arg(exec);
            QProcess::startDetached(QStringLiteral("bash"), {QStringLiteral("-c"), cmd});
        }
    } else if (type == QStringLiteral("system")) {
        QString cmd = item.value(QStringLiteral("command")).toString();
        QProcess::startDetached(QStringLiteral("bash"), {QStringLiteral("-c"), cmd});
    } else if (type == QStringLiteral("command")) {
        QString cmd = item.value(QStringLiteral("command")).toString();
        QProcess::startDetached(QStringLiteral("titan-exec-hook"), {QStringLiteral("kitty"), QStringLiteral("-e"), QStringLiteral("bash"), QStringLiteral("-c"), cmd + QStringLiteral("; read -p 'Press enter to exit...'")});
    } else if (type == QStringLiteral("clipboard")) {
        QString rawLine = item.value(QStringLiteral("rawLine")).toString();
        ClipboardManager::selectEntry(rawLine);
    } else if (type == QStringLiteral("web")) {
        QString q = item.value(QStringLiteral("query")).toString();
        QString url = QStringLiteral("https://duckduckgo.com/?q=") + QString::fromUtf8(QUrl::toPercentEncoding(q));
        QProcess::startDetached(QStringLiteral("titan-exec-hook"), {QStringLiteral("titanbrowser"), url});
    }
}
