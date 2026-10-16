// titan-zone-osd — QML-facing state for the hot-zone OSD
#pragma once

#include <QByteArray>
#include <QObject>
#include <QString>

class OsdController : public QObject {
  Q_OBJECT
  Q_PROPERTY(bool active READ active NOTIFY changed)
  Q_PROPERTY(QString kind READ kind NOTIFY changed)
  Q_PROPERTY(QString zone READ zone NOTIFY changed)
  Q_PROPERTY(QString label READ label NOTIFY changed)
  Q_PROPERTY(QString subtitle READ subtitle NOTIFY changed)
  Q_PROPERTY(QString icon READ icon NOTIFY changed)
  Q_PROPERTY(double progress READ progress NOTIFY changed)
  Q_PROPERTY(bool frame READ frame NOTIFY changed)

public:
  explicit OsdController(QObject *parent = nullptr) : QObject(parent) {}

  bool active() const { return active_; }
  QString kind() const { return kind_; }
  QString zone() const { return zone_; }
  QString label() const { return label_; }
  QString subtitle() const { return subtitle_; }
  QString icon() const { return icon_; }
  double progress() const { return progress_; }
  bool frame() const { return frame_; }

  // Screen name the active zone belongs to, so the surface can be moved to the
  // correct monitor. Not exposed to QML; read directly by the layer config.
  QString screen() const { return screen_; }

  // Consume one newline-delimited JSON message from titan-hotzones.
  void apply(const QByteArray &line);

signals:
  void changed();

private:
  bool active_ = false;
  bool frame_ = false;
  QString kind_ = QStringLiteral("zone");
  QString zone_;
  QString label_;
  QString subtitle_;
  QString icon_;
  QString screen_;
  double progress_ = 0.0;
};
