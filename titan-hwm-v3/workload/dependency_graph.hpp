// =============================================================================
// titan-hwm-v3/workload/dependency_graph.hpp
// v3.10 — Workload Dependency Graph
//
// The ownership graph is a PID -> workload forest. This graph adds the
// cross-root relationships a developer workflow actually has:
//   * IDE root -> LSP / build child (toolchain)
//   * IDE root -> process sharing the same project CWD (shared project)
//   * ancestor process in another workload (process ancestry)
//
// Direction: `from` DEPENDS ON `to`. Reclaim may only proceed when no active
// workload transitively depends on the candidate.
// =============================================================================
#pragma once

#include "../core/types.hpp"

#include <array>
#include <cstdint>
#include <string>
#include <unordered_map>
#include <unordered_set>
#include <vector>

namespace thm {

enum class DependencyKind : std::uint8_t {
    ProcessAncestry = 0,
    Toolchain       = 1,
    SharedProject   = 2,
};

struct DependencyEdge {
    uint32_t       from = 0;   // dependent workload
    uint32_t       to   = 0;   // provider workload
    DependencyKind kind = DependencyKind::ProcessAncestry;
    std::string    evidence;
};

struct DependencyNode {
    uint32_t id = 0;
    int      workspace_id = -1;
    bool     active = false;
    bool     protected_root = false;
    std::string window_class;
    std::string window_title;
    std::unordered_set<uint32_t> providers;
    std::unordered_set<uint32_t> dependents;
};

class WorkloadDependencyGraph {
public:
    static constexpr std::size_t kMaxAncestryDepth = 8;

    void rebuild(const std::unordered_map<uint32_t, Workload>& workloads,
                 const std::unordered_map<pid_t, ProcessNode>& procs);

    void clear();

    // True when this workload has any active (or transitively active)
    // dependent. Used by ReclaimEngine step 3 and step 7.
    bool has_active_dependent(uint32_t id) const;

    bool depends_on(uint32_t dependent, uint32_t provider) const;

    std::vector<uint32_t> providers_of(uint32_t id) const;
    std::vector<uint32_t> dependents_of(uint32_t id) const;

    // Mark a workload terminated after a successful reclaim so a later
    // candidate in the same tick cannot be protected by a dead dependent.
    void mark_terminated(uint32_t id);

    std::size_t node_count() const { return nodes_.size(); }
    std::size_t edge_count() const { return edges_.size(); }

    std::size_t edge_count(DependencyKind kind) const;

    // Number of nodes currently shielded by an active dependent.
    std::size_t active_dependent_count() const;

    const std::vector<DependencyEdge>& edges() const { return edges_; }

    std::string summary() const;

private:
    void add_edge(uint32_t from, uint32_t to, DependencyKind kind,
                  std::string evidence);

    std::unordered_map<uint32_t, DependencyNode> nodes_;
    std::vector<DependencyEdge>                  edges_;
    std::unordered_set<std::uint64_t>            edge_keys_;
    std::array<std::size_t, 3>                   kind_counts_{};
};

} // namespace thm
