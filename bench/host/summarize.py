#!/usr/bin/env python3
"""
summarize.py — turn benchmark run dirs into the A/B/C comparison table.

Reads  bench/results/<arm>-<timestamp>/{metrics.csv, probe.csv, builds.tsv,
       survival.tsv, oom-events.log, phase-timeline.tsv, summary.json, meta.txt}
Writes comparison.md (slides/report ready) and comparison.typ (typst).

Multiple runs of the same arm are aggregated (mean, with min–max in brackets).
"""

import argparse
import csv
import json
import os
import re
import statistics
import sys
from collections import defaultdict

ARMS = {
    "A": "ArchTitan + THM v3",
    "B": "ArchTitan — THM off",
    "C": "Vanilla Arch Linux",
}
PHASES_ORDER = ["baseline", "ramp", "hold", "release", "audit"]
PRESSURE_PHASES = {"ramp", "hold"}
RECOVERY_PHASES = {"release", "audit"}


# ── small helpers ─────────────────────────────────────────────────────────────

def fnum(x, default=None):
    try:
        return float(x)
    except (TypeError, ValueError):
        return default


def percentile(values, pct):
    if not values:
        return None
    s = sorted(values)
    k = (len(s) - 1) * pct / 100.0
    lo = int(k)
    hi = min(lo + 1, len(s) - 1)
    if lo == hi:
        return s[lo]
    return s[lo] + (s[hi] - s[lo]) * (k - lo)


def fmt(v, nd=1, unit="", none="—"):
    if v is None:
        return none
    return f"{v:.{nd}f}{unit}"


def read_csv_rows(path):
    rows = []
    if not os.path.exists(path):
        return rows
    with open(path, newline="") as f:
        r = csv.reader(f)
        header = next(r, None)
        for line in r:
            if len(line) != len(header):
                continue  # tolerate truncated final line (killed collector)
            rows.append(dict(zip(header, line)))
    return rows


def phase_windows(timeline_path):
    """[(ts_ms, phase)] sorted."""
    out = []
    if not os.path.exists(timeline_path):
        return out
    for line in open(timeline_path):
        m = re.match(r"(\d+)\s+(\w+)", line.strip())
        if m:
            out.append((int(m.group(1)), m.group(2)))
    return sorted(out)


def phase_of(ts, windows):
    ph = "?"
    for wts, wph in windows:
        if ts >= wts:
            ph = wph
        else:
            break
    return ph


# ── per-run analysis ─────────────────────────────────────────────────────────

def analyze_run(rundir):
    d = {}
    metrics = read_csv_rows(os.path.join(rundir, "metrics.csv"))

    if metrics:
        ts = [fnum(r["ts_ms"]) for r in metrics]
        # memory
        ma = [fnum(r["memavail_mb"]) for r in metrics]
        d["min_memavail_mb"] = min(v for v in ma if v is not None) if any(ma) else None
        sw = [fnum(r["swapused_mb"]) for r in metrics]
        d["peak_swapused_mb"] = max(v for v in sw if v is not None) if any(sw) else None
        # psi
        d["peak_psi_mem_some"] = max((fnum(r["psi_mem_some"]) or 0) for r in metrics)
        d["peak_psi_mem_full"] = max((fnum(r["psi_mem_full"]) or 0) for r in metrics)
        # stall-seconds: Σ psi_full(%) × dt(s) / 100
        stall = 0.0
        for i in range(1, len(metrics)):
            dt = ((ts[i] or 0) - (ts[i - 1] or 0)) / 1000.0
            if 0 < dt < 5:
                stall += (fnum(metrics[i]["psi_mem_full"]) or 0) * dt / 100.0
        d["psi_full_stall_seconds"] = stall
        # swap/fault deltas
        for col, key in [("pswpin", "pswpin_total"), ("pswpout", "pswpout_total"),
                         ("pgmajfault", "pgmajfault_total")]:
            vals = [fnum(r[col]) for r in metrics]
            vals = [v for v in vals if v is not None]
            d[key] = (vals[-1] - vals[0]) if len(vals) > 1 else 0
        # process evidence
        hog_rss = [fnum(r["hog_rss_mb"]) for r in metrics]
        d["hog_max_rss_mb"] = max((v for v in hog_rss if v is not None), default=None)
        d["hog_frozen_samples"] = sum(1 for r in metrics if r["hog_state"] == "T")
        d["idle_frozen_samples"] = sum(1 for r in metrics
                                       if r.get("idle1_state") == "T" or r.get("idle2_state") == "T")
        d["idle1_alive"] = any(r.get("idle1_state") not in ("X", "") for r in metrics)
        tick = [fnum(r["tick_ms"]) for r in metrics]
        d["tick_ms_max"] = max((v for v in tick if v is not None), default=None)
        # recovery: min during pressure vs max during recovery
        ma_ph = [(fnum(r["memavail_mb"]), r["phase"]) for r in metrics]
        pr = [v for v, ph in ma_ph if ph in PRESSURE_PHASES and v is not None]
        rc = [v for v, ph in ma_ph if ph in RECOVERY_PHASES and v is not None]
        if pr and rc:
            d["recovery_mb"] = max(rc) - min(pr)
        # THM overhead
        cpu = [fnum(r["thm_cpu_pct"]) for r in metrics if r.get("thm_cpu_pct")]
        rss = [fnum(r["thm_rss_mb"]) for r in metrics if r.get("thm_rss_mb")]
        if cpu:
            d["thm_cpu_avg"] = statistics.mean(cpu)
        if rss:
            d["thm_rss_max"] = max(rss)

    # probe latency per phase
    probe_rows = read_csv_rows(os.path.join(rundir, "probe.csv"))
    windows = phase_windows(os.path.join(rundir, "phase-timeline.tsv"))
    if probe_rows and windows:
        by_phase = defaultdict(list)
        for r in probe_rows:
            t = fnum(r["ts_ms"])
            ov = fnum(r["overshoot_ms"])
            if t is None or ov is None:
                continue
            by_phase[phase_of(t, windows)].append(ov)
        base = by_phase.get("baseline", [])
        press = [v for ph in PRESSURE_PHASES for v in by_phase.get(ph, [])]
        if base:
            d["probe_baseline_p95"] = percentile(base, 95)
        if press:
            d["probe_pressure_p50"] = percentile(press, 50)
            d["probe_pressure_p95"] = percentile(press, 95)
            d["probe_pressure_max"] = max(press)

    # builds
    ok = fail = 0
    walls = []
    bpath = os.path.join(rundir, "builds.tsv")
    if os.path.exists(bpath):
        for line in open(bpath):
            parts = line.rstrip("\n").split("\t")
            if len(parts) < 3:
                continue
            st, w = parts[1], fnum(parts[2])
            if st == "ok":
                ok += 1
                if w:
                    walls.append(w)
            elif st == "FAIL":
                fail += 1
            elif st == "SKIPPED":
                d["builds_skipped"] = True
    d["builds_ok"] = ok
    d["builds_fail"] = fail
    d["build_wall_median_ms"] = statistics.median(walls) if walls else None

    # OOM events
    d["oom_kills"] = 0
    d["oom_victims"] = []
    opath = os.path.join(rundir, "oom-events.log")
    if os.path.exists(opath):
        vic = re.findall(r"Killed process \d+ \(([^)]+)\)", open(opath).read())
        d["oom_kills"] = len(vic)
        d["oom_victims"] = sorted(set(vic))

    # survival
    d["survival"] = {}
    spath = os.path.join(rundir, "survival.tsv")
    if os.path.exists(spath):
        for line in open(spath):
            p = line.rstrip("\n").split("\t")
            if len(p) >= 4 and p[0] != "name":
                d["survival"][p[0]] = (p[2], p[3])

    # guest summary + meta (merge keys we don't compute)
    gsum = os.path.join(rundir, "summary.json")
    if os.path.exists(gsum):
        try:
            d["guest_summary"] = json.load(open(gsum))
        except json.JSONDecodeError:
            pass
    meta = os.path.join(rundir, "meta.txt")
    if os.path.exists(meta):
        d["meta"] = open(meta).read()
        d["quick"] = bool(re.search(r"^quick=1$", d["meta"], re.M))
    cal = os.path.join(rundir, "calibration.txt")
    if os.path.exists(cal):
        m = re.search(r"calib_tu_ms=(\d+) calib_tu_rss_mb=(\d+)", open(cal).read())
        if m:
            d["calib_tu_ms"] = int(m.group(1))
            d["calib_tu_rss_mb"] = int(m.group(2))
    return d


# ── aggregation ───────────────────────────────────────────────────────────────

def aggregate(runs):
    """runs: list of dicts → single dict with mean (+_min/_max) per numeric key."""
    out = {}
    keys = set()
    for r in runs:
        keys.update(k for k, v in r.items() if isinstance(v, (int, float)))
    for k in keys:
        vals = [r[k] for r in runs if isinstance(r.get(k), (int, float))]
        if not vals:
            continue
        out[k] = statistics.mean(vals)
        if len(vals) > 1:
            out[k + "_min"] = min(vals)
            out[k + "_max"] = max(vals)
    for k in ("builds_ok", "builds_fail", "oom_kills", "hog_frozen_samples",
              "idle_frozen_samples", "pswpin_total", "pswpout_total", "pgmajfault_total"):
        tot = [r.get(k) for r in runs if isinstance(r.get(k), (int, float))]
        if tot:
            out[k] = statistics.mean(tot)
    lists = defaultdict(list)
    for r in runs:
        for v in r.get("oom_victims", []):
            lists["oom_victims"].append(v)
    out["oom_victims"] = sorted(set(lists["oom_victims"]))
    surv = {}
    for r in runs:
        for name, (alive, st) in r.get("survival", {}).items():
            surv.setdefault(name, []).append((alive, st))
    out["survival"] = surv
    return out


def cell(ag, key, nd=1, unit="", better=""):
    v = ag.get(key)
    if v is None:
        return "—"
    s = fmt(v, nd, unit)
    if f"{key}_min" in ag:
        s += f" <br>({fmt(ag[key+'_min'], nd)}–{fmt(ag[key+'_max'], nd)})"
    return s


# ── output ────────────────────────────────────────────────────────────────────

METRICS = [
    # (label, key, decimals, unit, direction, description)
    ("Kernel OOM kills",              "oom_kills",              0, "",    "↓", "processes destroyed by the kernel OOM killer"),
    ("Compile rounds completed",      "builds_ok",              0, "",    "↑", "successful make -j2 rounds during the whole run"),
    ("Compile rounds FAILED",         "builds_fail",            0, "",    "↓", "rounds killed mid-build (OOM/crash)"),
    ("Median round wall time",        "build_wall_median_ms",   0, " ms", "↓", "compile throughput"),
    ("Min MemAvailable",              "min_memavail_mb",        0, " MB", "↑", "how close the system came to the wall"),
    ("Post-release recovery",         "recovery_mb",            0, " MB", "↑", "memory reclaimed after the hog exits"),
    ("Peak memory PSI (full)",        "peak_psi_mem_full",      1, "%",   "↓", "kernel full-stall pressure peak"),
    ("Full-stall seconds (Σ)",        "psi_full_stall_seconds", 1, " s",  "↓", "total time-equivalent of full memory stalls"),
    ("Peak swap in use",               "peak_swapused_mb",       0, " MB", "↓", "swap occupancy peak"),
    ("Swap-in pages (pswpin)",        "pswpin_total",           0, "",    "↓", "pages faulted back from swap — thrash indicator"),
    ("Swap-out pages (pswpout)",      "pswpout_total",          0, "",    "↓", "pages written to swap"),
    ("Major faults",                  "pgmajfault_total",       0, "",    "↓", "I/O page faults"),
    ("Probe latency p95 (pressure)",  "probe_pressure_p95",     1, " ms", "↓", "interactive-task stall, pressure window"),
    ("Probe latency max (pressure)",  "probe_pressure_max",      1, " ms", "↓", "worst single stall"),
    ("Probe latency p95 (baseline)",  "probe_baseline_p95",     1, " ms", "↓", "reference before pressure"),
    ("Sampler tick latency max",      "tick_ms_max",            0, " ms", "↓", "system responsiveness canary"),
    ("Hog max RSS",                   "hog_max_rss_mb",         0, " MB", "↓", "runaway background memory growth"),
    ("Idle apps frozen (T samples)",  "idle_frozen_samples",     0, "",    "↑", "THM freezing idle junk (arm A only)"),
    ("Hog frozen (T samples)",        "hog_frozen_samples",     0, "",    "↑", "THM containing the pressure source (arm A only)"),
    ("THM daemon CPU (avg)",          "thm_cpu_avg",            2, "%",   "↓", "cost of running THM (arm A only)"),
    ("THM daemon RSS (max)",          "thm_rss_max",            0, " MB", "↓", "memory cost of THM (arm A only)"),
]


def build_tables(arm_data, n_runs, quick=False):
    md = []
    ty = []

    arms = [a for a in ("A", "B", "C") if a in arm_data]

    if quick:
        workload = ("continuous `make -j2` (6 template-heavy C++ TUs) + probe "
                    "(100 ms heartbeat) + 2×400 MB idle apps + memory hog "
                    "(burst 1.9 GB, then 200 MB/10 s up to 3200 MB)")
        phases = "warm-up 30 s (not sampled) → baseline 25 s → ramp ≤90 s (stop at free <20%) → hold 45 s → release (hog TERM/CONT/KILL) → audit"
    else:
        workload = ("continuous `make -j2` (16 template-heavy C++ TUs) + probe "
                    "(100 ms heartbeat) + 2×400 MB idle apps + memory hog "
                    "(burst 1.9 GB, then 200 MB/10 s up to 4600 MB)")
        phases = "warm-up 60 s (not sampled) → baseline 60 s → ramp ≤240 s (stop at free <20%) → hold 90 s → release (hog TERM/CONT/KILL) → audit"

    # environment
    md.append("## Environment (identical across arms)\n")
    md.append("| Property | Value |")
    md.append("|---|---|")
    md.append("| VM | QEMU/KVM, 2 vCPU, 4 GB RAM, 2 GB swap on bench disk |")
    md.append("| Boot | live ISO, `systemd.unit=multi-user.target`, serial console |")
    md.append(f"| Workload | {workload} |")
    md.append(f"| Phases | {phases} |")
    md.append("")

    # headline table
    md.append("## Resource-usage comparison\n")
    md.append("| Metric (" + "↓ lower is better / ↑ higher is better) | " +
              " | ".join(ARMS[a] + f" (n={n_runs[a]})" for a in arms) + " |")
    md.append("|---|" + "---|" * len(arms))
    ty.append("#table(")
    ty.append("  columns: (3.2fr," + ",".join("1.4fr" for _ in arms) + "),")
    ty.append('  stroke: 0.5pt + rgb("#d0d8f0"), inset: 7pt,')
    ty.append("  align: (left, center, center, center),")
    ty.append('  [Metric], ' + ", ".join(f'[{ARMS[a]}]' for a in arms) + ",")
    for label, key, nd, unit, direction, _desc in METRICS:
        cells = []
        for a in arms:
            ag = arm_data[a]
            v = ag.get(key)
            if v is None:
                cells.append("—")
            else:
                s = fmt(v, nd, unit)
                if f"{key}_min" in ag:
                    s += f" ({fmt(ag[key+'_min'], nd)}–{fmt(ag[key+'_max'], nd)})"
                cells.append(s.replace("<br>", " "))
        md.append(f"| {direction} {label} | " + " | ".join(cells) + " |")
        ty.append(f"  [{label}], " + ", ".join(f"[{c}]" for c in cells) + ",")
    ty.append(")")

    # qualitative outcomes
    md.append("\n## Qualitative outcomes\n")
    md.append("| Outcome | " + " | ".join(ARMS[a] for a in arms) + " |")
    md.append("|---|" + "---|" * len(arms))
    rows = []
    for a in arms:
        ag = arm_data[a]
        surv = ag.get("survival", {})
        idle_state = "/".join(f"{n}:{v[0]}{'(' + v[1] + ')' if v[0]=='no' else ''}"
                             for n, v in surv.items() if n.startswith("idle"))
        rows.append((idle_state or "—"))
    md.append("| Idle apps survived (final state) | " + " | ".join(rows) + " |")
    rows = []
    for a in arms:
        ag = arm_data[a]
        vic = ag.get("oom_victims") or []
        rows.append(", ".join(vic) if vic else "none")
    md.append("| OOM victims | " + " | ".join(rows) + " |")
    rows = []
    for a in arms:
        ag = arm_data[a]
        surv = ag.get("survival", {})
        h = surv.get("hog", ("—", "—"))
        rows.append(f"{h[0]}" + (f" ({h[1]})" if h[0] == "no" else ""))
    md.append("| Hog contained | " + " | ".join(rows) + " |")

    # interpretation
    md.append("\n## Interpretation\n")
    A = arm_data.get("A")
    B = arm_data.get("B")
    C = arm_data.get("C")
    notes = []
    if A and B:
        if (A.get("oom_kills") or 0) == 0 and (B.get("oom_kills") or 0) > 0:
            notes.append(f"**THM prevented every kernel OOM kill** — the no-THM run lost "
                         f"`{', '.join(B.get('oom_victims') or [])}` to the OOM killer while "
                         "the THM run lost nothing.")
        if (A.get("builds_fail") or 0) == 0 and (B.get("builds_fail") or 0) > 0:
            notes.append(f"**THM protected the build**: {B['builds_fail']} compile round(s) "
                         "died without THM; zero died with THM.")
        if A.get("psi_full_stall_seconds") is not None and B.get("psi_full_stall_seconds") is not None:
            if A["psi_full_stall_seconds"] < B["psi_full_stall_seconds"]:
                notes.append(f"**Less time stalled**: full memory-stall equivalent was "
                             f"{A['psi_full_stall_seconds']:.1f}s with THM vs "
                             f"{B['psi_full_stall_seconds']:.1f}s without "
                             f"(−{(1 - A['psi_full_stall_seconds']/max(B['psi_full_stall_seconds'],1e-9))*100:.0f}%).")
        if A.get("probe_pressure_p95") is not None and B.get("probe_pressure_p95") is not None:
            if A["probe_pressure_p95"] < B["probe_pressure_p95"]:
                notes.append(f"**Foreground stayed fluid**: interactive probe p95 latency under "
                             f"pressure was {A['probe_pressure_p95']:.1f} ms with THM vs "
                             f"{B['probe_pressure_p95']:.1f} ms without "
                             f"({B['probe_pressure_p95']/max(A['probe_pressure_p95'],1e-9):.1f}× worse without).")
        if A.get("min_memavail_mb") is not None and B.get("min_memavail_mb") is not None:
            if A["min_memavail_mb"] > B["min_memavail_mb"]:
                notes.append(f"**Healthier memory floor**: minimum available memory was "
                             f"{A['min_memavail_mb']:.0f} MB with THM vs "
                             f"{B['min_memavail_mb']:.0f} MB without.")
        if A.get("idle_frozen_samples"):
            notes.append(f"THM froze idle apps/hog (observed in {A['idle_frozen_samples']} "
                         "samples) — a frozen workload cannot allocate or fault, so the "
                         "pressure source stops growing; the frozen pages stay resident "
                         "until the workload is released.")
        if A.get("thm_cpu_avg") is not None:
            notes.append(f"**Cost of THM**: daemon averaged {A['thm_cpu_avg']:.1f}% of one "
                         f"vCPU and ≤{A.get('thm_rss_max', 0):.0f} MB RSS in a 2-vCPU guest "
                         "(a fixed polling cost: ~0.2 s scan tick). On a many-core desktop "
                         "this is a much smaller fraction of total capacity.")
    if C:
        notes.append("Arm C (vanilla Arch) quantifies the same resource-blind behaviour "
                     "as arm B on a stock OS: no workload-aware reclamation, only the "
                     "kernel's RSS-blind OOM killer.")
    if not notes:
        notes.append("No headline differences computed — inspect the raw CSVs in the run dirs.")
    md.extend(f"- {n}\n" for n in notes)

    md.append("\n## Threats to validity (disclose in the viva)\n")
    md.append("- Live-ISO environments (tmpfs overlay) — representative but not an installed system.")
    md.append("- Synthetic template-heavy compile workload calibrated to real gcc RSS/time, not a real codebase.")
    md.append("- Single machine, KVM VM: CPU-governor effects of THM are NOT measured here (no cpufreq in QEMU); "
              "this benchmark isolates the memory/PSI/cgroup mechanisms.")
    md.append("- The harness (scenario shell, collector, compile driver) is double-forked out of THM's "
              "ownership tree so THM manages the *workloads* and not the benchmark controller. A real "
              "terminal shell that parents `make` would be classified SYSTEM_DEV and could be frozen at "
              "HIGH pressure — that would stop the *next* compile round, not the running build.")
    md.append("- Absolute compile times track the host CPU's power/thermal state; every arm runs a fixed "
              "30-60 s un-sampled warm-up and arms run back-to-back on the same host (load guard "
              "<60% of nproc). Compare arms, not absolute numbers.")
    md.append("- Kernel versions differ slightly between ISO build dates (disclosed in each meta.txt).")
    md.append("- Kernel OOM victim selection is nondeterministic; repeat runs (--arms A,B …) to add error bars.")
    return "\n".join(md), "\n".join(ty)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--results", required=True)
    ap.add_argument("--out-md", required=True)
    ap.add_argument("--out-typ", required=True)
    args = ap.parse_args()

    arm_runs = defaultdict(list)
    for name in sorted(os.listdir(args.results)):
        path = os.path.join(args.results, name)
        m = re.match(r"^([ABC])-\d{8}-\d{6}$", name)
        if m and os.path.isdir(path):
            arm_runs[m.group(1)].append(analyze_run(path))

    if not arm_runs:
        print(f"no run dirs found under {args.results} (expected <A|B|C>-<timestamp>/)")
        sys.exit(1)

    arm_data = {}
    n_runs = {}
    for arm, runs in arm_runs.items():
        arm_data[arm] = aggregate(runs)
        n_runs[arm] = len(runs)

    md, ty = build_tables(arm_data, n_runs,
                          quick=any(r.get("quick") for runs in arm_runs.values() for r in runs))
    with open(args.out_md, "w") as f:
        f.write("# ArchTitan THM v3 — A/B/C resource-usage stress benchmark\n\n"
                f"Generated {__import__('datetime').datetime.now().isoformat(timespec='seconds')}\n\n"
                + md + "\n")
    with open(args.out_typ, "w") as f:
        f.write("// ArchTitan THM v3 — benchmark comparison (typst)\n"
                "#set page(margin: (x: 2cm, y: 2.2cm))\n"
                "#set text(size: 9pt)\n\n"
                "= ArchTitan OS vs THM-off vs Vanilla Arch — resource usage under stress\n\n"
                + ty + "\n\n"
                + "// Interpretation & raw data: see comparison.md\n")
    print(md)
    print(f"\n[summarize] wrote {args.out_md} and {args.out_typ}")


if __name__ == "__main__":
    main()
