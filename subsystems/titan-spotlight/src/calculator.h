#pragma once

#include <QString>

struct CalcResult {
    bool valid = false;
    double value = 0.0;
    QString formula;
    QString formattedResult;
};

class SpotlightCalculator {
public:
    static CalcResult evaluate(const QString &expression);
    static bool isLikelyMath(const QString &input);
};
