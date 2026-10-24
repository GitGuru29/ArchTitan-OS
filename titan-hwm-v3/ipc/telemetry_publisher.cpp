// =============================================================================
// titan-hwm-v3/ipc/telemetry_publisher.cpp
// =============================================================================
#include "telemetry_publisher.hpp"

#include <chrono>
#include <cstdio>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <system_error>

namespace fs = std::filesystem;

namespace thm {

namespace {

long long wall_ms() {
    using namespace std::chrono;
    return duration_cast<milliseconds>(system_clock::now().time_since_epoch()).count();
}

// JSON string escaping — enough for cmdline labels / window titles.
std::string esc(const std::string& s) {
    std::string out;
    out.reserve(s.size() + 2);
    for (unsigned char c : s) {
        switch (c) {
            case '"':  out += "\\\""; break;
            case '\\': out += "\\\\"; break;
            case '\n': out += "\\n";  break;
            case '\r': out += "\\r";  break;
            case '\t': out += "\\t";  break;
            default:
                if (c < 0x20) {
                    char buf[8];
                    std::snprintf(buf, sizeof(buf), "\\u%04x", c);
                    out += buf;
                } else {
                    out += static_cast<char>(c);
                }
        }
    }
    return out;
}

// Fixed-precision float without locale surprises.
std::string f2(float v) {
    char buf[32];
    std::snprintf(buf, sizeof(buf), "%.2f", static_cast<double>(v));
    return buf;
}

} // namespace

std::string serialize_snapshot(const TelemetrySnapshot& s) {
    std::ostringstream o;
    o << '{';
    o << "\"version\":\"" << esc(s.version) << '"';
    o << ",\"timestamp_ms\":" << s.timestamp_ms;
    o << ",\"uptime_seconds\":" << s.uptime_seconds;
    o << ",\"pressure\":{"
      << "\"level\":\"" << esc(s.pressure_level) << '"'
      << ",\"psi_some_avg10\":" << f2(s.psi_some_avg10)
      << ",\"psi_full_avg10\":" << f2(s.psi_full_avg10)
      << ",\"mem_used_pct\":"   << f2(s.mem_used_pct)
      << ",\"mem_total_kb\":"   << s.mem_total_kb
      << ",\"mem_available_kb\":" << s.mem_available_kb
      << '}';
    o << ",\"cpu\":{"
      << "\"psi_valid\":"  << (s.cpu_psi_valid ? "true" : "false")
      << ",\"psi_some_avg10\":"  << f2(s.cpu_psi_avg10)
      << ",\"psi_some_avg60\":"  << f2(s.cpu_psi_avg60)
      << ",\"psi_some_avg300\":" << f2(s.cpu_psi_avg300)
      << ",\"load1\":"  << f2(s.load1)
      << ",\"load5\":"  << f2(s.load5)
      << ",\"load15\":" << f2(s.load15)
      << ",\"runnable\":" << s.runnable_procs
      << ",\"total\":"    << s.total_procs
      << '}';
    o << ",\"governor\":\"" << esc(s.governor) << '"';
    o << ",\"workload_count\":" << s.workload_count;
    o << ",\"active_workloads\":" << s.active_workloads;
    o << ",\"classified_workloads\":" << s.classified_workloads;
    o << ",\"observed_workloads\":" << s.observed_workloads;
    o << ",\"processes\":{"
      << "\"seen\":"      << s.processes_seen
      << ",\"protected\":" << s.processes_protected
      << ",\"assigned\":"  << s.processes_assigned
      << ",\"unmanaged\":" << s.processes_unmanaged
      << ",\"hyprland_connected\":" << (s.hyprland_connected ? "true" : "false")
      << '}';

    o << ",\"top_unmanaged\":[";
    for (size_t i = 0; i < s.top_unmanaged.size(); ++i) {
        const auto& u = s.top_unmanaged[i];
        if (i) o << ',';
        o << '{'
          << "\"pid\":"    << u.pid
          << ",\"comm\":\"" << esc(u.comm) << '"'
          << ",\"cpu_pct\":" << f2(u.cpu_pct)
          << ",\"mem_mb\":"  << (u.rss_kb / 1024)
          << ",\"reason\":\"" << esc(u.reason) << '"'
          << '}';
    }
    o << ']';

    o << ",\"last_action\":";
    if (s.has_last_action && !s.last_action.empty()) {
        o << "{\"decision\":\"" << esc(s.last_action) << '"'
          << ",\"target\":\""   << esc(s.last_action_target) << '"'
          << ",\"pid\":"        << s.last_action_pid
          << '}';
    } else {
        o << "null";
    }

    o << ",\"workloads\":[";
    for (size_t i = 0; i < s.workloads.size(); ++i) {
        const auto& w = s.workloads[i];
        if (i) o << ',';
        o << '{'
          << "\"id\":"        << w.id
          << ",\"pid\":"      << w.root_pid
          << ",\"workspace\":" << w.workspace_id
          << ",\"name\":\""   << esc(w.name) << '"'
          << ",\"type\":\""   << esc(w.type) << '"'
          << ",\"state\":\""  << esc(w.state) << '"'
          << ",\"pids\":"     << w.pid_count
          << ",\"mem_mb\":"   << (w.mem_kb / 1024)
          << ",\"cpu_pct\":"  << f2(w.cpu_pct)
          << ",\"observed\":" << (w.observed ? "true" : "false")
          << '}';
    }
    o << "]}";
    return o.str();
}

TelemetryPublisher::TelemetryPublisher(std::string path)
    : path_(std::move(path)) {
    // Optional override, primarily for testing without root (/run write access).
    if (const char* env = std::getenv("THM_TELEMETRY_PATH"); env && *env)
        path_ = env;
}

void TelemetryPublisher::publish(const TelemetrySnapshot& snap, long long min_interval_ms) {
    const std::string payload = serialize_snapshot(snap);
    const long long now = wall_ms();

    if (payload == last_payload_ && (now - last_write_ms_) < min_interval_ms)
        return;

    std::error_code ec;
    fs::path p(path_);
    if (p.has_parent_path())
        fs::create_directories(p.parent_path(), ec);

    const std::string tmp = path_ + ".tmp";
    {
        std::ofstream f(tmp, std::ios::binary | std::ios::trunc);
        if (!f) return;
        f << payload;
        f.flush();
        if (!f) return;
    }
    std::error_code rec;
    fs::rename(tmp, path_, rec);
    if (rec) {
        // Rename can fail across odd mounts; fall back to direct write.
        std::ofstream f(path_, std::ios::binary | std::ios::trunc);
        if (f) f << payload;
    }

    last_payload_  = payload;
    last_write_ms_ = now;
}

} // namespace thm
