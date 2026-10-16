// titan-hotzones — pointer hot-zone daemon for ArchTitan OS
//
// Watches the Hyprland cursor and fires a configured command when the pointer
// dwells in any of seven screen zones (four corners + three edge midpoints;
// the top-centre zone is excluded because Waybar occupies the top edge).
//
// See the subsystem README and the interaction plan for the design rationale.
#include <QCommandLineParser>
#include <QCoreApplication>
#include <QDateTime>
#include <QProcess>
#include <QTextStream>
#include <QTimer>

#include <climits>
#include <fnmatch.h>
#include <unistd.h>

#include "config.hpp"
#include "events.hpp"
#include "hyprland.hpp"
#include "osdserver.hpp"
#include "zones.hpp"

using namespace titan;

namespace {

QTextStream &err() {
  static QTextStream s(stderr);
  return s;
}

bool g_verbose = false;

void log(const QString &msg) {
  if (!g_verbose)
    return;
  err() << "titan-hotzones: " << msg << Qt::endl;
}

// Adaptive poll cadence: burst while the pointer is near a zone or dwelling,
// back off elsewhere so the daemon is effectively free at rest.
constexpr int kFastIntervalMs = 33;  // ~30 Hz
constexpr int kSlowIntervalMs = 200; // ~5 Hz
constexpr int kNearThresholdPx = 24;

constexpr qint64 kMonitorRefreshMs = 2000;
constexpr int kToastMs = 1200; // workspace/scratchpad notice hold time
constexpr int kFrameDebounceMs = 60; // coalesce bursts of focus events

// Hyprland fullscreen mode bits: 1 = maximized (keeps gaps), 2 = fullscreen.
constexpr int kFullscreenBit = 2;

bool classIgnored(const QString &windowClass, const QStringList &patterns) {
  if (windowClass.isEmpty())
    return false;
  for (const QString &pattern : patterns) {
    if (fnmatch(pattern.toUtf8().constData(), windowClass.toUtf8().constData(),
                0) == 0)
      return true;
  }
  return false;
}

bool inhibited(const Config &cfg, const ActiveWindow &aw) {
  if (cfg.excludeFullscreen && aw.valid && aw.fullscreen != 0)
    return true;
  if (aw.valid && classIgnored(aw.windowClass, cfg.ignoreClasses))
    return true;
  return false;
}

void fire(const QString &action) {
  if (action.isEmpty())
    return;
  log(QStringLiteral("firing: %1").arg(action));
  QProcess::startDetached(QStringLiteral("/bin/sh"),
                          {QStringLiteral("-c"), action});
}

// ── CLI probes ───────────────────────────────────────────────────────────────

int runCheck(const Config &cfg) {
  QTextStream out(stdout);
  out << cfg.describe();
  out.flush();
  return 0;
}

int runZones(const Config &cfg, const QString &probe) {
  QTextStream out(stdout);
  ZoneGeometry geo;
  geo.setGeometry(cfg.cornerSize, cfg.edgeLength, cfg.edgeThickness,
                  cfg.exclusionBox);
  const std::vector<Monitor> monitors = hyprMonitors();
  if (monitors.empty()) {
    out << "no monitors reported (is Hyprland running?)\n";
    return 1;
  }
  geo.setMonitors(monitors);
  for (const Monitor &m : monitors)
    out << m.name << " " << m.w << "x" << m.h << "+" << m.x << "+" << m.y
        << "\n";
  QPoint pos = hyprCursorPos();
  if (!probe.isEmpty()) {
    const QStringList parts = probe.split(',');
    if (parts.size() == 2) {
      bool okX = false, okY = false;
      const int px = parts.at(0).trimmed().toInt(&okX);
      const int py = parts.at(1).trimmed().toInt(&okY);
      if (okX && okY)
        pos = QPoint(px, py);
    }
  }
  out << "cursor: " << pos.x() << ", " << pos.y() << "\n";
  const ZoneHit hit = geo.hitTest(pos);
  out << "hit: " << zoneName(hit.id) << " (monitor " << hit.monitorIndex << ")"
      << " proximity=" << geo.proximity(pos)
      << " inner=" << (geo.inInnerRegion(pos) ? "yes" : "no") << "\n";
  out.flush();
  return 0;
}

// ── Daemon ───────────────────────────────────────────────────────────────────

class Daemon {
public:
  explicit Daemon(Config cfg) : cfg_(std::move(cfg)), enabled_(cfg_.enabled) {
    geo_.setGeometry(cfg_.cornerSize, cfg_.edgeLength, cfg_.edgeThickness,
                     cfg_.exclusionBox);
    sm_.configure(cfg_.dwellMs, cfg_.cooldownMs);
    tick_.setTimerType(Qt::PreciseTimer);
    QObject::connect(&tick_, &QTimer::timeout, [this] { onTick(); });

    toastHide_.setSingleShot(true);
    QObject::connect(&toastHide_, &QTimer::timeout, [this] { hideToast(); });
    QObject::connect(&events_, &HyprEventWatcher::workspaceChanged,
                     [this](const QString &name) {
                       showToast(QStringLiteral("Workspace %1").arg(name),
                                 name);
                     });
    QObject::connect(&events_, &HyprEventWatcher::specialChanged,
                     [this](const QString &name) { onSpecial(name); });
    QObject::connect(&osd_, &OsdServer::enableRequested,
                     [this] { setEnabled(true); });
    QObject::connect(&osd_, &OsdServer::disableRequested,
                     [this] { setEnabled(false); });
    QObject::connect(&osd_, &OsdServer::toggleRequested,
                     [this] { setEnabled(!enabled_); });

    // Workspace frame: re-evaluated only when Hyprland reports a focus /
    // fullscreen / window change (debounced), never per poll tick.
    frameDebounce_.setSingleShot(true);
    frameDebounce_.setInterval(kFrameDebounceMs);
    QObject::connect(&frameDebounce_, &QTimer::timeout,
                     [this] { updateFrame(false); });
    QObject::connect(&events_, &HyprEventWatcher::focusChanged,
                     [this] { frameDebounce_.start(); });
    // When an OSD client connects, send the current frame state immediately.
    QObject::connect(&osd_, &OsdServer::clientConnected,
                     [this] { updateFrame(true); });
  }

  void start() {
    if (!osd_.start())
      log(QStringLiteral("warning: could not host OSD socket"));
    events_.start();
    refreshMonitors(true);
    updateFrame(true);
    tick_.start(kSlowIntervalMs);
  }

private:
  void refreshMonitors(bool force) {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    if (!force && now - lastMonitorRefresh_ < kMonitorRefreshMs)
      return;
    std::vector<Monitor> monitors = hyprMonitors();
    if (!monitors.empty()) {
      geo_.setMonitors(std::move(monitors));
      lastMonitorRefresh_ = now;
    }
  }

  void onTick() {
    refreshMonitors(false);

    const QPoint pos = hyprCursorPos();
    if (pos.x() == INT_MIN)
      return; // compositor unavailable this tick

    const ZoneHit hit = geo_.hitTest(pos);
    const bool inner = geo_.inInnerRegion(pos);
    const qint64 now = QDateTime::currentMSecsSinceEpoch();

    bool fired = false;
    if (enabled_) {
      fired = sm_.update(hit, inner, now);
      if (fired) {
        const QString action = cfg_.actionFor(hit.id);
        if (action.isEmpty()) {
          log(QStringLiteral("zone %1 has no action").arg(zoneName(hit.id)));
        } else if (!inhibited(cfg_, hyprActiveWindow())) {
          fire(action);
        } else {
          log(QStringLiteral("zone %1 suppressed (fullscreen/ignored)")
                  .arg(zoneName(hit.id)));
        }
      }
    } else {
      sm_.update(hit, inner, now);
    }

    publishOsd(hit, fired, now);

    const int prox = geo_.proximity(pos);
    const bool burst =
        (sm_.state() == ZoneState::Armed) || prox <= kNearThresholdPx;
    const int wanted = burst ? kFastIntervalMs : kSlowIntervalMs;
    if (tick_.interval() != wanted)
      tick_.setInterval(wanted);
  }

  // Mirror the activation state to any connected OSD. The OSD shows the
  // dwell ring while armed, holds the full ring briefly after firing, and
  // fades out once the machine returns to Idle.
  void publishOsd(const ZoneHit &hit, bool fired, qint64 now) {
    QString zone;
    double progress = 0.0;
    bool show = false;

    switch (sm_.state()) {
    case ZoneState::Armed:
      show = true;
      zone = zoneName(hit.id);
      progress = sm_.dwellProgress(now);
      lastZone_ = hit.id;
      lastMonitor_ = hit.monitorIndex;
      break;
    case ZoneState::Locked:
      if (fired) {
        show = true;
        zone = zoneName(hit.id);
        progress = 1.0;
        lastZone_ = hit.id;
        lastMonitor_ = hit.monitorIndex;
      } else if (osdVisible_) {
        // Keep the completed ring on screen until the pointer leaves.
        show = true;
        zone = zoneName(lastZone_);
        progress = 1.0;
      }
      break;
    case ZoneState::Idle:
    default:
      break;
    }

    if (show) {
      // Suppress redundant frames: only re-send when the zone changes or
      // the ring advances a visible amount, so parking in a zone does not
      // flood the socket at the fast-tick rate.
      const bool newZone = (zone != sentZone_);
      const bool advanced = !newZone && progress - sentProgress_ >= 0.02;
      const bool appeared = !osdVisible_;
      if (!appeared && !newZone && !advanced)
        return;

      QString screen;
      const int index = lastMonitor_;
      if (index >= 0 && index < static_cast<int>(geo_.monitors().size()))
        screen = geo_.monitors()[index].name;
      osd_.broadcast(QJsonObject{
          {QStringLiteral("cmd"), QStringLiteral("show")},
          {QStringLiteral("zone"), zone},
          {QStringLiteral("progress"), progress},
          {QStringLiteral("screen"), screen},
      });
      osdVisible_ = true;
      sentZone_ = zone;
      sentProgress_ = progress;
    } else if (osdVisible_) {
      osd_.broadcast(QJsonObject{
          {QStringLiteral("cmd"), QStringLiteral("hide")},
      });
      osdVisible_ = false;
      sentZone_.clear();
      sentProgress_ = -1.0;
    }
  }

  // Brief notice shown when a workspace or scratchpad changes. Hyprland's
  // native gesture engine reports no per-gesture progress, so the resulting
  // change (delivered over the event socket) is what drives gesture feedback.
  void showToast(const QString &label, const QString &icon) {
    if (toastActive_ && toastLabel_ == label) {
      toastHide_.start(kToastMs); // refresh, don't re-send
      return;
    }
    osd_.broadcast(QJsonObject{
        {QStringLiteral("cmd"), QStringLiteral("show")},
        {QStringLiteral("kind"), QStringLiteral("workspace")},
        {QStringLiteral("label"), label},
        {QStringLiteral("icon"), icon},
        {QStringLiteral("screen"), QString()},
    });
    toastActive_ = true;
    toastLabel_ = label;
    toastHide_.start(kToastMs);
  }

  void onSpecial(const QString &name) {
    if (name.isEmpty()) {
      hideToast();
      return;
    }
    QString key = name;
    if (key.startsWith(QLatin1String("special:")))
      key = key.mid(8);
    QString label = key;
    if (key == QLatin1String("magic"))
      label = QStringLiteral("Scratchpad");
    else if (key == QLatin1String("showdesktop"))
      label = QStringLiteral("Desktop");
    else if (!key.isEmpty())
      label[0] = label.at(0).toUpper();
    showToast(label, QStringLiteral("\u25A6"));
  }

  void hideToast() {
    toastHide_.stop();
    if (!toastActive_)
      return;
    toastActive_ = false;
    // Don't clobber a zone OSD that may have taken over the overlay.
    if (sm_.state() == ZoneState::Idle && !osdVisible_)
      osd_.broadcast(QJsonObject{
          {QStringLiteral("cmd"), QStringLiteral("hide")},
      });
  }

  void hideOsd() {
    osd_.broadcast(
        QJsonObject{{QStringLiteral("cmd"), QStringLiteral("hide")}});
    osdVisible_ = false;
    sentZone_.clear();
    sentProgress_ = -1.0;
  }

  void setEnabled(bool on) {
    enabled_ = on;
    if (!enabled_)
      hideOsd();
    updateFrame(false);
  }

  // Steady border around the workspace marking the hot-zone boundary.
  // Shown when enabled; hidden automatically if the focused window is true fullscreen.
  void updateFrame(bool force) {
    bool want = enabled_ && cfg_.showFrame;
    if (want) {
      const ActiveWindow aw = hyprActiveWindow();
      if (aw.valid && (aw.fullscreen & kFullscreenBit))
        want = false;
    }
    if (!force && want == frameShown_)
      return;
    frameShown_ = want;
    osd_.broadcast(QJsonObject{
        {QStringLiteral("cmd"), QStringLiteral("frame")},
        {QStringLiteral("show"), want},
    });
  }

  Config cfg_;
  ZoneGeometry geo_;
  ZoneStateMachine sm_;
  QTimer tick_;
  OsdServer osd_;
  HyprEventWatcher events_;
  QTimer toastHide_;
  QTimer frameDebounce_;
  bool enabled_ = true;
  bool osdVisible_ = false;
  bool frameShown_ = false;
  bool toastActive_ = false;
  QString toastLabel_;
  QString sentZone_;
  double sentProgress_ = -1.0;
  ZoneId lastZone_ = ZoneId::None;
  int lastMonitor_ = -1;
  qint64 lastMonitorRefresh_ = 0;
};

} // namespace

int main(int argc, char **argv) {
  QCoreApplication app(argc, argv);
  QCoreApplication::setApplicationName(QStringLiteral("titan-hotzones"));
  QCoreApplication::setApplicationVersion(QStringLiteral("1.0.0"));

  QCommandLineParser parser;
  parser.setApplicationDescription(
      QStringLiteral("ArchTitan pointer hot-zone daemon"));
  parser.addHelpOption();
  parser.addVersionOption();
  // Long-only: QCommandLineParser::addVersionOption() already owns -v.
  const QCommandLineOption verboseOpt(
      QStringLiteral("verbose"),
      QStringLiteral("Log activation decisions to stderr."));
  const QCommandLineOption checkOpt(
      QStringLiteral("check"),
      QStringLiteral("Print the effective configuration and exit."));
  const QCommandLineOption zonesOpt(
      QStringLiteral("zones"),
      QStringLiteral(
          "Probe monitors/cursor and report the current hit, then exit."));
  const QCommandLineOption atOpt(
      QStringLiteral("at"),
      QStringLiteral("With --zones, test an arbitrary point as x,y."),
      QStringLiteral("x,y"));
  parser.addOption(verboseOpt);
  parser.addOption(checkOpt);
  parser.addOption(zonesOpt);
  parser.addOption(atOpt);
  parser.process(app);

  g_verbose =
      parser.isSet(verboseOpt) || !qgetenv("TITAN_HOTZONES_DEBUG").isEmpty();

  const Config cfg = Config::load();

  if (parser.isSet(checkOpt))
    return runCheck(cfg);
  if (parser.isSet(zonesOpt))
    return runZones(cfg, parser.value(atOpt));

  if (!cfg.enabled) {
    log(QStringLiteral("disabled by configuration; exiting"));
    return 0;
  }

  log(QStringLiteral("starting"));
  Daemon daemon(cfg);
  daemon.start();
  return app.exec();
}
