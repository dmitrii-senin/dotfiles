# Domain: market-data — CME market-data infrastructure

title: CME Market-Data Infrastructure (feed-handler ownership)
level: strong low-level C++/Rust + serialization (Meta) + microstructure theory (Harris); new to prop-HFT
       I/O/kernel layer and CME operations. Skip generic C++/CS basics; go deep on the MD-specific stack.

## Areas

`cme-mdp`, `sbe`, `feed-handler`, `lowlat-net`, `orderbook`, `systems`, `measurement`, `ownership`

| Area key | Scope | Keywords | Knowledge file |
|---|---|---|---|
| `cme-mdp` | CME MDP 3.0 workflow | packet header, incremental/snapshot refresh, msg types 46/52/48/30, channels, sequence numbers, gap detection, snapshot recovery, A/B arbitration, market state, schema evolution | `knowledge/cme-mdp-bank.md` |
| `sbe` | Simple Binary Encoding | schema XML, message header (block length/template id/schema id/version), groups, var-data, flyweight zero-copy decode, endianness, alignment, `start_lifetime_as`, Real Logic/Aeron codec | `knowledge/sbe-bank.md` |
| `feed-handler` | multicast I/O + reliability | `recvmmsg`/`epoll`/`io_uring`/`SO_BUSY_POLL`, batching, gap detection, snapshot recovery, backpressure/overwrite, `SO_REUSEPORT` | `knowledge/feed-handler-bank.md` |
| `lowlat-net` | host/kernel/NIC | NIC tuning (`ethtool`, coalescing, RSS), CPU isolation (`isolcpus`, affinity, `SCHED_FIFO`, IRQ), `mlockall`, hugepages, NUMA, HW timestamping/PTP, kernel-bypass awareness (Onload/ef_vi/DPDK) | `knowledge/lowlat-net-bank.md` |
| `orderbook` | book building + microstructure | L2 from incrementals, flat array vs `std::map`/`flat_map`, AoS vs SoA, instrument dispatch, implied prices, snapshot↔incremental transition, correctness | `knowledge/orderbook-bank.md` |
| `systems` | low-lat primitives (MD-flavored) | SPSC/MPSC rings, shm IPC over `mmap`, false sharing, cache layout, allocators, prefetch, branch behavior, SIMD, I-cache | `knowledge/systems-bank.md` |
| `measurement` | latency methodology | per-stage timestamping, HdrHistogram p50/p99/p999, `perf` stat/top-down/`c2c`, burst metrics, benchmarking | `knowledge/measurement-bank.md` |
| `ownership` | prop-HFT domain + service ownership | MD reliability/SLA semantics, trading-day lifecycle, what a feed-handler owner monitors, recovery runbooks, the Meta→prop gap (public knowledge only) | `knowledge/ownership-bank.md` |

### Area prerequisites (ZPD ordering)
- `cme-mdp` + `sbe` are foundational (the protocol you decode); prefer first.
- `systems` underpins `feed-handler` and `orderbook` (the primitives they're built from).
- `lowlat-net` pairs with `feed-handler`; `measurement` pairs with everything (measure before optimizing).
- `ownership` is standalone (the domain/service-owner mindset).

## Modes

enabled: `mm`, `flash`, `drill`, `challenge`, `cheatsheet`, `status`
default: `status`
no `schedule` — continuous mastery (like perf), not exam-gated. Flashcards inject immediately.

- **`systems`/`measurement`** are MD-flavored duplicates of `perf` material by design — cross-link to
  `/perf concurrency`, `/perf mem`, `/perf methodology` for the deepest theory; here it's applied to the feed pipeline.

## Drill flavor
Use the style of the plan's "grilling questions" + "experiments" (seeds in `scenarios/grilling-questions.md`):
- **Scenario diagnosis** — "p99 spikes every ~10ms — queue or OS? how to isolate?"; "IPC dropped, top-down says Backend Bound — what next?"
- **Benchmark-crossover** — "at what N does `std::lower_bound` beat linear scan?"; "AoS vs SoA for this message mix?"
- **Design-under-constraint** — "schema v1→v2 dispatch without mispredicting every v2 message"; "late-joining shm consumer — where to start reading?"
Always tie to the real hot-path budget (1–100µs) and ask for the *why* + the measurement that would confirm it.

## Cheatsheets (authored in Phase B)
default: `cme-msg-types`
planned: `sbe-wire-format`, `cme-msg-types`, `cpp23-codec`, `kernel-tuning-md`, `perf-commands`

## Confidentiality
**Public sources only** (CME public MDP 3.0 spec + published SBE schema, Real Logic SBE/Aeron, Linux/kernel docs,
Harris, cppreference). No firm-internal systems, codebases, or proprietary detail in any tracked file. See `resources.md`.
