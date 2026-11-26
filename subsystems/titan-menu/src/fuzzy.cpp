#include "fuzzy.hpp"

namespace titanmenu {

namespace {

bool isWordBoundary(const QString &text, int index)
{
    if (index == 0)
        return true;
    const QChar prev = text.at(index - 1);
    return prev == QLatin1Char(' ') || prev == QLatin1Char('-')
        || prev == QLatin1Char('_') || prev == QChar(0x203A) /* › */;
}

} // namespace

int fuzzyScore(const QString &query, const QString &text)
{
    if (query.isEmpty())
        return 0;

    const QString q = query.toCaseFolded();
    const QString t = text.toCaseFolded();

    int score = 0;
    int ti = 0;
    int prevMatch = -2;

    for (int qi = 0; qi < q.size(); ++qi) {
        // Skip whitespace in the query: "dark mode" should still match "darkmode".
        if (q.at(qi).isSpace())
            continue;

        int found = -1;
        for (; ti < t.size(); ++ti) {
            if (t.at(ti) == q.at(qi)) {
                found = ti;
                break;
            }
        }
        if (found < 0)
            return -1;

        score += 10;
        if (found == prevMatch + 1)
            score += 15;            // consecutive run
        if (isWordBoundary(t, found))
            score += 20;            // starts a word
        if (found == 0)
            score += 40;            // anchored at the very start

        prevMatch = found;
        ++ti;
    }

    // Prefer tighter texts: subtract a small length penalty (never below 1 so a
    // genuine match stays distinguishable from "no match").
    score -= qMin(score - 1, t.size() / 4);
    return score;
}

} // namespace titanmenu
