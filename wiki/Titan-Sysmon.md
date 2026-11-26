# Titan System Monitor (`titan-sysmon`)

The **ArchTitan System Monitor** (`titan-sysmon`) is a first-party, hardware-accelerated telemetry overlay and hardware inspection dashboard built with C++20 and Qt6 Quick / LayerShellQt. Designed specifically for developer workstations and performance monitoring, it delivers 1Hz real-time telemetry gauges and sparkline graphs with zero privileged helpers or external daemon dependencies.

Triggered via **`titan-sysmon --toggle`**, Waybar telemetry badge clicks, or through the **Titan Central Menu** under *Panels › System monitor*.

---

## Architecture & Data Sources

`titan-sysmon` samples live system state directly from the Linux kernel virtual filesystems and hardware interfaces:

```mermaid
graph TD
    subgraph Kernel["Kernel Telemetry (/proc & /sys)"]
        CPU_STAT["/proc/stat & /proc/cpuinfo (CPU Usage & Freq)"]
        MEM_STAT["/proc/meminfo & /proc/pressure/memory (RAM & PSI)"]
        DISK_STAT["/proc/diskstats & statvfs (Storage I/O & Capacity)"]
        HWMON["/sys/class/hwmon/* (Thermals: k10temp, coretemp, zenpower)"]
        DRM["DRM sysfs / nvidia-smi (AMD, Intel, NVIDIA GPU Telemetry)"]
    end

    subgraph Daemon["Titan Hardware Manager (v3)"]
        THM_STATE["/run/archtitan/thm-state.json (Workload, Pressure, Slices)"]
    end

    subgraph Controller["SysmonController (C++20, 1Hz Tick)"]
        PARSER["Zero-Allocation Sysfs/Proc Delta Parsers"]
        SPARK["Normalized History Ring Buffers (60s Sparklines)"]
    end

    subgraph UI["Qt6 Quick Layer-Shell Overlay"]
        QML["SystemMonitorWindow.qml (Obsidian Glassmorphic Card)"]
    end

    CPU_STAT --> PARSER
    MEM_STAT --> PARSER
    DISK_STAT --> PARSER
    HWMON --> PARSER
    DRM --> PARSER
    THM_STATE --> PARSER
    PARSER --> SPARK
    SPARK --> QML
```

---

## Monitored Telemetry Metrics

### 1. CPU Telemetry
- Total CPU utilization percentage and per-core utilization bars.
- Live scaling frequency (`cpufreq`) and maximum clock limits.
- 1-minute, 5-minute, and 15-minute load averages.
- 60-second real-time historical CPU load sparkline.

### 2. Memory & PSI Pressure
- Total, used, available, and cached physical memory (RAM in GB and %).
- Swap space utilization and pressure.
- Linux Kernel Pressure Stall Information (**PSI**): monitors memory stall percentages (`some` / `full`), surfacing workload contention before OOM killer events occur.
- 60-second RAM historical trend sparkline.

### 3. GPU Acceleration Telemetry
- Supports NVIDIA GPUs (via NVML / `nvidia-smi`) and AMD/Intel GPUs (via DRM sysfs).
- Reports GPU core clock, GPU memory utilization (VRAM), power draw in Watts, and engine utilization.

### 4. Thermals & Hardware Health
- Dynamic discovery of `/sys/class/hwmon/*` sensors across AMD `k10temp`/`zenpower`, Intel `coretemp`, `acpitz`, and discrete GPU nodes.
- Highlights package temperatures and warns when nearing thermal throttling thresholds.

### 5. THM v3 Workload State & Multi-Signal Classification
- Integrates directly with the **Titan Hardware Manager** (`/run/archtitan/thm-state.json`).
- **Telemetry Counter Properties**: Exposes classified vs. tracked workload counts (`X classified · Y tracked`), active workloads, total monitored processes, unmanaged daemon processes, and Hyprland IPC connection state.
- **Dynamic Pressure Indicators**: Surfaces real-time memory and CPU PSI pressure pills with semantic state styling (`NORMAL` in green, `MODERATE` / `ELEVATED` in warning amber, `CRITICAL` in danger red).
- **Workload Row Identification**:
  - Classifies process groups by workload type (`Android`, `Web`, `AI`, `Dev`, `Service`, `Observed`).
  - Formats process counts with singular/plural accuracy (`1 proc` vs. `N procs`).
  - Resolves workspace placement cleanly (`ws 1`, `headless` for background daemons, `special` for scratchpads).
  - Displays resident memory (MB) and execution status (`active`, `idle`, `background executing`) with zero column clipping.

---

## Layer-Shell Overlay Behavior & UI Architecture

- **Precision Geometry**: Fixed 450px width (`qMax(420, width)`) with 6px vertical margin clamps, preventing horizontal layout blowout and ensuring compatibility across ultrawide, standard 1080p, and high-DPI displays.
- **Vertical Scrollbar**: Integrated `QQC2.ScrollBar.vertical` within the flickable container to allow smooth scrolling through expanded workload lists without displacing header cards.
- **Proportional Hero Gauges**: Three GPU-accelerated `TitanArcItem` gauge rings (CPU utilization, RAM consumption, and package thermals) sized to 72px base diameter, sharing equal width without horizontal clipping.
- **Positioning**: Anchored to the **Left**, **Top**, and **Bottom** margins on the active monitor output (`LayerShellQt::Window::AnchorLeft | AnchorTop | AnchorBottom`).
- **Glassmorphism & Blur Masking**: Obsidian frosted glass backdrop (97%-95% mantle gradient) matching the Catppuccin Mocha TDL palette. Compositor blur is paired with an alpha threshold rule (`layerrule = ignore_alpha 0.05, match:namespace titan-sysmon`) to eliminate dark shadow halos around transparent window borders.
- **Dismiss on Click-Away**: Features an intelligent grace-period dismiss handler—clicking outside the panel or pressing <kbd>Escape</kbd> smoothly closes the overlay without accidental triggers on opening.

---

## CLI & Daemon Interface

`titan-sysmon` runs as a single-instance daemon managed by Hyprland autostart:

```bash
# Start hidden daemon on login
titan-sysmon --daemon

# Toggle overlay visibility
titan-sysmon --toggle

# Explicit control
titan-sysmon --show
titan-sysmon --hide
```

---

## Directory & File Locations

- **Source Code**: [`subsystems/titan-sysmon/`](file:///home/msfvenom/custom-os-build/subsystems/titan-sysmon)
- **Binary**: `/usr/local/bin/titan-sysmon`
- **Permissions**: `0:0:755` (in `profiledef.sh`)
