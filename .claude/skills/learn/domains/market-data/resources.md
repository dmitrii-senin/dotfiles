# Resources: market-data — vetted, PUBLIC sources only

**Confidentiality:** never cite or encode firm-internal systems, codebases, docs, or strategy. Everything
here is publicly available. Cite the source for precise facts (wire fields, msg types, syscall semantics,
cycle/latency figures); flag anything unattributable as `⚠ unsourced — verify`.

## CME MDP 3.0 (protocol — authoritative)
- **CME Globex Market Data Platform (MDP 3.0)** client documentation — CME public docs / CME Globex
  client systems wiki (message types, packet structure, channels, recovery, A/B feeds).
- **CME published MDP 3.0 SBE schema XML** (the template/schema definitions — the ground truth for fields).
- **CME DataMine** — sample/historical packet captures for integration testing.

## SBE / encoding
- **Real Logic `simple-binary-encoding`** (github.com/real-logic/simple-binary-encoding) — the codec the
  real handler uses; README + generated-code conventions.
- **FIX SBE specification** (FIX Trading Community) — the encoding standard.
- **Real Logic `aeron`** (github.com/real-logic/aeron) — transport/messaging context.

## Linux I/O, kernel, host tuning
- **Michael Kerrisk, *The Linux Programming Interface*** — sockets, multicast, syscalls.
- **Kernel & man pages** — `recvmmsg(2)`, `socket(7)`, `ip(7)` (multicast, `SO_REUSEPORT`, `SO_BUSY_POLL`),
  `io_uring`/`liburing`, hugepages (`MAP_HUGETLB`, `madvise`), `mlockall(2)`, `ethtool(8)`, `isolcpus`,
  `sched(7)`, `numa(7)`/`numactl`.
- **HW timestamping / PTP** — kernel `SO_TIMESTAMPING` docs, `linuxptp` (ptp4l/phc2sys).
- **Kernel-bypass (awareness)** — Solarflare **Onload**/**ef_vi** docs, **DPDK** docs (decision-level).

## Low-latency C++ / systems / perf
- **cppreference** — C++23 (`std::start_lifetime_as`, `std::expected`, `std::byteswap`, `std::bit_cast`,
  `[[assume]]`, deducing `this`, `std::flat_map`, `hardware_destructive_interference_size`).
- **Cross-reference the `perf` domain** (`resources.md` there): Agner Fog, Intel Optimization Manual,
  Brendan Gregg *Systems Performance*, `perf`/`toplev`, `llvm-mca` — the deepest CPU/cache/concurrency theory.
- **HdrHistogram** (and HdrHistogram-C) — latency measurement.
- Reference implementations to study (write your own): Folly `ProducerConsumerQueue`, `crossbeam` (Rust).

## Market microstructure / prop-HFT domain
- **Larry Harris, *Trading and Exchanges*** — microstructure (already read).
- **Cartea, Jaimungal, Penalva, *Algorithmic and High-Frequency Trading*** — HFT mechanics.
- **CME Group education** (public) — futures, Globex mechanics, market state/trading-day lifecycle.

> Personal prep roadmap (seed for challenges, not a citable source): `attic/trading-prep.md`.
