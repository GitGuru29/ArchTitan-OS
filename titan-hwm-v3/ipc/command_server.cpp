// =============================================================================
// titan-hwm-v3/ipc/command_server.cpp
// =============================================================================
#include "command_server.hpp"

#include <cerrno>
#include <cstring>
#include <iostream>

#include <poll.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/un.h>
#include <unistd.h>

namespace thm {

CommandServer::CommandServer(std::string path) : path_(std::move(path)) {}

CommandServer::~CommandServer() { stop(); }

bool CommandServer::start() {
    if (running_.load())
        return true;

    // Remove a stale socket left behind by a previous crash.
    ::unlink(path_.c_str());

    listen_fd_ = ::socket(AF_UNIX, SOCK_STREAM, 0);
    if (listen_fd_ < 0) {
        std::cerr << "[CMD] socket() failed: " << std::strerror(errno) << "\n";
        return false;
    }

    struct sockaddr_un addr{};
    addr.sun_family = AF_UNIX;
    std::strncpy(addr.sun_path, path_.c_str(), sizeof(addr.sun_path) - 1);

    if (::bind(listen_fd_, reinterpret_cast<struct sockaddr*>(&addr),
               sizeof(addr)) < 0) {
        std::cerr << "[CMD] bind(" << path_ << ") failed: "
                  << std::strerror(errno) << "\n";
        ::close(listen_fd_);
        listen_fd_ = -1;
        return false;
    }

    // World-connectable: the CLI may run as an unprivileged user. Commands are
    // read-only status queries, so no write authority is exposed here.
    ::chmod(path_.c_str(), 0666);

    if (::listen(listen_fd_, 8) < 0) {
        std::cerr << "[CMD] listen() failed: " << std::strerror(errno) << "\n";
        ::close(listen_fd_);
        listen_fd_ = -1;
        ::unlink(path_.c_str());
        return false;
    }

    running_ = true;
    thread_ = std::thread(&CommandServer::loop, this);
    std::cout << "[CMD] Command socket listening on " << path_ << "\n";
    return true;
}

void CommandServer::stop() {
    if (!running_.exchange(false))
        return;

    if (thread_.joinable())
        thread_.join();

    if (listen_fd_ >= 0) {
        ::close(listen_fd_);
        listen_fd_ = -1;
    }
    ::unlink(path_.c_str());
}

void CommandServer::loop() {
    while (running_.load()) {
        struct pollfd pfd{};
        pfd.fd = listen_fd_;
        pfd.events = POLLIN;

        int pr = ::poll(&pfd, 1, 500 /* ms */);
        if (pr <= 0)
            continue; // timeout or EINTR — re-check running_
        if (!(pfd.revents & POLLIN))
            continue;

        int cfd = ::accept(listen_fd_, nullptr, nullptr);
        if (cfd < 0)
            continue;

        char buf[1024];
        ssize_t n = ::read(cfd, buf, sizeof(buf) - 1);
        if (n > 0) {
            buf[n] = '\0';
            std::string cmd(buf, static_cast<size_t>(n));

            // Trim trailing whitespace/newlines.
            while (!cmd.empty() &&
                   (cmd.back() == '\n' || cmd.back() == '\r' ||
                    cmd.back() == ' ' || cmd.back() == '\t'))
                cmd.pop_back();

            std::string reply;
            if (handler_)
                reply = handler_(cmd);
            else
                reply = "titan-hwm: no handler installed\n";

            ssize_t off = 0;
            while (off < static_cast<ssize_t>(reply.size())) {
                ssize_t w = ::write(cfd, reply.data() + off, reply.size() - off);
                if (w <= 0)
                    break;
                off += w;
            }
        }
        ::close(cfd);
    }
}

} // namespace thm
