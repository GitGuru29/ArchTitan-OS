#pragma once

#include <QObject>
#include <QTimer>
#include <QVariantList>
#include <QVariantMap>

class NetworkController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool wifiEnabled READ wifiEnabled NOTIFY wifiEnabledChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)
    Q_PROPERTY(QString ssid READ ssid NOTIFY ssidChanged)
    Q_PROPERTY(QVariantList wifiList READ wifiList NOTIFY wifiListChanged)
    Q_PROPERTY(bool isScanning READ isScanning NOTIFY isScanningChanged)
    Q_PROPERTY(QString statusMessage READ statusMessage NOTIFY statusMessageChanged)
    Q_PROPERTY(bool isConnecting READ isConnecting NOTIFY isConnectingChanged)

public:
    explicit NetworkController(QObject *parent = nullptr);

    bool wifiEnabled() const { return m_wifiEnabled; }
    bool connected() const { return m_connected; }
    QString ssid() const { return m_ssid; }
    QVariantList wifiList() const { return m_wifiList; }
    bool isScanning() const { return m_isScanning; }
    QString statusMessage() const { return m_statusMessage; }
    bool isConnecting() const { return m_isConnecting; }

public slots:
    void toggleWifi();
    void refresh();
    void scanNetworks();
    void connectToNetwork(const QString &ssid, const QString &password = QString());
    void disconnectNetwork();

signals:
    void wifiEnabledChanged();
    void connectedChanged();
    void ssidChanged();
    void wifiListChanged();
    void isScanningChanged();
    void statusMessageChanged();
    void isConnectingChanged();
    void connectionResult(bool success, const QString &message);

private:
    void queryStatus();
    void parseWifiList(const QString &output);

    bool m_wifiEnabled{true};
    bool m_connected{false};
    QString m_ssid{"Not connected"};
    QVariantList m_wifiList;
    bool m_isScanning{false};
    bool m_isConnecting{false};
    QString m_statusMessage;

    QTimer *m_timer;
};
