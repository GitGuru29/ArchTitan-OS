#include "spotlightcontroller.h"
#include "clipboard.h"

#include <QProcess>
#include <QGuiApplication>
#include <QClipboard>
#include <QRegularExpression>
#include <QUrl>
#include <QDir>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

SpotlightController::SpotlightController(QObject *parent)
    : QObject(parent)
{
    loadPreferences();

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
        item[QStringLiteral("badge")] = QStringLiteral("SYS");
        m_systemActions.append(item);
    };

    addSysAction(QStringLiteral("ArchTitan Settings"), QStringLiteral("System preferences, display, themes & hardware"), QStringLiteral("preferences-system"), QStringLiteral("archtitan-settings"), QStringLiteral("settings control panel display theme hardware"));
    addSysAction(QStringLiteral("Task Manager"), QStringLiteral("Monitor processes, CPU, memory and GPU (btop)"), QStringLiteral("utilities-system-monitor"), QStringLiteral("kitty -e btop"), QStringLiteral("btop htop task manager monitor processes cpu"));
    addSysAction(QStringLiteral("File Manager"), QStringLiteral("Browse filesystem with Ranger"), QStringLiteral("system-file-manager"), QStringLiteral("kitty -e ranger"), QStringLiteral("files ranger explore directories home"));
    addSysAction(QStringLiteral("Volume Mixer"), QStringLiteral("Audio levels and PipeWire devices"), QStringLiteral("audio-volume-high"), QStringLiteral("pavucontrol"), QStringLiteral("volume audio sound mixer pavucontrol"));
    addSysAction(QStringLiteral("Take Screenshot"), QStringLiteral("Interactive area snip with annotation"), QStringLiteral("applets-screenshooter"), QStringLiteral("titan-screenshot --area"), QStringLiteral("screenshot snip capture screen grim"));
    addSysAction(QStringLiteral("Lock Screen"), QStringLiteral("Lock current Wayland session"), QStringLiteral("system-lock-screen"), QStringLiteral("hyprlock || swaylock -f -c 0b0e14"), QStringLiteral("lock session security"));
    addSysAction(QStringLiteral("Sleep / Suspend"), QStringLiteral("Suspend machine into low-power sleep"), QStringLiteral("system-suspend"), QStringLiteral("systemctl suspend -i"), QStringLiteral("sleep suspend standby"));
    addSysAction(QStringLiteral("Restart System"), QStringLiteral("Safely reboot ArchTitan OS"), QStringLiteral("system-reboot"), QStringLiteral("systemctl reboot -i"), QStringLiteral("reboot restart reset"));
    addSysAction(QStringLiteral("Shut Down"), QStringLiteral("Power off system completely"), QStringLiteral("system-shutdown"), QStringLiteral("systemctl poweroff -i"), QStringLiteral("shutdown poweroff turn off"));

    updateResults();
}

void SpotlightController::loadPreferences()
{
    const QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/archtitan");
    QFile file(cfgDir + QStringLiteral("/spotlight.json"));
    if (!file.open(QIODevice::ReadOnly)) return;

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    if (!doc.isObject()) return;

    const QString mode = doc.object().value(QStringLiteral("viewMode")).toString().trimmed().toLower();
    if (mode == QStringLiteral("grid") || mode == QStringLiteral("bento") || mode == QStringLiteral("list")) {
        m_viewMode = mode;
    }
}

void SpotlightController::savePreferences() const
{
    const QString cfgDir = QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/archtitan");
    QDir().mkpath(cfgDir);
    QFile file(cfgDir + QStringLiteral("/spotlight.json"));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) return;

    QJsonObject obj;
    obj[QStringLiteral("viewMode")] = m_viewMode;
    file.write(QJsonDocument(obj).toJson(QJsonDocument::Indented));
}

QString SpotlightController::classifyAppGroup(const AppEntry &entry)
{
    const QString joinedCats = entry.categories.join(QLatin1Char(' ')).toLower();
    const QString nameLower = entry.name.toLower();
    const QString execLower = entry.exec.toLower();

    if (joinedCats.contains(QStringLiteral("development")) ||
        joinedCats.contains(QStringLiteral("ide")) ||
        nameLower.contains(QStringLiteral("code")) ||
        nameLower.contains(QStringLiteral("antigravity")) ||
        nameLower.contains(QStringLiteral("kitty")) ||
        nameLower.contains(QStringLiteral("terminal")) ||
        execLower.contains(QStringLiteral("nvim")) ||
        execLower.contains(QStringLiteral("git"))) {
        return QStringLiteral("DEV");
    }
    if (joinedCats.contains(QStringLiteral("network")) ||
        joinedCats.contains(QStringLiteral("webbrowser")) ||
        nameLower.contains(QStringLiteral("browser")) ||
        nameLower.contains(QStringLiteral("chrome")) ||
        nameLower.contains(QStringLiteral("firefox")) ||
        nameLower.contains(QStringLiteral("brave"))) {
        return QStringLiteral("WEB");
    }
    if (joinedCats.contains(QStringLiteral("audiovideo")) ||
        joinedCats.contains(QStringLiteral("audio")) ||
        joinedCats.contains(QStringLiteral("video")) ||
        joinedCats.contains(QStringLiteral("graphics")) ||
        nameLower.contains(QStringLiteral("vlc")) ||
        nameLower.contains(QStringLiteral("mpv")) ||
        nameLower.contains(QStringLiteral("pavucontrol"))) {
        return QStringLiteral("MEDIA");
    }
    if (joinedCats.contains(QStringLiteral("system")) ||
        joinedCats.contains(QStringLiteral("settings")) ||
        nameLower.contains(QStringLiteral("settings")) ||
        nameLower.contains(QStringLiteral("btop")) ||
        nameLower.contains(QStringLiteral("htop")) ||
        nameLower.contains(QStringLiteral("calamares"))) {
        return QStringLiteral("SYSTEM");
    }
    return QStringLiteral("APPS");
}

int SpotlightController::gridColumns() const
{
    if (m_isClipboardMode) return 1;
    if (m_viewMode == QStringLiteral("grid")) return 4;
    if (m_viewMode == QStringLiteral("bento")) return 2;
    return 1;
}

void SpotlightController::setViewMode(const QString &mode)
{
    const QString normalized = mode.trimmed().toLower();
    if (normalized != QStringLiteral("grid") &&
        normalized != QStringLiteral("bento") &&
        normalized != QStringLiteral("list")) {
        return;
    }
    if (m_viewMode == normalized) return;
    m_viewMode = normalized;
    savePreferences();
    emit viewModeChanged();
}

void SpotlightController::cycleViewMode()
{
    if (m_viewMode == QStringLiteral("grid")) {
        setViewMode(QStringLiteral("bento"));
    } else if (m_viewMode == QStringLiteral("bento")) {
        setViewMode(QStringLiteral("list"));
    } else {
        setViewMode(QStringLiteral("grid"));
    }
}

void SpotlightController::setActiveCategory(const QString &category)
{
    const QString up = category.trimmed().toUpper();
    if (m_activeCategory == up) return;
    m_activeCategory = up;
    emit activeCategoryChanged();
    updateResults();
}

void SpotlightController::cycleCategory(int delta)
{
    static const QStringList cats = {
        QStringLiteral("ALL"),
        QStringLiteral("APPS"),
        QStringLiteral("DEV"),
        QStringLiteral("SYSTEM"),
        QStringLiteral("WEB"),
        QStringLiteral("MEDIA")
    };
    int idx = cats.indexOf(m_activeCategory);
    if (idx < 0) idx = 0;
    idx = (idx + delta + cats.size()) % cats.size();
    setActiveCategory(cats.at(idx));
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
        emit viewModeChanged();
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

void SpotlightController::selectRight()
{
    selectNext();
}

void SpotlightController::selectLeft()
{
    selectPrev();
}

void SpotlightController::selectDown()
{
    if (m_results.isEmpty()) return;
    const int cols = gridColumns();
    if (cols <= 1) {
        selectNext();
        return;
    }
    int next = m_selectedIndex + cols;
    if (next >= m_results.size()) {
        // Wrap to same column in top row
        next = m_selectedIndex % cols;
    }
    setSelectedIndex(next);
}

void SpotlightController::selectUp()
{
    if (m_results.isEmpty()) return;
    const int cols = gridColumns();
    if (cols <= 1) {
        selectPrev();
        return;
    }
    int prev = m_selectedIndex - cols;
    if (prev < 0) {
        // Wrap to bottom-most row in same column
        int col = m_selectedIndex % cols;
        int lastRowStart = ((m_results.size() - 1) / cols) * cols;
        prev = lastRowStart + col;
        if (prev >= m_results.size()) {
            prev -= cols;
        }
        if (prev < 0) prev = 0;
    }
    setSelectedIndex(prev);
}

void SpotlightController::reset()
{
    m_query.clear();
    m_isClipboardMode = false;
    m_activeCategory = QStringLiteral("ALL");
    m_selectedIndex = 0;
    m_calcResult = CalcResult();
    emit queryChanged();
    emit calcResultChanged();
    emit clipboardModeChanged();
    emit activeCategoryChanged();
    emit viewModeChanged();
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
            item[QStringLiteral("badge")] = QStringLiteral("CLIP");
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
            item[QStringLiteral("badge")] = QStringLiteral("CMD");
            m_results.append(item);
        }
    }

    // 4. Search Applications
    if (m_activeCategory != QStringLiteral("SYSTEM") || !trimmed.isEmpty()) {
        QList<SearchResult> appResults = m_indexer.search(trimmed, 80);
        for (const auto &res : appResults) {
            const QString group = classifyAppGroup(res.entry);
            if (m_activeCategory != QStringLiteral("ALL") &&
                m_activeCategory != QStringLiteral("APPS") &&
                m_activeCategory != group) {
                continue;
            }

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
            item[QStringLiteral("category")] = group;
            item[QStringLiteral("badge")] = (group == QStringLiteral("APPS")) ? QStringLiteral("APP") : group;
            m_results.append(item);
        }
    }

    // 5. System Quick Actions
    if (m_activeCategory == QStringLiteral("ALL") || m_activeCategory == QStringLiteral("SYSTEM")) {
        if (!trimmed.isEmpty()) {
            for (const auto &sys : m_systemActions) {
                QString title = sys.value(QStringLiteral("title")).toString();
                QString kw = sys.value(QStringLiteral("keywords")).toString();
                if (title.contains(trimmed, Qt::CaseInsensitive) || kw.contains(trimmed, Qt::CaseInsensitive)) {
                    m_results.append(sys);
                }
            }
        } else if (m_activeCategory == QStringLiteral("SYSTEM")) {
            for (const auto &sys : m_systemActions) {
                m_results.append(sys);
            }
        } else {
            for (int i = 0; i < qMin(6, m_systemActions.size()); ++i) {
                m_results.append(m_systemActions[i]);
            }
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
        webItem[QStringLiteral("badge")] = QStringLiteral("WEB");
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
