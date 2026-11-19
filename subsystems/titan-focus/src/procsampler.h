#pragma once

#include "configloader.h"

#include <QString>

namespace titan::focus {

struct ProcSample {
    bool    buildActive = false;
    QString activeBuildProc;
    bool    agentActive = false;
    QString activeAgentProc;
    bool    ideRunning = false;
    bool    meetingProcActive = false;
    bool    mediaPlayerRunning = false;
};

/**
 * ProcSampler — pure POSIX /proc/<pid>/comm scanner (zero subprocesses, zero Python).
 */
class ProcSampler {
public:
    static ProcSample sample(const FocusConfig &cfg);
};

} // namespace titan::focus
