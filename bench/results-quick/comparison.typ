// ArchTitan THM v3 — benchmark comparison (typst)
#set page(margin: (x: 2cm, y: 2.2cm))
#set text(size: 9pt)

= ArchTitan OS vs THM-off vs Vanilla Arch — resource usage under stress

#table(
  columns: (3.2fr,1.4fr,1.4fr),
  stroke: 0.5pt + rgb("#d0d8f0"), inset: 7pt,
  align: (left, center, center, center),
  [Metric], [ArchTitan + THM v3], [ArchTitan — THM off],
  [Kernel OOM kills], [0], [0],
  [Compile rounds completed], [1], [5],
  [Compile rounds FAILED], [1], [0],
  [Median round wall time], [67927 ms], [23687 ms],
  [Min MemAvailable], [653 MB], [49 MB],
  [Post-release recovery], [2041 MB], [2969 MB],
  [Peak memory PSI (full)], [2.6%], [24.1%],
  [Full-stall seconds (Σ)], [0.4 s], [5.2 s],
  [Peak swap in use], [—], [305 MB],
  [Swap-in pages (pswpin)], [0], [0],
  [Swap-out pages (pswpout)], [0], [28],
  [Major faults], [91], [409],
  [Probe latency p95 (pressure)], [6.9 ms], [5.1 ms],
  [Probe latency max (pressure)], [48.6 ms], [55.8 ms],
  [Probe latency p95 (baseline)], [10.0 ms], [3.3 ms],
  [Sampler tick latency max], [680 ms], [621 ms],
  [Hog max RSS], [1932 MB], [2721 MB],
  [Idle apps frozen (T samples)], [98], [0],
  [Hog frozen (T samples)], [0], [0],
  [THM daemon CPU (avg)], [32.19%], [—],
  [THM daemon RSS (max)], [5 MB], [—],
)

// Interpretation & raw data: see comparison.md
