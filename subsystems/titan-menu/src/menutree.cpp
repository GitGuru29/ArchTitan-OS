#include "menutree.hpp"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QStandardPaths>

namespace titanmenu {

namespace {

bool parseNode(const QJsonObject &obj, MenuNode *out, QString *error, int depth)
{
    if (depth > 6) {
        *error = QStringLiteral("menu nested deeper than 6 levels");
        return false;
    }

    out->id        = obj.value(QStringLiteral("id")).toString();
    out->title     = obj.value(QStringLiteral("title")).toString();
    out->hint      = obj.value(QStringLiteral("hint")).toString();
    out->icon      = obj.value(QStringLiteral("icon")).toString();
    out->keys      = obj.value(QStringLiteral("keys")).toString();
    out->exec      = obj.value(QStringLiteral("exec")).toString();
    out->provider  = obj.value(QStringLiteral("provider")).toString();
    out->requires_ = obj.value(QStringLiteral("requires")).toString();
    out->delayMs   = obj.value(QStringLiteral("delay")).toInt(0);

    if (out->title.isEmpty()) {
        *error = QStringLiteral("menu entry without a title (id='%1')").arg(out->id);
        return false;
    }

    const QJsonArray children = obj.value(QStringLiteral("children")).toArray();
    if (!out->exec.isEmpty() && (!children.isEmpty() || !out->provider.isEmpty())) {
        *error = QStringLiteral("'%1' has both exec and children/provider").arg(out->title);
        return false;
    }
    if (out->exec.isEmpty() && children.isEmpty() && out->provider.isEmpty()) {
        *error = QStringLiteral("'%1' has neither exec nor children/provider").arg(out->title);
        return false;
    }

    for (const QJsonValue &v : children) {
        MenuNode child;
        if (!parseNode(v.toObject(), &child, error, depth + 1))
            return false;
        out->children.append(child);
    }
    return true;
}

} // namespace

bool parseMenu(const QByteArray &json, MenuNode *root, QString *error)
{
    QJsonParseError parseError;
    const QJsonDocument doc = QJsonDocument::fromJson(json, &parseError);
    if (parseError.error != QJsonParseError::NoError) {
        *error = QStringLiteral("JSON: %1 (offset %2)")
                     .arg(parseError.errorString())
                     .arg(parseError.offset);
        return false;
    }
    if (!doc.isObject()) {
        *error = QStringLiteral("top level must be an object");
        return false;
    }

    // The top level is an implicit group; give it a title so the shared
    // node validator is happy.
    QJsonObject top = doc.object();
    top.insert(QStringLiteral("title"), QStringLiteral("Menu"));
    top.insert(QStringLiteral("id"), QStringLiteral("root"));
    if (top.value(QStringLiteral("children")).toArray().isEmpty()
        && top.value(QStringLiteral("items")).isArray()) {
        top.insert(QStringLiteral("children"), top.value(QStringLiteral("items")));
    }
    return parseNode(top, root, error, 0);
}

bool isAvailable(const MenuNode &node)
{
    if (node.requires_.isEmpty())
        return true;
    return !QStandardPaths::findExecutable(node.requires_).isEmpty();
}

} // namespace titanmenu
