#!/bin/bash
# =============================================================================
# collector.sh — THM v3 benchmark metric sampler (runs inside the guest)
#
# Samples every --interval-ms and writes one CSV row per tick:
#   • PSI (cpu / memory / io, "some" + "full" avg10)  — kernel stall metrics
#   • MemAvailable / SwapUsed / AnonPages             — memory state
#   • pswpin/pswpout/pgmajfault/pgfault               — swap & fault activity
#   • per-scenario-process state (R/S/T/Z) + RSS      — freeze/kill evidence
#   • THM daemon CPU% + RSS                          — overhead measurement
#   • THM telemetry (pressure level, workloads)      — arm A only
#   • archtitan slice populations                     — arm A only
#   • collector_tick_ms                               — sampler's own latency
#     (a canary: if the sampler itself slows down, the system is stalling)
#
# The tick is deliberately fork-light: every fork/exec under a saturated
# 2-vCPU guest costs milliseconds, so /proc is read with bash builtins and
# the remaining parsing is folded into two awk passes.  A ~50-fork tick
# stretched to 10 s/tick under load in early runs; this version keeps the
# 500 ms sampling grid even while `make -j2` saturates both vCPUs.
#
# usage: collector.sh <outdir> <duration_sec> <pidmap-file> <arm> <phase-file> <builds-file> [interval_ms]
# =============================================================================
set -u

OUTDIR="${1:?}"
DURATION="${2:?}"
PIDMAP="${3:?}"
ARM="${4:?}"
PHASEF="${5:?}"
BUILDSF="${6:?}"
INTERVAL="${7:-500}"

CSV="$OUTDIR/metrics.csv"
PAGESZ=$(getconf PAGESIZE 2>/dev/null || echo 4096)
CLK_TCK=$(getconf CLK_TCK 2>/dev/null || echo 100)

# The sampler must not be starved by the workload it is measuring.
renice -n -10 -p $$ >/dev/null 2>&1 || true

# resolve THM daemon pid once (arm A only)
THM_PID=""
if [ "$ARM" = "A" ]; then
    THM_PID=$(systemctl show -p MainPID --value titan-hwm 2>/dev/null | head -1)
    [ -z "$THM_PID" ] && THM_PID=""
    [ "$THM_PID" = "0" ] && THM_PID=$(pidof titan-hwm-daemon 2>/dev/null | awk '{print $1}')
fi

echo "ts_ms,phase,tick_ms,psi_cpu_some,psi_cpu_full,psi_mem_some,psi_mem_full,psi_io_some,psi_io_full,memavail_mb,swapused_mb,anon_mb,pswpin,pswpout,pgmajfault,pgfault,load1,builds_ok,builds_fail,hog_state,hog_rss_mb,idle1_state,idle1_rss_mb,idle2_state,idle2_rss_mb,probe_state,probe_rss_mb,compile_state,thm_alive,thm_cpu_pct,thm_rss_mb,thm_level,thm_psi_some,thm_mem_used_pct,thm_workloads,thm_frozen_slice_pids,thm_active_pids,thm_background_pids" > "$CSV"

# epoch milliseconds — EPOCHREALTIME is a bash builtin (no fork)
now_ms() {
    local t="${EPOCHREALTIME:-}"
    if [ -n "$t" ]; then
        t=${t//[.,]/}
        echo $(( 10#${t:0:13} ))
    else
        echo $(( $(date +%s%3N) ))
    fi
}

pid_state() { # $1=pid → state char or X  (builtin read, no fork)
    local p="${1:-}" _ _ st
    if [ -n "$p" ] && [ "$p" != "0" ] && read -r _ _ st _ 2>/dev/null < "/proc/$p/stat"; then
        echo "$st"
    else
        echo X
    fi
}

pid_rss_mb() { # $1=pid → RSS in MB with one decimal (integer math, no fork)
    local p="${1:-}" size res _ mb10
    if [ -n "$p" ] && [ "$p" != "0" ] && read -r size res _ 2>/dev/null < "/proc/$p/statm"; then
        mb10=$(( res * PAGESZ * 10 / 1048576 ))
        printf "%d.%d" $(( mb10 / 10 )) $(( mb10 % 10 ))
    else
        echo 0
    fi
}

count_procs() { # $1=slice-name fragment → number of pids in matching slices
    local frag="$1" n=0 line f
    for f in /sys/fs/cgroup/archtitan.slice/**/*"$frag"*/cgroup.procs; do
        [ -r "$f" ] || continue
        while read -r line; do
            [ -n "$line" ] && n=$((n + 1))
        done < "$f"
    done
    echo "$n"
}

shopt -s globstar nullglob

THM_PREV_TICKS=""
THM_PREV_TS=0

START=$(date +%s)
END=$((START + DURATION))
SEQ=0

# audit ends the sampling window early with SIGTERM — leave a completion marker
trap 'echo "COLLECTOR_DONE samples=$SEQ (terminated)" > "$OUTDIR/collector.done"; exit 0' TERM INT

while [ "$(date +%s)" -lt "$END" ]; do
    T0=$(now_ms)
    TS=$T0

    PHASE=unknown
    read -r PHASE 2>/dev/null < "$PHASEF" || PHASE=unknown

    # PSI: one awk over the three pressure files
    read -r PSI_CPU PSI_CPUF PSI_MEM PSI_MEMF PSI_IO PSI_IOF < <(
        awk '
            FNR == 1 { k = FILENAME; sub(".*/", "", k) }
            $1 == "some" || $1 == "full" {
                v = 0
                for (i = 2; i <= NF; i++)
                    if ($i ~ /^avg10=/) { sub("avg10=", "", $i); v = $i; break }
                out[k "_" $1] = v
            }
            END {
                printf "%s %s %s %s %s %s\n",
                    out["cpu_some"], out["cpu_full"],
                    out["memory_some"], out["memory_full"],
                    out["io_some"], out["io_full"]
            }' /proc/pressure/cpu /proc/pressure/memory /proc/pressure/io 2>/dev/null
    )
    [ -z "${PSI_CPU:-}" ] && { PSI_CPU=0; PSI_CPUF=0; PSI_MEM=0; PSI_MEMF=0; PSI_IO=0; PSI_IOF=0; }

    # memory + vmstat + loadavg: one awk over three files
    read -r MEMAVAIL SWAPUSED_MB ANON PSWPIN PSWPOUT PGMAJ PGFAULT LOAD1 < <(
        awk '
            FNR == 1 { k = FILENAME; sub(".*/", "", k) }
            k == "meminfo" && $1 == "MemAvailable:" { ma = $2 }
            k == "meminfo" && $1 == "SwapTotal:"    { st = $2 }
            k == "meminfo" && $1 == "SwapFree:"     { sf = $2 }
            k == "meminfo" && $1 == "AnonPages:"    { an = $2 }
            k == "vmstat"  && $1 == "pswpin"        { pi = $2 }
            k == "vmstat"  && $1 == "pswpout"       { po = $2 }
            k == "vmstat"  && $1 == "pgmajfault"    { mj = $2 }
            k == "vmstat"  && $1 == "pgfault"       { pf = $2 }
            k == "loadavg"                          { ld = $1 }
            END {
                printf "%d %d %d %d %d %d %d %s\n",
                    ma / 1024, (st - sf) / 1024, an / 1024, pi, po, mj, pf, ld
            }' /proc/meminfo /proc/vmstat /proc/loadavg 2>/dev/null
    )
    [ -z "${MEMAVAIL:-}" ] && { MEMAVAIL=0; SWAPUSED_MB=0; ANON=0; PSWPIN=0; PSWPOUT=0; PGMAJ=0; PGFAULT=0; LOAD1=0; }

    BOK=0; BFAIL=0
    read -r _ BOK BFAIL 2>/dev/null < "$BUILDSF" || true
    [ -z "${BOK:-}" ] && BOK=0
    [ -z "${BFAIL:-}" ] && BFAIL=0

    # per-process state + rss from pidmap (name:pid lines)
    declare -A PIDS=()
    if [ -f "$PIDMAP" ]; then
        while IFS=: read -r name pid; do
            [ -n "$name" ] && [ -n "$pid" ] && PIDS[$name]=$pid
        done < "$PIDMAP"
    fi
    HOGPID=${PIDS[hog]:-}
    I1PID=${PIDS[idle1]:-}
    I2PID=${PIDS[idle2]:-}
    PROBEPID=${PIDS[probe]:-}
    MAKEPID=${PIDS[compile]:-}

    HOG_ST=$(pid_state "$HOGPID");    HOG_RSS=$(pid_rss_mb "$HOGPID")
    I1_ST=$(pid_state "$I1PID");      I1_RSS=$(pid_rss_mb "$I1PID")
    I2_ST=$(pid_state "$I2PID");      I2_RSS=$(pid_rss_mb "$I2PID")
    PROBE_ST=$(pid_state "$PROBEPID"); PROBE_RSS=$(pid_rss_mb "$PROBEPID")
    MAKE_ST=$(pid_state "$MAKEPID")

    # THM daemon + telemetry (arm A only)
    THM_ALIVE=""; THM_CPU=""; THM_RSS=""; THM_LVL=""; THM_PSI=""; THM_MEMU=""; THM_WL=""
    FROZ_N=""; ACT_N=""; BG_N=""
    if [ "$ARM" = "A" ]; then
        if [ -n "$THM_PID" ] && [ -d "/proc/$THM_PID" ]; then
            THM_ALIVE=1
            local_stat=()
            read -r -a local_stat 2>/dev/null < "/proc/$THM_PID/stat" || true
            TICKS=$(( ${local_stat[13]:-0} + ${local_stat[14]:-0} ))
            NOWMS=$(now_ms)
            if [ -n "$THM_PREV_TICKS" ] && [ "$THM_PREV_TS" -gt 0 ]; then
                DTICK=$((TICKS - THM_PREV_TICKS))
                DMS=$((NOWMS - THM_PREV_TS))
                if [ "$DMS" -gt 0 ] && [ "$DTICK" -ge 0 ]; then
                    # CPU% = (ticks/CLK_TCK s) / (ms/1000 s) * 100
                    #      = ticks * 100000 / (CLK_TCK * ms)
                    THM_CPU=$(awk -v d="$DTICK" -v ms="$DMS" -v t="$CLK_TCK" 'BEGIN{printf "%.2f", d*100000.0/(t*ms)}')
                else
                    THM_CPU=0
                fi
            else
                THM_CPU=0
            fi
            THM_PREV_TICKS=$TICKS; THM_PREV_TS=$NOWMS
            THM_RSS=$(pid_rss_mb "$THM_PID")
        else
            THM_ALIVE=0
            THM_PID=$(pidof titan-hwm-daemon 2>/dev/null | awk '{print $1}')
        fi
        if [ -f /run/archtitan/thm-state.json ]; then
            JSON=$(</run/archtitan/thm-state.json)
            [[ $JSON =~ \"level\":\"([A-Z]+)\" ]]            && THM_LVL=${BASH_REMATCH[1]}
            [[ $JSON =~ \"psi_some_avg10\":([0-9.]+) ]]      && THM_PSI=${BASH_REMATCH[1]}
            [[ $JSON =~ \"mem_used_pct\":([0-9.]+) ]]        && THM_MEMU=${BASH_REMATCH[1]}
            [[ $JSON =~ \"workload_count\":([0-9]+) ]]       && THM_WL=${BASH_REMATCH[1]}
        fi
        FROZ_N=$(count_procs frozen)
        ACT_N=$(count_procs active)
        BG_N=$(count_procs background)
    fi

    T1=$(now_ms)
    TICK_MS=$((T1 - T0))

    printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
        "$TS" "$PHASE" "$TICK_MS" "$PSI_CPU" "$PSI_CPUF" "$PSI_MEM" "$PSI_MEMF" "$PSI_IO" "$PSI_IOF" \
        "$MEMAVAIL" "$SWAPUSED_MB" "$ANON" "$PSWPIN" "$PSWPOUT" "$PGMAJ" "$PGFAULT" "$LOAD1" \
        "$BOK" "$BFAIL" "$HOG_ST" "$HOG_RSS" "$I1_ST" "$I1_RSS" "$I2_ST" "$I2_RSS" \
        "$PROBE_ST" "$PROBE_RSS" "$MAKE_ST" "$THM_ALIVE" "$THM_CPU" "$THM_RSS" \
        "$THM_LVL" "$THM_PSI" "$THM_MEMU" "$THM_WL" "$FROZ_N" "$ACT_N" "$BG_N" >> "$CSV"

    SEQ=$((SEQ + 1))
    # pace to the next tick boundary
    ELAPSED=$(( $(now_ms) - T0 ))
    REMAIN=$(( INTERVAL - ELAPSED ))
    [ "$REMAIN" -lt 20 ] && REMAIN=20
    SLEEP_S=$(awk -v ms="$REMAIN" 'BEGIN{printf "%.3f", ms/1000}')
    sleep "$SLEEP_S"
done

echo "COLLECTOR_DONE samples=$SEQ" > "$OUTDIR/collector.done"
exit 0
