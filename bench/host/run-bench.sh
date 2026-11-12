#!/usr/bin/env bash
# =============================================================================
# run-bench.sh — THM v3 A/B/C stress-benchmark orchestrator (host side)
#
#   Arm A  ArchTitan OS (live ISO) with THM v3 running       — the system
#   Arm B  ArchTitan OS (live ISO) with THM v3 masked         — isolates THM
#   Arm C  vanilla Arch Linux (live ISO, no THM exists there)  — OS baseline
#
# All arms run in the SAME VM spec (KVM, 2 vCPU, 4 GB RAM, 2 GB bench-disk
# swap) with the SAME workload bits (shared bench disk) — the only variables
# are the OS image and whether THM is enabled.
#
# usage: run-bench.sh [--arms A,B,C] [--quick] [--iso-archtitan PATH] [--iso-vanilla PATH]
#        run-bench.sh --arms A,B --quick     # fast smoke test (~4 min/arm)
# =============================================================================
set -euo pipefail

BENCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$BENCH_DIR/.." && pwd)"
HOST_DIR="$BENCH_DIR/host"
BOOT_CACHE="${TMPDIR:-/tmp}/thm-bench"
RESULTS_ROOT="$BENCH_DIR/results"
BENCH_IMG="$BENCH_DIR/bench.img"
LOGS_DIR="$BENCH_DIR/logs"
ARMS="A,B,C"
QUICK=0
ISO_AT=""
ISO_VAN=""
ALLOW_LOAD=0
HOST_WAIT_MAX=600

while [ $# -gt 0 ]; do
    case "$1" in
        --arms) ARMS="$2"; shift 2 ;;
        --quick) QUICK=1; shift ;;
        --iso-archtitan) ISO_AT="$2"; shift 2 ;;
        --iso-vanilla) ISO_VAN="$2"; shift 2 ;;
        --allow-load) ALLOW_LOAD=1; shift ;;
        --host-wait) HOST_WAIT_MAX="$2"; shift 2 ;;
        *) echo "unknown arg: $1"; exit 2 ;;
    esac
done

# Quick smoke runs are functional tests, not data: keep them out of the results
# directory that feeds the report (otherwise summarize.py aggregates both).
if [ "$QUICK" = 1 ]; then
    RESULTS_ROOT="$BENCH_DIR/results-quick"
fi

# ── locate ISOs ───────────────────────────────────────────────────────────────
if [ -z "$ISO_AT" ]; then
    # newest by release date embedded in the filename (out/ > Desktop > Downloads)
    best=""; bestd=""
    for f in "$REPO_ROOT"/out/archtitan-*.iso "$HOME"/Desktop/archtitan-*.iso "$HOME"/Downloads/archtitan-*.iso; do
        [ -f "$f" ] || continue
        d=$(basename "$f" | grep -oE '[0-9]{4}\.[0-9]{2}\.[0-9]{2}' | head -1)
        [ -z "$d" ] && continue
        if [ -z "$bestd" ] || [[ "$d" > "$bestd" ]]; then best="$f"; bestd="$d"; fi
    done
    ISO_AT="$best"
fi
if [ -z "$ISO_VAN" ]; then
    ISO_VAN=$(ls -t "$HOME"/Downloads/archlinux-*.iso "$HOME"/Desktop/archlinux-*.iso 2>/dev/null | head -1 || true)
fi

NEED_AT=no; NEED_VAN=no
IFS=',' read -ra ARM_LIST <<< "$ARMS"
for a in "${ARM_LIST[@]}"; do
    case "$a" in
        A|B) NEED_AT=yes ;;
        C) NEED_VAN=yes ;;
        *) echo "unknown arm: $a (use A, B, C)"; exit 2 ;;
    esac
done

if [ "$NEED_AT" = yes ]; then
    [ -n "$ISO_AT" ] && [ -f "$ISO_AT" ] || { echo "ERROR: ArchTitan ISO not found (build one or pass --iso-archtitan)"; exit 1; }
fi
if [ "$NEED_VAN" = yes ]; then
    [ -n "$ISO_VAN" ] && [ -f "$ISO_VAN" ] || { echo "ERROR: vanilla Arch ISO not found in ~/Downloads (pass --iso-vanilla)"; exit 1; }
fi

echo "════════════════════════════════════════════════════════════════"
echo " ArchTitan THM v3 A/B/C resource-usage benchmark"
[ "$NEED_AT" = yes ] && echo " ArchTitan ISO : $ISO_AT"
[ "$NEED_VAN" = yes ] && echo " Vanilla ISO   : $ISO_VAN"
echo " Arms          : $ARMS $( [ $QUICK = 1 ] && echo '(quick mode)' )"
echo " VM            : KVM, 2 vCPU, 4G RAM, 2G swap (fixed for all arms)"
echo "════════════════════════════════════════════════════════════════"

[ -d /dev/kvm ] || true
if ! [ -w /dev/kvm ]; then
    echo "WARNING: /dev/kvm not writable — VMs will be VERY slow (TCG)."
    echo "         Fix with: sudo usermod -aG kvm \$USER && newgrp kvm"
fi

# ── build bench disk once ─────────────────────────────────────────────────────
if [ ! -f "$BENCH_IMG" ] \
   || [ "$BENCH_DIR/guest/tstress.c" -nt "$BENCH_IMG" ] \
   || [ "$BENCH_DIR/guest/scenario.sh" -nt "$BENCH_IMG" ] \
   || [ "$BENCH_DIR/guest/collector.sh" -nt "$BENCH_IMG" ] \
   || [ "$BENCH_DIR/guest/genproject.sh" -nt "$BENCH_IMG" ]; then
    bash "$HOST_DIR/make-bench-disk.sh"
fi

mkdir -p "$BOOT_CACHE" "$RESULTS_ROOT" "$LOGS_DIR"

# ── extract boot files + kernel params from an ISO ────────────────────────────
# Sets: KERNEL, INITRD, PARAMS (from the ISO's own bootloader config, verbatim)
prep_boot() {
    local iso="$1" tag="$2" dir="$BOOT_CACHE/$tag"
    mkdir -p "$dir"

    bsdtar -xOf "$iso" arch/boot/x86_64/vmlinuz-linux > "$dir/vmlinuz" 2>/dev/null \
        || { echo "ERROR: cannot extract kernel from $iso"; return 1; }
    bsdtar -xOf "$iso" arch/boot/x86_64/initramfs-linux.img > "$dir/initramfs" 2>/dev/null \
        || { echo "ERROR: cannot extract initramfs from $iso"; return 1; }

    # find a bootloader config inside the ISO and lift its kernel cmdline
    local cfg=""
    for p in boot/grub/grub.cfg EFI/boot/grub.cfg EFI/BOOT/grub.cfg grub/grub.cfg \
             loader/entries/01-archiso-linux.conf loader/entries/archiso-x86_64.conf \
             boot/syslinux/archiso_sys-linux.cfg; do
        cfg=$(bsdtar -xOf "$iso" "$p" 2>/dev/null || true)
        [ -n "$cfg" ] && break
    done
    if [ -n "$cfg" ]; then
        # grub style:  linux /arch/boot/x86_64/vmlinuz-linux <params...>
        PARAMS=$(printf '%s\n' "$cfg" | grep -m1 -E '^\s*linux\s' \
                 | sed -E 's/^\s*linux\s+\S+\s*//' | tr -d '\r')
        # systemd-boot style: options <params...>
        if [ -z "$PARAMS" ]; then
            PARAMS=$(printf '%s\n' "$cfg" | grep -m1 -E '^\s*options\s' \
                     | sed -E 's/^\s*options\s+//' | tr -d '\r')
        fi
        # syslinux style: APPEND <params...>
        if [ -z "$PARAMS" ]; then
            PARAMS=$(printf '%s\n' "$cfg" | grep -m1 -E '^\s*APPEND\s' \
                     | sed -E 's/^\s*APPEND\s+//' | tr -d '\r')
        fi
    fi
    if [ -z "$PARAMS" ]; then
        echo "ERROR: could not parse kernel params from $iso — see $dir"
        return 1
    fi
    # strip any console= the ISO config carries (we set our own)
    PARAMS=$(printf '%s' "$PARAMS" | sed -E 's/console=[^ ]+//g')
    echo "[boot:$tag] params: $PARAMS"
}

# ── extract results from the bench disk (rootless, via debugfs) ───────────────
extract_results() {
    local rundir="$1" outdir="$2"
    mkdir -p "$outdir/$rundir"
    local try
    for try in 1 2; do
        python3 -c "
import subprocess, os
rundir = '$rundir'
outdir = '$outdir'
target = os.path.join(outdir, rundir)
os.makedirs(target, exist_ok=True)
img = '$BENCH_IMG'
try:
    ls_out = subprocess.check_output(['debugfs', '-R', f'ls -l /results/{rundir}', img], stderr=subprocess.DEVNULL).decode().splitlines()
    for line in ls_out:
        parts = line.strip().split()
        if len(parts) >= 8 and parts[1].startswith('100'):
            fname = parts[-1]
            subprocess.run(['debugfs', '-R', f'dump /results/{rundir}/{fname} {target}/{fname}', img], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception:
    pass
"
        [ -f "$outdir/$rundir/summary.json" ] && break
        echo "[extract] summary.json missing (attempt $try) — replaying journal with e2fsck"
        e2fsck -fy "$BENCH_IMG" >/dev/null 2>&1 || true
        rm -rf "$outdir/$rundir"
    done
    if [ -f "$outdir/$rundir/summary.json" ]; then
        echo "[extract] OK — results in $outdir/$rundir"
    else
        echo "[extract] WARNING: summary.json not found for $rundir"
        echo "          (guest transcript + driver log in $LOGS_DIR)"
    fi
}

# ── host-load guard ───────────────────────────────────────────────────────────
# The VM is only as fast as the host is idle: a concurrent ISO build (load 14
# on 8 cores) stretched a 5.4 s translation unit to 44.8 s and starved the
# in-guest sampler. Refuse to start an arm on a busy host unless --allow-load.
wait_for_idle_host() {
    local need_mb=5000 load_pct=60 waited=0
    while :; do
        local load1 nproc avail loadmax
        read -r load1 _ < /proc/loadavg
        nproc=$(nproc)
        avail=$(awk '/^MemAvailable:/{print int($2/1024)}' /proc/meminfo)
        loadmax=$(awk -v n="$nproc" -v p="$load_pct" 'BEGIN{printf "%.2f", n*p/100}')
        if awk -v l="$load1" -v m="$loadmax" 'BEGIN{exit !(l < m)}' && [ "$avail" -ge "$need_mb" ]; then
            echo "[host] quiet: load1=$load1 (<$loadmax), MemAvailable=${avail}MB"
            return 0
        fi
        if [ "$ALLOW_LOAD" = 1 ]; then
            echo "[host] WARNING: host busy (load1=$load1 limit=$loadmax avail=${avail}MB) — --allow-load"
            return 0
        fi
        if [ "$waited" -ge "$HOST_WAIT_MAX" ]; then
            echo "[host] ERROR: host still busy after ${waited}s (load1=$load1 limit=$loadmax avail=${avail}MB)"
            echo "       Stop heavy builds/IDEs, or pass --allow-load (results will be noisy)."
            return 1
        fi
        [ $((waited % 60)) -eq 0 ] && \
            echo "[host] waiting for quiet host… load1=$load1 limit=$loadmax avail=${avail}MB (${waited}s/${HOST_WAIT_MAX}s)"
        sleep 10
        waited=$((waited + 10))
    done
}

# ── thermal cooldown between arms ─────────────────────────────────────────────
cooldown() {
    local seconds="${1:-60}"
    echo "[cooldown] resting ${seconds}s (thermal relief)"
    sleep "$seconds"
    # optional passive wait if the machine is hot
    local hottest
    hottest=$(awk -v max=0 '{ if ($1 > max) max = $1 } END { print max/1000 }' \
             /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 0)
    if [ "$(echo "$hottest > 70" | bc 2>/dev/null || echo 0)" = "1" ]; then
        echo "[cooldown] CPU hot (${hottest}°C) — waiting to cool below 60°C"
        for _ in $(seq 1 30); do
            sleep 10
            hottest=$(awk -v max=0 '{ if ($1 > max) max = $1 } END { print max/1000 }' \
                     /sys/class/thermal/thermal_zone*/temp 2>/dev/null || echo 0)
            [ "$(echo "$hottest < 60" | bc 2>/dev/null || echo 1)" = "1" ] && break
        done
    fi
}

# ── run one arm ────────────────────────────────────────────────────────────────
run_arm() {
    local arm="$1" iso="$2" tag="$3"
    local rundir="${arm}-$(date +%Y%m%d-%H%M%S)"
    echo ""
    echo "──────────────────────────────────────────────────────────────"
    echo " ARM $arm  ($tag)"
    echo "──────────────────────────────────────────────────────────────"
    prep_boot "$iso" "$tag" || return 1

    local scen_timeout=1500
    [ "$QUICK" = 1 ] && scen_timeout=700

    python3 "$HOST_DIR/console_driver.py" \
        --arm "$arm" \
        --iso "$iso" \
        --kernel "$BOOT_CACHE/$tag/vmlinuz" \
        --initrd "$BOOT_CACHE/$tag/initramfs" \
        --append "$PARAMS" \
        --bench-img "$BENCH_IMG" \
        --sock "$BOOT_CACHE/$arm.sock" \
        --transcript "$LOGS_DIR/$rundir-console-transcript.log" \
        --rundir-name "$rundir" \
        $( [ "$QUICK" = 1 ] && echo --quick ) \
        --scenario-timeout "$scen_timeout" \
        2>&1 | tee "$LOGS_DIR/$rundir-driver.log" || true

    extract_results "$rundir" "$RESULTS_ROOT"
}

FAILED=0
PREV=""
for arm in "${ARM_LIST[@]}"; do
    [ -n "$PREV" ] && cooldown 60
    PREV="$arm"
    if ! wait_for_idle_host; then
        echo "ABORT: host too busy to benchmark — no valid results would be produced."
        exit 1
    fi
    case "$arm" in
        A) run_arm A "$ISO_AT" archtitan || FAILED=$((FAILED+1)) ;;
        B) run_arm B "$ISO_AT" archtitan || FAILED=$((FAILED+1)) ;;
        C) run_arm C "$ISO_VAN" vanilla   || FAILED=$((FAILED+1)) ;;
    esac
done

echo ""
echo "════════════════════════════════════════════════════════════════"
echo " Summarizing results…"
echo "════════════════════════════════════════════════════════════════"
python3 "$HOST_DIR/summarize.py" --results "$RESULTS_ROOT" \
    --out-md "$RESULTS_ROOT/comparison.md" \
    --out-typ "$RESULTS_ROOT/comparison.typ" || true

echo "Done. Comparison: $RESULTS_ROOT/comparison.md"
[ "$FAILED" -gt 0 ] && echo "WARNING: $FAILED arm(s) failed — check $LOGS_DIR"
exit 0
