# Drill seeds — grilling questions & experiments

Authoritative seed for `drill` mode, from `attic/trading-prep.md`. These are real interview-grade
diagnosis / benchmark-crossover / design-under-constraint prompts. Drill mode should present one,
wait for the answer, then score on identification / next-step / reasoning, and demand the *measurement*
that would confirm it. Expand with new scenarios over time.

## sbe / cme-mdp
- Schema v1→v2 adds an optional field; some instruments still send v1. Branch on version? Why does that
  mispredict every v2 message early on — and what's the predictable alternative? (function-pointer table)
- Unknown template ID on the hot path: `switch` default that logs can block. How do you handle unknown IDs
  without logging on the hot path and without silently missing `SecurityStatus`?
- Eager (copy-and-swap at parse) vs lazy (`std::byteswap` at access) endianness — at what access count does
  eager win? Why is CME (little-endian on x86) a no-op but ICE/Eurex aren't?
- CME datagrams concatenate messages tightly → message N may be unaligned. `start_lifetime_as` needs alignment.
  Copy-to-aligned-staging vs `#pragma pack(1)` — tradeoffs? When does crossing a cache line / page cost show up?

## systems (cache / CPU / lock-free)
- False sharing: your SPSC `head_` (consumer) and `tail_` (producer) on the same cache line. Predict the
  throughput delta vs 64B apart on a 2-core setup. Which `perf` tool proves it? (`perf c2c`, HITM)
- AoS vs SoA order book: price-level search is hot, updates touch 2–3 fields. Which layout wins, and how does
  the message mix (more trades vs more modifies) flip the answer? What L1-miss delta do you expect?
- `seq_cst` is overkill for SPSC — what exactly breaks if you put `relaxed` on the wrong side?
- p99 spikes every ~10ms — queue contention or the OS? How do you isolate it?
- Branch prediction: 4 template types at uniform 25% vs skewed 80/15/4/1 — predict the `branch-misses` delta.
- Branchless SBE null-check (sentinel) vs branched — at 0% / 10% / 50% null rate, where's the crossover and why?
- Huge pages: 50 instruments × 64KB book data vs 64-entry dTLB. Predict the `dTLB-load-misses` delta with 2MB pages.
- NUMA: producer on node 0, consumer on node 1 — expected per-access shm penalty? How to pin both?
- Hot-path `malloc`: how do you *prove* zero allocations on the hot thread? (LD_PRELOAD interpose + abort)

## orderbook
- Implied prices: merge into one book or keep two? Cache cost of doubling book width?
- 20 levels: `std::lower_bound` vs linear scan — at what N does binary search actually win on your hardware?
- Snapshot→incremental transition: how do you avoid double-counting or missing a level at the handover?

## feed-handler / lowlat-net
- `recvmmsg` batching break-even pps? Below it, why does batching *add* latency?
- Receive strategy: `epoll`+`EPOLLET` vs `SO_BUSY_POLL` vs `io_uring`+`SQPOLL` — wake-up latency, core cost,
  when each wins. Key move: profile the full path first — if 80% is the book update, receive tuning is premature.
- NIC coalescing: `rx-usecs 0 rx-frames 1` vs `rx-usecs 10 rx-frames 16` — latency vs CPU tradeoff at a 100µs budget.
- CME multicast = single source IP → RSS lands on one core. How do you parallelize without book contention?
- CPU isolation: `isolcpus` + affinity + `SCHED_FIFO 99` can starve softirqs. What's the 2-core-per-feed fix?
- Page fault on the hot path = 1–10µs in p99. How do you eliminate it before market open? (`mlockall` + pre-fault)

## measurement
- IPC below 1.0 under load — `perf stat -M TopdownL1` says Backend Bound 31%, Bad Speculation 35%. Which first, and why?
- Frontend vs backend stalls (`stalled-cycles-frontend/backend`) — which points at I-cache/code-layout vs D-cache/data-layout?
- Sampling perturbs timing: why `-F 10000` (not 999kHz) on the hot path? What's the safe continuous-profiling rate?

## ownership (judgment)
- "Reliable market data" for a feed handler — what does it actually mean, and what would you monitor as the owner?
- A gap is detected mid-session under burst load — walk the recovery decision (NAK/replay vs snapshot channel vs A/B feed).
- Stale vs lost: why is the shm overwrite policy (drop-to-latest) the correct market-data tradeoff?
