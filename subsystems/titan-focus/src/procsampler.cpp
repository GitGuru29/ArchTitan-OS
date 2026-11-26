#include "procsampler.h"

#include <cctype>
#include <dirent.h>
#include <fcntl.h>
#include <string>
#include <unistd.h>
#include <unordered_set>

namespace titan::focus {

namespace {

bool isNumericName(const char *name) {
    if (!name || !*name) return false;
    for (const char *p = name; *p; ++p) {
        if (!std::isdigit(static_cast<unsigned char>(*p))) return false;
    }
    return true;
}

std::string readComm(const char *pidStr) {
    std::string path = "/proc/";
    path += pidStr;
    path += "/comm";

    const int fd = ::open(path.c_str(), O_RDONLY | O_CLOEXEC);
    if (fd < 0) return {};

    char buf[128];
    const ssize_t n = ::read(fd, buf, sizeof(buf) - 1);
    ::close(fd);
    if (n <= 0) return {};

    buf[n] = '\0';
    std::string s(buf);
    while (!s.empty() && (s.back() == '\n' || s.back() == '\r')) {
        s.pop_back();
    }
    return s;
}

std::string toLowerAscii(std::string s) {
    for (char &c : s) {
        c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
    }
    return s;
}

std::unordered_set<std::string> toLowerSet(const QStringList &list) {
    std::unordered_set<std::string> out;
    out.reserve(static_cast<size_t>(list.size()));
    for (const QString &q : list) {
        out.insert(q.toLower().toStdString());
    }
    return out;
}

} // namespace

ProcSample ProcSampler::sample(const FocusConfig &cfg) {
    ProcSample res;

    const auto builds   = toLowerSet(cfg.buildDaemons);
    const auto agents   = toLowerSet(cfg.aiInference);
    const auto ides     = toLowerSet(cfg.knownIdes);
    const auto meetings = toLowerSet(cfg.meetingApps);

    static const std::unordered_set<std::string> kMediaPlayers = {
        "mpv", "vlc", "celluloid", "totem", "smplayer"
    };

    DIR *dir = ::opendir("/proc");
    if (!dir) return res;

    while (struct dirent *ent = ::readdir(dir)) {
        if (!isNumericName(ent->d_name)) continue;

        const std::string comm = readComm(ent->d_name);
        if (comm.empty()) continue;

        const std::string low = toLowerAscii(comm);

        if (!res.buildActive && builds.count(low) > 0) {
            res.buildActive = true;
            res.activeBuildProc = QString::fromStdString(comm);
        }
        if (!res.agentActive && agents.count(low) > 0) {
            res.agentActive = true;
            res.activeAgentProc = QString::fromStdString(comm);
        }
        if (!res.ideRunning && ides.count(low) > 0) {
            res.ideRunning = true;
        }
        if (!res.meetingProcActive && meetings.count(low) > 0) {
            res.meetingProcActive = true;
        }
        if (!res.mediaPlayerRunning && kMediaPlayers.count(low) > 0) {
            res.mediaPlayerRunning = true;
        }
    }

    ::closedir(dir);
    return res;
}

} // namespace titan::focus
