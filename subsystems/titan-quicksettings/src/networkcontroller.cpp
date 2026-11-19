#include "networkcontroller.h"
#include <QProcess>
#include <QDebug>
#include <QPointer>
#include <algorithm>

NetworkController::NetworkController(QObject *parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
{
    queryStatus();
    connect(m_timer, &QTimer::timeout, this, &NetworkController::queryStatus);
    m_timer->start(5000);
}

void NetworkController::queryStatus()
{
    // Check radio wifi state
    QProcess radioProc;
    radioProc.start("nmcli", {"radio", "wifi"});
    if (radioProc.waitForFinished(1000)) {
        QString out = radioProc.readAllStandardOutput().trimmed();
        bool enabled = (out.compare("enabled", Qt::CaseInsensitive) == 0);
        if (enabled != m_wifiEnabled) {
            m_wifiEnabled = enabled;
            emit wifiEnabledChanged();
        }
    }

    if (!m_wifiEnabled) {
        if (m_connected) {
            m_connected = false;
            emit connectedChanged();
        }
        if (m_ssid != "Disabled") {
            m_ssid = "Disabled";
            emit ssidChanged();
        }
        return;
    }

    // Check active wifi connection SSID using nmcli device status
    QProcess devProc;
    devProc.start("nmcli", {"-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "dev"});
    if (devProc.waitForFinished(1000)) {
        QString out = QString::fromUtf8(devProc.readAllStandardOutput());
        const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList parts = line.split(':');
            if (parts.size() >= 4 && parts[1].compare("wifi", Qt::CaseInsensitive) == 0) {
                if (parts[2].compare("connected", Qt::CaseInsensitive) == 0) {
                    QString activeCon = parts[3].trimmed();
                    if (!activeCon.isEmpty()) {
                        if (!m_connected) {
                            m_connected = true;
                            emit connectedChanged();
                        }
                        if (m_ssid != activeCon) {
                            m_ssid = activeCon;
                            emit ssidChanged();
                        }
                        return;
                    }
                }
            }
        }
    }

    // Secondary fallback: active connection name
    QProcess conProc;
    conProc.start("nmcli", {"-t", "-f", "NAME,TYPE", "con", "show", "--active"});
    if (conProc.waitForFinished(1000)) {
        QString out = QString::fromUtf8(conProc.readAllStandardOutput());
        const QStringList lines = out.split('\n', Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList parts = line.split(':');
            if (parts.size() >= 2 && (parts[1].contains("wireless", Qt::CaseInsensitive) || parts[1].compare("wifi", Qt::CaseInsensitive) == 0)) {
                QString activeCon = parts[0].trimmed();
                if (!activeCon.isEmpty()) {
                    if (!m_connected) {
                        m_connected = true;
                        emit connectedChanged();
                    }
                    if (m_ssid != activeCon) {
                        m_ssid = activeCon;
                        emit ssidChanged();
                    }
                    return;
                }
            }
        }
    }

    // If no wifi connection active, mark as Not connected
    if (m_connected || m_ssid != "Not connected") {
        m_connected = false;
        m_ssid = "Not connected";
        emit connectedChanged();
        emit ssidChanged();
    }
}

void NetworkController::toggleWifi()
{
    m_wifiEnabled = !m_wifiEnabled;
    emit wifiEnabledChanged();
    QProcess::startDetached("nmcli", {"radio", "wifi", m_wifiEnabled ? "on" : "off"});
    QTimer::singleShot(800, this, &NetworkController::queryStatus);
}

void NetworkController::refresh()
{
    queryStatus();
    scanNetworks();
}

void NetworkController::scanNetworks()
{
    if (m_isScanning || !m_wifiEnabled)
        return;

    m_isScanning = true;
    emit isScanningChanged();

    auto *proc = new QProcess(this);
    proc->closeWriteChannel();

    QPointer<QProcess> safeProc(proc);
    QTimer::singleShot(12000, this, [this, safeProc]() {
        if (safeProc && safeProc->state() != QProcess::NotRunning) {
            safeProc->kill();
            m_isScanning = false;
            emit isScanningChanged();
        }
    });

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc](int exitCode, QProcess::ExitStatus) {
        if (exitCode == 0) {
            QString out = QString::fromUtf8(proc->readAllStandardOutput());
            parseWifiList(out);
        }
        m_isScanning = false;
        emit isScanningChanged();
        proc->deleteLater();
    });

    proc->start("nmcli", {"-t", "-f", "IN-USE,SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "auto"});
}

void NetworkController::parseWifiList(const QString &output)
{
    QMap<QString, QVariantMap> networkMap;

    QStringList lines = output.split('\n', Qt::SkipEmptyParts);
    for (const QString &line : lines) {
        // nmcli -t format escapes colons as \:
        QStringList parts;
        QString cur;
        bool esc = false;
        for (QChar c : line) {
            if (esc) {
                cur.append(c);
                esc = false;
            } else if (c == '\\') {
                esc = true;
            } else if (c == ':') {
                parts.append(cur);
                cur.clear();
            } else {
                cur.append(c);
            }
        }
        parts.append(cur);

        if (parts.size() < 4)
            continue;

        bool inUse = (parts[0].trimmed() == "*");
        QString ssid = parts[1].trimmed();
        if (ssid.isEmpty() || ssid == "--")
            continue;

        int signal = parts[2].toInt();
        QString security = parts[3].trimmed();
        bool isProtected = (!security.isEmpty() && security != "--");

        if (!networkMap.contains(ssid) || signal > networkMap[ssid]["signal"].toInt() || inUse) {
            QVariantMap item;
            item["ssid"] = ssid;
            item["signal"] = signal;
            item["security"] = security;
            item["isProtected"] = isProtected;
            item["inUse"] = inUse;
            networkMap[ssid] = item;
        }
    }

    QVariantList list;
    for (auto it = networkMap.begin(); it != networkMap.end(); ++it) {
        list.append(it.value());
    }

    // Sort: inUse at top, then signal descending
    std::sort(list.begin(), list.end(), [](const QVariant &a, const QVariant &b) {
        QVariantMap ma = a.toMap();
        QVariantMap mb = b.toMap();
        if (ma["inUse"].toBool() != mb["inUse"].toBool())
            return ma["inUse"].toBool();
        return ma["signal"].toInt() > mb["signal"].toInt();
    });

    m_wifiList = list;
    emit wifiListChanged();
}

void NetworkController::connectToNetwork(const QString &ssid, const QString &password)
{
    if (m_isConnecting || ssid.isEmpty())
        return;

    m_isConnecting = true;
    m_statusMessage = QStringLiteral("Connecting to %1...").arg(ssid);
    emit isConnectingChanged();
    emit statusMessageChanged();

    // If password was provided, delete any stale or conflicting profile for this SSID
    // so NetworkManager does not fail with cached/stale secrets or duplicate profile errors.
    if (!password.isEmpty()) {
        QProcess delProc;
        delProc.start("nmcli", {"connection", "delete", "id", ssid});
        delProc.waitForFinished(1000);
    }

    auto *proc = new QProcess(this);
    proc->closeWriteChannel(); // Ensure stdin is closed so nmcli cannot block on interactive prompts

    QPointer<QProcess> safeProc(proc);
    QTimer::singleShot(25000, this, [this, safeProc, ssid]() {
        if (safeProc && safeProc->state() != QProcess::NotRunning) {
            safeProc->kill();
            m_isConnecting = false;
            m_statusMessage = QStringLiteral("Connection timed out");
            emit isConnectingChanged();
            emit statusMessageChanged();
            emit connectionResult(false, m_statusMessage);
        }
    });

    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc, ssid](int exitCode, QProcess::ExitStatus) {
        m_isConnecting = false;
        emit isConnectingChanged();

        if (exitCode == 0) {
            m_statusMessage = QStringLiteral("Connected to %1").arg(ssid);
            emit statusMessageChanged();
            emit connectionResult(true, m_statusMessage);
            queryStatus();
            scanNetworks();
        } else {
            QString err = QString::fromUtf8(proc->readAllStandardError()).trimmed();
            if (err.isEmpty())
                err = QString::fromUtf8(proc->readAllStandardOutput()).trimmed();
            m_statusMessage = err.isEmpty() ? QStringLiteral("Failed to connect to %1").arg(ssid) : err;
            emit statusMessageChanged();
            emit connectionResult(false, m_statusMessage);
        }
        proc->deleteLater();
    });

    QStringList args;
    args << "--wait" << "20" << "dev" << "wifi" << "connect" << ssid;
    if (!password.isEmpty()) {
        args << "password" << password;
    }
    proc->start("nmcli", args);
}

void NetworkController::disconnectNetwork()
{
    if (m_connected && !m_ssid.isEmpty() && m_ssid != "Not connected") {
        QProcess::startDetached("nmcli", {"con", "down", "id", m_ssid});
    }

    // Disconnect any active wifi interface dynamically without hardcoding wlan0
    QProcess::startDetached("bash", {"-c", "for d in $(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi$' | cut -d: -f1); do nmcli dev disconnect \"$d\" 2>/dev/null; done"});

    QTimer::singleShot(800, this, [this]() {
        queryStatus();
        scanNetworks();
    });
}
