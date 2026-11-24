#pragma once

namespace titan::focus {

struct PressureSample {
    double psiMemAvg10 = 0.0; // percentage 0..100 from /proc/pressure/memory
    double memUsedPct  = 0.0; // percentage 0..100 from /proc/meminfo
    double cpuTempC    = 0.0; // max CPU thermal reading in Celsius
};

/**
 * PressureSampler — pure POSIX reader for /proc/pressure/memory, /proc/meminfo,
 * /sys/class/thermal, and optional /run/archtitan/thm-state.json enrichment.
 */
class PressureSampler {
public:
    static PressureSample sample();
};

} // namespace titan::focus
