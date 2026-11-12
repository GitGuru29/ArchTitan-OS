// =============================================================================
// tstress — ArchTitan / THM v3 A-B-C benchmark workload generator
//
// One static binary, three workload personalities used by scenario.sh:
//
//   idle-app  Allocates --mb MB of anonymous memory, touches every page once,
//             then sleeps forever at ~0% CPU. Models an idle GUI app /
//             background browser tab: memory held, no activity.
//             THM expects: IDLE -> frozen under HIGH pressure -> pages
//             reclaimed -> SIGCONT'd when pressure drops. Vanilla: untouched.
//
//   hog       Ramp-allocates memory in steps (the pressure source), touching
//             pages SLOWLY and uniformly so CPU stays below THM's idle
//             threshold (0.5%). After reaching --max-mb it keeps a slow
//             rolling re-touch of the whole region so its anonymous pages stay
//             "hot" (the kernel cannot silently drop them in the vanilla arm,
//             but a FROZEN cgroup cannot fault them back either).
//             Writes progress to --status-file for the collector.
//
//   probe     Every --period-ms: hash --work-mb of memory (~3-6 ms of CPU,
//             keeps it classified EXECUTING so THM protects it — like a real
//             interactive app), then clock_nanosleep(PERIOD) and measures the
//             wake overshoot. Overshoot = scheduler + direct-reclaim + swap
//             stall — the same stalls a user feels as UI jank. CSV output.
//
// Build (host):  gcc -O2 -static -o tstress tstress.c -lm
// =============================================================================

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <stdarg.h>
#include <time.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <sys/types.h>

// ── helpers ─────────────────────────────────────────────────────────────────

static long g_page_size = 4096;

static double now_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1e6;
}

// wall-clock epoch ms — joinable with collector.sh timestamps (date +%s%3N)
static double wall_ms(void) {
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    return (double)ts.tv_sec * 1000.0 + (double)ts.tv_nsec / 1e6;
}

static void die(const char* fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap);
    fprintf(stderr, "\n");
    exit(2);
}

// Touch every page in [ptr, ptr+nbytes) — one byte write per page.
static void touch_region(char* ptr, size_t nbytes) {
    volatile char* p = (volatile char*)ptr;
    size_t end = nbytes / (size_t)g_page_size;
    for (size_t i = 0; i < end; ++i) p[i * (size_t)g_page_size] = (char)(i & 0xff);
    if (nbytes) p[nbytes - 1] = 1; // ensure last page
}

static char* xalloc(size_t nbytes) {
    // MAP private anon via calloc: RSS grows only when touched (we always touch)
    char* p = (char*)calloc(1, nbytes ? nbytes : 1);
    if (!p) die("tstress: alloc of %zu bytes failed", nbytes);
    return p;
}

// Parse "--name value" pairs; returns value of key or dflt.
static const char* opt(int argc, char** argv, const char* key, const char* dflt) {
    size_t klen = strlen(key);
    for (int i = 1; i < argc - 1; ++i)
        if (!strncmp(argv[i], key, klen) && argv[i][klen] == '\0')
            return argv[i + 1];
    // also support --key=value
    for (int i = 1; i < argc; ++i)
        if (!strncmp(argv[i], key, klen) && argv[i][klen] == '=')
            return argv[i] + klen + 1;
    return dflt;
}

static long argl(int argc, char** argv, const char* key, long dflt) {
    const char* v = opt(argc, argv, key, NULL);
    return v ? strtol(v, NULL, 10) : dflt;
}

// Prevent dead-code elimination of calibration hashes (result must be
// observable to the compiler).
static volatile uint64_t g_hash_sink = 0;

// nanosleep for ms
static void sleep_ms(double ms) {
    struct timespec ts;
    ts.tv_sec = (time_t)(ms / 1000.0);
    ts.tv_nsec = (long)((ms - (double)ts.tv_sec * 1000.0) * 1e6);
    clock_nanosleep(CLOCK_MONOTONIC, 0, &ts, NULL);
}

// ── idle-app ─────────────────────────────────────────────────────────────────

static int run_idle_app(int argc, char** argv) {
    long mb = argl(argc, argv, "--mb", 400);
    const char* name = opt(argc, argv, "--id", "idle-app");
    size_t nbytes = (size_t)mb * 1024UL * 1024UL;

    char* p = xalloc(nbytes);
    touch_region(p, nbytes);
    printf("IDLE_APP_READY %s pid=%d mb=%ld\n", name, (int)getpid(), mb);
    fflush(stdout);

    for (;;) {
        sleep_ms(60000);
        // NOTE: no work, no touching — pages stay resident and unreferenced.
        // A single trivial write keeps us from being optimized away entirely:
        *(volatile int*)p = (int)(now_ms() / 1000.0);
    }
    return 0; // unreachable
}

// ── hog ──────────────────────────────────────────────────────────────────────
//
// Growth: every --step-sec seconds add --step-mb MB (touched uniformly across
// the step so instantaneous CPU stays well under 0.5%).
// Hold: rolling re-touch of the entire region over --retouch-sec per cycle.
// Exits cleanly on SIGTERM/SIGINT.

static volatile sig_atomic_t g_stop = 0;
static void on_term(int sig) { (void)sig; g_stop = 1; }

typedef struct {
    char*  base;
    size_t bytes;   // allocated+touched bytes so far
} region_t;

static region_t g_reg = {0};

static void write_status(const char* path, long alloc_mb, long max_mb) {
    if (!path || !*path) return;
    char tmp[512];
    snprintf(tmp, sizeof tmp, "%s.tmp", path);
    FILE* f = fopen(tmp, "w");
    if (!f) return;
    fprintf(f, "alloc_mb=%ld max_mb=%ld pid=%d\n", alloc_mb, max_mb, (int)getpid());
    fclose(f);
    rename(tmp, path); // atomic-ish for the collector
}

static int run_hog(int argc, char** argv) {
    long max_mb     = argl(argc, argv, "--max-mb", 4200);
    long step_mb    = argl(argc, argv, "--step-mb", 100);
    long step_sec   = argl(argc, argv, "--step-sec", 8);
    long retouch_ms = argl(argc, argv, "--retouch-sec", 300) * 1000;
    const char* status = opt(argc, argv, "--status-file", "");
    long init_mb    = argl(argc, argv, "--initial-mb", 0);

    signal(SIGTERM, on_term);
    signal(SIGINT, on_term);

    g_page_size = sysconf(_SC_PAGESIZE);
    if (g_page_size <= 0) g_page_size = 4096;

    // Pre-reserve the max region so growth is pure touching (avoids mmap/munmap
    // jitter in RSS): calloc once for max, touch incrementally.
    size_t max_bytes = (size_t)max_mb * 1024UL * 1024UL;
    char* base = xalloc(max_bytes);
    g_reg.base = base;
    // calloc gives zero pages; RSS grows as we touch.

    size_t cur = 0;
    size_t init_bytes = (size_t)init_mb * 1024UL * 1024UL;
    if (init_bytes > max_bytes) init_bytes = max_bytes;
    if (init_bytes) { touch_region(base, init_bytes); cur = init_bytes; }

    printf("HOG_READY pid=%d max_mb=%ld step_mb=%ld step_sec=%ld\n",
           (int)getpid(), max_mb, step_mb, step_sec);
    fflush(stdout);
    write_status(status, (long)(cur >> 20), max_mb);

    double last_status = now_ms();

    // ── ramp phase ────────────────────────────────────────────────────────
    while (!g_stop && cur < max_bytes) {
        size_t add = (size_t)step_mb * 1024UL * 1024UL;
        if (cur + add > max_bytes) add = max_bytes - cur;

        // spread touching of `add` bytes over step_sec in 50ms slices
        double  slice_ms = 50.0;
        long    slices = (long)(step_sec * 1000.0 / slice_ms);
        size_t  per_slice = add / (size_t)(slices > 0 ? slices : 1) + 1;
        size_t  done = 0;
        size_t  start = cur;
        for (long s = 0; s < slices && !g_stop; ++s) {
            size_t lo = start + done;
            size_t hi = lo + per_slice;
            if (hi > start + add) hi = start + add;
            if (hi > lo) touch_region(base + lo, hi - lo);
            done = hi - start;
            if (done >= add) break;
            sleep_ms(slice_ms);
            if (now_ms() - last_status > 1000.0) {
                write_status(status, (long)((cur + done) >> 20), max_mb);
                last_status = now_ms();
            }
        }
        cur = start + add;
        if (cur > max_bytes) cur = max_bytes;
        write_status(status, (long)(cur >> 20), max_mb);
        printf("HOG_ALLOC_MB %ld\n", (long)(cur >> 20));
        fflush(stdout);
    }

    // ── hold phase: rolling re-touch of everything ────────────────────────
    // Each page re-touched once per retouch cycle. CPU ≈ (max_mb/retouch_sec)
    // MB/s of page touches ≈ well under 0.1% of one core.
    while (!g_stop) {
        if (cur == 0) { sleep_ms(500); continue; }
        double  slice_ms = 50.0;
        long    slices = (long)(retouch_ms / slice_ms);
        size_t  per_slice = cur / (size_t)(slices > 0 ? slices : 1) + 1;
        size_t  off = 0;
        for (long s = 0; s < slices && !g_stop; ++s) {
            size_t hi = off + per_slice;
            if (hi > cur) hi = cur;
            if (hi > off) touch_region(base + off, hi - off);
            off = hi;
            if (off >= cur) break;
            sleep_ms(slice_ms);
        }
        write_status(status, (long)(cur >> 20), max_mb);
    }

    printf("HOG_EXIT pid=%d\n", (int)getpid());
    fflush(stdout);
    if (status && *status) unlink(status);
    return 0;
}

// ── probe ────────────────────────────────────────────────────────────────────

static uint64_t mix(uint64_t h, uint64_t v) {
    h ^= v + 0x9e3779b97f4a7c15ULL + (h << 6) + (h >> 2);
    return h;
}

static int run_probe(int argc, char** argv) {
    long   period_ms = argl(argc, argv, "--period-ms", 100);
    long   work_mb   = argl(argc, argv, "--work-mb", 32);
    double work_frac = 0.04; // target ~4% CPU — above THM's 0.5% idle
                              // threshold (so the probe is treated as an
                              // active interactive task and never frozen),
                              // yet negligible as a load generator.
    const char* csv   = opt(argc, argv, "--csv", "");
    double period = (double)period_ms;

    size_t nbytes = (size_t)work_mb * 1024UL * 1024UL;
    uint64_t* buf = (uint64_t*)xalloc(nbytes);
    size_t nwords = nbytes / sizeof(uint64_t);
    touch_region((char*)buf, nbytes); // fault everything in first

    // ── calibrate hashing rate so work lands at ~work_frac of the period ──
    // (adapts to machine speed: identical CPU% profile on host and in-VM)
    double t0 = now_ms();
    uint64_t h = 0x243f6a8885a308d3ULL;
    for (size_t i = 0; i < nwords; ++i) h = mix(h, buf[i] + i);
    g_hash_sink = h; // keep the loop
    double full_ms = now_ms() - t0;
    size_t chunk_words = nwords;
    if (full_ms > 0.01) {
        double target_ms = period * work_frac;
        if (target_ms < 1.0) target_ms = 1.0;
        double rate_wps = (double)nwords / full_ms;     // words per ms
        chunk_words = (size_t)(rate_wps * target_ms);
        if (chunk_words < 64) chunk_words = 64;
        if (chunk_words > nwords) chunk_words = nwords;
    }

    FILE* out = stdout;
    if (csv && *csv) {
        out = fopen(csv, "w");
        if (!out) die("tstress probe: cannot open %s", csv);
    }
    fprintf(out, "ts_ms,work_ms,overshoot_ms,seq\n");

    signal(SIGTERM, on_term);
    signal(SIGINT, on_term);

    long seq = 0;
    size_t off = 0;
    printf("PROBE_READY pid=%d period_ms=%ld chunk_words=%zu\n",
           (int)getpid(), period_ms, chunk_words);
    fflush(stdout);

    while (!g_stop) {
        double c0 = now_ms();

        // bounded chunk of real work, round-robin over the buffer
        h = 0x243f6a8885a308d3ULL;
        size_t end = off + chunk_words;
        if (end <= nwords) {
            for (size_t i = off; i < end; ++i) h = mix(h, buf[i] + i);
            off = end == nwords ? 0 : end;
        } else {
            for (size_t i = off; i < nwords; ++i) h = mix(h, buf[i] + i);
            size_t rem = end - nwords;
            for (size_t i = 0; i < rem; ++i) h = mix(h, buf[i] + i);
            off = rem;
        }
        if (h == 0xdeadbeefULL) printf("."); // never true; keeps the loop honest
        g_hash_sink = h;
        double work = now_ms() - c0;

        // sleep the REMAINDER of the period so the cycle lands on `period`
        double remaining = period - work;
        if (remaining > 0.5) sleep_ms(remaining);
        double t2 = now_ms();

        double overshoot = (t2 - c0) - period; // pure wake/stall jitter
        if (overshoot < 0) overshoot = 0;
        fprintf(out, "%.0f,%.2f,%.2f,%ld\n", wall_ms(), work, overshoot, seq++);
        if (seq % 20 == 0) fflush(out);
    }
    fflush(out);
    if (out != stdout) fclose(out);
    return 0;
}

// ── main ──────────────────────────────────────────────────────────────────────

int main(int argc, char** argv) {
    g_page_size = sysconf(_SC_PAGESIZE);
    if (g_page_size <= 0) g_page_size = 4096;

    if (argc < 2) {
        fprintf(stderr,
            "usage: tstress <mode> [options]\n"
            "  idle-app  --mb N --id NAME\n"
            "  hog       --max-mb N --step-mb N --step-sec S --retouch-sec R\n"
            "            --status-file F --initial-mb N\n"
            "  probe     --period-ms P --work-mb W --csv FILE\n");
        return 2;
    }
    if (!strcmp(argv[1], "idle-app")) return run_idle_app(argc, argv);
    if (!strcmp(argv[1], "hog"))      return run_hog(argc, argv);
    if (!strcmp(argv[1], "probe"))    return run_probe(argc, argv);
    fprintf(stderr, "tstress: unknown mode '%s'\n", argv[1]);
    return 2;
}
