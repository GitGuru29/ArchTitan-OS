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
    const QString commentLower = entry.comment.toLower();
    const QString combined = joinedCats + QLatin1Char(' ') + nameLower + QLatin1Char(' ') + execLower + QLatin1Char(' ') + commentLower;

    if (combined.contains(QStringLiteral("chat")) ||
        combined.contains(QStringLiteral("social")) ||
        combined.contains(QStringLiteral("whatsapp")) ||
        combined.contains(QStringLiteral("telegram")) ||
        combined.contains(QStringLiteral("discord")) ||
        combined.contains(QStringLiteral("slack")) ||
        combined.contains(QStringLiteral("signal")) ||
        combined.contains(QStringLiteral("element")) ||
        combined.contains(QStringLiteral("thunderbird")) ||
        combined.contains(QStringLiteral("mail")) ||
        combined.contains(QStringLiteral("messenger"))) {
        return QStringLiteral("SOCIAL");
    }

    if (combined.contains(QStringLiteral("office")) ||
        combined.contains(QStringLiteral("finance")) ||
        combined.contains(QStringLiteral("spreadsheet")) ||
        combined.contains(QStringLiteral("calc")) ||
        combined.contains(QStringLiteral("libreoffice")) ||
        combined.contains(QStringLiteral("writer")) ||
        combined.contains(QStringLiteral("impress")) ||
        combined.contains(QStringLiteral("calendar")) ||
        combined.contains(QStringLiteral("contact")) ||
        combined.contains(QStringLiteral("notes")) ||
        combined.contains(QStringLiteral("obsidian")) ||
        combined.contains(QStringLiteral("notion")) ||
        combined.contains(QStringLiteral("todo"))) {
        return QStringLiteral("PRODUCTIVITY");
    }

    if (combined.contains(QStringLiteral("audiovideo")) ||
        combined.contains(QStringLiteral("audio")) ||
        combined.contains(QStringLiteral("video")) ||
        combined.contains(QStringLiteral("player")) ||
        combined.contains(QStringLiteral("music")) ||
        combined.contains(QStringLiteral("game")) ||
        combined.contains(QStringLiteral("vlc")) ||
        combined.contains(QStringLiteral("mpv")) ||
        combined.contains(QStringLiteral("spotify")) ||
        combined.contains(QStringLiteral("steam")) ||
        combined.contains(QStringLiteral("retroarch"))) {
        return QStringLiteral("ENTERTAINMENT");
    }

    if (combined.contains(QStringLiteral("education")) ||
        combined.contains(QStringLiteral("science")) ||
        combined.contains(QStringLiteral("documentation")) ||
        combined.contains(QStringLiteral("news")) ||
        combined.contains(QStringLiteral("webbrowser")) ||
        combined.contains(QStringLiteral("browser")) ||
        combined.contains(QStringLiteral("chrome")) ||
        combined.contains(QStringLiteral("firefox")) ||
        combined.contains(QStringLiteral("brave")) ||
        combined.contains(QStringLiteral("edge")) ||
        combined.contains(QStringLiteral("reader")) ||
        combined.contains(QStringLiteral("pdf")) ||
        combined.contains(QStringLiteral("evince")) ||
        combined.contains(QStringLiteral("zathura")) ||
        combined.contains(QStringLiteral("book"))) {
        return QStringLiteral("INFORMATION");
    }

    if (combined.contains(QStringLiteral("development")) ||
        combined.contains(QStringLiteral("ide")) ||
        combined.contains(QStringLiteral("texteditor")) ||
        combined.contains(QStringLiteral("graphics")) ||
        combined.contains(QStringLiteral("photography")) ||
        combined.contains(QStringLiteral("code")) ||
        combined.contains(QStringLiteral("vscode")) ||
        combined.contains(QStringLiteral("antigravity")) ||
        combined.contains(QStringLiteral("studio")) ||
        combined.contains(QStringLiteral("gimp")) ||
        combined.contains(QStringLiteral("inkscape")) ||
        combined.contains(QStringLiteral("blender")) ||
        combined.contains(QStringLiteral("kdenlive")) ||
        combined.contains(QStringLiteral("krita")) ||
        combined.contains(QStringLiteral("figma")) ||
        combined.contains(QStringLiteral("nvim")) ||
        combined.contains(QStringLiteral("vim"))) {
        return QStringLiteral("CREATIVITY");
    }

    if (combined.contains(QStringLiteral("utility")) ||
        combined.contains(QStringLiteral("terminal")) ||
        combined.contains(QStringLiteral("kitty")) ||
        combined.contains(QStringLiteral("alacritty")) ||
        combined.contains(QStringLiteral("calculator")) ||
        combined.contains(QStringLiteral("filemanager")) ||
        combined.contains(QStringLiteral("files")) ||
        combined.contains(QStringLiteral("thunar")) ||
        combined.contains(QStringLiteral("dolphin")) ||
        combined.contains(QStringLiteral("ranger")) ||
        combined.contains(QStringLiteral("archive")) ||
        combined.contains(QStringLiteral("zip")) ||
        combined.contains(QStringLiteral("screenshot")) ||
        combined.contains(QStringLiteral("snip"))) {
        return QStringLiteral("UTILITIES");
    }

    if (combined.contains(QStringLiteral("system")) ||
        combined.contains(QStringLiteral("settings")) ||
        combined.contains(QStringLiteral("preferences")) ||
        combined.contains(QStringLiteral("btop")) ||
        combined.contains(QStringLiteral("htop")) ||
        combined.contains(QStringLiteral("monitor")) ||
        combined.contains(QStringLiteral("control")) ||
        combined.contains(QStringLiteral("pavucontrol"))) {
        return QStringLiteral("SYSTEM");
    }

    return QStringLiteral("OTHER");
}

int SpotlightController::gridColumns() const
{
    if (m_isClipboardMode) return 1;
    return 7;
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
        QStringLiteral("UTILITIES"),
        QStringLiteral("SOCIAL"),
        QStringLiteral("PRODUCTIVITY"),
        QStringLiteral("ENTERTAINMENT"),
        QStringLiteral("INFORMATION"),
        QStringLiteral("CREATIVITY"),
        QStringLiteral("OTHER")
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
    QList<SearchResult> appResults = m_indexer.search(trimmed, 200);
    for (const auto &res : appResults) {
        const QString group = classifyAppGroup(res.entry);
        if (m_activeCategory != QStringLiteral("ALL")) {
            if (m_activeCategory == QStringLiteral("OTHER")) {
                if (group != QStringLiteral("OTHER") && group != QStringLiteral("SYSTEM")) {
                    continue;
                }
            } else if (m_activeCategory != group) {
                continue;
            }
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
        item[QStringLiteral("badge")] = group;
        m_results.append(item);
    }

    // 5. System Quick Actions
    if (m_activeCategory == QStringLiteral("ALL") || m_activeCategory == QStringLiteral("OTHER") || m_activeCategory == QStringLiteral("UTILITIES")) {
        if (!trimmed.isEmpty()) {
            for (const auto &sys : m_systemActions) {
                QString title = sys.value(QStringLiteral("title")).toString();
                QString kw = sys.value(QStringLiteral("keywords")).toString();
                if (title.contains(trimmed, Qt::CaseInsensitive) || kw.contains(trimmed, Qt::CaseInsensitive)) {
                    m_results.append(sys);
                }
            }
        } else if (m_activeCategory == QStringLiteral("OTHER")) {
            for (const auto &sys : m_systemActions) {
                m_results.append(sys);
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
