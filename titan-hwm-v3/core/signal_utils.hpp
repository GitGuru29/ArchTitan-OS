// =============================================================================
// titan-hwm-v3/core/signal_utils.hpp
// Shared pidfd-based signal delivery for all THM enforcement paths.
//
// A liveness check followed by kill() has a time-of-check/time-of-use window:
// the PID can exit and be recycled, and the signal then lands on an unrelated
// process. A pidfd pins the *process*, not the number, so once opened the
// descriptor always refers to the same process — if that process has exited,
// the send fails with ESRCH and a recycled PID can never be signalled through
// it. This makes check-and-signal atomic with respect to PID recycling.
//
// The glibc wrappers are not exported by this toolchain's glibc, so the
// syscalls are issued directly. Kernels before 5.3 return ENOSYS and fall back
// to kill(), which is still guarded by the caller's protected-PID check.
// =============================================================================
#pragma once

#include <cerrno>
#include <csignal>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

namespace thm {

// Outcome of a signal attempt, distinguished so callers can log accurately.
enum class SignalResult {
    Signaled,  // signal delivered (or the process was already gone at open time)
    Gone,      // no such process — nothing to do, and the correct thing to log
    Failed     // refused or errored; errno is set
};

inline SignalResult signal_process(pid_t pid, int sig) {
    const int pfd = static_cast<int>(::syscall(SYS_pidfd_open, pid, 0));

    if (pfd >= 0) {
        const long rc = ::syscall(SYS_pidfd_send_signal, pfd, sig, nullptr, 0);
        const int err = (rc == 0) ? 0 : errno;
        ::close(pfd);
        if (rc == 0)      return SignalResult::Signaled;
        if (err == ESRCH) return SignalResult::Gone;
        if (err != ENOSYS) { errno = err; return SignalResult::Failed; }
        // ENOSYS — pre-5.3 kernel, fall through to the plain path.
    } else if (errno == ESRCH) {
        return SignalResult::Gone;
    }
    // errno == ENOSYS here means pidfd is unsupported entirely.

    if (::kill(pid, sig) == 0 || errno == ESRCH) return SignalResult::Signaled;
    return SignalResult::Failed;
}

// Liveness probe. EPERM means the process exists but belongs to another UID.
inline bool process_alive(pid_t pid) {
    return ::kill(pid, 0) == 0 || errno == EPERM;
}

} // namespace thm
