#include "gpumodel.hpp"

GpuModel::GpuModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int GpuModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_gpus.size();
}

QVariant GpuModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_gpus.size())
        return {};

    const GpuInfo &g = m_gpus.at(index.row());
    switch (role) {
    case NameRole:     return g.name;
    case VendorRole:   return g.vendor;
    case UtilRole:     return g.util;
    case HasMemRole:   return g.hasMem;
    case MemUsedRole:  return g.memUsedMb;
    case MemTotalRole: return g.memTotalMb;
    case MemPctRole:
        return (g.hasMem && g.memTotalMb > 0)
                   ? (100.0 * static_cast<double>(g.memUsedMb) / static_cast<double>(g.memTotalMb))
                   : 0.0;
    case HasTempRole:  return g.hasTemp;
    case TempRole:     return g.temp;
    default:           return {};
    }
}

QHash<int, QByteArray> GpuModel::roleNames() const
{
    return {
        { NameRole,     "name"     },
        { VendorRole,   "vendor"   },
        { UtilRole,     "util"     },
        { HasMemRole,   "hasMem"   },
        { MemUsedRole,  "memUsed"  },
        { MemTotalRole, "memTotal" },
        { MemPctRole,   "memPct"   },
        { HasTempRole,  "hasTemp"  },
        { TempRole,     "temp"     },
    };
}

void GpuModel::setGpus(const QVector<GpuInfo> &gpus)
{
    beginResetModel();
    m_gpus = gpus;
    endResetModel();
    emit changed();
}
