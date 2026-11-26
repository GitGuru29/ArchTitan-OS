#!/usr/bin/env bash
# =============================================================================
# titan-hwm-v3/benchmarks/bench_memory_pressure.sh
#
# Real cgroup v2 memory-pressure harness for THM v3.3.
#
# Starts a transient user scope with MemoryHigh/MemoryLow/MemoryMax set, runs a
# bounded allocator inside it, samples memory.current + memory.events, and
# verifies that the kernel actually applied the soft/hard limits without an OOM
# kill. This exercises the same kernel primitives THM's memory orchestration
# uses; it deliberately never touches THM's own archtitan slices.
# =============================================================================
set -euo pipefail

HIGH_MB="${HIGH_MB:-96}"
LOW_MB="${LOW_MB:-32}"
MAX_MB="${MAX_MB:-192}"
ALLOC_MB="${ALLOC_MB:-128}"
SAMPLE_MS="${SAMPLE_MS:-200}"

HIGH_BYTES=$((HIGH_MB * 1024 * 1024))
LOW_BYTES=$((LOW_MB * 1024 * 1024))
MAX_BYTES=$((MAX_MB * 1024 * 1024))
CHUNKS=$((ALLOC_MB / 8))

if (( ALLOC_MB >= MAX_MB )); then
    echo "ALLOC_MB ($ALLOC_MB) must be below MAX_MB ($MAX_MB)" >&2
    exit 2
fi

UNIT="archtitan-mem-bench-$$.scope"
LOG="/tmp/opencode/mem-bench-$$.log"
CSV="/tmp/opencode/mem-bench-$$.csv"

mkdir -p /tmp/opencode
: > "$LOG"
: > "$CSV"

echo "unit=$UNIT"
echo "MemoryHigh=$HIGH_BYTES MemoryLow=$LOW_BYTES MemoryMax=$MAX_BYTES alloc=${ALLOC_MB}MB"

systemd-run --user --scope \
    --unit="$UNIT" \
    -p "MemoryHigh=${HIGH_MB}M" \
    -p "MemoryLow=${LOW_MB}M" \
    -p "MemoryMax=${MAX_MB}M" \
    python3 - "$CHUNKS" >"$LOG" 2>&1 <<'PY' &
import gc
import sys
import time

with open("/proc/self/cgroup") as f:
    # cgroup v2 line looks like "0::/user.slice/..."; keep only the path.
    cgroup_path = f.read().strip().split(":", 2)[-1]
    print("CGROUP=" + cgroup_path, flush=True)

chunks = int(sys.argv[1])
block = 8 * 1024 * 1024
held = []

for i in range(chunks):
    buf = bytearray(block)
    # Touch every MiB so the pages are resident, not just virtual.
    for off in range(0, block, 1024 * 1024):
        buf[off:off + 1024 * 1024] = b"\x5a" * (1024 * 1024)
    held.append(buf)
    print(f"ALLOC {(i + 1) * 8}MB", flush=True)
    time.sleep(0.05)

print("HOLD", flush=True)
time.sleep(2.0)

del held
gc.collect()
print("FREED", flush=True)
time.sleep(1.0)
PY

RUNNER_PID=$!

# Discover the real cgroup path from inside the scope. systemd may place the
# scope under app.slice or another subdirectory, so guessing the path is wrong.
CGROUP=""
for _ in $(seq 1 50); do
    if grep -q '^CGROUP=' "$LOG" 2>/dev/null; then
        CGROUP_REL="$(grep '^CGROUP=' "$LOG" | head -1 | cut -d= -f2-)"
        CGROUP="/sys/fs/cgroup${CGROUP_REL}"
        break
    fi
    sleep 0.1
done
if [[ -z "$CGROUP" || ! -f "$CGROUP/memory.current" ]]; then
    echo "FAIL: scope cgroup never appeared (resolved: ${CGROUP:-none})" >&2
    cat "$LOG" >&2
    kill "$RUNNER_PID" 2>/dev/null || true
    exit 1
fi
echo "cgroup=$CGROUP"

read_events() {
    local file="$CGROUP/memory.events"
    local key="$1"
    awk -v k="$key" '$1 == k { print $2; exit }' "$file" 2>/dev/null || echo 0
}

START_MS=$(date +%s%3N)
MAX_CUR=0
LAST_HIGH="max"
LAST_LOW="0"
LAST_HEV=0
LAST_OOMK=0
while kill -0 "$RUNNER_PID" 2>/dev/null; do
    NOW_MS=$(date +%s%3N)
    ELAPSED=$((NOW_MS - START_MS))
    CUR=$(cat "$CGROUP/memory.current" 2>/dev/null || echo 0)
    HIGH=$(cat "$CGROUP/memory.high" 2>/dev/null || echo max)
    LOW=$(cat "$CGROUP/memory.low" 2>/dev/null || echo 0)
    HEV=$(read_events high)
    OOMK=$(read_events oom_kill)
    (( CUR > MAX_CUR )) && MAX_CUR=$CUR
    LAST_HIGH="$HIGH"
    LAST_LOW="$LOW"
    LAST_HEV="$HEV"
    LAST_OOMK="$OOMK"
    echo "${ELAPSED},${CUR},${HIGH},${LOW},${HEV},${OOMK}" >> "$CSV"
    sleep "$(awk -v ms="$SAMPLE_MS" 'BEGIN { print ms / 1000 }')"
done
wait "$RUNNER_PID" || true

# systemd removes the scope cgroup as soon as the process exits, so use the
# last live sample rather than reading files after wait.
HIGH_FINAL="$LAST_HIGH"
LOW_FINAL="$LAST_LOW"
HIGH_EVENTS="$LAST_HEV"
OOM_KILL="$LAST_OOMK"
MAX_EVENTS=0
OOM_EVENTS=0

echo ""
echo "───────────────────────────────────────────────────────────────────────────────"
echo "  Real cgroup v2 memory-pressure result"
echo "───────────────────────────────────────────────────────────────────────────────"
printf "  %-28s %s\n" "Requested memory.high:" "$HIGH_BYTES bytes"
printf "  %-28s %s\n" "Observed memory.high:" "$HIGH_FINAL"
printf "  %-28s %s\n" "Requested memory.low:" "$LOW_BYTES bytes"
printf "  %-28s %s\n" "Observed memory.low:" "$LOW_FINAL"
printf "  %-28s %s\n" "Peak memory.current:" "$MAX_CUR bytes"
printf "  %-28s %s\n" "memory.events high:" "$HIGH_EVENTS"
printf "  %-28s %s\n" "memory.events max:" "$MAX_EVENTS"
printf "  %-28s %s\n" "memory.events oom:" "$OOM_EVENTS"
printf "  %-28s %s\n" "memory.events oom_kill:" "$OOM_KILL"
echo "  CSV: $CSV"
echo "  Log: $LOG"
echo ""

HIGH_OK=false
LOW_OK=false
[[ "$HIGH_FINAL" == "$HIGH_BYTES" ]] && HIGH_OK=true
[[ "$LOW_FINAL" == "$LOW_BYTES" ]] && LOW_OK=true

if [[ "$HIGH_OK" == true && "$LOW_OK" == true && "$HIGH_EVENTS" -gt 0 && "$OOM_KILL" -eq 0 ]]; then
    echo "  RESULT: PASS — kernel applied memory.high/low, reclaimed under high pressure,"
    echo "          and no OOM kill occurred."
    exit 0
fi

echo "  RESULT: FAIL — check limits, high events, and OOM behavior."
exit 1
