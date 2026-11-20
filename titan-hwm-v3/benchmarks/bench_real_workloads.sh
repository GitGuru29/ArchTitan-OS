#!/usr/bin/env bash
# =============================================================================
# THM v3 — real-workload CPU arbitration A/B benchmark
#
# Two REAL CPU-bound workloads run concurrently in delegated user cgroups:
#   foreground: gcc -O2 compile loop  (compiling / building)
#   background: ffmpeg libx264 encodes (render / encode workload)
#
# Background encoders are started and reach steady state BEFORE the foreground
# is timed, so systemd-run startup cost is excluded. Background cost is the
# cpu.stat usage delta during the foreground window, not wall time.
#
# Baseline: equal weights, no quota. Managed: THM-like foreground priority and
# background bandwidth cap (the value from compute_cpu_slice_policy).
#
# Requires: systemd --user (cpu controller delegated), ffmpeg (libx264), gcc,
# awk. No root. Sized for 4 physical cores / 8 logical threads by default.
# =============================================================================
set -euo pipefail

REPS=3
QUOTA="87.5%"          # THM HIGH with no extra demand: (N-1)/N of 8 CPUs
COMPILE_ITER=5
BG_PROCS=4             # one encoder per physical core
FFMPEG_SEC=10
SMT_ISOLATE=0          # --smt-isolate adds a third, affinity-isolated mode
CPUS_FG=""
CPUS_BG=""

usage() {
    cat <<'EOF'
Usage: bench_real_workloads.sh [options]
  --reps N          A/B repetitions (default: 3)
  --quota PCT       managed background CPUQuota (default: 87.5%)
  --compile-iter N  number of gcc -O2 compiles in the timed window (default: 5)
  --bg-procs N      concurrent ffmpeg encoders (default: 4 = physical cores)
  --ffmpeg-sec N    seconds of video per encode (default: 10)
  --smt-isolate     add a managed mode with FG/BG pinned to disjoint physical cores
  -h, --help        show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reps)         REPS="$2"; shift 2 ;;
        --quota)        QUOTA="$2"; shift 2 ;;
        --compile-iter) COMPILE_ITER="$2"; shift 2 ;;
        --bg-procs)     BG_PROCS="$2"; shift 2 ;;
        --ffmpeg-sec)   FFMPEG_SEC="$2"; shift 2 ;;
        --smt-isolate)  SMT_ISOLATE=1; shift ;;
        -h|--help)      usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

for tool in systemd-run systemctl ffmpeg gcc awk; do
    command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 2; }
done

tmp="$(mktemp -d "${TMPDIR:-/tmp/opencode}/thm-realbench.XXXXXX")"
cleanup() {
    systemctl --user kill --signal=TERM "thm-real-bg-$$-"*.scope 2>/dev/null || true
    rm -rf "$tmp"
}
trap cleanup EXIT

# Deterministic compile input, large enough per invocation to be CPU-bound.
{
    echo 'int sink;'
    for ((i = 0; i < 100; i++)); do
        printf 'int f%d(int x){return x*%d+%d;}\n' "$i" "$((i % 97 + 1))" "$i"
    done
} > "$tmp/workload.c"

now_ns() { date +%s%N; }

# Derive physical-core groups from sysfs and split them in half: latency work
# gets whole cores (both SMT siblings), background gets the other cores.
build_cpusets() {
    local cpu ncpu id i half
    declare -A groups=()
    ncpu="$(nproc)"
    for ((cpu = 0; cpu < ncpu; cpu++)); do
        id="$(cat "/sys/devices/system/cpu/cpu${cpu}/topology/core_id" 2>/dev/null || echo "$cpu")"
        if [[ -z "${groups[$id]:-}" ]]; then
            groups[$id]="$cpu"
        else
            groups[$id]="${groups[$id]},${cpu}"
        fi
    done
    mapfile -t ids < <(printf '%s\n' "${!groups[@]}" | sort -n)
    half=$(( ${#ids[@]} / 2 ))
    for ((i = 0; i < half; i++)); do
        CPUS_FG="${CPUS_FG:+${CPUS_FG},}${groups[${ids[$i]}]}"
    done
    for ((i = half; i < ${#ids[@]}; i++)); do
        CPUS_BG="${CPUS_BG:+${CPUS_BG},}${groups[${ids[$i]}]}"
    done
}

if (( SMT_ISOLATE )); then
    build_cpusets
    echo "SMT split on this host: FG=[$CPUS_FG] BG=[$CPUS_BG]"
fi

run_pair() {
    local label="$1" fg_weight="$2" bg_weight="$3" bg_quota="$4" rep="$5"
    local fg_prefix="${6:-}" bg_prefix="${7:-}"
    local bg_unit="thm-real-bg-$$-${rep}-${label}"
    local fg_unit="thm-real-fg-$$-${rep}-${label}"

    local -a bg_props=(-p "CPUWeight=$bg_weight")
    [[ "$bg_quota" != "infinity" ]] && bg_props+=(-p "CPUQuota=$bg_quota")

    # Continuous real render workload: each worker loops libx264 encodes.
    local bg_script="" b
    for ((b = 1; b <= BG_PROCS; b++)); do
        bg_script+="while :; do ${bg_prefix} ffmpeg -y -hide_banner -loglevel error "
        bg_script+="-f lavfi -i testsrc=size=640x360:rate=30 -t ${FFMPEG_SEC} "
        bg_script+="-c:v libx264 -preset veryfast -f null - >/dev/null 2>&1; done & "
    done
    bg_script+="wait"

    systemd-run --user --collect --unit="$bg_unit" --scope \
        "${bg_props[@]}" -- bash -c "$bg_script" >/dev/null 2>&1 &
    local bg_launch_pid=$!

    # Wait for the scope's cgroup to appear, then let the encoders settle.
    local cg="" i
    for ((i = 0; i < 200; i++)); do
        cg="$(systemctl --user show -p ControlGroup --value "${bg_unit}.scope" 2>/dev/null || true)"
        [[ -n "$cg" && -r "/sys/fs/cgroup${cg}/cpu.stat" ]] && break
        sleep 0.02
    done
    if [[ -z "$cg" ]]; then
        echo "background scope never appeared: $bg_unit" >&2
        return 1
    fi
    sleep 0.4

    read_usage() { awk '/^usage_usec/{print $2}' "/sys/fs/cgroup${cg}/cpu.stat"; }
    local bg_before bg_after fg_start fg_end fg_ms bg_cpu_ms
    bg_before="$(read_usage)"

    fg_start="$(now_ns)"
    systemd-run --user --collect --unit="$fg_unit" --scope \
        -p "CPUWeight=$fg_weight" \
        -- bash -c "for ((i=0;i<${COMPILE_ITER};i++)); do ${fg_prefix} gcc -O2 -c '${tmp}/workload.c' -o '${tmp}/workload.o'; done" \
        >"$tmp/fg.log" 2>&1
    fg_end="$(now_ns)"

    bg_after="$(read_usage)"
    systemctl --user kill --signal=TERM "${bg_unit}.scope" 2>/dev/null || true
    wait "$bg_launch_pid" 2>/dev/null || true

    fg_ms=$(( (fg_end - fg_start) / 1000000 ))
    bg_cpu_ms=$(( (bg_after - bg_before) / 1000 ))
    printf '%s,%s,%s,%s,%s,%s,%s\n' \
        "$rep" "$label" "$fg_weight" "$bg_weight" "$bg_quota" "$fg_ms" "$bg_cpu_ms"
}

{
    echo "rep,mode,fg_weight,bg_weight,bg_quota,fg_compile_ms,bg_cpu_ms"
    for ((rep = 1; rep <= REPS; rep++)); do
        run_pair baseline 100 100 infinity "$rep" "" ""
        run_pair managed 1000 10 "$QUOTA" "$rep" "" ""
        if (( SMT_ISOLATE )); then
            # Equal weights + no quota: isolates the physical-core effect from
            # the much larger cpu.weight / cpu.max effect.
            run_pair smt-only 100 100 infinity "$rep" \
                "taskset -c ${CPUS_FG}" "taskset -c ${CPUS_BG}"
            run_pair managed-smt 1000 10 "$QUOTA" "$rep" \
                "taskset -c ${CPUS_FG}" "taskset -c ${CPUS_BG}"
        fi
    done
} | tee "$tmp/results.csv"

awk -F, 'NR>1 {
    key=$2; n[key]++; fg[key]+=$6; bg[key]+=$7
} END {
    printf "\n%-10s %14s %16s\n", "mode", "avg compile", "avg BG cpu";
    for (k in n) printf "%-10s %12.0fms %14.0fms\n", k, fg[k]/n[k], bg[k]/n[k];
    if (n["baseline"] && n["managed"]) {
        printf "\nforeground speedup: %.2fx\n", (fg["baseline"]/n["baseline"])/(fg["managed"]/n["managed"]);
        printf "background CPU:     %.2fx (managed/baseline)\n", (bg["managed"]/n["managed"])/(bg["baseline"]/n["baseline"]);
    }
}' "$tmp/results.csv"
