#include "powermenucontroller.h"

#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QProcess>
#include <QHostInfo>
#include <QTimer>
#include <iostream>

PowerMenuController::PowerMenuController(QObject *parent)
    : QObject(parent)
{
    m_userName = qEnvironmentVariable("USER");
    if (m_userName.isEmpty()) {
        m_userName = QStringLiteral("archtitan");
    }

    m_hostName = QHostInfo::localHostName();
    if (m_hostName.isEmpty()) {
        QFile hf(QStringLiteral("/etc/hostname"));
        if (hf.open(QIODevice::ReadOnly | QIODevice::Text)) {
            m_hostName = QString::fromUtf8(hf.readLine()).trimmed();
        }
    }
    if (m_hostName.isEmpty()) {
        m_hostName = QStringLiteral("archtitan");
    }

    refreshStats();
}

void PowerMenuController::setSelectedIndex(int idx)
{
    if (m_selectedIndex != idx) {
        m_selectedIndex = idx;
        emit selectedIndexChanged();
    }
}

void PowerMenuController::refreshStats()
{
    updateUptime();
    updateBattery();
    emit statsChanged();
}

void PowerMenuController::updateUptime()
{
    QFile file(QStringLiteral("/proc/uptime"));
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray data = file.readAll();
        QList<QByteArray> parts = data.split(' ');
        if (!parts.isEmpty()) {
            double uptimeSec = parts.first().toDouble();
            int totalMins = static_cast<int>(uptimeSec) / 60;
            int hours = totalMins / 60;
            int mins = totalMins % 60;
            int days = hours / 24;
            hours = hours % 24;

            if (days > 0) {
                m_uptimeString = QStringLiteral("%1d %2h %3m").arg(days).arg(hours).arg(mins);
            } else if (hours > 0) {
                m_uptimeString = QStringLiteral("%1h %2m").arg(hours).arg(mins);
            } else {
                m_uptimeString = QStringLiteral("%1m").arg(mins);
            }
            return;
        }
    }
    m_uptimeString = QStringLiteral("Online");
}

void PowerMenuController::updateBattery()
{
    m_batteryPercent = -1;
    m_batteryCharging = false;
    m_batteryStatus.clear();

    const QStringList batDirs = {
        QStringLiteral("/sys/class/power_supply/BAT0"),
        QStringLiteral("/sys/class/power_supply/BAT1"),
        QStringLiteral("/sys/class/power_supply/battery")
    };

    for (const QString &dirPath : batDirs) {
        QDir dir(dirPath);
        if (dir.exists()) {
            QFile capFile(dirPath + QStringLiteral("/capacity"));
            if (capFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                m_batteryPercent = capFile.readLine().trimmed().toInt();
            }

            QFile statusFile(dirPath + QStringLiteral("/status"));
            if (statusFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QString status = QString::fromUtf8(statusFile.readLine()).trimmed();
                m_batteryStatus = status;
                m_batteryCharging = (status.compare(QStringLiteral("Charging"), Qt::CaseInsensitive) == 0);
            }
            break;
        }
    }
}

void PowerMenuController::cancel()
{
    emit closeRequested();
}

void PowerMenuController::executeAction(const QString &action)
{
    QString act = action.toLower().trimmed();
    if (act == QStringLiteral("lock")) {
        lockSession();
    } else if (act == QStringLiteral("suspend") || act == QStringLiteral("sleep")) {
        suspendSession();
    } else if (act == QStringLiteral("logout") || act == QStringLiteral("exit")) {
        logoutSession();
    } else if (act == QStringLiteral("reboot") || act == QStringLiteral("restart")) {
        rebootSystem();
    } else if (act == QStringLiteral("shutdown") || act == QStringLiteral("poweroff")) {
        shutdownSystem();
    }
}

void PowerMenuController::lockSession()
{
    emit closeRequested();
    QTimer::singleShot(150, []() {
        QProcess::startDetached(QStringLiteral("sh"), {
            QStringLiteral("-c"),
            QStringLiteral("pidof hyprlock || hyprlock || swaylock -f -c 0b0e14 || loginctl lock-session")
        });
    });
}

void PowerMenuController::suspendSession()
{
    emit closeRequested();
    QTimer::singleShot(200, []() {
        QProcess::startDetached(QStringLiteral("sh"), {
            QStringLiteral("-c"),
            QStringLiteral("systemctl suspend -i || loginctl suspend || sudo systemctl suspend -i")
        });
    });
}

void PowerMenuController::logoutSession()
{
    emit closeRequested();
    QTimer::singleShot(150, []() {
        QProcess::startDetached(QStringLiteral("sh"), {
            QStringLiteral("-c"),
            QStringLiteral("hyprctl dispatch exit || pkill -u \"$USER\" -x Hyprland || loginctl terminate-session \"${XDG_SESSION_ID}\" || loginctl terminate-user \"$USER\"")
        });
    });
}

void PowerMenuController::rebootSystem()
{
    emit closeRequested();
    QTimer::singleShot(150, []() {
        QProcess::startDetached(QStringLiteral("sh"), {
            QStringLiteral("-c"),
            QStringLiteral("systemctl reboot -i || loginctl reboot || sudo reboot || reboot")
        });
    });
}

void PowerMenuController::shutdownSystem()
{
    emit closeRequested();
    QTimer::singleShot(150, []() {
        QProcess::startDetached(QStringLiteral("sh"), {
            QStringLiteral("-c"),
            QStringLiteral("systemctl poweroff -i || loginctl poweroff || sudo poweroff || poweroff")
        });
    });
}
