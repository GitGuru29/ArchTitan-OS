#!/bin/bash
# =============================================================================
# scenario.sh — THM v3 A/B/C benchmark scenario (runs inside the guest)
#
# Choreography (durations in seconds; --quick shrinks them):
#
#   phase        | what happens
#   -------------+------------------------------------------------------------
#   warmup       | compile loop + probe + idle apps run without the collector so
#                | the CPU reaches its steady-state frequency (the reference
#                | laptop ramps for ~30-60 s after an idle period) and the
#                | squashfs header cache is hot before any measurement.
#   baseline     | compile loop + 2 idle apps running, no pressure. Reference
#                | metrics for latency/PSI/compile speed.
#   ramp         | memory hog burst-allocates 1.9 GB ("big app opens"), then keeps
#                | growing 200 MB / 10 s until free% < 20 or cap.
#                | THM arm: idle apps + hog get FROZEN at HIGH pressure, so the
#                | hog stops growing and memory stays bounded (V-curve).
#                | No-THM arms: pressure mounts unchecked -> swap thrash ->
#                | kernel OOM killer fires (nondeterministic victim).
#   hold         | pressure window held; recovery / thrash / OOM visible.
#   release      | hog SIGTERM'd ("user closes the tab") -> recovery latency.
#   audit        | survival audit of every scenario process, OOM victim list,
#                | build results, guest-side summary.json (printed to serial).
#
# usage: scenario.sh --arm A|B|C --dir <rundir> [--quick]
# =============================================================================
set -u

ARM=""
RUNDIR=""
QUICK=0
while [ $# -gt 0 ]; do
    case "$1" in
        --arm)  ARM="$2";  shift 2 ;;
        --dir)  RUNDIR="$2"; shift 2 ;;
        --quick) QUICK=1; shift ;;
        *) echo "scenario: unknown arg $1"; exit 2 ;;
    esac
done
[ -z "$ARM" ] && { echo "scenario: --arm required"; exit 2; }
[ -z "$RUNDIR" ] && { echo "scenario: --dir required"; exit 2; }
mkdir -p "$RUNDIR"
cd "$RUNDIR" || exit 2

BENCH=/bench
TS=$BENCH/guest/tstress
# Project lives on the bench disk (0755 root), NOT under /tmp: THM treats a
# world-writable CWD as unattributable ([S3] Ignored CWD) and skips the
# workload, and the resulting per-scan log spam also skews its CPU overhead.
PROJ=$BENCH/proj

# ── tunables (calibrated on the reference VM: 2 vCPU / 4 GB RAM / 2 GB swap) ──
IDLE_MB=400
# Hog: allocate HOG_INIT_MB in one burst (the "app opened a big project" moment),
# then keep growing at a deliberately *slow* pace.  The pace matters: THM only
# freezes workloads that are IDLE (<0.5% CPU), so the steady-state growth has to
# stay cheap (200 MB / 10 s ≈ 0.2% CPU) while still crossing the HIGH threshold.
# 1.9 GB puts MemAvailable at ~18-20% (HIGH = free <25%, CRITICAL = free <15%)
# with enough margin that compiler bursts do not flap the level back to
# MODERATE between rounds.
HOG_INIT_MB=1900
HOG_MAX_MB=4200
HOG_STEP_MB=200
HOG_STEP_SEC=10
HOG_RETOUCH_SEC=3600
# CHAINS/DEPTH calibration (host gcc 16.2.1): chains=12/depth=512 → ~5.4s/TU,
# ~88MB cc1plus RSS. depth per chain = DEPTH-c (501..512), all <= gcc's default
# -fconstexpr-depth=512 so TUs stay in the fast constexpr-fold regime.
NTUS=16
CHAINS=12
DEPTH=512

if [ "$QUICK" = "1" ]; then
    T_WARM=30; T_BASE=25; T_RAMP=90; T_HOLD=45; T_REL=30; T_AUDIT=40
    # quick mode must still cross the HIGH threshold and exercise the freeze
    HOG_MAX_MB=3200; NTUS=6
else
    T_WARM=60; T_BASE=60; T_RAMP=240; T_HOLD=90; T_REL=60; T_AUDIT=60
    # long hold + release: without THM the hog keeps growing past RAM+swap and
    # the kernel OOM killer fires; with THM it is frozen at HIGH and never grows
    HOG_MAX_MB=4600
fi

PHASEF=$RUNDIR/phase
PIDMAP=$RUNDIR/pidmap
BUILDSF=$RUNDIR/builds.count
echo "init" > "$PHASEF"
echo "0 0 0" > "$BUILDSF"

say() { echo "=== [SCENARIO:$ARM] $* ==="; }
# If the shell ever exits early (session killed, unbound var, etc.) leave a
# breadcrumb on the serial console so the transcript shows where it stopped.
trap 'rc=$?; echo "=== [SCENARIO:$ARM] EXIT rc=$rc at: $BASH_COMMAND ==="' EXIT

# ── 0. environment metadata ──────────────────────────────────────────────────
{
    echo "arm=$ARM quick=$QUICK date=$(date -Is)"
    echo "kernel=$(uname -r)"
    echo "cmdline=$(cat /proc/cmdline)"
    echo "nproc=$(nproc)"
    free -m | head -3
    echo "cgroup_v2=$(stat -fc %T /sys/fs/cgroup 2>/dev/null)"
    if command -v titan-hwm-daemon >/dev/null 2>&1; then
        echo "thm_present=yes"
    else
        echo "thm_present=no"
    fi
    if command -v pacman >/dev/null 2>&1; then
        pacman -Q gcc make 2>/dev/null || true
    fi
} > meta.txt 2>&1
say "environment recorded"; cat meta.txt

# ── 1. arm-specific preparation ──────────────────────────────────────────────
case "$ARM" in
    A)
        if ! systemctl is-active --quiet titan-hwm; then
            say "THM not active — starting it"
            systemctl start titan-hwm
            sleep 2
        fi
        if systemctl is-active --quiet titan-hwm; then
            say "ARM A: THM v3 ACTIVE (systemctl: $(systemctl is-active titan-hwm))"
            systemctl status titan-hwm --no-pager | head -14 > thm-service-before.txt 2>&1
            titan-hwm status > thm-status-before.txt 2>&1 || true
            ls /sys/fs/cgroup/archtitan.slice/ > thm-slices-before.txt 2>&1 || true
            THMPID=$(systemctl show -p MainPID --value titan-hwm 2>/dev/null)
            echo "thm_pid=$THMPID" >> meta.txt
            ps -o pid,%cpu,rss,etime,comm -p "$THMPID" >> meta.txt 2>/dev/null || true
        else
            say "FATAL: THM refused to start — aborting arm A"
            exit 3
        fi
        ;;
    B)
        say "ARM B: disabling titan-hwm (isolates the THM variable)"
        # The unit ships as a *real file* in /etc/systemd/system, so
        # `systemctl mask` fails ("File ... already exists" — mask cannot
        # replace a regular unit file with its /dev/null symlink). Remove the
        # unit and its enablement links instead, then reload and make sure the
        # daemon is really gone (Restart= always would resurrect a plain kill).
        systemctl stop titan-hwm 2>/dev/null || true
        rm -f /etc/systemd/system/titan-hwm.service
        rm -f /etc/systemd/system/*.wants/titan-hwm.service
        systemctl daemon-reload 2>/dev/null || true
        systemctl reset-failed titan-hwm 2>/dev/null || true
        sleep 1
        # /proc/<pid>/comm truncates to 15 chars ("titan-hwm-daemo"), so an
        # exact-name pkill never matches; match the full command line.
        pkill -9 -f 'titan-hwm-daemon' 2>/dev/null || true
        sleep 1
        if pgrep -f 'titan-hwm-daemon' >/dev/null 2>&1; then
            say "FATAL: could not disable THM — aborting arm B"
            exit 3
        fi
        say "ARM B: THM disabled — unit removed, no daemon process"
        echo "thm_status=disabled" >> meta.txt
        ;;
    C)
        if command -v titan-hwm-daemon >/dev/null 2>&1; then
            say "FATAL: arm C must run on vanilla Arch (THM found)"
            exit 3
        fi
        say "ARM C: vanilla Arch — THM confirmed absent"
        if ! command -v g++ >/dev/null 2>&1; then
            say "installing gcc/make from repos (network required)"
            ip route | grep -q default && NET=yes || NET=no
            if [ "$NET" = "yes" ]; then
                pacman -Sy --noconfirm --needed gcc make > pacman-install.log 2>&1 || \
                    pacman -Syy --noconfirm --needed gcc make >> pacman-install.log 2>&1 || true
            fi
            if command -v g++ >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
                say "gcc/make installed"
            else
                say "WARNING: gcc/make unavailable — compile loop will be skipped"
            fi
        fi
        ;;
    *) echo "unknown arm $ARM"; exit 2 ;;
esac

# ── 2. swap on the bench disk (uniform across arms) ──────────────────────────
SWAPFILE=$BENCH/swapfile
swapoff "$SWAPFILE" 2>/dev/null || true
rm -f "$SWAPFILE"
if fallocate -l 2G "$SWAPFILE" 2>/dev/null; then
    chmod 600 "$SWAPFILE"
    mkswap "$SWAPFILE" >/dev/null 2>&1
    if swapon -p 5 "$SWAPFILE" 2>/dev/null; then
        say "2G swap enabled on bench disk"
        echo "swap=on" >> meta.txt
    else
        say "WARNING: swapon failed — continuing without swap"
        echo "swap=off" >> meta.txt
    fi
else
    say "WARNING: swapfile creation failed — continuing without swap"
    echo "swap=off" >> meta.txt
fi

# ── 3. compile project + one-TU calibration ───────────────────────────────────
if command -v g++ >/dev/null 2>&1 && command -v make >/dev/null 2>&1; then
    bash "$BENCH/guest/genproject.sh" "$PROJ" "$NTUS" "$CHAINS" "$DEPTH" > project-info.txt
    # The first compile in a live ISO pulls libstdc++ headers through squashfs
    # (cold page cache): ~15-25 s in the VM vs ~5-9 s warm. Throw that away
    # before calibration so the reported per-TU time is steady-state.
    say "warm-up compile (populates squashfs header cache before calibration)"
    WARM_T0=$(date +%s%3N)
    g++ -O1 -c -std=c++20 -w "$PROJ/tu0.cpp" -o "$PROJ/warmup.o" >/dev/null 2>&1 || true
    WARM_T1=$(date +%s%3N)
    rm -f "$PROJ/warmup.o"
    say "warm-up compile: $(( WARM_T1-WARM_T0 )) ms (excluded from metrics)"
    # Two calibration passes.  The reference laptop's CPU governor ramps over
    # ~30-60 s of sustained load, so the *first* pass after boot is still slow;
    # only the second (steady-state) value is recorded as calib_tu_ms.
    say "calibrating one TU x2 (second pass recorded)"
    CAL_RSS=0
    CAL_MS=0
    CAL_RC=0
    for pass in 1 2; do
        CAL_T0=$(date +%s%3N)
        g++ -O1 -c -std=c++20 -w "$PROJ/tu0.cpp" -o "$PROJ/cal.o" &
        GP=$!
        # sample g++ driver AND its cc1plus child (the real memory consumer)
        for n in $(seq 1 40); do
            for p in $GP $(pgrep -P "$GP" 2>/dev/null); do
                R=$(awk -v p=4096 '{printf "%d", $2*p/1048576}' "/proc/$p/statm" 2>/dev/null || echo 0)
                [ "$R" -gt "$CAL_RSS" ] 2>/dev/null && CAL_RSS=$R
            done
            kill -0 "$GP" 2>/dev/null || break
            sleep 0.5
        done
        wait "$GP" 2>/dev/null
        CAL_RC=$?
        CAL_T1=$(date +%s%3N)
        CAL_MS=$((CAL_T1-CAL_T0))
        rm -f "$PROJ/cal.o"
        say "calibration pass $pass: ${CAL_MS} ms (peak cc1plus RSS ${CAL_RSS} MB)"
    done
    echo "calib_tu_ms=$CAL_MS calib_tu_rss_mb=$CAL_RSS calib_exit=$CAL_RC" > calibration.txt
    say "calibration: $(cat calibration.txt)"
else
    echo "compile_workload=SKIPPED_NO_GCC" > calibration.txt
fi

# ── 4. compile loop ──────────────────────────────────────────────────────────
STOPF=$RUNDIR/STOP_COMPILE
rm -f "$STOPF"
cat > compile-loop.sh <<'EOF'
#!/bin/bash
# Runs make rounds until STOP_COMPILE appears; records per-round outcome + wall
# time.
#
# THM classifies a process as SYSTEM_DEV if any of its descendants (depth-3
# child walk) is a build command.  A loop shell that is the parent of `make` is
# therefore itself tagged SYSTEM_DEV, looks IDLE while it waits, and gets
# SIGSTOPped at HIGH pressure — which stalls the loop between rounds.  Each
# round's `make` is double-forked to PID 1 so this controller never has a build
# command in its subtree; make/cc1plus stay tracked via their CWD markers.
RUNDIR=__RUNDIR__
PROJ=__PROJ__
echo "0 0 0" > "$RUNDIR/builds.count"
R=0; OK=0; FAIL=0
while [ ! -e "$RUNDIR/STOP_COMPILE" ]; do
    T0=$(date +%s%3N)
    rm -f "$RUNDIR/round.pid"
    # double-fork: the subshell exits immediately, make is reparented to init
    ( exec make -j2 -C "$PROJ" > "$RUNDIR/last-build.log" 2>&1 & echo $! > "$RUNDIR/round.pid" )
    RP=$(cat "$RUNDIR/round.pid" 2>/dev/null)
    while [ -n "$RP" ] && kill -0 "$RP" 2>/dev/null; do
        [ -e "$RUNDIR/STOP_COMPILE" ] && kill -TERM "$RP" 2>/dev/null
        sleep 0.2
    done
    T1=$(date +%s%3N)
    # make's exit status is lost with the reparent, so read it off the log
    if grep -q 'make: \*\*\*' "$RUNDIR/last-build.log" 2>/dev/null; then
        ST=FAIL; FAIL=$((FAIL+1))
    else
        ST=ok; OK=$((OK+1))
    fi
    R=$((R+1))
    # wall time in milliseconds (summarize.py reports median round ms)
    echo -e "$R\t$ST\t$(( T1-T0 ))" >> "$RUNDIR/builds.tsv"
    echo "$R $OK $FAIL" > "$RUNDIR/builds.count"
    # equivalent of `make clean` (rm -rf build) without spawning a build command
    rm -rf "$PROJ/build"
done
EOF
sed -i "s|__RUNDIR__|$RUNDIR|; s|__PROJ__|$PROJ|" compile-loop.sh
chmod +x compile-loop.sh

if [ ! -f calibration.txt ] || ! grep -q SKIPPED calibration.txt; then
    # Detach the loop driver from this shell (double-fork → parent becomes PID 1)
    # for the same reason: the scenario must not have a build command in its
    # descendant tree, or THM would classify *the scenario* and freeze it.
    ( bash compile-loop.sh >> compile.log 2>&1 & echo "compile:$!" >> "$PIDMAP" )
    say "compile loop started (detached from THM ownership tree; make -j2 rounds)"
else
    printf '0\tSKIPPED\t0\n' > builds.tsv
    say "compile loop SKIPPED (no gcc)"
fi

# ── 5. probe + idle apps ─────────────────────────────────────────────────────
# idle apps run with CWD=$PROJ: THM's classifier attributes processes by project
# markers in their CWD (CMakeLists.txt), and only attributed workloads can be
# throttled/frozen.  Running them from the results dir left them NEUTRAL and
# invisible to THM — the freeze path then never fired.
( cd "$PROJ" && exec $TS idle-app --mb $IDLE_MB --id idle1 > $RUNDIR/idle1-stdout.log 2>&1 ) &
echo "idle1:$!" >> "$PIDMAP"
( cd "$PROJ" && exec $TS idle-app --mb $IDLE_MB --id idle2 > $RUNDIR/idle2-stdout.log 2>&1 ) &
echo "idle2:$!" >> "$PIDMAP"
# The latency probe is the *control* task: it must measure the system's
# responsiveness, not THM's opinion of it.  CWD=$RUNDIR leaves it NEUTRAL, and
# root-owned NEUTRAL processes are never turned into observed workloads, so THM
# never freezes it.  (With CWD=$PROJ it was classified SYSTEM_DEV and, at ~4%
# CPU, intermittently crossed THM's 0.5% idle line and was SIGSTOPped.)
( cd "$RUNDIR" && exec $TS probe --period-ms 100 --work-mb 32 --csv $RUNDIR/probe.csv > $RUNDIR/probe-stdout.log 2>&1 ) &
echo "probe:$!" >> "$PIDMAP"
say "probe (untracked control task) + 2 idle apps (${IDLE_MB}MB each, CWD=$PROJ) started"

# ── 6. THM journal follower (arm A evidence) ──────────────────────────────────
if [ "$ARM" = "A" ]; then
    (journalctl -u titan-hwm -f -o short-precise > $RUNDIR/thm-journal.log 2>&1) &
    echo "journal:$!" >> "$PIDMAP"
fi

# ── 6. phase timeline (wallclock) — host joins probe.csv rows to phases ─────
echo -e "$(date +%s%3N)\tinit" > phase-timeline.tsv
note_phase() { echo -e "$(date +%s%3N)\t$1" >> phase-timeline.tsv; }

# ── PHASE: warmup (not sampled) ───────────────────────────────────────────────
# Let the CPU reach steady-state frequency and the build loop reach steady
# state before the first measured row.  The reference laptop ramps for ~30-60 s
# after an idle period; measuring during the ramp made arm-to-arm absolute
# numbers meaningless (a cold first TU took 3-4x a warm one).
echo "warmup" > "$PHASEF"; note_phase warmup
say "PHASE warmup (${T_WARM}s, not sampled) — CPU frequency / cache ramp"
sleep "$T_WARM"

# ── 7. collector ─────────────────────────────────────────────────────────────
TOTAL=$(( T_BASE + T_RAMP + T_HOLD + T_REL + T_AUDIT + 30 ))
bash $BENCH/guest/collector.sh "$RUNDIR" "$TOTAL" "$PIDMAP" "$ARM" "$PHASEF" "$BUILDSF" 500 &
COLPID=$!
say "collector started (pid $COLPID, ${TOTAL}s budget)"

free_pct() {
    awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {if (t>0) printf "%.1f", a*100.0/t}' /proc/meminfo
}

# ── PHASE: baseline ──────────────────────────────────────────────────────────
echo "baseline" > "$PHASEF"; note_phase baseline
say "PHASE baseline (${T_BASE}s) — reference metrics"
sleep "$T_BASE"

# ── PHASE: ramp ──────────────────────────────────────────────────────────────
echo "ramp" > "$PHASEF"; note_phase ramp
say "PHASE ramp — hog burst ${HOG_INIT_MB}MB then ${HOG_STEP_MB}MB/${HOG_STEP_SEC}s (cap ${HOG_MAX_MB}MB)"
( cd "$PROJ" && exec $TS hog --initial-mb $HOG_INIT_MB --max-mb $HOG_MAX_MB \
        --step-mb $HOG_STEP_MB --step-sec $HOG_STEP_SEC \
        --retouch-sec $HOG_RETOUCH_SEC --status-file $RUNDIR/hog.status \
        > $RUNDIR/hog-stdout.log 2>&1 ) &
echo "hog:$!" >> "$PIDMAP"
RAMP_T0=$(date +%s)
while [ $(( $(date +%s) - RAMP_T0 )) -lt "$T_RAMP" ]; do
    FP=$(free_pct)
    ALLOC=$(grep -o 'alloc_mb=[0-9]*' "$RUNDIR/hog.status" 2>/dev/null | cut -d= -f2)
    [ -z "$ALLOC" ] && ALLOC=0
    ELAPSED=$(( $(date +%s) - RAMP_T0 ))
    say "ramp: hog=${ALLOC}MB, free=${FP}% (${ELAPSED}s/${T_RAMP}s)"
    if [ "$ALLOC" -ge "$HOG_MAX_MB" ]; then say "hog reached cap (${ALLOC}MB)"; break; fi
    if awk -v f="$FP" 'BEGIN{exit !(f < 20)}'; then say "free pct ${FP}% < 20% — ramp complete"; break; fi
    sleep 5
done
say "ramp end: hog=$(grep -o 'alloc_mb=[0-9]*' "$RUNDIR/hog.status" 2>/dev/null) free=$(free_pct)%"

# ── PHASE: hold ──────────────────────────────────────────────────────────────
echo "hold" > "$PHASEF"; note_phase hold
say "PHASE hold (${T_HOLD}s) — pressure window (free: $(free_pct)%)"
sleep "$T_HOLD"

# ── PHASE: release ────────────────────────────────────────────────────────────
echo "release" > "$PHASEF"; note_phase release
HOGPID=$(grep '^hog:' "$PIDMAP" | cut -d: -f2)
if [ -n "$HOGPID" ] && kill -0 "$HOGPID" 2>/dev/null; then
    say "PHASE release — SIGTERM hog (simulates user closing the app)"
    kill -TERM "$HOGPID" 2>/dev/null
    # If THM froze the hog, it is SIGSTOPped (and possibly cgroup-frozen):
    # SIGTERM stays pending until it can run again. Nudge it, then force it.
    kill -CONT "$HOGPID" 2>/dev/null
    for _ in 1 2 3 4 5 6; do kill -0 "$HOGPID" 2>/dev/null || break; sleep 0.5; done
    if kill -0 "$HOGPID" 2>/dev/null; then
        say "hog survived TERM (frozen by THM) — SIGKILL (force quit)"
        kill -KILL "$HOGPID" 2>/dev/null
    fi
else
    say "PHASE release — hog already dead (state evidence in metrics.csv)"
fi
sleep "$T_REL"
say "post-release free: $(free_pct)%"

# ── PHASE: audit ──────────────────────────────────────────────────────────────
echo "audit" > "$PHASEF"; note_phase audit
say "PHASE audit — stopping compile loop"
# Snapshot the journal first: if the serial session ever dies mid-audit this
# file still explains why (logind / OOM / THM messages).
journalctl -b --no-pager -n 400 > journal-tail-audit.log 2>/dev/null || true

# stop the journal follower (evidence file is complete)
JPID=$(grep '^journal:' "$PIDMAP" | cut -d: -f2)
[ -n "$JPID" ] && kill -TERM "$JPID" 2>/dev/null
echo "AUDIT step=1 journal-follower-stopped"
touch "$STOPF"
AUDIT_T0=$(date +%s)
while [ $(( $(date +%s) - AUDIT_T0 )) -lt 30 ]; do
    pgrep -x make >/dev/null 2>&1 || break
    sleep 2
done
echo "AUDIT step=2 compile-stop (waited $(( $(date +%s) - AUDIT_T0 ))s)"
# kill the loop driver first so it cannot start another round, then stragglers
LOOPPID=$(grep '^compile:' "$PIDMAP" | cut -d: -f2)
[ -n "$LOOPPID" ] && kill -TERM "$LOOPPID" 2>/dev/null
pkill -9 -x make 2>/dev/null; pkill -9 -x cc1plus 2>/dev/null; pkill -9 -x g++ 2>/dev/null
echo "AUDIT step=3 compilers-killed"

sleep 3
say "stopping probe + collector"
PROBEPID=$(grep '^probe:' "$PIDMAP" | cut -d: -f2)
[ -n "$PROBEPID" ] && kill -TERM "$PROBEPID" 2>/dev/null
sleep 3
[ -n "${COLPID:-}" ] && kill -TERM "$COLPID" 2>/dev/null
wait "$COLPID" 2>/dev/null
echo "AUDIT step=4 probe-collector-stopped"

# survival audit (single kernel-log snapshot instead of one journalctl per pid)
KLOG=kernel-log-tail.log
journalctl -k --no-pager > "$KLOG" 2>/dev/null || true
{
    echo -e "name\tpid\talive\tfinal_state\toom_killed"
    while IFS=: read -r name pid; do
        case "$name" in journal) continue ;; esac
        if [ -d "/proc/$pid" ]; then ALIVE=yes; ST=$(awk '{print $3}' "/proc/$pid/stat" 2>/dev/null); else ALIVE=no; ST=gone; fi
        OOM=no
        grep -q "Killed process $pid " "$KLOG" 2>/dev/null && OOM=maybe
        echo -e "$name\t$pid\t$ALIVE\t$ST\t$OOM"
    done < "$PIDMAP"
} > survival.tsv
say "survival audit:"; cat survival.tsv

# kernel OOM events
journalctl -k --no-pager 2>/dev/null | grep -iE "out of memory|oom-kill|killed process" > oom-events.log || true
OOMN=$(grep -c "Killed process" oom-events.log 2>/dev/null || echo 0)
say "kernel OOM kill events: $OOMN"
[ -s oom-events.log ] && tail -20 oom-events.log

# THM final state (arm A)
if [ "$ARM" = "A" ]; then
    titan-hwm status > thm-status-after.txt 2>&1 || true
    cp /run/archtitan/thm-state.json thm-state-final.json 2>/dev/null || true
    systemctl status titan-hwm --no-pager | head -14 > thm-service-after.txt 2>&1
fi

# ── guest-side summary.json ──────────────────────────────────────────────────
awk -v oomn="$OOMN" -v arm="$ARM" '
BEGIN { FS="," }
NR>1 {
    if ($10+0 < minma || minma==0) { minma=$10+0; minma_ts=$1 }
    if ($6+0 > pkms) pkms=$6+0
    if ($7+0 > pkmf) pkmf=$7+0
    stall += $7 * 0.5 / 100
    if ($11+0 > swpk) swpk=$11+0
    if ($21+0 > hogmax) hogmax=$21+0
    if ($20=="T") hogfrozen++
    if ($22=="T" || $24=="T") idlefrozen++
    if ($29=="1") thmalive=1
    if ($30!="" ) { thmc += $30+0; thmn++; if ($31+0 > thmrss) thmrss=$31+0 }
    pswpin=$13; pswpout=$14; pgmaj=$16
    if ($3 > tickmax) tickmax=$3
}
END {
    printf "{\n"
    printf "  \"arm\": \"%s\",\n", arm
    printf "  \"min_memavail_mb\": %.0f,\n", minma
    printf "  \"min_memavail_ts\": %s,\n", minma_ts
    printf "  \"peak_psi_mem_some\": %.2f,\n", pkms
    printf "  \"peak_psi_mem_full\": %.2f,\n", pkmf
    printf "  \"psi_full_stall_seconds\": %.1f,\n", stall
    printf "  \"peak_swapused_mb\": %.0f,\n", swpk
    printf "  \"pswpin_total\": %d,\n", pswpin
    printf "  \"pswpout_total\": %d,\n", pswpout
    printf "  \"pgmajfault_total\": %d,\n", pgmaj
    printf "  \"hog_max_rss_mb\": %.0f,\n", hogmax
    printf "  \"hog_frozen_samples\": %d,\n", hogfrozen+0
    printf "  \"idle_frozen_samples\": %d,\n", idlefrozen+0
    printf "  \"collector_tick_ms_max\": %.0f,\n", tickmax+0
    if (thmn>0) printf "  \"thm_daemon_avg_cpu\": %.2f,\n", thmc/thmn
    if (thmn>0) printf "  \"thm_daemon_max_rss_mb\": %.0f,\n", thmrss
    printf "  \"thm_alive\": %d,\n", thmalive+0
    printf "  \"oom_kills\": %d\n", oomn+0
    printf "}\n"
}' metrics.csv > summary.json

say "=== GUEST SUMMARY (arm $ARM) ==="
cat summary.json

# ── release bench-disk resources (so the host can unmount cleanly) ───────────
# The swapfile and every workload CWD live on /bench; both keep the mount busy.
pkill -9 -x tstress 2>/dev/null || true
pkill -9 -f 'compile-loop.sh' 2>/dev/null || true
timeout 60 swapoff "$SWAPFILE" 2>/dev/null || true
rm -f "$SWAPFILE" 2>/dev/null || true
sync
cd /
say "bench resources released (swap off, workloads stopped)"

echo "SCENARIO_COMPLETE arm=$ARM"
sync
exit 0
