#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>
#include <QTimer>

#include "appindexer.h"
#include "calculator.h"

class SpotlightController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QVariantList results READ results NOTIFY resultsChanged)
    Q_PROPERTY(int selectedIndex READ selectedIndex WRITE setSelectedIndex NOTIFY selectedIndexChanged)
    Q_PROPERTY(bool hasCalcResult READ hasCalcResult NOTIFY calcResultChanged)
    Q_PROPERTY(QString calcFormula READ calcFormula NOTIFY calcResultChanged)
    Q_PROPERTY(QString calcResult READ calcResult NOTIFY calcResultChanged)
    Q_PROPERTY(bool isClipboardMode READ isClipboardMode WRITE setClipboardMode NOTIFY clipboardModeChanged)
    Q_PROPERTY(QString viewMode READ viewMode WRITE setViewMode NOTIFY viewModeChanged)
    Q_PROPERTY(QString activeCategory READ activeCategory WRITE setActiveCategory NOTIFY activeCategoryChanged)
    Q_PROPERTY(int gridColumns READ gridColumns NOTIFY viewModeChanged)

public:
    explicit SpotlightController(QObject *parent = nullptr);

    QString query() const { return m_query; }
    void setQuery(const QString &q);

    QVariantList results() const { return m_results; }
    int selectedIndex() const { return m_selectedIndex; }
    void setSelectedIndex(int idx);

    bool hasCalcResult() const { return m_calcResult.valid; }
    QString calcFormula() const { return m_calcResult.formula; }
    QString calcResult() const { return m_calcResult.formattedResult; }

    bool isClipboardMode() const { return m_isClipboardMode; }
    void setClipboardMode(bool enabled);

    QString viewMode() const { return m_viewMode; }
    void setViewMode(const QString &mode);

    QString activeCategory() const { return m_activeCategory; }
    void setActiveCategory(const QString &category);

    int gridColumns() const;

    Q_INVOKABLE void selectNext();
    Q_INVOKABLE void selectPrev();
    Q_INVOKABLE void selectUp();
    Q_INVOKABLE void selectDown();
    Q_INVOKABLE void selectLeft();
    Q_INVOKABLE void selectRight();
    Q_INVOKABLE void cycleViewMode();
    Q_INVOKABLE void cycleCategory(int delta = 1);
    Q_INVOKABLE void activateCurrent();
    Q_INVOKABLE void activate(int index);
    Q_INVOKABLE void copyCalcResult();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void refreshApps();

signals:
    void queryChanged();
    void resultsChanged();
    void selectedIndexChanged();
    void calcResultChanged();
    void clipboardModeChanged();
    void viewModeChanged();
    void activeCategoryChanged();
    void closeRequested();

private:
    void updateResults();
    void executeAction(const QVariantMap &item);
    void loadPreferences();
    void savePreferences() const;
    static QString classifyAppGroup(const AppEntry &entry);

    QString m_query;
    QVariantList m_results;
    int m_selectedIndex = 0;
    CalcResult m_calcResult;
    bool m_isClipboardMode = false;
    QString m_viewMode = QStringLiteral("grid");
    QString m_activeCategory = QStringLiteral("ALL");

    AppIndexer m_indexer;
    QList<QVariantMap> m_systemActions;
};
