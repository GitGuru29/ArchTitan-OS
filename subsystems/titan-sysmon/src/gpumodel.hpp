#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

/// One detected GPU.
struct GpuInfo
{
    QString name;
    QString vendor;                  // "NVIDIA" / "AMD" / "Intel"
    double  util        = 0.0;       // 0..100
    bool    hasMem      = false;
    qint64  memUsedMb   = 0;
    qint64  memTotalMb  = 0;
    bool    hasTemp     = false;
    double  temp        = 0.0;       // °C
};

/**
 * GpuModel — list model of the GPUs present on the machine.
 *
 * Populated by SysmonController each tick (NVIDIA via nvidia-smi, AMD/Intel via
 * DRM sysfs). QML consumes it through a ListView/Repeater; the row count tracks
 * the number of GPUs and the "no GPU" state is expressed by an empty model.
 */
class GpuModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY changed)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        VendorRole,
        UtilRole,
        HasMemRole,
        MemUsedRole,
        MemTotalRole,
        MemPctRole,
        HasTempRole,
        TempRole,
    };
    Q_ENUM(Roles)

    explicit GpuModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    int count() const { return m_gpus.size(); }

    void setGpus(const QVector<GpuInfo> &gpus);

signals:
    void changed();

private:
    QVector<GpuInfo> m_gpus;
};
