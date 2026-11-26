#include "filtermodel.h"

#include <QAbstractItemModel>

TitanFilterModel::TitanFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setSortCaseSensitivity(Qt::CaseInsensitive);

    connect(this, &QAbstractItemModel::rowsInserted, this, &TitanFilterModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &TitanFilterModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &TitanFilterModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &TitanFilterModel::countChanged);
}

void TitanFilterModel::setSourceModelObj(QObject *source)
{
    auto *model = qobject_cast<QAbstractItemModel *>(source);
    if (sourceModel() == model)
        return;

    setSourceModel(model);
    updateFilterRole();
    emit sourceChanged();
    emit countChanged();
}

void TitanFilterModel::setFilterString(const QString &str)
{
    if (m_filterString == str)
        return;

    m_filterString = str;
    emit filterStringChanged();
    invalidate();
    if (m_fuzzy && !m_filterString.isEmpty()) {
        sort(0, Qt::DescendingOrder);
    }
    emit countChanged();
}

void TitanFilterModel::setFilterRoleName(const QString &name)
{
    if (m_filterRoleName == name)
        return;

    m_filterRoleName = name;
    updateFilterRole();
    emit filterRoleNameChanged();
    invalidate();
    emit countChanged();
}

void TitanFilterModel::setFuzzy(bool f)
{
    if (m_fuzzy == f)
        return;

    m_fuzzy = f;
    emit fuzzyChanged();
    invalidate();
    emit countChanged();
}

void TitanFilterModel::updateFilterRole()
{
    if (!sourceModel() || m_filterRoleName.isEmpty())
        return;

    const QHash<int, QByteArray> roles = sourceModel()->roleNames();
    for (auto it = roles.constBegin(); it != roles.constEnd(); ++it) {
        if (it.value() == m_filterRoleName.toUtf8()) {
            setFilterRole(it.key());
            setSortRole(it.key());
            return;
        }
    }
}

bool TitanFilterModel::computeFuzzyMatch(const QString &candidate, const QString &query, int *outScore) const
{
    if (query.isEmpty()) {
        if (outScore) *outScore = 0;
        return true;
    }

    const int cLen = candidate.length();
    const int qLen = query.length();
    if (qLen > cLen) {
        if (outScore) *outScore = -1;
        return false;
    }

    int qIdx = 0;
    int score = 0;
    int consecutive = 0;

    for (int cIdx = 0; cIdx < cLen && qIdx < qLen; ++cIdx) {
        const QChar c = candidate.at(cIdx).toLower();
        const QChar q = query.at(qIdx).toLower();

        if (c == q) {
            ++qIdx;
            score += 10 + (consecutive * 5); // consecutive match bonus
            // Word boundary bonus
            if (cIdx == 0 ||
                candidate.at(cIdx - 1) == QLatin1Char(' ') ||
                candidate.at(cIdx - 1) == QLatin1Char('-') ||
                candidate.at(cIdx - 1) == QLatin1Char('_') ||
                candidate.at(cIdx - 1) == QLatin1Char('/')) {
                score += 20;
            } else if (candidate.at(cIdx).isUpper()) {
                score += 15; // camelCase bonus
            }
            ++consecutive;
        } else {
            consecutive = 0;
        }
    }

    const bool matched = (qIdx == qLen);
    if (outScore) *outScore = matched ? score : -1;
    return matched;
}

int TitanFilterModel::score(const QString &candidate, const QString &query) const
{
    int s = 0;
    computeFuzzyMatch(candidate, query, &s);
    return s;
}

bool TitanFilterModel::filterAcceptsRow(int source_row, const QModelIndex &source_parent) const
{
    if (m_filterString.isEmpty())
        return true;

    if (!sourceModel())
        return false;

    const QModelIndex idx = sourceModel()->index(source_row, 0, source_parent);
    const int role = filterRole() >= 0 ? filterRole() : Qt::DisplayRole;
    const QString value = sourceModel()->data(idx, role).toString();

    if (m_fuzzy) {
        return computeFuzzyMatch(value, m_filterString);
    }

    return value.contains(m_filterString, Qt::CaseInsensitive);
}

bool TitanFilterModel::lessThan(const QModelIndex &source_left, const QModelIndex &source_right) const
{
    if (m_fuzzy && !m_filterString.isEmpty() && sourceModel()) {
        const int role = filterRole() >= 0 ? filterRole() : Qt::DisplayRole;
        const QString leftVal = sourceModel()->data(source_left, role).toString();
        const QString rightVal = sourceModel()->data(source_right, role).toString();

        int leftScore = 0;
        int rightScore = 0;
        computeFuzzyMatch(leftVal, m_filterString, &leftScore);
        computeFuzzyMatch(rightVal, m_filterString, &rightScore);

        if (leftScore != rightScore)
            return leftScore < rightScore;
    }

    return QSortFilterProxyModel::lessThan(source_left, source_right);
}
