// =============================================================================
// titan-hwm-v3/ipc/command_server.hpp
//
// Minimal UNIX-domain command server for the `titan-hwm` CLI.
//
// The v3 daemon is an autonomous loop with no user-facing control channel.
// This server restores one: it listens on a well-known socket, reads a single
// command line per connection, and returns a text reply produced by a handler
// callback supplied by the daemon. The daemon owns the live state, so it is the
// only place that can answer truthfully.
// =============================================================================
#pragma once

#include <atomic>
#include <functional>
#include <string>
#include <thread>

namespace thm {

class CommandServer {
public:
    // Handler receives the raw command string and returns the reply body.
    using Handler = std::function<std::string(const std::string&)>;

    explicit CommandServer(std::string path = "/tmp/titan_hwm.sock");
    ~CommandServer();

    CommandServer(const CommandServer&) = delete;
    CommandServer& operator=(const CommandServer&) = delete;

    void set_handler(Handler handler) { handler_ = std::move(handler); }

    // Bind the socket and start the accept loop. Returns false on failure.
    bool start();

    // Stop the accept loop and remove the socket file.
    void stop();

    const std::string& path() const { return path_; }

private:
    void loop();

    std::string        path_;
    int                listen_fd_ = -1;
    std::atomic<bool>  running_{false};
    std::thread        thread_;
    Handler            handler_;
};

} // namespace thm
