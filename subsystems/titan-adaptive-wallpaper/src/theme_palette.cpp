#include "theme_palette.hpp"
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDir>
#include <QFileInfo>
#include <QStringList>
#include <algorithm>
#include <cctype>
#include <cstdlib>

namespace taw {

void ThemePalette::compute_oklab_anchors() {
    oklab_crust    = rgb_to_oklab(crust);
    oklab_mantle   = rgb_to_oklab(mantle);
    oklab_base     = rgb_to_oklab(base);
    oklab_surface1 = rgb_to_oklab(surface1);
    oklab_accent   = rgb_to_oklab(accent);
    oklab_accent2  = rgb_to_oklab(accent2);
    oklab_textHigh = rgb_to_oklab(textHigh);
}

ThemePalette ThemePalette::mocha() {
    ThemePalette p;
    p.id = "mocha";
    p.name = "Catppuccin Mocha";
    p.isDark = true;
    p.accent = RGB::from_hex("#89B4FA");    // Blue
    p.accent2 = RGB::from_hex("#CBA6F7");   // Mauve
    p.crust = RGB::from_hex("#11111B");
    p.mantle = RGB::from_hex("#181825");
    p.base = RGB::from_hex("#1E1E2E");
    p.surface0 = RGB::from_hex("#313244");
    p.surface1 = RGB::from_hex("#45475A");
    p.surface2 = RGB::from_hex("#585B70");
    p.surface3 = RGB::from_hex("#6C7086");
    p.textHigh = RGB::from_hex("#CDD6F4");
    p.textMid = RGB::from_hex("#A6ADC8");
    p.textLow = RGB::from_hex("#7F849C");
    p.teal = RGB::from_hex("#94E2D5");
    p.mauve = RGB::from_hex("#CBA6F7");
    p.peach = RGB::from_hex("#FAB387");
    p.pink = RGB::from_hex("#F5C2E7");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::nord() {
    ThemePalette p;
    p.id = "nord";
    p.name = "Nord";
    p.isDark = true;
    p.accent = RGB::from_hex("#88C0D0");    // Frost Cyan
    p.accent2 = RGB::from_hex("#81A1C1");   // Frost Blue
    p.crust = RGB::from_hex("#242933");
    p.mantle = RGB::from_hex("#2E3440");
    p.base = RGB::from_hex("#3B4252");
    p.surface0 = RGB::from_hex("#434C5E");
    p.surface1 = RGB::from_hex("#4C566A");
    p.surface2 = RGB::from_hex("#616E88");
    p.surface3 = RGB::from_hex("#7B88A1");
    p.textHigh = RGB::from_hex("#ECEFF4");
    p.textMid = RGB::from_hex("#E5E9F0");
    p.textLow = RGB::from_hex("#D8DEE9");
    p.teal = RGB::from_hex("#8FBCBB");
    p.mauve = RGB::from_hex("#B48EAD");
    p.peach = RGB::from_hex("#D08770");
    p.pink = RGB::from_hex("#BF616A");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::tokyonight() {
    ThemePalette p;
    p.id = "tokyonight";
    p.name = "Tokyo Night";
    p.isDark = true;
    p.accent = RGB::from_hex("#7AA2F7");    // Electric Blue
    p.accent2 = RGB::from_hex("#BB9AF7");   // Violet
    p.crust = RGB::from_hex("#16161E");
    p.mantle = RGB::from_hex("#1A1B26");
    p.base = RGB::from_hex("#24283B");
    p.surface0 = RGB::from_hex("#2F354F");
    p.surface1 = RGB::from_hex("#414868");
    p.surface2 = RGB::from_hex("#565F89");
    p.surface3 = RGB::from_hex("#7AA2F7");
    p.textHigh = RGB::from_hex("#C0CAF5");
    p.textMid = RGB::from_hex("#A9B1D6");
    p.textLow = RGB::from_hex("#787C99");
    p.teal = RGB::from_hex("#7DCFFF");
    p.mauve = RGB::from_hex("#BB9AF7");
    p.peach = RGB::from_hex("#FF9E64");
    p.pink = RGB::from_hex("#F7768E");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::dracula() {
    ThemePalette p;
    p.id = "dracula";
    p.name = "Dracula";
    p.isDark = true;
    p.accent = RGB::from_hex("#BD93F9");    // Purple
    p.accent2 = RGB::from_hex("#FF79C6");   // Pink / Magenta
    p.crust = RGB::from_hex("#191A21");
    p.mantle = RGB::from_hex("#21222C");
    p.base = RGB::from_hex("#282A36");
    p.surface0 = RGB::from_hex("#343746");
    p.surface1 = RGB::from_hex("#44475A");
    p.surface2 = RGB::from_hex("#6272A4");
    p.surface3 = RGB::from_hex("#7888B4");
    p.textHigh = RGB::from_hex("#F8F8F2");
    p.textMid = RGB::from_hex("#E2E2DC");
    p.textLow = RGB::from_hex("#6272A4");
    p.teal = RGB::from_hex("#8BE9FD");
    p.mauve = RGB::from_hex("#BD93F9");
    p.peach = RGB::from_hex("#FFB86C");
    p.pink = RGB::from_hex("#FF79C6");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::gruvbox() {
    ThemePalette p;
    p.id = "gruvbox";
    p.name = "Gruvbox";
    p.isDark = true;
    p.accent = RGB::from_hex("#FE8019");    // Orange
    p.accent2 = RGB::from_hex("#FABD2F");   // Yellow
    p.crust = RGB::from_hex("#1D2021");
    p.mantle = RGB::from_hex("#282828");
    p.base = RGB::from_hex("#32302F");
    p.surface0 = RGB::from_hex("#3C3836");
    p.surface1 = RGB::from_hex("#504945");
    p.surface2 = RGB::from_hex("#665C54");
    p.surface3 = RGB::from_hex("#7C6F64");
    p.textHigh = RGB::from_hex("#EBDBB2");
    p.textMid = RGB::from_hex("#D5C4A1");
    p.textLow = RGB::from_hex("#BDAE93");
    p.teal = RGB::from_hex("#8EC07C");
    p.mauve = RGB::from_hex("#D3869B");
    p.peach = RGB::from_hex("#FE8019");
    p.pink = RGB::from_hex("#FB4934");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::everforest() {
    ThemePalette p;
    p.id = "everforest";
    p.name = "Everforest";
    p.isDark = true;
    p.accent = RGB::from_hex("#A7C080");    // Green
    p.accent2 = RGB::from_hex("#83C092");   // Aqua
    p.crust = RGB::from_hex("#232A2E");
    p.mantle = RGB::from_hex("#2D353B");
    p.base = RGB::from_hex("#343F44");
    p.surface0 = RGB::from_hex("#3D484D");
    p.surface1 = RGB::from_hex("#475258");
    p.surface2 = RGB::from_hex("#4F585E");
    p.surface3 = RGB::from_hex("#56635f");
    p.textHigh = RGB::from_hex("#D3C6AA");
    p.textMid = RGB::from_hex("#9DA9A0");
    p.textLow = RGB::from_hex("#7A8478");
    p.teal = RGB::from_hex("#7FBBB3");
    p.mauve = RGB::from_hex("#D699B6");
    p.peach = RGB::from_hex("#E69875");
    p.pink = RGB::from_hex("#E67E80");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::rosepine() {
    ThemePalette p;
    p.id = "rosepine";
    p.name = "Rosé Pine";
    p.isDark = true;
    p.accent = RGB::from_hex("#EB6F92");    // Love / Rose
    p.accent2 = RGB::from_hex("#C4A7E7");   // Iris / Mauve
    p.crust = RGB::from_hex("#14131C");
    p.mantle = RGB::from_hex("#191724");
    p.base = RGB::from_hex("#1F1D2E");
    p.surface0 = RGB::from_hex("#26233A");
    p.surface1 = RGB::from_hex("#312E46");
    p.surface2 = RGB::from_hex("#393552");
    p.surface3 = RGB::from_hex("#4A4668");
    p.textHigh = RGB::from_hex("#E0DEF4");
    p.textMid = RGB::from_hex("#908CAA");
    p.textLow = RGB::from_hex("#6E6A86");
    p.teal = RGB::from_hex("#9CCFD8");
    p.mauve = RGB::from_hex("#C4A7E7");
    p.peach = RGB::from_hex("#F6C177");
    p.pink = RGB::from_hex("#EB6F92");
    p.compute_oklab_anchors();
    return p;
}

ThemePalette ThemePalette::amoled() {
    ThemePalette p;
    p.id = "amoled";
    p.name = "AMOLED";
    p.isDark = true;
    p.accent = RGB::from_hex("#00E5FF");    // Cyan
    p.accent2 = RGB::from_hex("#8A2BE2");   // Purple
    p.crust = RGB::from_hex("#000000");     // Pure Black
    p.mantle = RGB::from_hex("#050505");
    p.base = RGB::from_hex("#0A0A0A");
    p.surface0 = RGB::from_hex("#141414");
    p.surface1 = RGB::from_hex("#202020");
    p.surface2 = RGB::from_hex("#303030");
    p.surface3 = RGB::from_hex("#404040");
    p.textHigh = RGB::from_hex("#FFFFFF");
    p.textMid = RGB::from_hex("#B0B0B0");
    p.textLow = RGB::from_hex("#707070");
    p.teal = RGB::from_hex("#00FFFF");
    p.mauve = RGB::from_hex("#BB86FC");
    p.peach = RGB::from_hex("#FFB74D");
    p.pink = RGB::from_hex("#FF4081");
    p.compute_oklab_anchors();
    return p;
}

namespace {

QStringList preset_search_dirs() {
    return {
        QStringLiteral("/usr/share/archtitan/themes"),
        QDir::currentPath() + QStringLiteral("/airootfs/usr/share/archtitan/themes"),
        QStringLiteral("/home/msfvenom/custom-os-build/airootfs/usr/share/archtitan/themes")
    };
}

std::string normalize_preset_key(const std::string& name) {
    std::string key;
    for (unsigned char c : name) {
        if (std::isalnum(c)) key.push_back(static_cast<char>(std::tolower(c)));
    }
    if (key == "catppuccinmocha") key = "mocha";
    if (key == "catppuccinlatte") key = "latte";
    if (key == "archtitansignature") key = "archtitan";
    return key;
}

std::optional<ThemePalette> from_installed_theme(const std::string& id) {
    if (id.empty()) return std::nullopt;
    for (const QString& dir : preset_search_dirs()) {
        for (const QString& candidate : {
                 QString::fromStdString(id),
                 QString::fromStdString(id) + QStringLiteral(".json")}) {
            QFileInfo file(QDir(dir), candidate);
            if (file.isFile()) {
                return ThemePalette::from_json_file(file.absoluteFilePath().toStdString());
            }
        }
    }
    return std::nullopt;
}

} // namespace

std::vector<std::string> ThemePalette::available_presets() {
    std::vector<std::string> out = {
        "mocha", "nord", "tokyonight", "dracula",
        "gruvbox", "everforest", "rosepine", "amoled"
    };

    for (const QString& dir : preset_search_dirs()) {
        QDir d(dir);
        if (!d.exists()) continue;
        const QStringList files = d.entryList({QStringLiteral("*.json")}, QDir::Files, QDir::Name);
        for (const QString& file : files) {
            auto parsed = from_json_file(d.filePath(file).toStdString());
            std::string id = parsed.has_value() ? parsed->id
                                                : QFileInfo(file).completeBaseName().toStdString();
            if (id.empty()) continue;
            if (std::find(out.begin(), out.end(), id) == out.end()) out.push_back(id);
        }
    }
    return out;
}

std::optional<ThemePalette> ThemePalette::from_preset(const std::string& name) {
    const std::string key = normalize_preset_key(name);
    if (key == "mocha" || key == "catppuccin") return mocha();
    if (key == "nord") return nord();
    if (key == "tokyonight" || key == "tokyo") return tokyonight();
    if (key == "dracula") return dracula();
    if (key == "gruvbox") return gruvbox();
    if (key == "everforest") return everforest();
    if (key == "rosepine" || key == "rose") return rosepine();
    if (key == "amoled" || key == "pureblack") return amoled();

    // Any installed theme JSON (archtitan, kanagawa, latte, custom, future
    // additions) works as a palette without needing a hard-coded preset.
    return from_installed_theme(key);
}

static RGB parse_color_prop(const QJsonObject& obj, const QString& key, const RGB& fallback) {
    if (obj.contains(key) && obj[key].isString()) {
        return RGB::from_hex(obj[key].toString().toStdString());
    }
    return fallback;
}

std::optional<ThemePalette> ThemePalette::from_json_string(const std::string& json_str) {
    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(QByteArray::fromStdString(json_str), &err);
    if (doc.isNull() || !doc.isObject()) return std::nullopt;

    QJsonObject root = doc.object();
    ThemePalette p = mocha(); // start from baseline defaults

    if (root.contains("id") && root["id"].isString())
        p.id = root["id"].toString().toStdString();
    if (root.contains("name") && root["name"].isString())
        p.name = root["name"].toString().toStdString();
    if (root.contains("isDark") && root["isDark"].isBool())
        p.isDark = root["isDark"].toBool();

    p.accent = parse_color_prop(root, "accent", p.accent);
    p.accent2 = parse_color_prop(root, "accent2", p.accent2);

    if (root.contains("palette") && root["palette"].isObject()) {
        QJsonObject pal = root["palette"].toObject();
        p.crust    = parse_color_prop(pal, "crust", p.crust);
        p.mantle   = parse_color_prop(pal, "mantle", p.mantle);
        p.base     = parse_color_prop(pal, "base", p.base);
        p.surface0 = parse_color_prop(pal, "surface0", p.surface0);
        p.surface1 = parse_color_prop(pal, "surface1", p.surface1);
        p.surface2 = parse_color_prop(pal, "surface2", p.surface2);
        p.surface3 = parse_color_prop(pal, "surface3", p.surface3);
        p.textHigh = parse_color_prop(pal, "textHigh", p.textHigh);
        p.textMid  = parse_color_prop(pal, "textMid", p.textMid);
        p.textLow  = parse_color_prop(pal, "textLow", p.textLow);
        p.teal     = parse_color_prop(pal, "teal", p.teal);
        p.mauve    = parse_color_prop(pal, "mauve", p.mauve);
        p.peach    = parse_color_prop(pal, "peach", p.peach);
        p.pink     = parse_color_prop(pal, "pink", p.pink);
    }

    p.compute_oklab_anchors();
    return p;
}

std::optional<ThemePalette> ThemePalette::from_json_file(const std::string& filepath) {
    QFile file(QString::fromStdString(filepath));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return std::nullopt;
    }
    QByteArray data = file.readAll();
    return from_json_string(data.toStdString());
}

ThemePalette ThemePalette::active_system_theme() {
    // 1. Try ~/.config/archtitan/theme.json
    const char* home = std::getenv("HOME");
    if (home) {
        std::string user_theme = std::string(home) + "/.config/archtitan/theme.json";
        auto opt = from_json_file(user_theme);
        if (opt.has_value()) return *opt;
    }

    // 2. Try default system themes in /usr/share/archtitan/themes/
    auto opt2 = from_json_file("/usr/share/archtitan/themes/archtitan.json");
    if (opt2.has_value()) return *opt2;

    // 3. Fallback to Mocha preset
    return mocha();
}

} // namespace taw

