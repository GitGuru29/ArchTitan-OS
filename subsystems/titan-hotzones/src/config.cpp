// titan-hotzones — configuration model and TOML loader
#include "config.hpp"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QStandardPaths>
#include <QTextStream>

namespace titan {

const char *zoneName(ZoneId id) {
  switch (id) {
  case ZoneId::TopLeft:
    return "top_left";
  case ZoneId::TopRight:
    return "top_right";
  case ZoneId::BottomLeft:
    return "bottom_left";
  case ZoneId::BottomRight:
    return "bottom_right";
  case ZoneId::LeftCenter:
    return "left_center";
  case ZoneId::RightCenter:
    return "right_center";
  case ZoneId::BottomCenter:
    return "bottom_center";
  case ZoneId::None:
  default:
    return "none";
  }
}

ZoneId zoneFromKey(const QString &key) {
  if (key == "top_left")
    return ZoneId::TopLeft;
  if (key == "top_right")
    return ZoneId::TopRight;
  if (key == "bottom_left")
    return ZoneId::BottomLeft;
  if (key == "bottom_right")
    return ZoneId::BottomRight;
  if (key == "left_center")
    return ZoneId::LeftCenter;
  if (key == "right_center")
    return ZoneId::RightCenter;
  if (key == "bottom_center")
    return ZoneId::BottomCenter;
  return ZoneId::None;
}

QString Config::actionFor(ZoneId id) const {
  if (id == ZoneId::None)
    return {};
  return actions[static_cast<int>(id)];
}

bool Config::zoneEnabled(ZoneId id) const {
  return id != ZoneId::None && !actionFor(id).isEmpty();
}

// ── Minimal TOML support ─────────────────────────────────────────────────────
// Mirrors the hand-rolled parser in sandbox/titan-sandboxd.cpp: enough of TOML
// for [sections], `key = "value"`, `key = true|false|int`, `key = [..]`.
// It is deliberately not a general TOML implementation.
namespace {

QString stripComment(const QString &line) {
  bool inString = false;
  for (int i = 0; i < line.size(); ++i) {
    const QChar c = line.at(i);
    if (c == '"')
      inString = !inString;
    else if (c == '#' && !inString)
      return line.left(i);
  }
  return line;
}

QString unquote(QString value) {
  value = value.trimmed();
  if (value.size() >= 2 && value.startsWith('"') && value.endsWith('"'))
    return value.mid(1, value.size() - 2);
  if (value.size() >= 2 && value.startsWith('\'') && value.endsWith('\''))
    return value.mid(1, value.size() - 2);
  return value;
}

QStringList parseArray(const QString &value) {
  QStringList out;
  const int open = value.indexOf('[');
  const int close = value.lastIndexOf(']');
  if (open < 0 || close < open)
    return out;
  const QString inner = value.mid(open + 1, close - open - 1);
  for (const QString &part : inner.split(',')) {
    const QString item = unquote(part);
    if (!item.isEmpty())
      out << item;
  }
  return out;
}

} // namespace

Config Config::fromFile(const QString &path) {
  Config cfg;
  QFile file(path);
  if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    return cfg;

  QTextStream stream(&file);
  QString section;
  while (!stream.atEnd()) {
    QString line = stripComment(stream.readLine());
    line = line.trimmed();
    if (line.isEmpty())
      continue;

    if (line.startsWith('[')) {
      section = line.mid(1, line.indexOf(']') - 1).trimmed();
      continue;
    }

    const int eq = line.indexOf('=');
    if (eq < 0)
      continue;
    const QString key = line.left(eq).trimmed();
    const QString val = line.mid(eq + 1).trimmed();

    if (section == "hotzones") {
      if (key == "enabled")
        cfg.enabled = (val == "true");
      else if (key == "corner_size")
        cfg.cornerSize = val.toInt();
      else if (key == "edge_length")
        cfg.edgeLength = val.toInt();
      else if (key == "edge_thickness")
        cfg.edgeThickness = val.toInt();
      else if (key == "dwell_ms")
        cfg.dwellMs = val.toInt();
      else if (key == "cooldown_ms")
        cfg.cooldownMs = val.toInt();
      else if (key == "exclusion_box")
        cfg.exclusionBox = val.toInt();
      else if (key == "exclude_fullscreen")
        cfg.excludeFullscreen = (val == "true");
      else if (key == "ignore_classes")
        cfg.ignoreClasses = parseArray(val);
      else if (key == "show_frame")
        cfg.showFrame = (val == "true");
    } else if (section == "hotzones.zones") {
      const ZoneId id = zoneFromKey(key);
      if (id != ZoneId::None)
        cfg.actions[static_cast<int>(id)] = unquote(val);
    }
  }

  // Guard against nonsensical values.
  cfg.cornerSize = qBound(1, cfg.cornerSize, 64);
  cfg.edgeThickness = qBound(1, cfg.edgeThickness, 64);
  cfg.edgeLength = qBound(1, cfg.edgeLength, 2000);
  cfg.dwellMs = qBound(0, cfg.dwellMs, 5000);
  cfg.cooldownMs = qBound(0, cfg.cooldownMs, 10000);
  cfg.exclusionBox = qBound(0, cfg.exclusionBox, 2000);
  return cfg;
}

Config Config::load() {
  QStringList candidates;
  const QByteArray override = qgetenv("TITAN_HOTZONES_CONFIG");
  if (!override.isEmpty())
    candidates << QString::fromLocal8Bit(override);
  candidates << QStringLiteral("/etc/archtitan/hotzones.toml");

  const QString configHome =
      QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation);
  if (!configHome.isEmpty())
    candidates << configHome + QStringLiteral("/archtitan/hotzones.toml");

  for (const QString &path : candidates) {
    if (QFileInfo::exists(path))
      return fromFile(path);
  }
  return Config{};
}

QString Config::describe() const {
  QString out;
  QTextStream s(&out);
  s << "enabled=" << (enabled ? "true" : "false") << " corner=" << cornerSize
    << " edge=" << edgeThickness << "x" << edgeLength << " dwell=" << dwellMs
    << "ms"
    << " cooldown=" << cooldownMs << "ms"
    << " exclusion=" << exclusionBox
    << " exclude_fullscreen=" << (excludeFullscreen ? "true" : "false")
    << " show_frame=" << (showFrame ? "true" : "false")
    << "\nignore_classes=" << ignoreClasses.join(',') << "\n";
  for (int i = 0; i < kZoneCount; ++i) {
    const ZoneId id = static_cast<ZoneId>(i);
    s << "  " << zoneName(id) << " = "
      << (actions[i].isEmpty() ? QStringLiteral("(disabled)") : actions[i])
      << "\n";
  }
  return out;
}

} // namespace titan
