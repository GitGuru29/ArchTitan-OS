// titan-zone-osd — QML-facing state for the hot-zone OSD
#include "osdcontroller.hpp"

#include <QJsonDocument>
#include <QJsonObject>
#include <QPair>

namespace {

QPair<QString, QString> zoneInfo(const QString &zone) {
  // label, icon
  if (zone == QLatin1String("top_left"))
    return {QStringLiteral("Launcher"), QStringLiteral("\u276F")};
  if (zone == QLatin1String("top_right"))
    return {QStringLiteral("Quick Settings"), QStringLiteral("\u2630")};
  if (zone == QLatin1String("bottom_left"))
    return {QStringLiteral("Scratchpad"), QStringLiteral("\u25A6")};
  if (zone == QLatin1String("bottom_right"))
    return {QStringLiteral("Notifications"), QStringLiteral("\u25C7")};
  if (zone == QLatin1String("left_center"))
    return {QStringLiteral("System Monitor"), QStringLiteral("\uf2db")};
  if (zone == QLatin1String("right_center"))
    return {QStringLiteral("Next Workspace"), QStringLiteral("\u25B6")};
  if (zone == QLatin1String("bottom_center"))
    return {QStringLiteral("Show Desktop"), QStringLiteral("\u25BC")};
  return {QString(), QString()};
}

} // namespace

void OsdController::apply(const QByteArray &line) {
  const QJsonDocument doc = QJsonDocument::fromJson(line);
  if (!doc.isObject())
    return;

  const QJsonObject obj = doc.object();
  const QString cmd = obj.value(QStringLiteral("cmd")).toString();

  if (cmd == QLatin1String("hide")) {
    if (!active_)
      return;
    active_ = false;
    emit changed();
    return;
  }

  if (cmd == QLatin1String("frame")) {
    const bool show = obj.value(QStringLiteral("show")).toBool();
    if (show == frame_)
      return;
    frame_ = show;
    emit changed();
    return;
  }

  if (cmd == QLatin1String("show")) {
    kind_ = obj.value(QStringLiteral("kind")).toString();
    if (kind_.isEmpty())
      kind_ = QStringLiteral("zone");
    screen_ = obj.value(QStringLiteral("screen")).toString();

    // Workspace / scratchpad toast: the daemon supplies the label and glyph
    // directly (they are dynamic), rendered as a centred pill.
    if (kind_ == QLatin1String("workspace")) {
      label_ = obj.value(QStringLiteral("label")).toString();
      icon_ = obj.value(QStringLiteral("icon")).toString();
      subtitle_ = obj.value(QStringLiteral("subtitle")).toString();
      zone_.clear();
      progress_ = 1.0;
      active_ = true;
      emit changed();
      return;
    }

    zone_ = obj.value(QStringLiteral("zone")).toString();
    if (zone_.isEmpty() || zone_ == QLatin1String("none"))
      return;
    progress_ = obj.value(QStringLiteral("progress")).toDouble();
    const auto info = zoneInfo(zone_);
    label_ = info.first;
    icon_ = info.second;
    subtitle_ = QStringLiteral("Keep holding to activate");
    active_ = true;
    emit changed();
  }
}
