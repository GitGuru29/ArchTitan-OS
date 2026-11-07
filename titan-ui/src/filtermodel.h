#pragma once

#include <QSortFilterProxyModel>
#include <QQmlEngine>

/**
 * TitanFilterModel — high-performance C++ fuzzy filter and sort proxy model.
 *
 * Implements fzf-style subsequence fuzzy matching with word boundary and
 * consecutive match scoring. Enables instant 144Hz responsive filtering for
 * launchers, wallpaper pickers, and search overlays without JavaScript overhead.
 */
class TitanFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QObject *source READ sourceModelObj WRITE setSourceModelObj NOTIFY sourceChanged)
    Q_PROPERTY(QString filterString READ filterString WRITE setFilterString NOTIFY filterStringChanged)
    Q_PROPERTY(QString filterRoleName READ filterRoleName WRITE setFilterRoleName NOTIFY filterRoleNameChanged)
    Q_PROPERTY(bool fuzzy READ fuzzy WRITE setFuzzy NOTIFY fuzzyChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit TitanFilterModel(QObject *parent = nullptr);

    QObject *sourceModelObj() const { return sourceModel(); }
    void setSourceModelObj(QObject *source);

    QString filterString() const { return m_filterString; }
    void setFilterString(const QString &str);

    QString filterRoleName() const { return m_filterRoleName; }
    void setFilterRoleName(const QString &name);

    bool fuzzy() const { return m_fuzzy; }
    void setFuzzy(bool f);

    int count() const { return rowCount(); }

    Q_INVOKABLE int score(const QString &candidate, const QString &query) const;

signals:
    void sourceChanged();
    void filterStringChanged();
    void filterRoleNameChanged();
    void fuzzyChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int source_row, const QModelIndex &source_parent) const override;
    bool lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const override;

private:
    void updateFilterRole();
    bool computeFuzzyMatch(const QString &candidate, const QString &query, int *outScore = nullptr) const;

    QString m_filterString;
    QString m_filterRoleName;
    bool m_fuzzy = true;
};

