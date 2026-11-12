#!/usr/bin/env python3
"""
console_driver.py — drive one benchmark arm inside a QEMU VM via serial console.

The VM boots the ISO's own kernel + initrd directly (GRUB is bypassed with
-kernel/-initrd/-append), with console=ttyS0 and systemd.unit=multi-user.target.
Both live ISOs ship an empty root password, so the driver logs in as root over
the serial line, mounts the bench disk, and runs scenario.sh.

Everything typed and printed on the serial line is captured to a transcript
file — that transcript is the audit trail (boot, THM service state, phase
transitions, guest summary, exit codes).

usage:
  console_driver.py --arm A --iso <path> --kernel <vmlinuz> --initrd <initramfs> \
      --append "<kernel params from the ISO's own bootloader config>" \
      --bench-img <path> --sock <unix socket> --transcript <file> \
      [--quick] [--scenario-timeout SEC]
"""

import argparse
import os
import re
import socket
import subprocess
import sys
import time


# ── serial console with transcript ────────────────────────────────────────────

class Serial:
    def __init__(self, sock_path, transcript_path, echo=True):
        self.sock_path = sock_path
        self.echo = echo
        self.transcript = open(transcript_path, "ab")
        self.buf = b""
        self._connect(retries=60)

    def _connect(self, retries=60):
        last = None
        for _ in range(retries):
            try:
                self.sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                self.sock.connect(self.sock_path)
                self.sock.setblocking(False)
                return
            except (FileNotFoundError, ConnectionRefusedError, OSError) as e:
                last = e
                time.sleep(1.0)
        raise ConnectionError(f"cannot connect to serial socket {self.sock_path}: {last}")

    def _pump(self):
        """Read everything available; append to buffer + transcript; echo live."""
        try:
            while True:
                d = self.sock.recv(65536)
                if not d:
                    raise ConnectionError("serial socket closed by QEMU")
                self.buf += d
                self.transcript.write(d)
                self.transcript.flush()
                if self.echo:
                    sys.stdout.write(d.decode(errors="replace"))
                    sys.stdout.flush()
        except BlockingIOError:
            pass
        # Auto-reply to terminal queries — plymouthd/systemd/agetty/fish all
        # probe the terminal and BLOCK waiting for the answer. A real terminal
        # replies instantly; we must too.
        #   ESC[6n  → cursor position report        → ESC[25;80R
        #   ESC[c   → primary device attributes      → ESC[?6c   (fish waits 10s!)
        #   ESC[18t → text area size                 → ESC[8;25;80t
        for query, reply in ((b"\x1b[6n", b"\x1b[25;80R"),
                              (b"\x1b[c",  b"\x1b[?6c"),
                              (b"\x1b[0c", b"\x1b[?6c"),   # fish's PDA variant
                              (b"\x1b[18t", b"\x1b[8;25;80t")):
            while query in self.buf:
                i = self.buf.index(query)
                self.buf = self.buf[:i] + self.buf[i + len(query):]
                try:
                    self.sock.sendall(reply)
                except OSError:
                    pass

    def sendline(self, s):
        self.sock.sendall(s.encode() + b"\n")

    def wait_for(self, pattern, timeout, nudge=None, nudge_every=25):
        rx = re.compile(pattern.encode() if isinstance(pattern, str) else pattern)
        deadline = time.time() + timeout
        last_nudge = time.time()
        while time.time() < deadline:
            self._pump()
            m = rx.search(self.buf)
            if m:
                self.buf = self.buf[m.end():]
                return True
            if nudge and time.time() - last_nudge > nudge_every:
                self.sendline(nudge)
                last_nudge = time.time()
            time.sleep(0.2)
        raise TimeoutError(f"timeout ({timeout}s) waiting for {pattern!r}; "
                           f"tail of console: {self.buf[-300:]!r}")

    def close(self):
        try:
            self.sock.close()
        except Exception:
            pass
        self.transcript.close()


# ── qemu ──────────────────────────────────────────────────────────────────────

def launch_qemu(args, full_append):
    kvm = os.access("/dev/kvm", os.W_OK)
    accel = ["-enable-kvm", "-cpu", "host"] if kvm else ["-cpu", "max"]
    if not kvm:
        print("[driver] WARNING: /dev/kvm unavailable — TCG emulation (slow)", flush=True)

    cmd = [
        "qemu-system-x86_64",
        *accel,
        "-m", "4G",
        "-smp", "2",
        "-machine", "q35",
        "-kernel", args.kernel,
        "-initrd", args.initrd,
        "-append", full_append,
        "-drive", f"if=none,id=iso,file={args.iso},format=raw,readonly=on",
        "-device", "virtio-blk-pci,drive=iso",
        "-drive", f"if=none,id=bench,file={args.bench_img},format=raw",
        "-device", "virtio-blk-pci,drive=bench",
        "-netdev", "user,id=n0",
        "-device", "virtio-net-pci,netdev=n0",
        "-display", "none",
        "-vga", "none",
        "-serial", f"unix:{args.sock},server=on,wait=off",
        "-monitor", "none",
        "-no-reboot",
    ]
    print("[driver] qemu: " + " ".join(cmd), flush=True)
    return subprocess.Popen(cmd, stdout=subprocess.DEVNULL,
                            stderr=subprocess.STDOUT)


# ── login + command helpers ───────────────────────────────────────────────────

def wait_boot_and_login(ser, boot_timeout=420):
    """Wait for the serial login prompt and log in as root (empty password)."""
    ser.wait_for(r"login:", timeout=boot_timeout, nudge="\n", nudge_every=30)
    ser.sendline("root")
    time.sleep(5)   # login shell starts (fish on ArchTitan, zsh on vanilla)
    # Escape into plain bash — ArchTitan's root shell is fish (non-POSIX
    # syntax: `$?`/`$((…))` don't work there). Vanilla Arch's zsh/bash accept
    # `exec bash` too, so this is uniform across arms.
    # NOTE: fish's line editor can read-ahead (and then DISCARD on exec) a
    # line sent too early — so keep re-sending the exec line (nudge) until
    # the bash prompt actually appears.
    ser.sendline("exec bash --noprofile --norc")
    ser.wait_for(r"bash-[\d.]+# ", timeout=120,
                 nudge="exec bash --noprofile --norc", nudge_every=15)
    # terminal-query replies we auto-sent while nobody was listening (fish
    # had already given up on the query) can linger in the tty input queue —
    # bash would insert them as garbage. Kill the pending line, then verify.
    ser.sendline("\x15")            # Ctrl-U: readline kill-line
    time.sleep(1)
    # Probe marker that cannot be confused with its own terminal echo:
    # typed line shows '$((41+1))', shell output shows the evaluated '42'.
    ser.sendline("echo __LOGIN_OK__$((41+1))")
    ser.wait_for(r"__LOGIN_OK__42", timeout=60)


class CmdRunner:
    """Run shell commands; rc extracted from a unique completion marker."""

    def __init__(self, ser, transcript_path):
        self.ser = ser
        self.transcript_path = transcript_path
        self.n = 0

    def __call__(self, cmd, timeout=120, label=""):
        self.n += 1
        mk = f"__BENCHEDGE_{self.n}"
        self.ser.sendline(f"{cmd}; echo {mk}=$?")
        self.ser.wait_for(mk + r"=\d+", timeout=timeout)
        with open(self.transcript_path, "rb") as f:
            data = f.read()
        matches = list(re.finditer((mk + r"=(\d+)").encode(), data))
        rc = matches[-1].group(1).decode() if matches else "?"
        if label:
            print(f"[driver] rc({label}) = {rc}", flush=True)
        return rc


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--arm", required=True, choices=["A", "B", "C"])
    ap.add_argument("--iso", required=True)
    ap.add_argument("--kernel", required=True)
    ap.add_argument("--initrd", required=True)
    ap.add_argument("--append", required=True)
    ap.add_argument("--bench-img", required=True)
    ap.add_argument("--sock", required=True)
    ap.add_argument("--transcript", required=True)
    ap.add_argument("--rundir-name", default=None)
    ap.add_argument("--quick", action="store_true")
    ap.add_argument("--scenario-timeout", type=int, default=1500)
    args = ap.parse_args()

    # disablehooks=plymouth: mkinitcpio skips the plymouth hook — plymouthd
    # busy-loops forever in a headless VM (no DRM device) and stalls the boot.
    # Harmless on ISOs without a plymouth hook (vanilla Arch).
    full_append = (args.append
                   + " console=ttyS0,115200 systemd.unit=multi-user.target"
                   " plymouth.enable=0 disablehooks=plymouth")

    if os.path.exists(args.sock):
        os.unlink(args.sock)

    qemu = launch_qemu(args, full_append)
    ser = None
    rc = 1
    try:
        ser = Serial(args.sock, args.transcript)
        print(f"[driver] arm {args.arm}: booting (qemu pid {qemu.pid})", flush=True)
        wait_boot_and_login(ser)
        print("[driver] logged in as root", flush=True)
        run = CmdRunner(ser, args.transcript)

        # ── mount the bench disk ──────────────────────────────────────────
        if run("mkdir -p /bench && mount /dev/disk/by-label/BENCHDISK /bench && "
               "chmod +x /bench/guest/tstress && echo MOUNTOK", 60, "mount bench") != "0":
            run("mount /dev/vdb /bench && chmod +x /bench/guest/tstress && "
                "echo MOUNTOK", 60, "mount bench (vdb)")

        # ── arm-specific verification (captured in transcript = evidence) ──
        print(f"[driver] arm {args.arm}: verifying environment", flush=True)
        if args.arm == "A":
            run("systemctl is-active titan-hwm", 30, "thm active?")
            run("ls /sys/fs/cgroup/archtitan.slice/ 2>/dev/null", 30, "thm slice")
            run("ps -o pid,%cpu,rss,etime,comm -p "
                "$(systemctl show -p MainPID --value titan-hwm)", 30, "thm daemon before")
        elif args.arm == "B":
            # THM ships its unit as a regular file in /etc/systemd/system, so
            # `systemctl mask` fails (it cannot replace a real unit with its
            # /dev/null symlink). Remove the unit + enablement links instead.
            run("systemctl stop titan-hwm 2>/dev/null; "
                "rm -f /etc/systemd/system/titan-hwm.service "
                "/etc/systemd/system/*.wants/titan-hwm.service; "
                "systemctl daemon-reload 2>/dev/null; "
                "systemctl reset-failed titan-hwm 2>/dev/null; "
                "pkill -9 -f titan-hwm-daemon 2>/dev/null; sleep 1; "
                "systemctl is-active titan-hwm 2>&1", 60, "thm disabled")
            run("pidof titan-hwm-daemon || echo NO_DAEMON", 30, "thm gone?")
        else:
            run("command -v titan-hwm-daemon || echo NO_THM_ON_VANILLA", 30, "thm absent?")
        run("nproc; free -m | head -2; uname -r", 30, "guest specs")

        # ── run the scenario ───────────────────────────────────────────────
        rundir = args.rundir_name or f"{args.arm}-{time.strftime('%Y%m%d-%H%M%S')}"
        scen = f"bash /bench/guest/scenario.sh --arm {args.arm} --dir /bench/results/{rundir}"
        if args.quick:
            scen += " --quick"
        print(f"[driver] arm {args.arm}: running scenario (rundir {rundir})", flush=True)
        try:
            src = run(scen, timeout=args.scenario_timeout, label="scenario")
        except TimeoutError as e:
            # The guest serial session can end underneath us (getty restart /
            # session teardown). The scenario may still have finished and
            # written its artifacts, so try to recover instead of discarding
            # a whole arm's worth of measurements.
            print(f"[driver] scenario did not report completion: {e}", flush=True)
            try:
                ser.wait_for(r"login:", timeout=5)
            except TimeoutError:
                raise
            print("[driver] serial session ended — re-login and recover artifacts", flush=True)
            wait_boot_and_login(ser)
            run(f"ls -la /bench/results/{rundir}/ | tail -8", 60, "recovered listing")
            rc_probe = run(f"test -f /bench/results/{rundir}/summary.json && echo SUMMARY_PRESENT",
                           30, "recovered summary.json?")
            if rc_probe == "0":
                src = "0"
                print("[driver] recovered: summary.json present", flush=True)
            else:
                src = "?"

        # ── confirm artifacts + clean shutdown ─────────────────────────────
        run(f"ls -la /bench/results/{rundir}/ | head -25", 60, "results listing")
        run(f"test -f /bench/results/{rundir}/summary.json && echo SUMMARY_PRESENT",
            30, "summary.json present?")
        # The scenario swaps on /bench/swapfile and its workloads run with CWD
        # inside /bench; both keep the mount busy. swapoff + kill any straggler,
        # then retry, then fall back to a lazy unmount (poweroff flushes anyway).
        run("cd /; swapoff -a 2>/dev/null; pkill -9 -x tstress 2>/dev/null; "
            "sync; umount /bench && echo UMOUNTOK || "
            "{ sleep 1; umount /bench && echo UMOUNTOK_RETRY || "
            "{ umount -l /bench && echo UMOUNT_LAZY; }; }", 180, "umount")

        print(f"[driver] arm {args.arm}: scenario rc={src} — powering off", flush=True)
        ser.sendline("poweroff")
        try:
            qemu.wait(timeout=180)
        except subprocess.TimeoutExpired:
            print("[driver] guest did not power off in time — killing qemu", flush=True)
            qemu.kill()
            qemu.wait()
        rc = 0 if src == "0" else 2
    except KeyboardInterrupt:
        print("[driver] interrupted — killing qemu", flush=True)
        qemu.kill()
        qemu.wait()
        rc = 130
    except (TimeoutError, ConnectionError) as e:
        print(f"[driver] ERROR: {e}", flush=True)
        if qemu.poll() is None:
            qemu.kill()
            qemu.wait()
        rc = 3
    finally:
        if ser:
            ser.close()
    sys.exit(rc)


if __name__ == "__main__":
    main()
