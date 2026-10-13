#pragma once

#include <QDateTime>
#include <QObject>
#include <QTimer>

class SystemController : public QObject {
  Q_OBJECT
  Q_PROPERTY(QString uptime READ uptime NOTIFY uptimeChanged)
  Q_PROPERTY(QString currentDateString READ currentDateString NOTIFY
                 currentDateStringChanged)
  Q_PROPERTY(QString userName READ userName CONSTANT)
  Q_PROPERTY(bool caffeineActive READ caffeineActive WRITE setCaffeineActive
                 NOTIFY caffeineActiveChanged)
  Q_PROPERTY(
      bool themeDark READ themeDark WRITE setThemeDark NOTIFY themeDarkChanged)
  Q_PROPERTY(bool visualizerActive READ visualizerActive WRITE
                 setVisualizerActive NOTIFY visualizerActiveChanged)
  Q_PROPERTY(bool gameModeActive READ gameModeActive WRITE setGameModeActive
                 NOTIFY gameModeActiveChanged)
  Q_PROPERTY(
      bool vpnActive READ vpnActive WRITE setVpnActive NOTIFY vpnActiveChanged)
  Q_PROPERTY(bool screenRecordingActive READ screenRecordingActive NOTIFY
                 screenRecordingActiveChanged)
  Q_PROPERTY(bool airplaneMode READ airplaneMode WRITE setAirplaneMode NOTIFY
                 airplaneModeChanged)
  Q_PROPERTY(int brightness READ brightness NOTIFY brightnessChanged)
  Q_PROPERTY(int tileVisibilityRevision READ tileVisibilityRevision NOTIFY tileVisibilityChanged)

public:
  explicit SystemController(QObject *parent = nullptr);

  QString uptime() const { return m_uptime; }
  QString currentDateString() const { return m_currentDateString; }
  QString userName() const;
  bool caffeineActive() const { return m_caffeineActive; }
  bool themeDark() const { return m_themeDark; }
  bool visualizerActive() const { return m_visualizerActive; }
  bool gameModeActive() const { return m_gameModeActive; }
  bool vpnActive() const { return m_vpnActive; }
  bool screenRecordingActive() const { return m_screenRecordingActive; }
  bool airplaneMode() const { return m_airplaneMode; }
  int brightness() const { return m_brightness; }
  int tileVisibilityRevision() const { return m_tileVisibilityRevision; }

  void setCaffeineActive(bool active);
  void setThemeDark(bool dark);
  void setVisualizerActive(bool active);
  void setGameModeActive(bool active);
  void setVpnActive(bool active);
  void setAirplaneMode(bool active);

  Q_INVOKABLE bool getTileVisible(const QString &tileKey, bool defaultVal = true) const;
  Q_INVOKABLE void setTileVisible(const QString &tileKey, bool visible);
  Q_INVOKABLE void resetTileVisibility();

public slots:
  void refresh();
  void openSettings();
  void openPowerMenu();
  void takeScreenshot();
  void pickColor();
  void toggleVirtualKeyboard();
  void openMediaWidget();
  void setBrightness(int value);
  void toggleScreenRecording();
  void toggleAirplaneMode();
  void openClipboard();

signals:
  void uptimeChanged();
  void currentDateStringChanged();
  void caffeineActiveChanged();
  void themeDarkChanged();
  void visualizerActiveChanged();
  void gameModeActiveChanged();
  void vpnActiveChanged();
  void screenRecordingActiveChanged();
  void airplaneModeChanged();
  void brightnessChanged();
  void tileVisibilityChanged();

private:
  void updateUptime();
  void updateDate();
  void updateBrightness();
  void updateTheme();
  void updateScreenRecording();
  void updateAirplaneMode();

  QString m_uptime{"Up 0m"};
  QString m_currentDateString;
  bool m_caffeineActive{false};
  bool m_themeDark{true};
  bool m_visualizerActive{true};
  bool m_gameModeActive{false};
  bool m_vpnActive{false};
  bool m_screenRecordingActive{false};
  bool m_airplaneMode{false};
  int m_brightness{80};
  int m_tileVisibilityRevision{0};

  QTimer *m_timer;
};
