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
RUNDIR=/bench/results/B-20261112-113119
PROJ=/bench/proj
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
