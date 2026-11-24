// =============================================================================
// titan-hwm-v3/policy/reclaim_engine.cpp
// Phase 10 — 9-step safety-checked termination sequence
// =============================================================================
#include "reclaim_engine.hpp"
#include "../core/signal_utils.hpp"

#include <fstream>
#include <iostream>
#include <thread>
#include <chrono>
#include <csignal>
#include <cstring>
#include <cerrno>
#include <vector>

#include <spawn.h>
#include <sys/wait.h>
#include <sys/syscall.h>
#include <unistd.h>

extern char** environ;

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// Safety checks
// ─────────────────────────────────────────────────────────────────────────────

bool ReclaimEngine::check_not_protected(const Workload& wl) const {
    if (wl.is_protected) return false;
    if (registry_.is_protected_any(wl.pids)) return false;
    return true;
}

bool ReclaimEngine::check_not_executing(
        const Workload& wl,
        const std::unordered_map<pid_t, ProcessNode>& graph) const {
    ActivityState act = detector_.aggregate(wl, graph);
    return act != ActivityState::EXECUTING;
}

bool ReclaimEngine::check_no_active_dependent(
        const Workload& wl,
        const std::unordered_map<uint32_t, Workload>& all) const {
    // A dependent is another workload whose root_pid is a child of this workload's pids
    for (const auto& [id, other] : all) {
        if (id == wl.id) continue;
        if (other.state != WorkloadState::ACTIVE &&
            other.state != WorkloadState::BACKGROUND_EXECUTING) continue;
        // Check if the other workload's root_pid is in this workload's pid set
        for (pid_t our_pid : wl.pids) {
            if (other.root_pid == our_pid) return false; // dependency found
        }
    }
    return true;
}

bool ReclaimEngine::check_no_recent_focus(const Workload& wl) const {
    long secs = std::chrono::duration_cast<std::chrono::seconds>(
        ms_clock::now() - wl.last_active).count();
    return secs >= cfg_.recent_focus_s;
}

// ─────────────────────────────────────────────────────────────────────────────
// notify — desktop notification
//
// ISSUE-09/14: this used to build a shell command line and hand it to
// std::system(). That forked /bin/sh once per reclaim — 5,184 times in a 10 h
// run — inside the tick loop. std::system() also blocks until the child exits
// and is not thread-safe, and the interpolated command line was a latent
// quoting hazard.
//
// posix_spawn() execs notify-send directly from an argv array: no shell, no
// quoting, no interpolation, and it returns as soon as the child is created.
// Bursts are coalesced, and children are reaped so they do not linger as
// zombies.
// ─────────────────────────────────────────────────────────────────────────────
NotifyOutcome ReclaimEngine::notify(const std::string& name) {
    reap_notifications();

    if (!cfg_.notify_enabled) return NotifyOutcome::Unavailable;

    const auto now = std::chrono::steady_clock::now();
    if (last_notify_.time_since_epoch().count() != 0) {
        const auto since = now - last_notify_;
        if (since < std::chrono::seconds(cfg_.notify_min_interval_s))
            return NotifyOutcome::Coalesced;
    }
    last_notify_ = now;

    const std::string body =
        "\"" + name + "\" is idle and will be removed.";

    // posix_spawn() does not perform a PATH search the way execvp() does, and the
    // daemon's PATH under systemd is minimal anyway, so the binary is resolved
    // against the standard locations explicitly.
    static const char* kNotifyBin[] = {
        "/usr/bin/notify-send", "/bin/notify-send", "/usr/local/bin/notify-send"
    };
    const char* notify_bin = nullptr;
    for (const char* candidate : kNotifyBin) {
        if (::access(candidate, X_OK) == 0) { notify_bin = candidate; break; }
    }
    if (!notify_bin) return NotifyOutcome::Unavailable;

    // argv for: notify-send -u normal -t 4000 <summary> <body>
    char* argv[] = {
        const_cast<char*>("notify-send"),
        const_cast<char*>("-u"),
        const_cast<char*>("normal"),
        const_cast<char*>("-t"),
        const_cast<char*>("4000"),
        const_cast<char*>("THM: Reclaiming idle workload"),
        const_cast<char*>(body.c_str()),
        nullptr
    };

    pid_t child = 0;
    // Non-fatal: a desktop notification is never worth failing a reclaim over.
    if (::posix_spawn(&child, notify_bin, nullptr, nullptr, argv, environ) != 0)
        return NotifyOutcome::Unavailable;

    notify_children_.push_back(child);
    return NotifyOutcome::Dispatched;
}

void ReclaimEngine::reap_notifications() {
    for (size_t i = 0; i < notify_children_.size(); ) {
        const pid_t child = notify_children_[i];
        if (::waitpid(child, nullptr, WNOHANG) == child)
            notify_children_.erase(notify_children_.begin() + static_cast<long>(i));
        else
            ++i;
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// kill_tree — send signal to all PIDs in workload; skip protected PIDs
//
// ISSUE-16: the pre-signal /proc existence check was removed rather than kept.
// It was the source of the check-then-act window, and signal_pid() now answers
// "does this PID still exist" atomically via pidfd. Keeping it would have left
// a redundant race in front of a correct check.
// ─────────────────────────────────────────────────────────────────────────────
void ReclaimEngine::kill_tree(const std::vector<pid_t>& pids, int sig,
                              const char* stage) const {
    for (pid_t pid : pids) {
        if (registry_.is_protected_any({pid})) {
            std::cerr << "[Reclaim] BLOCKED " << stage << ": refusing signal "
                      << sig << " to protected PID " << pid << "\n";
            continue;
        }
        // Collateral-only tier. Reclaim verdicts are per-workload, so a reclaim
        // aimed at a dev-tool root (node -> playwright -> chromium) would sweep
        // the browser with it even though nothing was wrong with the browser.
        // Skip it here — on the signal path only — so it is never given blanket
        // OOM/deprioritize immunity just for not being collateral.
        if (registry_.is_collateral_protected_any({pid})) {
            std::cerr << "[Reclaim] SKIPPED " << stage << ": PID " << pid
                      << " is a browser, not the reclaim target — not signalled\n";
            continue;
        }
        switch (signal_process(pid, sig)) {
            case SignalResult::Gone:
                break;  // already exited — not an error, and nothing to log
            case SignalResult::Failed:
                std::cerr << "[Reclaim] kill(" << pid << ", " << sig
                          << "): " << std::strerror(errno) << "\n";
                break;
            case SignalResult::Signaled:
                if (sig == SIGKILL)
                    std::cout << "[Reclaim] PID " << pid
                              << " survived SIGTERM — sending SIGKILL\n";
                break;
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// reclaim — the full 9-step safety sequence (from Phase 10 spec)
// ─────────────────────────────────────────────────────────────────────────────
bool ReclaimEngine::reclaim(
        const Workload&                               wl,
        const std::unordered_map<pid_t, ProcessNode>& graph,
        const std::unordered_map<uint32_t, Workload>& all_workloads)
{
    // ── Step 1: Protected check ───────────────────────────────────────────
    if (!check_not_protected(wl)) {
        std::cout << "[Reclaim] Abort: workload " << wl.id << " is protected.\n";
        return false;
    }

    // ── Step 2: Execution check ────────────────────────────────────────────
    if (!check_not_executing(wl, graph)) {
        std::cout << "[Reclaim] Abort: workload " << wl.id << " is executing.\n";
        return false;
    }

    // ── Step 3: Active dependent check ────────────────────────────────────
    if (!check_no_active_dependent(wl, all_workloads)) {
        std::cout << "[Reclaim] Abort: workload " << wl.id
                  << " has an active dependent.\n";
        return false;
    }

    // ── Step 4: Recent user interaction check ─────────────────────────────
    if (!check_no_recent_focus(wl)) {
        std::cout << "[Reclaim] Abort: workload " << wl.id
                  << " had user focus within " << cfg_.recent_focus_s << "s.\n";
        return false;
    }

    // ── Step 5: Grace notification ────────────────────────────────────────
    std::string name = wl.pids.empty() ? "workload-" + std::to_string(wl.id)
                                       : std::to_string(wl.root_pid);
    switch (notify(name)) {
        case NotifyOutcome::Dispatched:  std::cout << "[Reclaim] Notified. "; break;
        case NotifyOutcome::Coalesced:   std::cout << "[Reclaim] Notification coalesced. "; break;
        case NotifyOutcome::Unavailable: std::cout << "[Reclaim] notify-send unavailable. "; break;
    }
    std::cout << "Waiting " << cfg_.grace_period_ms
              << "ms before SIGTERM...\n";

    // ── Step 6: Wait grace period ─────────────────────────────────────────
    std::this_thread::sleep_for(std::chrono::milliseconds(cfg_.grace_period_ms));

    // ── Step 7: Re-check all conditions ───────────────────────────────────
    // Conditions may have changed during the grace period
    if (!check_not_protected(wl)          ||
        !check_not_executing(wl, graph)   ||
        !check_no_active_dependent(wl, all_workloads) ||
        !check_no_recent_focus(wl)) {
        std::cout << "[Reclaim] Conditions changed during grace period — aborting.\n";
        return false;
    }

    // ── Step 8: SIGTERM ────────────────────────────────────────────────────
    std::cout << "[Reclaim] Sending SIGTERM to workload " << wl.id
              << " (" << wl.pids.size() << " PIDs)\n";
    kill_tree(wl.pids, SIGTERM, "SIGTERM");

    // ── Step 9: Wait SIGTERM grace, then SIGKILL survivors ────────────────
    std::this_thread::sleep_for(std::chrono::milliseconds(cfg_.sigterm_grace_ms));

    kill_tree(wl.pids, SIGKILL, "SIGKILL after SIGTERM grace");

    std::cout << "[Reclaim] Workload " << wl.id << " reclaimed.\n";
    return true;
}

} // namespace thm
