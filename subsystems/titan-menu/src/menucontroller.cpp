#include "menucontroller.hpp"

#include <QDebug>
#include <QDir>
#include <QFile>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>
#include <algorithm>

#include "fuzzy.hpp"

using titanmenu::MenuNode;

namespace {

// The › separator is also a word boundary for the fuzzy scorer.
const QString kCrumbSep = QStringLiteral(" \u203A ");

QString userMenuPath()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
           + QStringLiteral("/archtitan/menu.json");
}

} // namespace

MenuController::MenuController(QObject *parent)
    : QObject(parent)
{
}

bool MenuController::loadJson(const QByteArray &json, QString *error)
{
    MenuNode root;
    if (!titanmenu::parseMenu(json, &root, error))
        return false;
    m_root = root;
    reset();
    return true;
}

bool MenuController::loadDefault()
{
    QString error;

    QFile user(userMenuPath());
    if (user.exists() && user.open(QIODevice::ReadOnly)) {
        if (loadJson(user.readAll(), &error)) {
            m_loadedFromUser = true;
            return true;
        }
        m_loadWarning = QStringLiteral("%1: %2").arg(userMenuPath(), error);
        qWarning().noquote() << "[titan-menu] ignoring invalid user menu:" << m_loadWarning;
    }

    QFile builtin(QStringLiteral(":/data/menu.json"));
    if (!builtin.open(QIODevice::ReadOnly)) {
        qCritical("[titan-menu] built-in menu missing from resources");
        return false;
    }
    if (!loadJson(builtin.readAll(), &error)) {
        qCritical().noquote() << "[titan-menu] built-in menu invalid:" << error;
        return false;
    }
    return true;
}

QString MenuController::breadcrumb() const
{
    QStringList parts;
    for (int i = 1; i < m_stack.size(); ++i)
        parts << m_stack.at(i).title;
    return parts.join(kCrumbSep);
}

void MenuController::setQuery(const QString &q)
{
    if (q == m_query)
        return;
    m_query = q;
    emit queryChanged();
    rebuild();
}

void MenuController::reset()
{
    m_flatValid = false;
    m_flatCache.clear();
    if (!m_query.isEmpty()) {
        m_query.clear();
        emit queryChanged();
    }
    m_stack.clear();
    MenuNode root = m_root;
    root.children = expand(m_root);
    m_stack.append(root);
    rebuild();
}

QVector<MenuNode> MenuController::parseThemeList(const QByteArray &output)
{
    // `titan-theme list` prints "<mark> <id padded> <Display Name>" per line,
    // where mark is '*' for the active theme and ' ' otherwise.
    QVector<MenuNode> nodes;
    const QList<QByteArray> lines = output.split('\n');
    for (const QByteArray &raw : lines) {
        const QString line = QString::fromUtf8(raw);
        if (line.size() < 3)
            continue;
        const bool active = line.at(0) == QLatin1Char('*');
        const QString rest = line.mid(1).trimmed();
        const int space = rest.indexOf(QLatin1Char(' '));
        const QString id = space < 0 ? rest : rest.left(space);
        const QString name = space < 0 ? id : rest.mid(space).trimmed();
        if (id.isEmpty())
            continue;

        MenuNode n;
        n.id = id;
        n.title = name;
        n.hint = active ? QStringLiteral("Active theme") : QStringLiteral("Apply this theme");
        n.icon = active ? QStringLiteral("\uf058") /* check-circle */
                        : QStringLiteral("\uf10c") /* circle-o */;
        n.exec = QStringLiteral("titan-theme set ") + id;
        n.requires_ = QStringLiteral("titan-theme");
        nodes.append(n);
    }
    return nodes;
}

QVector<MenuNode> MenuController::resolveProvider(const QString &provider) const
{
    if (provider == QLatin1String("@themes")) {
        if (QStandardPaths::findExecutable(QStringLiteral("titan-theme")).isEmpty())
            return {};
        QProcess p;
        p.start(QStringLiteral("titan-theme"), {QStringLiteral("list")});
        if (!p.waitForFinished(1500) || p.exitCode() != 0) {
            qWarning("[titan-menu] 'titan-theme list' failed or timed out");
            return {};
        }
        return parseThemeList(p.readAllStandardOutput());
    }
    qWarning().noquote() << "[titan-menu] unknown provider" << provider;
    return {};
}

QVector<MenuNode> MenuController::expand(const MenuNode &group) const
{
    QVector<MenuNode> out;
    for (const MenuNode &child : group.children) {
        if (!titanmenu::isAvailable(child))
            continue;
        if (child.isGroup()) {
            // Hide groups that would be empty on this machine.
            MenuNode probe = child;
            probe.children = expand(child);
            if (probe.children.isEmpty())
                continue;
        }
        out.append(child);
    }
    if (!group.provider.isEmpty())
        out += resolveProvider(group.provider);
    return out;
}

void MenuController::collectLeaves(const MenuNode &group, const QString &crumb,
                                   QVector<Flat> *out) const
{
    for (const MenuNode &child : expand(group)) {
        if (child.isGroup()) {
            const QString next = crumb.isEmpty() ? child.title : crumb + kCrumbSep + child.title;
            collectLeaves(child, next, out);
        } else {
            out->append({child, crumb});
        }
    }
}

void MenuController::rebuild()
{
    m_visible.clear();
    QVariantList rows;

    auto push = [&](const MenuNode &n, const QString &crumb) {
        QVariantMap row;
        row[QStringLiteral("title")] = n.title;
        row[QStringLiteral("hint")]  = n.hint;
        row[QStringLiteral("icon")]  = n.icon;
        row[QStringLiteral("keys")]  = n.keys;
        row[QStringLiteral("group")] = n.isGroup();
        row[QStringLiteral("crumb")] = crumb;
        rows.append(row);
        m_visible.append(n);
    };

    const QString q = m_query.trimmed();
    if (q.isEmpty()) {
        for (const MenuNode &n : m_stack.last().children)
            push(n, QString());
    } else {
        if (!m_flatValid) {
            m_flatCache.clear();
            collectLeaves(m_root, QString(), &m_flatCache);
            m_flatValid = true;
        }
        struct Scored { int score; int order; const Flat *flat; };
        QVector<Scored> scored;
        for (int i = 0; i < m_flatCache.size(); ++i) {
            const Flat &f = m_flatCache.at(i);
            int best = titanmenu::fuzzyScore(q, f.node.title);
            if (best >= 0)
                best += 30;     // a title hit beats a breadcrumb/hint hit
            const QString full = f.crumb.isEmpty() ? f.node.title : f.crumb + kCrumbSep + f.node.title;
            best = std::max(best, titanmenu::fuzzyScore(q, full));
            const int hint = titanmenu::fuzzyScore(q, f.node.hint);
            if (hint >= 0)
                best = std::max(best, hint - 10);
            if (best >= 0)
                scored.append({best, i, &f});
        }
        std::stable_sort(scored.begin(), scored.end(),
                         [](const Scored &a, const Scored &b) { return a.score > b.score; });
        for (const Scored &s : scored)
            push(s.flat->node, s.flat->crumb);
    }

    m_entries = rows;
    emit entriesChanged();
}

void MenuController::enter(int row)
{
    if (row < 0 || row >= m_visible.size() || !m_visible.at(row).isGroup())
        return;
    MenuNode group = m_visible.at(row);
    group.children = expand(group);
    m_stack.append(group);
    if (!m_query.isEmpty()) {
        m_query.clear();
        emit queryChanged();
    }
    rebuild();
}

void MenuController::activate(int row)
{
    if (row < 0 || row >= m_visible.size())
        return;
    const MenuNode node = m_visible.at(row);
    if (node.isGroup())
        enter(row);
    else
        run(node);
}

void MenuController::back()
{
    if (!m_query.isEmpty()) {
        m_query.clear();
        emit queryChanged();
        rebuild();
        return;
    }
    if (m_stack.size() > 1) {
        m_stack.removeLast();
        rebuild();
        return;
    }
    emit closeRequested();
}

void MenuController::run(const MenuNode &node)
{
    const QString command = node.exec;
    qInfo().noquote() << "[titan-menu] run:" << command;
    emit commandLaunched(command);
    emit closeRequested();

    QTimer::singleShot(kExecBaseDelayMs + node.delayMs, this, [command]() {
        QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), command});
    });
}
