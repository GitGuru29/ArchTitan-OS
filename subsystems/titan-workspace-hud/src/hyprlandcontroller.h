#pragma once

#include <QObject>
#include <QVariantList>
#include <QVariantMap>

class HyprlandController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int activeWorkspace READ activeWorkspace NOTIFY stateChanged)
    Q_PROPERTY(QVariantList workspaces READ workspaces NOTIFY stateChanged)

public:
    explicit HyprlandController(QObject *parent = nullptr);

    int activeWorkspace() const { return m_activeWorkspace; }
    QVariantList workspaces() const { return m_workspaces; }

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void switchToWorkspace(int wsId);
    Q_INVOKABLE void focusWindow(const QString &address);
    Q_INVOKABLE void closeWindow(const QString &address);
    Q_INVOKABLE void moveWindowToWorkspace(const QString &address, int targetWs);

    static QString resolveIcon(const QString &appClass);

signals:
    void stateChanged();

private:
    QByteArray queryHyprland(const QString &cmd);
    void dispatchHyprland(const QString &cmd);
    void captureActiveThumbnails(const QList<QJsonObject> &activeClients);
    void updateThumbnails();

    int m_activeWorkspace = 1;
    QVariantList m_workspaces;
};
