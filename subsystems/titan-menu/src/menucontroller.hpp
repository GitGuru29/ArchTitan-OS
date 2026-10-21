#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QVector>

#include "menutree.hpp"

/**
 * MenuController — navigation, search and execution for titan-menu.
 *
 * QML binds to `entries` (the rows to show) and calls activate()/back().
 * The controller never touches the UI: when an action fires or the user backs
 * out of the root it emits closeRequested() and QML plays the exit animation.
 */
class MenuController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList entries READ entries NOTIFY entriesChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString breadcrumb READ breadcrumb NOTIFY entriesChanged)
    Q_PROPERTY(bool atRoot READ atRoot NOTIFY entriesChanged)
    Q_PROPERTY(bool loadedFromUser READ loadedFromUser CONSTANT)
    Q_PROPERTY(QString loadWarning READ loadWarning CONSTANT)

public:
    // Delay between asking QML to close and spawning the command. QML hides the
    // layer surface after ~180 ms; the layer holds exclusive keyboard focus
    // until then, so a command that opens its own window must wait.
    static constexpr int kExecBaseDelayMs = 230;

    explicit MenuController(QObject *parent = nullptr);

    /** Loads the user menu (~/.config/archtitan/menu.json), else the built-in one. */
    bool loadDefault();
    /** Loads from explicit JSON (used by tests). */
    bool loadJson(const QByteArray &json, QString *error);

    QVariantList entries() const { return m_entries; }
    QString query() const { return m_query; }
    QString breadcrumb() const;
    bool atRoot() const { return m_stack.size() <= 1; }
    bool loadedFromUser() const { return m_loadedFromUser; }
    QString loadWarning() const { return m_loadWarning; }

    void setQuery(const QString &q);

    Q_INVOKABLE void reset();
    Q_INVOKABLE void activate(int row);
    Q_INVOKABLE void back();
    /** Descend into a group row without running anything (→ key). */
    Q_INVOKABLE void enter(int row);

    /** Provider hook, public so tests can substitute theme output. */
    static QVector<titanmenu::MenuNode> parseThemeList(const QByteArray &output);

signals:
    void entriesChanged();
    void queryChanged();
    void closeRequested();
    void commandLaunched(const QString &command);

private:
    struct Flat {
        titanmenu::MenuNode node;
        QString crumb;
    };

    QVector<titanmenu::MenuNode> expand(const titanmenu::MenuNode &group) const;
    QVector<titanmenu::MenuNode> resolveProvider(const QString &provider) const;
    void collectLeaves(const titanmenu::MenuNode &group, const QString &crumb,
                       QVector<Flat> *out) const;
    void rebuild();
    void run(const titanmenu::MenuNode &node);

    titanmenu::MenuNode m_root;
    QVector<titanmenu::MenuNode> m_stack;    // expanded groups, root first
    QVector<titanmenu::MenuNode> m_visible;  // nodes behind the rows in `entries`
    QVector<Flat> m_flatCache;
    bool m_flatValid = false;

    QVariantList m_entries;
    QString m_query;
    bool m_loadedFromUser = false;
    QString m_loadWarning;
};
