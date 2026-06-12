# Measurement (Latency Methodology) Topic Bank
Updated: 2026-06-12

Scope: how to measure the CME feed-handler hot path — per-stage timestamping, percentile
distributions, `perf` top-down/`c2c`, burst metrics, benchmarking discipline. Anchored to the
real budget (**1–100µs** wire→book→publish). This area is the MD-flavored sibling of `/perf
methodology`; for the deepest CPU/cache/concurrency theory cross-link to `/perf cpu`, `/perf mem`,
`/perf concurrency`. Rule for the whole bank: **measure before you optimize**, and pair every
claim with the measurement that confirms it.

## beginner

### Why measure latency at all — the hot-path budget
The whole point of the measurement area is to make the 1–100µs pipeline *legible*: you cannot defend a design or a regression without numbers. The end-to-end CME path is wire arrival → SBE decode → instrument dispatch → book update → publish, and each stage spends a slice of the total budget. A ~10µs target for "decode + book" on a tuned host is a reasonable working anchor; the I/O wake-up and publish stages add the rest. The first discipline is to know *what* you're measuring (which two timestamps bound the interval) and *where* the clock is read, before arguing about any single number.
**Key concepts:** end-to-end vs per-stage latency, hot-path budget, tick-to-trade vs decode-to-publish, measurement boundary definition
**Tip:** Always name the two endpoints of a latency number. "p99 is 14µs" is meaningless until you say "t_receive→t_published"; the same pipeline can be "fast" or "slow" depending on whether you include kernel wake-up or NIC-to-app DMA.
**Tool anchor:** `clock_gettime(CLOCK_MONOTONIC_RAW, &ts)` at each stage boundary; diff into an HdrHistogram per stage.
**Drill:** Your dashboard shows "median latency 6µs, p99 40µs." A teammate says the handler is "fast enough." What two questions do you ask before agreeing, and which percentile actually matters for a strategy that reacts to every book update?
**Tags:** latency-budget, measurement-boundary, hot-path, tick-to-trade, per-stage

### Per-stage timestamping — instrument the pipeline, not just the ends
The single most useful instrumentation is a timestamp captured at each pipeline boundary: `t_birth` (generator/exchange), `t_receive` (after the recv syscall returns), `t_parsed` (after SBE decode), `t_book_updated`, `t_published`, `t_consumed`. Per-stage deltas turn one opaque end-to-end number into a decomposition that tells you *which* stage to optimize. The seed pipeline does exactly this and budgets ~120ns total for six stamps (6 × ~20ns), under 1% of a 10µs budget — small enough not to perturb the thing it measures.
**Key concepts:** stage stamps (t_receive/t_parsed/t_book_updated/t_published), latency decomposition, instrumentation overhead budget, amortization
**Tip:** Store stamps in a pre-allocated per-thread ring and flush on a background thread — never format, log, or `malloc` on the hot path. A single hot-path `printf` or allocation shows up directly in p99.
**Tool anchor:** pre-allocated `std::array<uint64_t, N>` per message slot; background flush every ~1s.
**Drill:** End-to-end p99 is 50µs. Your six per-stage stamps show t_receive→t_parsed = 3µs, t_parsed→t_book_updated = 4µs, but t_birth→t_receive = 42µs. Where is the problem, and why is "optimize the SBE decoder" the wrong first move?
**Tags:** timestamping, per-stage, decomposition, instrumentation-overhead, hot-path-discipline

### Clock sources — CLOCK_MONOTONIC_RAW, vDSO, and why not wall-clock
For interval measurement use a *monotonic* clock, never wall-clock (`CLOCK_REALTIME`) which can jump on NTP steps. `CLOCK_MONOTONIC_RAW` is not slewed by NTP/adjtime, making it the right choice for raw deltas. On modern x86-64 kernels these reads are served from the **vDSO** (a kernel page mapped read-only into the process) so no syscall/ring transition occurs — the call reads the TSC in userspace, applies a mult/shift, and returns nanoseconds. A `clock_gettime()` vDSO call typically costs on the order of tens of ns once `CLOCK_MONOTONIC_RAW` has vDSO support (added to the x86 vDSO in Linux 5.3, 2019; before that it fell back to a real syscall on x86 and was *slower* despite doing less).
**Key concepts:** monotonic vs realtime, CLOCK_MONOTONIC_RAW (no NTP slew), vDSO (no syscall), TSC-backed read, mult/shift conversion, COARSE variants
**Tip:** Verify the clocksource is TSC: `cat /sys/devices/system/clocksource/clocksource0/current_clocksource` — and that `/proc/cpuinfo` flags include `constant_tsc` and `nonstop_tsc`. If the clocksource is `hpet`, your reads are far slower and noisier.
**Tool anchor:** `cat /sys/devices/system/clocksource/clocksource0/current_clocksource`; `grep -o 'constant_tsc\|nonstop_tsc' /proc/cpuinfo`
**Drill:** Your latency histogram occasionally shows *negative* deltas. What clock did someone likely use, what happened, and which clock fixes it without paging the kernel?
**Tags:** clock-monotonic-raw, vdso, tsc, clocksource, no-syscall, ntp-slew

### rdtsc vs clock_gettime — the raw counter and its hazards
`rdtsc` reads the 64-bit Time Stamp Counter directly (~20–25 cycles reciprocal throughput on Skylake) — faster than even the vDSO `clock_gettime` (~200 cycles / ~25–100ns). The catch: `rdtsc` is **not serializing**. Out-of-order execution can read the counter before earlier instructions retire or after later ones start, corrupting tight measurements by 10–30%. The fixes: `rdtscp` (waits for prior instructions to retire — one-directional barrier), or `lfence; rdtsc` (Intel's documented equivalent), or `cpuid; rdtsc` (full barrier but ~100–250 cycles and high variance, so keep it *outside* the measured region). For µs-scale pipeline stamps the vDSO clock is usually fine; raw `rdtsc` is for sub-100ns micro-benchmarks. Requires an *invariant* TSC (`constant_tsc`/`nonstop_tsc`).
**Key concepts:** rdtsc reciprocal throughput, non-serializing read, out-of-order contamination, rdtscp, lfence;rdtsc, cpuid;rdtsc, invariant TSC
**Tip:** Use `lfence;rdtsc` at the start and `rdtscp` at the end of a micro-benchmarked region — barrier the start cheaply, read+barrier the end with rdtscp, and subtract the measured overhead of the instruction pair itself.
**Tool anchor:** `#include <x86intrin.h>`; `_mm_lfence(); uint64_t s=__rdtsc(); /* work */ unsigned a; uint64_t e=__rdtscp(&a);`
**Drill:** A colleague brackets a 5-instruction SBE field accessor with bare `__rdtsc()` and reports it costs "1 cycle." Explain how out-of-order execution produced that nonsense and which two instruction sequences give a trustworthy number.
**Tags:** rdtsc, rdtscp, lfence, serializing, out-of-order, micro-benchmark

### Percentiles, not averages — p50/p99/p999 and why the mean lies
Latency distributions are heavily right-skewed: a fast bulk plus a long tail. The **mean is dragged toward the bulk and hides the tail entirely** — "average 6µs" can coexist with "p99 40µs." For market data the tail *is* the product: a strategy reacts to every update, so the slow 1-in-100 (p99) or 1-in-1000 (p999) updates are real money, not noise. Track p50 (typical), p99 (1% slowest), p999 (0.1% slowest) together. The gap between them diagnoses the cause: p50 low + p99 high = a *tail* problem (pauses, contention, cold cache, page fault); p50 and p99 rising *together* = systemic saturation (out of capacity).
**Key concepts:** right-skewed distribution, mean vs median, p50/p99/p999, tail latency, p50↔p99 gap as diagnostic, queueing
**Tip:** Quote the percentile that matches consumption. A burst-reacting strategy is exposed to your p99/p999, not your mean — and at high rates "rare" stops being rare (0.1% of 500k msg/s ≈ 500 slow updates/sec).
**Tool anchor:** HdrHistogram `getValueAtPercentile(99.0)`, `(99.9)`; plot p50/p99/p999 time-series vs message rate.
**Drill:** Two builds: A has p50=5µs, p99=8µs; B has p50=4µs, p99=60µs. B "wins on average." Which do you ship for a latency-sensitive consumer, and what does B's p50↔p99 gap suggest is wrong?
**Tags:** percentiles, tail-latency, mean-vs-median, p99, p999, distribution-shape

### HdrHistogram — high dynamic range, constant footprint, ~3–6ns record
HdrHistogram is the standard tool for hot-path latency capture: it records value counts across a configurable range at a configurable precision (significant digits), with **constant memory footprint** and **constant-time recording** (~3–6ns/record on modern Intel; ~185KB for a 0–3.6e9 range at 3 sig-digits). Internally it's float-like: exponentially-growing buckets (the "exponent") each with linear sub-buckets (the "mantissa"), giving wide range at controlled relative error (3 sig-digits ⇒ ≤0.1% quantization at any value). No allocation on record, no searching — so it's safe on the hot path, unlike storing raw samples.
**Key concepts:** significant value digits, highestTrackableValue, constant footprint (~185KB example), constant-time record (~3–6ns), bucket/sub-bucket (exponent/mantissa), no hot-path allocation
**Tip:** Pick `highestTrackableValue` generously (e.g. 1s in ns) and 3 sig-digits — over-recording costs almost nothing in footprint, but truncating large outliers (clamp / array-bounds throw) silently hides your worst tail.
**Tool anchor:** HdrHistogram-C `hdr_init(1, 1000000000, 3, &h)`; `hdr_record_value(h, delta_ns)`; `hdr_value_at_percentile(h, 99.9)`.
**Drill:** Your handler records into an HdrHistogram with `highestTrackableValue` = 10µs. The exchange has a 2ms gap-recovery pause. What does your p999 report, and why is the histogram now lying about your worst case?
**Tags:** hdrhistogram, significant-digits, constant-footprint, percentile-recording, hot-path-safe

### Throughput vs latency — two different numbers, two different tests
Throughput (messages/sec the handler can sustain) and latency (time one message takes) are distinct and measured differently. A batching design can have *high* throughput and *bad* per-message latency (it waits to fill a batch); a per-packet design has low latency but lower peak throughput. For a feed handler both matter: you must sustain the open-burst rate (throughput, ~500k–1M msg/s in the seed scenarios) *and* keep per-update latency in budget. Measure them separately — saturate the input to find max throughput, then measure latency at a *fixed* sub-saturation rate. Reporting "X µs at Y msg/s" is the only honest form; a latency number without its load level is meaningless because latency rises as you approach saturation.
**Key concepts:** throughput vs latency, batching tradeoff, peak msg/s, latency-at-fixed-rate, "X µs at Y msg/s", saturation
**Tip:** Never report a latency number without the offered load it was measured at. The same handler is "8µs" at 50k msg/s and "200µs" at 500k msg/s — the rate is half the fact.
**Tool anchor:** drive a fixed rate from the feed generator; HdrHistogram for latency, message counter / time for throughput; sweep rate to build the curve.
**Drill:** A vendor claims their decoder does "2M msg/s" and "5µs latency." Why can both be true yet useless together, and what single missing qualifier would make the latency number meaningful?
**Tags:** throughput, latency, batching-tradeoff, offered-load, saturation, fixed-rate

## intermediate

### Coordinated omission — the bias that hides your worst latency
Coordinated omission is the most common latency-measurement bug: when the system stalls, the very samples that *would* show the stall are never recorded, because the measuring loop is itself blocked. Classic example: sample every 10ms, system is perfect for 100s (10,000 samples @ 1ms), then stalls 100s (one sample @ 100s). Uncorrected, ~99.99% of samples read ≤1ms — "looks fine" — when the system was broken for half the run. For a feed handler this happens when you stamp *inside* the processing loop: a 2ms stall (gap recovery, page fault, scheduler preemption) suppresses the thousands of queued messages that were also late. HdrHistogram corrects it via `recordValueWithExpectedInterval(value, expectedInterval)`, which synthesizes the missing decreasing samples; or post-hoc via `copyCorrectedForCoordinatedOmission` (use exactly one — never both).
**Key concepts:** coordinated omission, expected interval, synthesized samples, in-loop stamping bias, recordValueWithExpectedInterval, copyCorrectedForCoordinatedOmission
**Tip:** If you stamp arrival-to-processed *per message inside the consumer loop*, you're vulnerable: a stalled consumer stops pulling, so the backed-up messages never get a "late" stamp. Stamp against *expected arrival time* (from sequence/birth timestamp), or correct with the expected interval.
**Tool anchor:** HdrHistogram `recordValueWithExpectedInterval(delta_ns, expected_interarrival_ns)`.
**Drill:** Your consumer pulls from the shm ring in a loop and stamps `t_consumed - t_published` per item. A 5ms pause hits the producer's host. Explain why your p999 barely moves, name the bias, and give the one-line HdrHistogram fix.
**Tags:** coordinated-omission, expected-interval, measurement-bias, tail-hiding, hdrhistogram

### perf stat and IPC — the cheap first-pass health check
Before profiling, get the counters: `perf stat` gives cycles, instructions, **IPC**, branch-misses, cache-misses with near-zero perturbation. IPC is the single most useful first number — superscalar cores can retire 4–6 uops/cycle but real code lands 1.0–2.5; IPC < 1.0 means the pipeline is stalled (the *why* needs top-down). For the feed handler, run `perf stat` on a fixed replay (real CME pcap from DataMine) so the workload is reproducible. A drop in IPC between two builds, or between 1 instrument and 50, is your earliest signal of a cache or branch regression. See `/perf cpu` for IPC interpretation depth.
**Key concepts:** perf stat counters, IPC, branch-misses, cache-misses, reproducible replay, low perturbation
**Tip:** IPC can mislead with SIMD (one AVX instruction = many scalar ops) and is meaningless without a fixed input — always replay the *same* pcap so cycle/instruction counts are comparable run-to-run.
**Tool anchor:** `perf stat -e cycles,instructions,branches,branch-misses,L1-dcache-load-misses -- ./handler --replay capture.pcap`
**Drill:** Replaying the same pcap, IPC is 2.4 with 1 instrument but 0.7 with 50 instruments. Branch-miss rate is unchanged. What's the most likely cause, and which `perf stat` event confirms it?
**Tags:** perf-stat, ipc, branch-miss, cache-miss, reproducible-replay, first-pass

### Top-down (TMA) — classify the bottleneck before optimizing
Top-Down Microarchitecture Analysis splits every pipeline slot into exactly four buckets that sum to 100%: **Frontend Bound** (frontend didn't deliver uops — I-cache/decode), **Backend Bound** (backend couldn't accept — usually cache/memory), **Bad Speculation** (mispredicts/machine clears), **Retiring** (useful work). The largest bucket tells you *what* to fix — don't guess. For the SBE decode + book-update loop, Backend Bound usually means data-layout/cache (the book, the dispatch array); Bad Speculation points at the template-ID switch or schema-version branch; Frontend Bound points at template/inlining code bloat. High Retiring with low IPC means the *algorithm* is the problem (vectorize/restructure), not the uarch. Cross-link `/perf cpu` (TMA L1) and `/perf methodology`.
**Key concepts:** TMA L1 four buckets, slot accounting, Frontend/Backend/Bad-Spec/Retiring, largest-bucket-first, Retiring≠done
**Tip:** Backend Bound dominating + high LLC-load-misses ⇒ working set exceeds cache (e.g. 50 books at once spilling L2/L3). Bad Speculation dominating + low branch-miss% ⇒ suspect machine clears (false sharing / memory-ordering), not ordinary mispredicts.
**Tool anchor:** `perf stat -M TopdownL1 -- ./handler --replay capture.pcap` (or `toplev.py -l1`)
**Drill:** v1 TMA = {FE 8%, BE 60%, BadSpec 7%, Retiring 25%}. After your fix v2 = {FE 25%, BE 15%, BadSpec 5%, Retiring 55%}. What did the fix most likely address, why did Frontend Bound *rise*, and is v2 done?
**Tags:** tma, topdown, backend-bound, bad-speculation, retiring, bottleneck-classification

### perf record sampling — frequency, skid, and PEBS precision
`perf record -F <hz>` samples the IP at a fixed frequency (default 1000Hz); higher frequency = more interrupts = more **observer effect** (the measurement steals cycles from the workload — "shades of Heisenberg"). For a hot path, oversampling perturbs the very timing you measure; ~5% overhead is a common acceptable ceiling. Worse, interrupt-based samples suffer **skid**: the recorded IP is where the PMU interrupt landed, not where the event occurred — possibly dozens of instructions away, so the profile blames the wrong load. The fix is **PEBS** (Intel) / IBS (AMD): the CPU writes the precise IP to a buffer (≤1 instruction skid) and only interrupts when the buffer fills — *less* skid *and* less overhead. Request it with the `:p`/`:pp`/`:ppp` modifier.
**Key concepts:** sampling frequency, observer effect, skid, PEBS/IBS, :p precision modifier, buffer-fill interrupts, shadow effect
**Tip:** For attributing cache misses to the *right* instruction in the book-update loop, use a precise event (e.g. `mem_load_retired.l1_miss:pp`) — plain `:` sampling will skid the blame onto a neighboring instruction and send you optimizing the wrong line.
**Tool anchor:** `perf record -e cycles:pp -F 4000 -g -- ./handler --replay capture.pcap`; `perf record -vv` to see `precise_ip`.
**Drill:** Your profile blames a `mov` 30 instructions after the binary-search load for 40% of L1 misses. Explain skid, name the hardware feature that fixes it, and give the exact `perf` event-name modifier you'd add.
**Tags:** perf-record, sampling-frequency, skid, pebs, precise-events, observer-effect

### perf c2c — finding false sharing between cores
`perf c2c` ("cache-to-cache") is the definitive tool for false sharing — the silent killer in the SPSC ring and the shm bus. It uses load-latency + precise-store events to match stores and loads across cores and surface **HITM** (Hit Modified): a load that misses local L1 and finds the line *modified* in another core's cache. High **remote HITM** (across NUMA nodes) is the strong signal of false sharing. Workflow: `perf c2c record` (run 3–10s only — longer and concurrent contention blurs into disjoint accesses) then `perf c2c report`; read "LLC Misses to Remote Cache (HITM)" in the trace-event table, then the per-cache-line Pareto, then map the byte offset to a struct field with `pahole`. The canonical MD case: SPSC `head_` (consumer-written) and `tail_` (producer-written) on one cache line — see `/perf concurrency`.
**Key concepts:** perf c2c, HITM (hit-modified), local vs remote HITM, ldlat, Pareto cache-line table, offset→field via pahole, 3–10s window
**Tip:** A non-trivial "LLC Misses to Remote cache HITM" number means real false sharing; map the hot offset to the field with `pahole <binary>` and fix with `alignas(64)` separation (or `alignas(std::hardware_destructive_interference_size)`).
**Tool anchor:** `perf c2c record --all-user -- ./pipeline`; `perf c2c report -NN -c pid,iaddr`; `pahole ./pipeline | less`
**Drill:** Your SPSC ring throughput is 3x lower than expected. `perf c2c` shows high remote HITM on one cache line at offsets 0 and 8. What two fields are colliding, why does the line "ping-pong," and what's the fix?
**Tags:** perf-c2c, hitm, false-sharing, remote-hitm, pahole, spsc-ring

### Benchmark stability — pin, isolate, fix frequency, warm up
A latency benchmark is worthless if the platform jitters more than the effect you're measuring. Sources of noise to kill before trusting any number: (1) CPU frequency scaling — set governor to `performance`, since dynamic governors like `schedutil` re-evaluate and switch P-states under load, adding frequency-transition jitter and run-to-run variance; (2) core migration — pin with `taskset`/`pthread_setaffinity_np`; (3) SMT sibling contention — disable the HT sibling of the pinned core (gives the thread the full core resources, e.g. the un-partitioned ROB, measurably lowering the p99 tail — see `/perf cpu` SMT); (4) cold caches/first-touch — warm up before recording; (5) NUMA — `numactl --membind` to keep memory local. Reproducibility comes from replaying the *same* CME pcap each run.
**Key concepts:** performance governor, core pinning, SMT sibling disable, warm-up, NUMA binding, fixed input, run-to-run variance
**Tip:** `cpupower frequency-set -g performance` before benchmarking; if `turbostat` shows the core swinging 2.8↔4.7GHz, your "15% improvement" may be pure frequency noise. Also compare `cycles` vs `ref-cycles` — if `cycles < ref-cycles` the core ran below TSC rate (throttling).
**Tool anchor:** `cpupower frequency-set -g performance`; `taskset -c 3 numactl --membind=0 ./bench`; `turbostat -- ./bench`
**Drill:** Your SBE-decode micro-benchmark shows 15% variance across runs. `turbostat` shows frequency swinging 2.8–4.7GHz. List three changes to stabilize it and explain how `cycles` vs `ref-cycles` reveals throttling after the fact.
**Tags:** benchmark-stability, cpu-governor, affinity, smt, numa, warm-up, variance

### Sample size and statistical confidence in tail percentiles
A percentile is only as trustworthy as the sample count behind it. p99 from 50 samples is essentially noise — it's governed by your single slowest point; you need hundreds–thousands of samples per window for a stable p99, and *far* more for p999 (a stable p999 needs on the order of tens of thousands). At 500k msg/s a feed handler generates samples fast, so the constraint is usually the *window* length, not throughput. The deeper trap: **you cannot average per-shard/per-window percentiles** to get an aggregate — percentiles must be merged from the underlying counts. HdrHistogram supports this correctly: merge the *histograms* (add count arrays), then read the percentile; never average two p99 numbers.
**Key concepts:** samples-per-percentile, p999 needs ≥~10k samples, non-averageable percentiles, histogram merge, window length
**Tip:** To get a cross-host or cross-interval aggregate tail, merge the HdrHistograms (`add`) and read the percentile from the merged histogram — averaging two hosts' p99 values is mathematically wrong and usually understates the true tail.
**Tool anchor:** HdrHistogram `histogram.add(other)` then `getValueAtPercentile(99.9)`; never `mean(p99_a, p99_b)`.
**Drill:** Monitoring averages each minute's p99 into an hourly p99. Why is the hourly number wrong, in which direction does it typically err, and what aggregation does HdrHistogram give you instead?
**Tags:** sample-size, p999-confidence, percentile-aggregation, histogram-merge, statistics

### Burst metrics — spike depth, recovery time, queue growth
Steady-state percentiles miss the thing market data cares about most: behavior under bursts (market open, news spikes — the seed's scenarios reach 500k–1M msg/s). Beyond p50/p99/p999 you measure burst-specific signals: **spike depth** (how high p99 climbs during the burst), **recovery time** (how long until latency returns to baseline after the burst ends), **queue/ring high-water mark** (max depth of the recv batch / SPSC ring / shm ring during the burst — the leading indicator of impending overflow), and **drop/overwrite count**. A handler that's fine at 50k msg/s can collapse at the open; only burst metrics expose the cliff. Plot latency time-series *overlaid with message rate* so cause (rate) and effect (latency) are visible together.
**Key concepts:** spike depth, recovery time, queue high-water mark, overwrite/drop count, latency-vs-rate overlay, burst cliff
**Tip:** Queue depth is a *leading* indicator; latency is *lagging*. Watch the SPSC/shm ring high-water mark during the burst — it climbs before p99 does, giving the earliest warning of saturation. (Overwrite-on-full is the correct MD policy — see `/perf concurrency`; count the overwrites as a metric.)
**Tool anchor:** per-burst HdrHistogram + atomic max-depth counter on each ring; CSV export, plot p99/p999 vs msg/s time-series.
**Drill:** During a simulated open at 500k msg/s, p99 climbs to 200µs and takes 8s to recover after the burst ends. Ring high-water hit 90% of capacity. Is the bottleneck throughput or latency, what does the slow recovery tell you, and which metric warned you first?
**Tags:** burst-metrics, spike-depth, recovery-time, high-water-mark, queue-depth, latency-vs-rate

### The latency-vs-load curve and the saturation knee
The most informative single chart for a feed handler is p99 latency plotted against offered message rate. It's flat-and-low while there's headroom, then bends sharply upward at the **saturation knee** — the rate beyond which the handler can't keep up and queues start growing without bound (latency → ∞). The knee, not any single-point number, is your real capacity: a handler with an 8µs p99 at 50k msg/s but a knee at 300k msg/s will fall over at the open (which can exceed that). Sweep the rate, find the knee, and leave headroom above the worst expected burst. Past the knee, latency is dominated by queueing delay (Little's Law: queued time grows as utilization → 1), so the fix is capacity/parallelism, not micro-optimizing the per-message path.
**Key concepts:** latency-vs-load curve, saturation knee, capacity headroom, queueing delay, Little's Law, utilization→1
**Tip:** Capacity is the knee, not the peak you survived once. Size for the *worst* burst (news/open) plus headroom; if the knee is below your expected open rate, no amount of shaving nanoseconds off the decoder saves you — you need more parallelism or a faster receive path.
**Tool anchor:** feed generator rate sweep; plot p99/p999 vs msg/s; mark where the curve bends and where ring depth starts climbing.
**Drill:** Your p99-vs-rate curve is flat at ~7µs until 280k msg/s, then shoots to 500µs by 320k. The open hits 350k. Where is the knee, what does crossing it do to the queue, and is "optimize the SBE decoder by 20%" the right response?
**Tags:** latency-vs-load, saturation-knee, capacity, queueing, littles-law, headroom

## advanced

### Hardware timestamping & PTP — measuring before the kernel touches the packet
Software stamps (`t_receive` after `recvmmsg`) include host-stack jitter — typically several dozen µs, sometimes up to ~200µs — so to measure the *true* wire-arrival time you need **NIC hardware timestamps** via `SO_TIMESTAMPING` with `SOF_TIMESTAMPING_RX_HARDWARE`/`SOF_TIMESTAMPING_RAW_HARDWARE`. The NIC stamps at L1/L2 from its on-board PTP Hardware Clock (PHC), ~1–10ns resolution, delivered in the `recvmsg` control message (`cmsg`). The PHC is disciplined to UTC by PTP (IEEE 1588): `ptp4l` syncs PHC↔master, `phc2sys` syncs system-clock↔PHC. This is also the regulatory path — MiFID II RTS 25 demands 100µs UTC accuracy + 1µs granularity for HFT activity, unachievable with NTP. Check support with `ethtool -T`; steer PTP/feed traffic to one RX ring (RSS can reorder it).
**Key concepts:** SO_TIMESTAMPING, SOF_TIMESTAMPING_RX_HARDWARE, PHC, ptp4l/phc2sys, IEEE 1588, cmsg delivery, ethtool -T, RTS 25 (100µs/1µs)
**Tip:** Size the control-message buffer with `CMSG_SPACE(...)` or the hardware timestamp is silently truncated; and verify with `ethtool -T` that the NIC reports *RX* hardware support (a common failure is TX-only or vice-versa).
**Tool anchor:** `ethtool -T eth0`; `setsockopt(fd, SOL_SOCKET, SO_TIMESTAMPING, &flags, ...)` with `SOF_TIMESTAMPING_RX_HARDWARE|SOF_TIMESTAMPING_RAW_HARDWARE`; read via `recvmsg` cmsg.
**Drill:** Your software `t_receive` shows wire→receive of 60µs p99 but the strategy team's NIC-stamped capture shows the packet arrived ~55µs earlier. Where did the time go, which socket option measures it directly, and what daemon pair keeps the NIC clock traceable to UTC?
**Tags:** hardware-timestamping, so-timestamping, phc, ptp, rts-25, host-stack-jitter

### Distinguishing OS jitter from queue latency in the tail
A p99 spike has two broad causes that demand opposite fixes: **OS/host jitter** (a one-off stall — scheduler preemption, page fault, IRQ, frequency transition, SMT contention, a `malloc` hitting the kernel) versus **queue latency** (sustained backlog — the consumer can't keep up so messages wait). They look identical on an end-to-end histogram; per-stage stamps + queue depth separate them. Signature of OS jitter: the spike is *isolated* (one message late, neighbors fine), correlates with a system event, and queue depth stays low. Signature of queue latency: the spike is *correlated* across a run of consecutive messages and the ring high-water rises. The "p99 spikes every ~10ms" question is the canonical drill — periodicity ≈ a timer tick / IRQ ⇒ OS; ramp tied to message rate ⇒ queue.
**Key concepts:** OS jitter vs queue latency, isolated vs correlated spikes, periodicity analysis, queue-depth correlation, page fault/preemption/IRQ
**Tip:** Correlate the latency time-series with `perf sched`/`/proc/interrupts`/`sar` and with ring depth simultaneously. Periodic spikes (fixed interval, independent of rate) are almost always OS/timer/IRQ; rate-dependent ramps are queueing. `mlockall` + pre-fault kills the page-fault class entirely.
**Tool anchor:** `perf record -e sched:sched_switch -e page-faults -g`; overlay against per-message latency + ring high-water; `cat /proc/interrupts` before/after.
**Drill:** p99 spikes to 30µs at a near-perfect 10ms period regardless of message rate; queue depth never exceeds 2. Is this OS or queue? Name two likely OS sources and the isolation step (and one config change) that confirms and fixes it.
**Tags:** os-jitter, queue-latency, tail-diagnosis, periodicity, page-fault, mlockall

### Production latency monitoring — measuring the live feed without perturbing it
Benchmarking is offline and reproducible; production monitoring must be continuous, low-overhead, and non-perturbing — the same per-stage HdrHistogram instrumentation, but with a background flush and bounded cost. The owner's question shifts from "how fast is build X" to "is the *live* feed healthy right now": export rolling p50/p99/p999 per stage, gap/recovery counts, A/B feed arbitration lag, ring high-water, and overwrite counts. The instrumentation must obey the same hot-path rules as the handler itself: pre-allocated buffers, no logging/allocation on the hot path, ~120ns total stamp budget (<1% of 10µs). Coordinated-omission correction matters *more* in production because real stalls (gap recovery, exchange pauses) are exactly the events monitoring exists to catch.
**Key concepts:** continuous monitoring vs offline benchmark, rolling percentiles, A/B arbitration lag, gap/recovery counters, non-perturbing instrumentation, owner SLIs
**Tip:** Snapshot the histogram on the background thread with a `Recorder` (lock-free/wait-free record + interval sampling) so the hot path never blocks on a reader copying the histogram out for export.
**Tool anchor:** HdrHistogram `Recorder` + interval `getIntervalHistogram()`; background thread exports rolling p50/p99/p999 + gap/overwrite counters.
**Drill:** You own the live CME handler. List the five latency/health signals you'd put on the dashboard, which percentile each uses, and the one instrumentation rule that keeps the monitoring from becoming the latency problem it's measuring.
**Tags:** production-monitoring, rolling-percentiles, recorder, slis, non-perturbing, coordinated-omission

### Comparing receive strategies & layouts — disciplined A/B measurement
Many MD decisions are crossovers, not absolutes: `recvmmsg` vs `epoll` vs `io_uring` vs `SO_BUSY_POLL`; AoS vs SoA book; linear scan vs `std::lower_bound`; flat array vs `flat_map`. The measurement discipline is the same: fix everything else (same pcap, same pinned core, same governor), vary one axis, and report the *distribution* (p50/p99/p999), not a single mean — because the strategies differ most in the tail. `recvmmsg` batching only wins once packets reliably backlog in the socket queue — i.e. at high enough rates that a single call returns several messages (the seed uses ~100k pps as a working anchor, but the true break-even is hardware/workload-dependent, not a fixed number); below that, batching *adds* latency waiting for a batch. Busy-poll trades a burned core for lower wake-up latency; the AoS/SoA winner depends on the message mix (more searches favor SoA, more modifies favor AoS). The meta-rule from the seed: profile the *full* path first — if 80% of latency is the book update, optimizing receive is premature.
**Key concepts:** crossover benchmarking, one-axis-at-a-time, distribution not mean, recvmmsg break-even (queue-backlog dependent), busy-poll tradeoff, profile-full-path-first, message-mix dependence
**Tip:** Report break-even points, not winners: "recvmmsg beats epoll above the rate where the queue backlogs; below that it's slower" is a usable owner fact, whereas "recvmmsg is faster" is wrong half the time. Measure the crossover on your own hardware/pcap rather than trusting a fixed pps number. Tie every comparison to the burst scenario it'll actually run under.
**Tool anchor:** same pcap replayed through each strategy on a pinned/isolated core; HdrHistogram per strategy; overlay p99 vs pps to find the crossover.
**Drill:** Benchmarks say `io_uring`+SQPOLL has the best mean but `recvmmsg`+busy-poll has the best p99. The handler's dominant cost (per your per-stage stamps) is the book update at 70% of latency. What's the right next move, and why is "switch to io_uring" probably wrong?
**Tags:** ab-testing, receive-strategy, crossover, distribution-reporting, profile-first, aos-soa

### Validating correctness alongside latency — a fast wrong book is worthless
A measurement harness that only reports latency can ship a fast handler that builds the wrong book. For a feed-handler owner, correctness *is* a measured signal: after a replay/burst scenario, compare the final per-instrument book state against an independent reference (e.g. CME pcap-derived snapshot), count book mismatches, sequence gaps detected vs recovered, dropped vs overwritten messages, and snapshot↔incremental transition errors. Inject faults (`tc netem` packet loss, scripted sequence gaps) and verify gap/snapshot recovery actually restores correct state — measuring *recovery time* and *correctness after recovery* together. Latency without a correctness gate is how a "10x faster" change silently corrupts the book under loss.
**Key concepts:** book correctness as a metric, reference comparison, gap detected-vs-recovered, drop/overwrite accounting, fault injection (tc netem), recovery correctness
**Tip:** Gate every perf change behind a correctness check on the same replay: final book must match the reference snapshot *and* the gap-recovery path must reconstruct correct state under injected `tc netem` loss — otherwise you've optimized a bug.
**Tool anchor:** `tc qdisc add dev eth0 root netem loss 0.1%`; diff final book vs reference snapshot; counters for gaps detected/recovered, drops, overwrites.
**Drill:** A new SBE fast-path cuts p99 by 30% but a burst with 0.1% injected loss leaves 3 instruments with the wrong top-of-book. The latency numbers look great. Why do you reject the change, and which two non-latency metrics caught it?
**Tags:** correctness-validation, fault-injection, tc-netem, gap-recovery, book-correctness, perf-gate

## Sources
- HdrHistogram README + JavaDoc (coordinated omission, `recordValueWithExpectedInterval`, significant digits, constant footprint ~185KB, ~3–6ns record): github.com/HdrHistogram/HdrHistogram
- Linux kernel timestamping docs + `ethtool -T` / `SO_TIMESTAMPING` (PHC, PTP, RX hardware flags): docs.kernel.org/networking/timestamping.html; ptp4l/phc2sys (Red Hat PTP docs)
- `clock_gettime`/vDSO/`CLOCK_MONOTONIC_RAW` (vDSO ~tens of ns, TSC mult/shift; x86 vDSO support added in Linux 5.3, 2019 — Sverdlin patch series): kernel vDSO docs; lore.kernel.org x86/vdso CLOCK_MONOTONIC_RAW patch; btorpey "Measuring Latency in Linux"
- `rdtsc`/`rdtscp`/`lfence`/`cpuid` serialization (Intel SDM equivalence `LFENCE;RDTSC`≈`RDTSCP`, cycle costs): Intel SDM Vol 2/3; Agner Fog instruction tables
- `perf stat`/TMA/`perf record` skid/PEBS (`:p` modifier, default 1000Hz, observer effect, shadow effect): Brendan Gregg perf docs; Easyperf (skid, PEBS); perf-record(1) man page
- `perf c2c` HITM / remote HITM / `pahole` (false-sharing workflow): Joe Mario c2c blog; Red Hat "Detecting false sharing"; kernel false-sharing docs
- Tail-latency / percentiles / non-averageable percentiles (Gil Tene "outliers are the norm", p999 sample-size): danluu latency pitfalls; Aerospike/Redis p99 explainers
- MiFID II RTS 25 (100µs accuracy + 1µs granularity for HFT, UTC traceability): EU 2017/574; Meinberg / Pico / Corvil RTS 25 guides
- Seed prep plan (pipeline stages, ~120ns stamp budget, recvmmsg break-even working anchor ~100k pps — not a citable universal figure, burst scenarios, verification): attic/trading-prep.md
- Cross-domain theory: /perf cpu (IPC, TMA, SMT), /perf mem (cache/NUMA), /perf concurrency (false sharing, SPSC), /perf methodology
