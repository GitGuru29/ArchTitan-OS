// titan-hotzones — Hyprland event-socket watcher
#include "events.hpp"

#include <QFileInfo>
#include <unistd.h>

namespace titan {
namespace {

QString hyprEventSocketPath() {
  const QByteArray sig = qgetenv("HYPRLAND_INSTANCE_SIGNATURE");
  if (sig.isEmpty())
    return {};
  QByteArray runtime = qgetenv("XDG_RUNTIME_DIR");
  if (runtime.isEmpty())
    runtime = QByteArray("/run/user/") + QByteArray::number(getuid());
  return QString::fromLocal8Bit(runtime) + "/hypr/" +
         QString::fromLocal8Bit(sig) + "/.socket2.sock";
}

} // namespace

HyprEventWatcher::HyprEventWatcher(QObject *parent) : QObject(parent) {
  retry_.setInterval(2000);
  connect(&retry_, &QTimer::timeout, this, &HyprEventWatcher::connectToSocket);
  connect(&socket_, &QLocalSocket::readyRead, this,
          &HyprEventWatcher::onReadyRead);
  connect(&socket_, &QLocalSocket::disconnected, this, [this] {
    if (!retry_.isActive())
      retry_.start();
  });
}

void HyprEventWatcher::start() { connectToSocket(); }

void HyprEventWatcher::connectToSocket() {
  if (socket_.state() == QLocalSocket::ConnectedState)
    return;
  const QString path = hyprEventSocketPath();
  if (path.isEmpty() || !QFileInfo::exists(path)) {
    if (!retry_.isActive())
      retry_.start();
    return;
  }
  socket_.abort();
  buffer_.clear();
  socket_.connectToServer(path);
  if (socket_.waitForConnected(500))
    retry_.stop();
  else if (!retry_.isActive())
    retry_.start();
}

void HyprEventWatcher::onReadyRead() {
  buffer_ += socket_.readAll();

  int newline;
  while ((newline = buffer_.indexOf('\n')) >= 0) {
    const QByteArray line = buffer_.left(newline);
    buffer_.remove(0, newline + 1);

    const int sep = line.indexOf(">>");
    if (sep < 0)
      continue;
    const QString event = QString::fromUtf8(line.left(sep));
    const QString data = QString::fromUtf8(line.mid(sep + 2));

    if (event == QLatin1String("workspace")) {
      if (!data.isEmpty())
        emit workspaceChanged(data);
    } else if (event == QLatin1String("workspacev2")) {
      const QStringList parts = data.split(',');
      if (parts.size() == 2 && !parts.at(1).isEmpty())
        emit workspaceChanged(parts.at(1));
      emit focusChanged();
    } else if (event == QLatin1String("activespecial")) {
      const QString name = data.section(',', 0, 0);
      emit specialChanged(name);
      emit focusChanged();
    } else if (event == QLatin1String("fullscreen") ||
               event == QLatin1String("activewindowv2") ||
               event == QLatin1String("openwindow") ||
               event == QLatin1String("closewindow") ||
               event == QLatin1String("movewindowv2") ||
               event == QLatin1String("focusedmon")) {
      emit focusChanged();
    }
  }
}

} // namespace titan
