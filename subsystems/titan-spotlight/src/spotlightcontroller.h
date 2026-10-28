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

    Q_INVOKABLE void selectNext();
    Q_INVOKABLE void selectPrev();
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
    void closeRequested();

private:
    void updateResults();
    void executeAction(const QVariantMap &item);

    QString m_query;
    QVariantList m_results;
    int m_selectedIndex = 0;
    CalcResult m_calcResult;
    bool m_isClipboardMode = false;

    AppIndexer m_indexer;
    QList<QVariantMap> m_systemActions;
};
