#include "calculator.h"

#include <QJSEngine>
#include <QJSValue>
#include <QRegularExpression>
#include <cmath>

bool SpotlightCalculator::isLikelyMath(const QString &input)
{
    QString trimmed = input.trimmed();
    if (trimmed.isEmpty()) return false;

    // Must have at least one digit
    static const QRegularExpression digitRx(QStringLiteral("[0-9]"));
    if (!trimmed.contains(digitRx)) return false;

    // Check for math operators or functions
    static const QRegularExpression opRx(QStringLiteral(R"([\+\-\*\/\^\%]|sqrt|sin|cos|tan|log|abs|pi|pow)"), QRegularExpression::CaseInsensitiveOption);
    if (!trimmed.contains(opRx)) return false;

    // Guard against pure filenames or options like "--help" or "file-1.txt"
    if (trimmed.startsWith(QLatin1Char('-')) && !trimmed.contains(QRegularExpression(R"([\+\*\/])"))) {
        // e.g. -version or --help
        if (trimmed.contains(QRegularExpression(R"([a-zA-Z]{2,})"))) return false;
    }

    // Must not contain shell redirect / pipe
    if (trimmed.contains(QLatin1Char('>')) || trimmed.contains(QLatin1Char('|')) || trimmed.contains(QLatin1Char('&')) || trimmed.contains(QLatin1Char(';'))) {
        return false;
    }

    return true;
}

CalcResult SpotlightCalculator::evaluate(const QString &expression)
{
    CalcResult result;
    if (!isLikelyMath(expression)) return result;

    QString sanitized = expression.trimmed();

    // Support "X% of Y" -> (X/100 * Y)
    static const QRegularExpression pctOfRx(R"((\d+(?:\.\d+)?)\s*%\s*(?:of|\*)\s*(\d+(?:\.\d+)?))", QRegularExpression::CaseInsensitiveOption);
    sanitized.replace(pctOfRx, R"(((\1 / 100.0) * \2))");

    // Replace ^ with ** for exponentiation
    sanitized.replace(QLatin1Char('^'), QStringLiteral("**"));

    // Replace math function names with Math.fn
    sanitized.replace(QRegularExpression(R"(\bsqrt\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.sqrt"));
    sanitized.replace(QRegularExpression(R"(\bsin\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.sin"));
    sanitized.replace(QRegularExpression(R"(\bcos\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.cos"));
    sanitized.replace(QRegularExpression(R"(\btan\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.tan"));
    sanitized.replace(QRegularExpression(R"(\babs\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.abs"));
    sanitized.replace(QRegularExpression(R"(\blog\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.log"));
    sanitized.replace(QRegularExpression(R"(\bpi\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.PI"));
    sanitized.replace(QRegularExpression(R"(\be\b)", QRegularExpression::CaseInsensitiveOption), QStringLiteral("Math.E"));

    // Ensure only safe mathematical characters exist in sanitized string
    static const QRegularExpression safeRx(R"(^[0-9\.\+\-\*\/\(\)\s,]|Math\.(sqrt|sin|cos|tan|abs|log|PI|E))");
    // Verify it doesn't contain arbitrary JS keywords
    if (sanitized.contains(QRegularExpression(R"(\b(function|var|let|const|window|document|eval|import|export|class|this|delete|typeof|while|for|if)\b)"))) {
        return result;
    }

    QJSEngine engine;
    QJSValue val = engine.evaluate(sanitized);

    if (val.isError() || !val.isNumber()) {
        return result;
    }

    double num = val.toNumber();
    if (std::isnan(num) || std::isinf(num)) {
        return result;
    }

    result.valid = true;
    result.value = num;
    result.formula = expression.trimmed();

    // Format output cleanly:
    if (std::floor(num) == num && std::abs(num) < 1e14) {
        result.formattedResult = QString::number(static_cast<qint64>(num));
    } else {
        result.formattedResult = QString::number(num, 'g', 10);
    }

    return result;
}
