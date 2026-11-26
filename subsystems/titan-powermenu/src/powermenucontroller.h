#pragma once

#include <QObject>
#include <QString>

class PowerMenuController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString userName READ userName NOTIFY statsChanged)
    Q_PROPERTY(QString hostName READ hostName NOTIFY statsChanged)
    Q_PROPERTY(QString uptimeString READ uptimeString NOTIFY statsChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY statsChanged)
    Q_PROPERTY(bool batteryCharging READ batteryCharging NOTIFY statsChanged)
    Q_PROPERTY(QString batteryStatus READ batteryStatus NOTIFY statsChanged)
    Q_PROPERTY(int selectedIndex READ selectedIndex WRITE setSelectedIndex NOTIFY selectedIndexChanged)

public:
    explicit PowerMenuController(QObject *parent = nullptr);

    QString userName() const { return m_userName; }
    QString hostName() const { return m_hostName; }
    QString uptimeString() const { return m_uptimeString; }
    int batteryPercent() const { return m_batteryPercent; }
    bool batteryCharging() const { return m_batteryCharging; }
    QString batteryStatus() const { return m_batteryStatus; }

    int selectedIndex() const { return m_selectedIndex; }
    void setSelectedIndex(int idx);

    Q_INVOKABLE void executeAction(const QString &action);
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void suspendSession();
    Q_INVOKABLE void logoutSession();
    Q_INVOKABLE void rebootSystem();
    Q_INVOKABLE void shutdownSystem();
    Q_INVOKABLE void cancel();
    Q_INVOKABLE void refreshStats();

signals:
    void closeRequested();
    void statsChanged();
    void selectedIndexChanged();

private:
    void updateUptime();
    void updateBattery();

    QString m_userName;
    QString m_hostName;
    QString m_uptimeString;
    int m_batteryPercent = -1;
    bool m_batteryCharging = false;
    QString m_batteryStatus;
    int m_selectedIndex = -1;
};
