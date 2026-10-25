#include "networkcontroller.h"
#include <QProcess>
#include <QDebug>
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
    radioProc.start("bash", {"-c", "nmcli radio wifi 2>/dev/null"});
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

    // Check active wifi connection SSID
    QProcess wifiProc;
    wifiProc.start("bash", {"-c", "nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | cut -d: -f2"});
    if (wifiProc.waitForFinished(1000)) {
        QString ssid = wifiProc.readAllStandardOutput().trimmed();
        if (!ssid.isEmpty()) {
            if (!m_connected) {
                m_connected = true;
                emit connectedChanged();
            }
            if (m_ssid != ssid) {
                m_ssid = ssid;
                emit ssidChanged();
            }
            return;
        }
    }

    // Secondary check: active connection name
    QProcess conProc;
    conProc.start("bash", {"-c", "nmcli -t -f NAME,TYPE con show --active 2>/dev/null | grep -iE 'wireless|wifi' | cut -d: -f1"});
    if (conProc.waitForFinished(1000)) {
        QString conName = conProc.readAllStandardOutput().trimmed();
        if (!conName.isEmpty()) {
            if (!m_connected) {
                m_connected = true;
                emit connectedChanged();
            }
            if (m_ssid != conName) {
                m_ssid = conName;
                emit ssidChanged();
            }
            return;
        }
    }

    // If no wifi connection active, mark as Not connected
    if (m_ssid.isEmpty() || m_ssid != "Not connected") {
        m_ssid = "Not connected";
        m_connected = false;
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
    connect(proc, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, [this, proc](int exitCode, QProcess::ExitStatus) {
        if (exitCode == 0) {
            QString out = proc->readAllStandardOutput();
            parseWifiList(out);
        }
        m_isScanning = false;
        emit isScanningChanged();
        proc->deleteLater();
    });

    proc->start("bash", {"-c", "nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes 2>/dev/null"});
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

    auto *proc = new QProcess(this);
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
            QString err = proc->readAllStandardError().trimmed();
            if (err.isEmpty())
                err = proc->readAllStandardOutput().trimmed();
            m_statusMessage = err.isEmpty() ? QStringLiteral("Failed to connect to %1").arg(ssid) : err;
            emit statusMessageChanged();
            emit connectionResult(false, m_statusMessage);
        }
        proc->deleteLater();
    });

    if (password.isEmpty()) {
        proc->start("nmcli", {"dev", "wifi", "connect", ssid});
    } else {
        proc->start("nmcli", {"dev", "wifi", "connect", ssid, "password", password});
    }
}

void NetworkController::disconnectNetwork()
{
    QProcess::startDetached("bash", {"-c", "nmcli dev disconnect $(nmcli -t -f DEVICE,TYPE dev 2>/dev/null | grep ':wifi' | head -1 | cut -d: -f1)"});
    QTimer::singleShot(800, this, [this]() {
        queryStatus();
        scanNetworks();
    });
}
