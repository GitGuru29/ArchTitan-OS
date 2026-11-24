// =============================================================================
// titan-hwm-v3/resources/input_feedforward.hpp
// v3.6 — keyboard/mouse feed-forward for foreground latency
//
// Reads /dev/input/event* non-blockingly and grants a short, bounded priority
// boost right after real user input — before CPU pressure rises. All policy is
// expressed as pure helpers, so the unit tests need no input hardware.
// HC-CPU-1 is preserved: this module never signals, freezes or kills anything.
// =============================================================================
#pragma once

#include "../enforcement/cgroup_controller.hpp"

#include <algorithm>
#include <cerrno>
#include <chrono>
#include <cstdint>
#include <dirent.h>
#include <fcntl.h>
#include <linux/input.h>
#include <string>
#include <unistd.h>
#include <vector>

namespace thm {

// Short-lived boost granted after a keystroke or mouse movement.
struct InputBoost {
    bool active = false;
    int  active_weight_bonus       = 400; // 1000 -> 1400 at HIGH
    int  latency_weight_bonus      = 400; // 950  -> 1350 at HIGH
    int  background_weight_penalty = 5;   // floored well above the THROTTLE cap
    int  extra_reserve_cores       = 1;   // one more core away from bulk work
};

// Apply the boost to an already-computed CPU policy. When no cap is engaged a
// short one is armed, so input latency is protected at NORMAL/MODERATE pressure
// instead of waiting for PSI to climb. The effect is bounded: active/latency
// weights are clamped to 10000 and BG never drops below weight 10.
inline void apply_input_boost(CpuSlicePolicy& p, const InputBoost& boost,
                              int online_cpus) {
    if (!boost.active || p.unattended_lift) return;

    p.active_weight  = std::min(10000, p.active_weight + boost.active_weight_bonus);
    p.latency_weight = std::min(10000, p.latency_weight + boost.latency_weight_bonus);
    p.background_weight = std::max(10, p.background_weight -
                                        boost.background_weight_penalty);

    const int cpus = std::max(1, online_cpus);
    if (!p.headroom_engaged) {
        if (cpus <= 2) return; // a 2-CPU box cannot afford an input-only cap
        p.headroom_engaged = true;
        p.reserved_cores = std::max(1, p.reserved_cores);
    } else {
        p.reserved_cores += std::max(0, boost.extra_reserve_cores);
    }

    const int quota_cores = std::max(1, cpus - p.reserved_cores);
    p.background_quota_us = quota_cores * p.period_us;
    p.background_max_pct = 100.0f * static_cast<float>(quota_cores) /
                           static_cast<float>(cpus);
}

// True only for deliberate user input: key press/repeat or non-zero relative /
// absolute pointer motion. Power/lid/sleep keys and key releases are ignored.
inline bool is_user_input_event(const struct input_event& ev) {
    if (ev.type == EV_REL || ev.type == EV_ABS) return ev.value != 0;
    if (ev.type != EV_KEY) return false;
    if (ev.value != 1 && ev.value != 2) return false; // not press / repeat
    switch (ev.code) {
        case KEY_POWER:
        case KEY_SLEEP:
        case KEY_WAKEUP:
#ifdef KEY_LID
        case KEY_LID:
#endif
            return false;
        default:
            return true;
    }
}

// Bounded-time latch: an event refreshes the deadline, and the boost expires
// on its own even if no further events arrive (e.g. device disappears).
class InputFeedForwardTracker {
public:
    using Clock = std::chrono::steady_clock;
    static constexpr auto kWindow = std::chrono::milliseconds(1200);

    bool observe(bool input_now, Clock::time_point now) {
        if (input_now) { last_ = now; seen_ = true; }
        return active(now);
    }

    bool active(Clock::time_point now) const {
        return seen_ && (now - last_) <= kWindow;
    }

    long age_ms(Clock::time_point now) const {
        if (!seen_) return -1;
        return static_cast<long>(
            std::chrono::duration_cast<std::chrono::milliseconds>(now - last_).count());
    }

private:
    Clock::time_point last_{};
    bool seen_ = false;
};

// Best-effort evdev reader. Opens every readable /dev/input/eventN once and
// drains it each tick with O_NONBLOCK. No udev/libevdev dependency; a missing
// device or permission failure simply means "no input observed".
class InputDeviceMonitor {
public:
    InputDeviceMonitor() { rescan(); }
    ~InputDeviceMonitor() { for (int fd : fds_) if (fd >= 0) ::close(fd); }

    InputDeviceMonitor(const InputDeviceMonitor&) = delete;
    InputDeviceMonitor& operator=(const InputDeviceMonitor&) = delete;

    int device_count() const { return static_cast<int>(fds_.size()); }

    bool poll() {
        struct input_event ev;
        bool any = false;
        for (int fd : fds_) {
            for (int i = 0; i < 64; ++i) {
                const ssize_t n = ::read(fd, &ev, sizeof(ev));
                if (n != static_cast<ssize_t>(sizeof(ev))) break;
                if (is_user_input_event(ev)) any = true;
            }
        }
        return any;
    }

private:
    void rescan() {
        DIR* dir = ::opendir("/dev/input");
        if (!dir) return;
        struct dirent* ent = nullptr;
        while ((ent = ::readdir(dir)) != nullptr) {
            const std::string name = ent->d_name;
            if (name.rfind("event", 0) != 0) continue;
            const std::string path = "/dev/input/" + name;
            const int fd = ::open(path.c_str(), O_RDONLY | O_NONBLOCK | O_CLOEXEC);
            if (fd >= 0) fds_.push_back(fd);
        }
        ::closedir(dir);
    }

    std::vector<int> fds_;
};

} // namespace thm
