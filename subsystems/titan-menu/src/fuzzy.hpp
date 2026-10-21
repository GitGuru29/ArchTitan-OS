#pragma once

#include <QString>

namespace titanmenu {

/**
 * Fuzzy subsequence scorer used by the menu search.
 *
 * Every character of `query` must appear in `text` in order (case-insensitive).
 * Returns -1 when it does not match, otherwise a score where higher is better:
 *   - consecutive matched characters are rewarded,
 *   - matches that start a word (after a space, '-', '_', '›' or at index 0)
 *     are rewarded more,
 *   - a match starting at index 0 gets a large prefix bonus,
 *   - longer texts are penalised slightly so "Lock" outranks "Lock screen now".
 * An empty query matches everything with score 0.
 */
int fuzzyScore(const QString &query, const QString &text);

} // namespace titanmenu
