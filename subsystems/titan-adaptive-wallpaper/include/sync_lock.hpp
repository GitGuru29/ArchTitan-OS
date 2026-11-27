#pragma once

#include <QLockFile>
#include <QString>

namespace taw {

// Cross-process guard for operations that mutate the wallpaper state.
// The daemon, the CLI and the settings app can all call sync() at the same
// time; without this they race over the config file, cache and swaybg.
class SyncLock {
public:
    explicit SyncLock(const QString& path, int wait_ms = 20000)
        : m_lock(path)
    {
        m_lock.setStaleLockTime(60000);
        m_acquired = m_lock.tryLock(wait_ms);
    }

    ~SyncLock() {
        if (m_acquired) m_lock.unlock();
    }

    bool acquired() const { return m_acquired; }

    SyncLock(const SyncLock&) = delete;
    SyncLock& operator=(const SyncLock&) = delete;

private:
    QLockFile m_lock;
    bool m_acquired = false;
};

} // namespace taw
