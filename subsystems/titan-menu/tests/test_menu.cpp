#include <QtTest>

#include "fuzzy.hpp"
#include "menucontroller.hpp"
#include "menutree.hpp"

using namespace titanmenu;

namespace {

// A tiny menu with a nested group, a hidden-by-requires entry, and a group
// whose only child is unavailable (so the group itself must disappear).
const char *kMenu = R"JSON({
  "items": [
    { "id": "apps", "title": "Apps", "hint": "Launch an application", "icon": "a", "exec": "true" },
    { "id": "cap", "title": "Capture", "icon": "c", "children": [
        { "id": "r", "title": "Region to clipboard", "icon": "r", "exec": "true" },
        { "id": "f", "title": "Full screen", "icon": "f", "exec": "true" } ] },
    { "id": "gone", "title": "Ghost tool", "icon": "g", "requires": "definitely-not-installed-xyz", "exec": "true" },
    { "id": "emptygroup", "title": "Empty group", "icon": "e", "children": [
        { "id": "x", "title": "Nope", "icon": "x", "requires": "definitely-not-installed-xyz", "exec": "true" } ] },
    { "id": "sys", "title": "System", "icon": "s", "children": [
        { "id": "lock", "title": "Lock", "hint": "Lock the screen", "icon": "l", "exec": "true" },
        { "id": "lockdown", "title": "Lockdown procedure for remote machines", "icon": "l", "exec": "true" } ] }
  ]
})JSON";

QStringList titles(const QVariantList &rows)
{
    QStringList out;
    for (const QVariant &v : rows)
        out << v.toMap().value("title").toString();
    return out;
}

} // namespace

class TestMenu : public QObject
{
    Q_OBJECT

private slots:
    // ── fuzzy ───────────────────────────────────────────────────────────────
    void fuzzy_emptyQueryMatchesAll() { QCOMPARE(fuzzyScore("", "anything"), 0); }
    void fuzzy_nonMatchIsNegative()   { QCOMPARE(fuzzyScore("zq", "Capture"), -1); }
    void fuzzy_isCaseInsensitive()    { QVERIFY(fuzzyScore("CAP", "capture") > 0); }
    void fuzzy_requiresOrder()        { QCOMPARE(fuzzyScore("tc", "ct"), -1); }
    void fuzzy_prefixBeatsMidWord()
    {
        QVERIFY(fuzzyScore("lock", "Lock") > fuzzyScore("lock", "Unlock"));
    }
    void fuzzy_wordStartBeatsScattered()
    {
        QVERIFY(fuzzyScore("rtc", "Region to clipboard") > fuzzyScore("rtc", "Rotation scale"));
    }
    void fuzzy_shorterTextWins()
    {
        QVERIFY(fuzzyScore("lock", "Lock") > fuzzyScore("lock", "Lockdown procedure for remote machines"));
    }
    void fuzzy_ignoresQuerySpaces()
    {
        QVERIFY(fuzzyScore("night light", "Nightlight") > 0);
    }

    // ── parsing ─────────────────────────────────────────────────────────────
    void parse_acceptsValid()
    {
        MenuNode root; QString err;
        QVERIFY2(parseMenu(kMenu, &root, &err), qPrintable(err));
        QCOMPARE(root.children.size(), 5);
    }
    void parse_rejectsBadJson()
    {
        MenuNode root; QString err;
        QVERIFY(!parseMenu("{ not json", &root, &err));
        QVERIFY(!err.isEmpty());
    }
    void parse_rejectsMissingTitle()
    {
        MenuNode root; QString err;
        QVERIFY(!parseMenu(R"({"items":[{"id":"a","exec":"true"}]})", &root, &err));
    }
    void parse_rejectsExecAndChildren()
    {
        MenuNode root; QString err;
        QVERIFY(!parseMenu(R"({"items":[{"title":"A","exec":"true","children":[{"title":"B","exec":"true"}]}]})",
                           &root, &err));
    }
    void parse_rejectsEmptyNode()
    {
        MenuNode root; QString err;
        QVERIFY(!parseMenu(R"({"items":[{"title":"A"}]})", &root, &err));
    }

    // ── themes provider ─────────────────────────────────────────────────────
    void themes_parsesListOutput()
    {
        const QByteArray out =
            "  catppuccin   Catppuccin Mocha\n"
            "* nord         Nord\n"
            "  rosepine     Rosé Pine\n";
        const auto nodes = MenuController::parseThemeList(out);
        QCOMPARE(nodes.size(), 3);
        QCOMPARE(nodes[1].id, QString("nord"));
        QCOMPARE(nodes[1].title, QString("Nord"));
        QCOMPARE(nodes[1].hint, QString("Active theme"));
        QCOMPARE(nodes[1].exec, QString("titan-theme set nord"));
        QCOMPARE(nodes[0].title, QString("Catppuccin Mocha"));
        QCOMPARE(nodes[2].hint, QString("Apply this theme"));
    }
    void themes_ignoresBlankLines()
    {
        QCOMPARE(MenuController::parseThemeList("\n\n").size(), 0);
    }

    // ── controller ──────────────────────────────────────────────────────────
    void controller_hidesUnavailableAndEmptyGroups()
    {
        MenuController c; QString err;
        QVERIFY2(c.loadJson(kMenu, &err), qPrintable(err));
        QCOMPARE(titles(c.entries()), QStringList({"Apps", "Capture", "System"}));
    }
    void controller_drillDownAndBack()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        QVERIFY(c.atRoot());

        c.activate(1);                                   // Capture
        QVERIFY(!c.atRoot());
        QCOMPARE(c.breadcrumb(), QString("Capture"));
        QCOMPARE(titles(c.entries()), QStringList({"Region to clipboard", "Full screen"}));

        QSignalSpy closed(&c, &MenuController::closeRequested);
        c.back();                                        // back to root
        QVERIFY(c.atRoot());
        QCOMPARE(closed.count(), 0);
        c.back();                                        // back at root closes
        QCOMPARE(closed.count(), 1);
    }
    void controller_searchIsGlobalAndRanked()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.setQuery("lock");
        const QStringList t = titles(c.entries());
        QVERIFY(t.size() >= 2);
        QCOMPARE(t.first(), QString("Lock"));            // exact beats Lockdown…
        QVERIFY(t.contains("Lockdown procedure for remote machines"));
        // Groups never appear as results, only their leaves.
        QVERIFY(!t.contains("System"));
    }
    void controller_searchShowsBreadcrumb()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.setQuery("region");
        QCOMPARE(c.entries().size(), 1);
        QCOMPARE(c.entries().first().toMap().value("crumb").toString(), QString("Capture"));
    }
    void controller_searchNoMatch()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.setQuery("zzzzqqq");
        QCOMPARE(c.entries().size(), 0);
    }
    void controller_backClearsQueryBeforeLeaving()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.setQuery("lock");
        QSignalSpy closed(&c, &MenuController::closeRequested);
        c.back();
        QVERIFY(c.query().isEmpty());
        QCOMPARE(closed.count(), 0);
    }
    void controller_activateActionCloses()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        QSignalSpy closed(&c, &MenuController::closeRequested);
        QSignalSpy launched(&c, &MenuController::commandLaunched);
        c.activate(0);                                   // Apps -> exec "true"
        QCOMPARE(closed.count(), 1);
        QCOMPARE(launched.count(), 1);
        QCOMPARE(launched.first().first().toString(), QString("true"));
    }
    void controller_resetReturnsToRoot()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.activate(1);
        c.setQuery("x");
        c.reset();
        QVERIFY(c.atRoot());
        QVERIFY(c.query().isEmpty());
        QCOMPARE(c.entries().size(), 3);
    }
    void controller_outOfRangeIsIgnored()
    {
        MenuController c; QString err;
        QVERIFY(c.loadJson(kMenu, &err));
        c.activate(-1);
        c.activate(99);
        c.enter(99);
        QVERIFY(c.atRoot());
    }

    // ── the shipped menu must itself be valid ───────────────────────────────
    void builtinMenuIsValid()
    {
        QFile f(":/data/menu.json");
        QVERIFY(f.open(QIODevice::ReadOnly));
        MenuNode root; QString err;
        QVERIFY2(parseMenu(f.readAll(), &root, &err), qPrintable(err));
        QVERIFY(root.children.size() >= 8);
    }
};

QTEST_MAIN(TestMenu)
#include "test_menu.moc"
