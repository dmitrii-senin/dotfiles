# Domain: perf — x86 performance investigation

title: Perf — x86 performance investigation
level: intermediate (skip basics; start from real depth)

## Areas

`cpu`, `mem`, `compiler`, `concurrency`, `methodology`, `kernel`

- **cpu** — pipeline, OoO execution, branch prediction, µop cache, TMA, SMT, ILP, SIMD
- **mem** — cache lines, L1/L2/L3 latency, TLB, NUMA (numactl placement + numastat/autonuma diagnosis), prefetching, bandwidth, false sharing, store buffers
- **compiler** — disassembly, opt levels, auto-vectorization, inlining, LTO, PGO, `restrict`, opt reports
- **concurrency** — x86-TSO, atomics, LOCK prefix, fences, MESI, lock-free, futex, CAS
- **methodology** — USE method, flame graphs, perf stat/record/annotate, bpftrace, TMA, sampling vs tracing, benchmarking stats
- **kernel** — syscall overhead, vDSO, context switches, CFS/EEVDF, interrupts, page faults, huge pages, io_uring, affinity/isolation, NIC tuning (ethtool rings/coalescing/offloads, RSS/ntuple IRQ steering, HW timestamping/PTP, drop localization), TSC, preemption

### Area prerequisites (for ZPD ordering)

- `cpu` and `mem` are foundational — prefer before `compiler`, `concurrency`, `kernel`.
- `methodology` pairs with everything; introduce TMA early alongside `cpu`.
- `compiler` benefits from `cpu` (ports/latency) and `mem` (vectorization payoff).
- `concurrency` benefits from `mem` (coherence, false sharing) and `cpu` (fences cost).

## Modes

enabled: `mm`, `flash`, `drill`, `cheatsheet`, `status`
not yet: `challenge` (no `challenges.md` authored), `schedule` (no deadline — inject all flashcards immediately)

## Cheatsheets

default: `perf`
available: `perf`, `pmc-events`, `bpftrace`, `compiler-flags`, `kernel-tuning`
- map: `pmc`/`events` → `pmc-events`; `flags` → `compiler-flags`; `tuning` → `kernel-tuning`

## Drill flavor

Present realistic artifacts and ask for a diagnosis + next step:
- `perf stat` counter output (IPC, branch-misses, cache-misses) → name the bottleneck / TMA L1 category
- `toplev.py` TMA Level 1–3 breakdown → which category dominates, what to investigate next
- `llvm-mca` analysis of a snippet → port pressure / critical path
- pipeline/memory symptoms ("IPC dropped 3.2→0.8 after a data-dependent branch") → microarch explanation
- resource contention ("HT dropped single-thread throughput 15%") → which shared resource

Reliability / determinism flavor (tail latency, jitter, drops):
- `numastat -p` with high `other_node` that drifts over time → NUMA imbalance vs AutoNUMA; placement fix + how to verify
- `ethtool -S` rising `rx_no_buffer_count` / sequence gaps → localize the drop (wire vs NIC ring vs kernel/socket), then the right tuning lever
- jitter on an isolated core (NET_RX softirq, AutoNUMA migration, residual tick) → which determinism lever (ntuple+IRQ steer, `numa_balancing=0`, `nohz_full`)
- p99.9 tail spike (THP compaction, C-state exit, frequency transition) → root cause + the config change that removes it

## Cross-references

Areas reference each other freely (TMA ↔ methodology, backend-bound ↔ mem, SIMD ↔ compiler,
SMT ↔ concurrency). Encourage `See also:` links across areas during sessions.
