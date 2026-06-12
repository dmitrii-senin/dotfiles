# Challenges: market-data — the build roadmap

Real-world build projects (the `challenge` mode bank), in build order, from the 3-week prototyping
roadmap (`attic/trading-prep.md`). Continuous — work in order, no hard dates. Each builds muscle memory
on a critical-path component and its performance tradeoffs. Stack: C++23 hot path, Rust feed generator,
Buck2, Linux bare metal, CME published MDP 3.0 SBE schema (4 msg types: 46/52/48/30).

Capture insights as you go in `records/`; persist durable write-ups in `notes/`.

---

## ch-01 — Feed Generator (Rust) · areas: sbe, cme-mdp, lowlat-net
Single Rust binary: reads TOML burst scenarios, SBE-encodes synthetic MDP 3.0 (`MDIncrementalRefreshBook` 46,
`SnapshotFullRefresh` 52, `MDIncrementalRefreshTrade` 48, `SecurityStatus` 30) for 10–50 instruments, sends
multicast UDP with birth timestamps, rate control via `Instant`, fault injection (drops, seq gaps).
**Tech:** `serde`/`toml`, `std::net::UdpSocket` multicast, `byteorder`, `#[repr(C, packed)]`. Buck2 `rust_binary`.
**Done:** 4 burst profiles (market_open, sustained, news_spike, recovery) emit valid SBE that the ch-02 decoder parses.

## ch-02 — SBE Zero-Copy Codec, decode-only (C++23) · areas: sbe
Flyweight decoder overlaying typed accessors on raw buffers, no memcpy. Groups (variable offsets), var-data,
header dispatch. Benchmark flyweight vs naive deserialize-to-struct.
**Tech:** `std::start_lifetime_as` (UB-free overlay), `std::byteswap`, `std::span`, `std::expected`, deducing `this`, cursor accessors.
**Done:** decodes all 4 types; benchmark shows flyweight ≥ naive; `-fsanitize=undefined` clean.
**Grill:** eager vs lazy byteswap crossover? aligned vs unaligned overlay cost? schema v1→v2 without per-message misprediction?

## ch-03 — Lock-Free SPSC Ring Buffer (C++23) · areas: systems  (cross-ref /perf concurrency)
Bounded SPSC queue from scratch, cache-line padded, acquire/release only, latency histogram. Extend to MPSC (CAS).
**Tech:** `std::atomic`, `alignas(64)`, `hardware_destructive_interference_size`, `std::expected` try-push/pop. Google Benchmark.
**Done:** false-sharing demo (head/tail same line vs 64B apart → 3–10x); p50/p99/p999 reported.
**Grill:** why is `seq_cst` overkill for SPSC — what breaks with `relaxed` on the wrong side? p99 spike every ~10ms — queue or OS? MPSC CAS-retry vs N×SPSC under 4 producers?

## ch-04 — Order Book Engine (C++23) · areas: orderbook, systems
Per-instrument L2 book from incrementals (new/modify/delete/trade), flat sorted array (not `std::map`),
implied prices. Instrument dispatcher: SecurityID → book via pre-allocated array (dense IDs). 50 instruments × 500k msg/s.
**Tech:** `std::flat_map` baseline, `std::to_underlying`, `std::unreachable()` in dispatch, `perf stat`.
**Done:** correct book vs expected; benchmark flat-array vs flat_map; AoS vs SoA L1-miss comparison.
**Grill:** implied prices — one book or two (cache cost)? `lower_bound` vs linear scan crossover N? snapshot→incremental transition without double-count/miss?

## ch-05 — Multicast UDP Feed Handler (C++23) · areas: feed-handler, lowlat-net  (the reliability core)
Join CME multicast (incremental + snapshot channels), sequence gap detection, snapshot recovery, batch parsing.
Compare `recvmmsg` vs `epoll` vs `io_uring` vs `SO_BUSY_POLL`. Wires ch-02..04 into a pipeline.
**Tech:** `recvmmsg`, `SO_REUSEPORT`, `IP_ADD_MEMBERSHIP`, `liburing`, `std::expected`, `std::print`.
**Done:** recovers from injected gaps; receive-strategy latency comparison under each burst; A/B arbitration sketch.
**Grill:** recvmmsg break-even pps? when does busy-poll lose to epoll? where does 80% of latency actually live (measure first)?

## ch-06 — Shared Memory IPC Bus (C++23) · areas: systems, measurement  (cross-ref /perf mem)
Publish normalized book updates via lock-free ring over `mmap` shm (reuse ch-03). Seq numbers for consumer gap
detection. Overwrite policy (producer never blocks; stale > lost). Python consumer.
**Tech:** `mmap`, `MAP_HUGETLB`/`madvise(MADV_HUGEPAGE)`, cache-line slots, `start_lifetime_as`; Python `mmap`+`ctypes`.
**Done:** late-joining consumer starts at `latest_sequence`; NUMA-pinned vs cross-node latency measured.
**Grill:** how to signal a late joiner where to start? cross-node shm penalty — how to pin producer+consumer?

## ch-07 — Measurement Harness (C++23) · areas: measurement
Embedded timestamps at 6 stages (`t_birth`..`t_consumed`), per-stage deltas in HdrHistogram, CSV export. Integrated, not separate.
**Tech:** `clock_gettime(CLOCK_MONOTONIC_RAW)` (~20ns vDSO), HdrHistogram-C, pre-allocated per-thread buffer + background flush.
**Done:** <1% overhead at 10µs budget; per-stage p50/p99/p999 over time vs rate.

## ch-08 — Analysis Dashboard (Python) · areas: measurement
Read latency CSVs; plot p50/p99/p999 over time overlaid with rate; burst metrics: spike depth, recovery time,
loss count, end-state book correctness.
**Tech:** `matplotlib`, `pandas`, `hdrhistogram`. Buck2 `python_binary`.

## ch-09 — End-to-End (capstone) · areas: all
Run all 4 burst scenarios end-to-end; profile the full pipeline (top-down per stage); `tc netem` packet loss →
verify gap recovery; verify book correctness; answer every grilling question with a measurement.
**Done:** a written latency/reliability report per scenario, decisions backed by `perf`/HdrHistogram data.

---

### Verification (per challenge)
Unit tests (synthetic CME-like sequences) · integration (CME DataMine pcaps) · Google Benchmark p50/p99/p999 ·
`perf stat` IPC/cache-miss/branch-miss · naive-vs-optimized delta quantified.
