// =============================================================================
// titan-hwm-v3/workload/dependency_graph.cpp
// v3.10 — cross-root dependency inference
// =============================================================================
#include "dependency_graph.hpp"

#include <algorithm>
#include <sstream>
#include <utility>

namespace thm {
namespace {

bool is_active(WorkloadState state) {
    return state == WorkloadState::ACTIVE ||
           state == WorkloadState::BACKGROUND_EXECUTING;
}

bool is_protected_root(const Workload& wl) {
    return wl.is_protected || wl.latency_sensitive || wl.gpu_feeding ||
           wl.is_browser_root;
}

std::uint64_t edge_key(uint32_t from, uint32_t to) {
    return (static_cast<std::uint64_t>(from) << 32) |
           static_cast<std::uint64_t>(to);
}

const char* kind_name(DependencyKind kind) {
    switch (kind) {
        case DependencyKind::ProcessAncestry: return "ancestry";
        case DependencyKind::Toolchain:       return "toolchain";
        case DependencyKind::SharedProject:   return "project";
    }
    return "unknown";
}

} // namespace

void WorkloadDependencyGraph::clear() {
    nodes_.clear();
    edges_.clear();
    edge_keys_.clear();
    kind_counts_.fill(0);
}

void WorkloadDependencyGraph::add_edge(uint32_t from, uint32_t to,
                                       DependencyKind kind,
                                       std::string evidence) {
    if (from == 0 || to == 0 || from == to) return;
    if (nodes_.find(from) == nodes_.end() || nodes_.find(to) == nodes_.end())
        return;

    const auto key = edge_key(from, to);
    if (!edge_keys_.insert(key).second) return;

    nodes_[from].providers.insert(to);
    nodes_[to].dependents.insert(from);
    edges_.push_back(DependencyEdge{from, to, kind, std::move(evidence)});
    ++kind_counts_[static_cast<std::size_t>(kind)];
}

void WorkloadDependencyGraph::rebuild(
        const std::unordered_map<uint32_t, Workload>& workloads,
        const std::unordered_map<pid_t, ProcessNode>& procs) {
    clear();
    nodes_.reserve(workloads.size());
    edges_.reserve(workloads.size() * 2);
    edge_keys_.reserve(workloads.size() * 2);

    for (const auto& [id, wl] : workloads) {
        if (wl.state == WorkloadState::TERMINATED) continue;
        DependencyNode node;
        node.id = id;
        node.workspace_id = wl.workspace_id;
        node.active = is_active(wl.state);
        node.protected_root = is_protected_root(wl);
        node.window_class = wl.window_class;
        node.window_title = wl.window_title;
        nodes_.emplace(id, std::move(node));
    }

    // ── 1. Process ancestry: a child workload inherits a dependency on the
    // nearest ancestor that belongs to a different workload root.
    for (const auto& [pid, node] : procs) {
        (void)pid;
        if (node.workload_id == 0) continue;

        pid_t ancestor = node.ppid;
        for (std::size_t depth = 0;
             depth < kMaxAncestryDepth && ancestor > 1; ++depth) {
            auto ait = procs.find(ancestor);
            if (ait == procs.end()) break;
            const auto& parent = ait->second;
            if (parent.workload_id != 0 &&
                parent.workload_id != node.workload_id) {
                add_edge(node.workload_id, parent.workload_id,
                         DependencyKind::ProcessAncestry,
                         "pid " + std::to_string(node.pid) + " <- " +
                         std::to_string(parent.pid));
                break;
            }
            ancestor = parent.ppid;
        }
    }

    // ── 2. Window-bound roots by workspace. Prefer an active bound root; a
    // stale bound root is still better than no authority at all.
    std::unordered_map<int, uint32_t> window_root_by_ws;
    for (const auto& [id, node] : nodes_) {
        if (node.window_class.empty()) continue;
        auto it = window_root_by_ws.find(node.workspace_id);
        if (it == window_root_by_ws.end()) {
            window_root_by_ws[node.workspace_id] = id;
            continue;
        }
        const auto* current = &nodes_.at(it->second);
        if (!current->active && node.active)
            it->second = id;
    }

    for (const auto& [id, wl] : workloads) {
        if (!wl.has_lsp && !wl.is_building) continue;
        auto it = window_root_by_ws.find(wl.workspace_id);
        if (it == window_root_by_ws.end() || it->second == id) continue;
        const char* signal = wl.has_lsp ? "lsp" : "build";
        add_edge(id, it->second, DependencyKind::Toolchain,
                 std::string(signal) + " -> " +
                 nodes_.at(it->second).window_class);
    }

    // ── 3. Shared project CWD: bind headless children to the window-bound
    // root working in the same directory. No title-only binding is used.
    std::unordered_map<std::string, uint32_t> window_root_by_cwd;
    for (const auto& [pid, node] : procs) {
        (void)pid;
        if (node.workload_id == 0 || node.cwd.empty()) continue;
        auto nit = nodes_.find(node.workload_id);
        if (nit == nodes_.end() || nit->second.window_class.empty()) continue;
        window_root_by_cwd.emplace(node.cwd, node.workload_id);
    }

    for (const auto& [pid, node] : procs) {
        (void)pid;
        if (node.workload_id == 0 || node.cwd.empty()) continue;
        auto nit = nodes_.find(node.workload_id);
        if (nit == nodes_.end() || !nit->second.window_class.empty()) continue;
        auto wit = window_root_by_cwd.find(node.cwd);
        if (wit == window_root_by_cwd.end() || wit->second == node.workload_id)
            continue;
        add_edge(node.workload_id, wit->second,
                 DependencyKind::SharedProject, "cwd " + node.cwd);
    }
}

bool WorkloadDependencyGraph::has_active_dependent(uint32_t id) const {
    auto sit = nodes_.find(id);
    if (sit == nodes_.end()) return false;

    std::unordered_set<uint32_t> visited;
    std::vector<uint32_t> stack;
    for (uint32_t dep : sit->second.dependents) stack.push_back(dep);

    while (!stack.empty()) {
        const uint32_t current = stack.back();
        stack.pop_back();
        if (!visited.insert(current).second) continue;
        auto nit = nodes_.find(current);
        if (nit == nodes_.end()) continue;
        if (nit->second.active || nit->second.protected_root) return true;
        for (uint32_t next : nit->second.dependents) stack.push_back(next);
    }
    return false;
}

bool WorkloadDependencyGraph::depends_on(uint32_t dependent,
                                         uint32_t provider) const {
    auto it = nodes_.find(dependent);
    return it != nodes_.end() && it->second.providers.count(provider) != 0;
}

std::vector<uint32_t> WorkloadDependencyGraph::providers_of(uint32_t id) const {
    auto it = nodes_.find(id);
    if (it == nodes_.end()) return {};
    return {it->second.providers.begin(), it->second.providers.end()};
}

std::vector<uint32_t> WorkloadDependencyGraph::dependents_of(uint32_t id) const {
    auto it = nodes_.find(id);
    if (it == nodes_.end()) return {};
    return {it->second.dependents.begin(), it->second.dependents.end()};
}

void WorkloadDependencyGraph::mark_terminated(uint32_t id) {
    auto it = nodes_.find(id);
    if (it == nodes_.end()) return;
    it->second.active = false;
    it->second.protected_root = false;
    it->second.providers.clear();
}

std::size_t WorkloadDependencyGraph::edge_count(DependencyKind kind) const {
    return kind_counts_[static_cast<std::size_t>(kind)];
}

std::size_t WorkloadDependencyGraph::active_dependent_count() const {
    std::size_t count = 0;
    for (const auto& [id, node] : nodes_) {
        (void)node;
        if (has_active_dependent(id)) ++count;
    }
    return count;
}

std::string WorkloadDependencyGraph::summary() const {
    std::ostringstream o;
    o << node_count() << " nodes, " << edge_count() << " edges ("
      << edge_count(DependencyKind::ProcessAncestry) << ' '
      << kind_name(DependencyKind::ProcessAncestry) << '/'
      << edge_count(DependencyKind::Toolchain) << ' '
      << kind_name(DependencyKind::Toolchain) << '/'
      << edge_count(DependencyKind::SharedProject) << ' '
      << kind_name(DependencyKind::SharedProject) << ", "
      << active_dependent_count() << " shielded)";
    return o.str();
}

} // namespace thm
