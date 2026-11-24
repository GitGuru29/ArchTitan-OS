// =============================================================================
// titan-hwm-v3/resources/smt_topology.hpp
// v3.5 — SMT-aware physical-core discovery and cpuset planning
//
// Pure parsing/planning helpers (no cgroup writes) plus a best-effort sysfs
// reader. Keeping the plan pure lets the unit tests verify the exact cpuset
// split on a 4c/8t machine without touching /sys/fs/cgroup.
// =============================================================================
#pragma once

#include "../core/types.hpp"

#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <string>
#include <unordered_map>
#include <vector>

namespace thm {

// Parse a Linux CPU list such as "0,4", "1-3", or "0-1,4-5".
inline std::vector<int> parse_cpu_list(const std::string& text) {
    std::vector<int> out;
    size_t pos = 0;
    while (pos < text.size()) {
        const size_t comma = text.find(',', pos);
        const std::string token = text.substr(pos, comma == std::string::npos
                                                     ? std::string::npos
                                                     : comma - pos);
        if (!token.empty()) {
            const size_t dash = token.find('-');
            if (dash != std::string::npos) {
                const int lo = std::atoi(token.substr(0, dash).c_str());
                const int hi = std::atoi(token.substr(dash + 1).c_str());
                if (lo >= 0 && hi >= lo && (hi - lo) < 1024) {
                    for (int c = lo; c <= hi; ++c) out.push_back(c);
                }
            } else {
                const int c = std::atoi(token.c_str());
                if (c >= 0) out.push_back(c);
            }
        }
        if (comma == std::string::npos) break;
        pos = comma + 1;
    }
    std::sort(out.begin(), out.end());
    out.erase(std::unique(out.begin(), out.end()), out.end());
    return out;
}

struct SmtTopology {
    int logical_cpus = 0;
    std::vector<int> core_id; // indexed by logical CPU; -1 = unknown

    bool valid() const { return logical_cpus > 0 &&
                                static_cast<int>(core_id.size()) == logical_cpus; }

    bool has_smt() const {
        for (const auto& g : core_groups())
            if (g.size() > 1) return true;
        return false;
    }

    // Logical CPUs grouped by physical core, ordered by lowest logical id.
    std::vector<std::vector<int>> core_groups() const {
        std::unordered_map<int, size_t> index;
        std::vector<std::vector<int>> groups;
        for (int cpu = 0; cpu < logical_cpus; ++cpu) {
            int id = (cpu < static_cast<int>(core_id.size())) ? core_id[cpu] : -1;
            if (id < 0) id = 1000000 + cpu; // unknown topology: treat as own core
            auto it = index.find(id);
            if (it == index.end()) {
                it = index.emplace(id, groups.size()).first;
                groups.emplace_back();
            }
            groups[it->second].push_back(cpu);
        }
        std::sort(groups.begin(), groups.end(),
                  [](const std::vector<int>& a, const std::vector<int>& b) {
                      return a.front() < b.front();
                  });
        return groups;
    }
};

// Best-effort sysfs discovery. Falls back to thread_siblings_list when core_id
// is unavailable, then to "one logical CPU per core".
inline SmtTopology read_smt_topology(int online_cpus) {
    SmtTopology t;
    t.logical_cpus = std::max(0, online_cpus);
    t.core_id.assign(t.logical_cpus, -1);

    for (int cpu = 0; cpu < t.logical_cpus; ++cpu) {
        const std::string base =
            "/sys/devices/system/cpu/cpu" + std::to_string(cpu) + "/topology/";
        {
            std::ifstream f(base + "core_id");
            int id = -1;
            if (f >> id && id >= 0) t.core_id[cpu] = id;
        }
        if (t.core_id[cpu] < 0) {
            std::ifstream f(base + "thread_siblings_list");
            std::string list;
            if (f >> list) {
                const auto siblings = parse_cpu_list(list);
                int lowest = t.logical_cpus;
                for (int s : siblings)
                    if (s >= 0 && s < t.logical_cpus) lowest = std::min(lowest, s);
                if (lowest < t.logical_cpus) t.core_id[cpu] = 10000 + lowest;
            }
        }
    }
    return t;
}

inline std::string format_cpu_list(const std::vector<int>& cpus) {
    std::string out;
    for (size_t i = 0; i < cpus.size(); ++i) {
        if (i) out += ',';
        out += std::to_string(cpus[i]);
    }
    return out;
}

struct CpuIsolationPlan {
    bool active = false;
    std::vector<int> latency_ids;    // logical CPUs given to ACTIVE + LATENCY
    std::vector<int> background_ids; // logical CPUs left for BACKGROUND
    int reserved_physical_cores = 0;
};

// Pick whole physical cores for latency work. Siblings of a reserved core are
// kept OUT of the background slice — otherwise a game's thread and a compile
// worker would still fight over the same execution units.
//
// No more than half the physical cores are reserved, and at least two physical
// cores stay with background work. A classified latency workload or GPU feeder
// is enough on its own — even at NORMAL/MODERATE pressure, a background build
// on the game's SMT sibling steals execution units before PSI notices. Only an
// unattended user (or no latency intent) returns an inactive plan, telling the
// caller to restore the full CPU list. No signals — only cpuset strings.
inline CpuIsolationPlan plan_smt_isolation(const SmtTopology& topo,
                                           int latency_workloads,
                                           int gpu_feeders,
                                           PressureLevel pressure,
                                           bool unattended) {
    CpuIsolationPlan plan;
    (void)pressure; // intent alone decides; pressure still drives cpu.max/weights
    if (!topo.valid() || unattended) return plan;

    const int latency_demand = std::max(0, latency_workloads) + std::max(0, gpu_feeders);
    if (latency_demand <= 0) return plan;

    const auto groups = topo.core_groups();
    const int physical = static_cast<int>(groups.size());
    if (physical < 2) return plan; // isolation needs at least one core left for BG

    int reserve = std::min(latency_demand, physical / 2);
    reserve = std::min(reserve, physical - 2);
    if (reserve <= 0) return plan;

    std::vector<bool> excluded(topo.logical_cpus, false);
    for (int g = 0; g < reserve; ++g) {
        for (int cpu : groups[g]) {
            if (cpu >= 0 && cpu < topo.logical_cpus) {
                excluded[cpu] = true;
                plan.latency_ids.push_back(cpu);
            }
        }
    }
    for (int cpu = 0; cpu < topo.logical_cpus; ++cpu)
        if (!excluded[cpu]) plan.background_ids.push_back(cpu);

    if (plan.latency_ids.empty() || plan.background_ids.empty()) return CpuIsolationPlan{};

    plan.active = true;
    plan.reserved_physical_cores = reserve;
    std::sort(plan.latency_ids.begin(), plan.latency_ids.end());
    std::sort(plan.background_ids.begin(), plan.background_ids.end());
    return plan;
}

} // namespace thm
