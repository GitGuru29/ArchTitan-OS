// titan-hotzones — configuration model and TOML loader
#pragma once

#include <QString>
#include <QStringList>

namespace titan {

// The seven activatable zones. The top-centre zone is intentionally absent:
// Waybar occupies the top edge, so a top-centre hot zone can never be reached
// and is excluded by design.
enum class ZoneId {
  None = -1,
  TopLeft = 0,
  TopRight,
  BottomLeft,
  BottomRight,
  LeftCenter,
  RightCenter,
  BottomCenter,
};

constexpr int kZoneCount = 7;

const char *zoneName(ZoneId id);
ZoneId zoneFromKey(const QString &key);

struct Config {
  bool enabled = true;

  // Geometry (px). Corners are square; edge-midpoint zones are
  // `edgeThickness` x `edgeLength`, centred on the edge.
  int cornerSize = 4;
  int edgeLength = 140;
  int edgeThickness = 4;

  // Activation timing (ms).
  int dwellMs = 180;
  int cooldownMs = 500;

  // The pointer must leave this inner box before a zone re-arms.
  int exclusionBox = 64;

  // Inhibition.
  bool excludeFullscreen = true;
  QStringList ignoreClasses;

  // Steady workspace boundary frame.
  bool showFrame = true;

  // Per-zone shell command, empty when unset/disabled.
  QString actions[kZoneCount];

  QString actionFor(ZoneId id) const;
  bool zoneEnabled(ZoneId id) const;

  // Load the first existing config from the search path. Missing or partial
  // files fall back to the compiled-in defaults above.
  static Config load();
  static Config fromFile(const QString &path);

  // Human-readable summary, used by --check.
  QString describe() const;
};

} // namespace titan
