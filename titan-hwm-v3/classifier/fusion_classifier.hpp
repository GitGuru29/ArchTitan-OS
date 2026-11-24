// =============================================================================
// titan-hwm-v3/classifier/fusion_classifier.hpp
// Phase 3 — FusionClassifier (ported from v2, output repurposed)
//
// The 3-signal classification logic is UNCHANGED from v2.
// What changed: FusionResult is gone. Output is ClassificationResult (types.hpp).
// ClassificationResult is DESCRIPTIVE METADATA ONLY — it never selects processes
// to kill, freeze, or target. It populates Workload::type and Workload::confidence.
//
// Signal weights (same as v2):
//   S1 child walk   0.6+ per matching process
//   S2 window title 0.3  (0.5 if high-specificity ext present)
//   S3 cwd stat     0.2  tiebreaker
// =============================================================================
#pragma once

#include "../core/types.hpp"

#include <string>
#include <vector>
#include <unordered_map>
#include <unordered_set>
#include <optional>
#include <map>
#include <deque>
#include <mutex>
#include <cstddef>
#include <sys/types.h>

namespace thm {

// ─────────────────────────────────────────────────────────────────────────────
// ClassifierConfig — tool name sets (sourced from Config in Phase 12)
// Mirror the existing /etc/titan-hwm/config fields
// ─────────────────────────────────────────────────────────────────────────────
struct ClassifierConfig {
    std::vector<std::string> lsp_binaries  = {
        "clangd", "ccls", "rust-analyzer",
        "tsserver", "typescript-language-server",
        "eslint_d", "pyright", "jdtls",
        "kotlin-language-server", "gopls"
    };
    std::vector<std::string> build_daemons = {
        "gradle", "gradlew", "java", "adb", "kotlin-compiler", "aapt2",
        "cargo", "cmake", "ninja", "make", "bazel", "buck2", "meson",
        "webpack", "vite", "esbuild", "tsc", "bun", "node"
    };
    std::vector<std::string> ai_inference  = {
        "ollama", "llama-server", "llamacpp", "llama.cpp",
        "aider", "sgpt", "openai", "litellm",
        "titan-ai", "titanai"
    };
    std::vector<std::string> latency_sensitive = {
        "titan-mirror", "titanmirror",
        "obs", "obs-studio",
        "ffmpeg", "gst-launch-1.0"
    };
    // ── v3.1 additions ────────────────────────────────────────────────────
    // HC-05/06: Browser root process names. These get is_browser_root=true and
    // latency_sensitive=true (video calls). SIGSTOP is skipped for FREEZE.
    std::vector<std::string> browser_roots = {
        "chrome", "chromium", "google-chrome", "google-chrome-stable",
        "firefox", "firefox-bin", "gecko-main",
        "brave", "brave-browser",
        "titan-browser",   // ArchTitan native browser
        "microsoft-edge", "msedge",
        "opera",
        "vivaldi-bin", "vivaldi"
    };
    // HC-07: Container runtime root processes — WorkloadType::SERVICE
    std::vector<std::string> container_runtimes = {
        "dockerd", "docker", "containerd", "crun", "runc", "podman"
    };
    // HC-08: VM host process names — WorkloadType::VM
    std::vector<std::string> vm_processes = {
        "qemu-system-x86_64", "qemu-system-aarch64", "qemu-system-arm",
        "qemu-kvm", "kvm"
    };
    // ── v3.3 workload intent sets ─────────────────────────────────────────
    // Games and real-time apps: must never be capped or given cpu.idle.
    std::vector<std::string> latency_critical_apps = {
        "steam", "steamwebhelper", "gamescope", "gamemode", "mangohud",
        "wine", "wine64", "wineserver", "lutris", "heroic", "bottles",
        "proton", "cs2", "dota2", "minecraft", "factorio", "terraria",
        "retroarch", "rpcs3", "yuzu", "dolphin-emu", "osu!",
        // Standalone game/benchmark engines. Unigine Superposition launches
        // `bin/superposition` directly with no launcher parent, so without its
        // own name it silently lands in OBSERVED and never gets latency intent.
        "superposition", "superposition_cli", "unigine", "unigine-superposition"
    };
    // Bulk throughput jobs: safe to cap when they are not the foreground task.
    std::vector<std::string> bulk_render_apps = {
        "blender", "cycles", "inkscape", "krita", "handbrake", "handbrakecli",
        "resolve", "davinci-resolve", "povray", "luxrender", "octane",
        "octanerender", "renderdoc", "sshadertoy",
        // Compiler/driver processes are short-lived bulk work. Without explicit
        // intent they look IDLE between samples and get frozen under memory
        // pressure, stalling the whole build (the v3.4 QEMU regression).
        "gcc", "g++", "cc1", "cc1plus", "clang", "clang++", "cpp",
        "make", "gmake", "cmake", "ninja", "meson", "rustc", "cargo",
        "go", "javac", "dotnet", "ld", "collect2", "as"
    };
    // Training marker: requires a python-family executable AND one of these in
    // the full command line, so ordinary python scripts are not misclassified.
    std::vector<std::string> training_markers = {
        "torch", "pytorch", "torchrun", "tensorflow", "train.py", "training",
        "dataloader", "lightning", "keras"
    };
};

// ─────────────────────────────────────────────────────────────────────────────
// FusionClassifier — 3-signal fusion (logic unchanged from v2)
// ─────────────────────────────────────────────────────────────────────────────
class FusionClassifier {
public:
    explicit FusionClassifier(ClassifierConfig cfg = {}) : cfg_(std::move(cfg)) {}

    // Main entry point — fuse all 3 signals and return ClassificationResult.
    // pid:   root PID of the workload being classified
    // title: active window title (from Hyprland activewindowv2 event)
    // graph: full /proc snapshot (pid → ProcessNode)
    ClassificationResult classify(pid_t                                       pid,
                                   const std::string&                          title,
                                   const std::unordered_map<pid_t, ProcessNode>& graph) const;

    // Individual signals (public for testing)
    ClassificationResult from_children(pid_t pid,
                                        const std::unordered_map<pid_t, ProcessNode>& graph) const;
    static std::optional<WorkloadType> from_title(const std::string& title);
    static std::optional<WorkloadType> from_cwd(pid_t pid);

    // v3.3 intent detection (public for testing): games/renderers by executable
    // name, training by python-family executable + full-cmdline marker.
    // `full_cmdline` is optional so tests need not fabricate a /proc entry.
    static void detect_intent(const ClassifierConfig& cfg,
                              const std::string& cmd, pid_t pid,
                              ClassificationResult& r,
                              const std::string* full_cmdline = nullptr);

private:
    ClassifierConfig cfg_;

    // Security: reject executables running from world-writable paths
    static bool is_valid_executable_path(pid_t pid);

    // Recursive child walk (depth 3) — same as v2
    static void walk_child_procs_recursive(
        pid_t pid,
        const std::unordered_map<pid_t, ProcessNode>& graph,
        std::vector<std::pair<pid_t, std::string>>& out,
        int depth = 3);

    // TC-1.3: boost S2 weight when title has unambiguous extension
    static bool title_has_specific_ext(const std::string& title);

    // TC-1.5: strip IDE variant suffixes (nightly, preview, etc.)
    static std::string strip_ide_suffix(const std::string& name);

    // Read argv[0] from /proc/<pid>/cmdline
    static std::string read_cmdline(pid_t pid);
    // Read the full NUL-delimited command line (needed for training markers
    // such as `python train.py --epochs 20`; argv[0] alone is just "python").
    static std::string read_full_cmdline(pid_t pid);

    static constexpr std::size_t kMaxWarnedCwds = 256;

    // Bounded FIFO dedup set for S3 "unreachable cwd" warnings. Bounded because
    // it only suppresses duplicate log lines; evicting the oldest entry costs at
    // most one repeated warning. Mutex-guarded because from_cwd is static and
    // therefore callable from any thread.
    static std::unordered_set<std::string> s_warned_cwds_;
    static std::deque<std::string>        s_warned_cwd_order_;
    static std::mutex                     s_warned_cwds_mutex_;

    static bool remember_warned_cwd(const std::string& cwd);
};

} // namespace thm
