// titan-hotzones — Hyprland event-socket watcher
//
// Hyprland pushes state changes over a second UNIX socket (`.socket2.sock`) as
// newline-delimited `EVENT>>DATA` messages. We watch it so the OSD can show a
// brief workspace / scratchpad toast when one changes — the native gesture
// engine offers no per-gesture progress IPC, so the resulting change is the
// signal we get.
#pragma once

#include <QLocalSocket>
#include <QObject>
#include <QTimer>

namespace titan {

class HyprEventWatcher : public QObject {
  Q_OBJECT
public:
  explicit HyprEventWatcher(QObject *parent = nullptr);

  void start();

signals:
  void workspaceChanged(const QString &name);
  void specialChanged(const QString &name);
  void focusChanged();

private:
  void connectToSocket();
  void onReadyRead();

  QLocalSocket socket_;
  QTimer retry_;
  QByteArray buffer_;
};

} // namespace titan
