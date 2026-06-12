# systems — Low-Latency Primitives (MD-flavored) Topic Bank
Updated: 2026-06-12

> Scope: the systems primitives the CME feed pipeline is built from — SPSC/MPSC rings,
> shared-memory IPC over `mmap`, false sharing, cache layout, allocators, prefetch, branch
> behavior, SIMD, I-cache. Anchored to the hot-path budget (1–100µs).
> This area is a **market-data-flavored duplicate of `perf`** by design: for the deepest
> CPU/cache/concurrency theory, cross-link to **`/perf concurrency`**, **`/perf mem`**,
> **`/perf cpu`**, **`/perf methodology`**. Here it stays applied to the pipeline:
> generator → handler → SBE codec → dispatcher → book → shm bus → consumers.

## beginner

### The hot-path budget and the latency hierarchy
The whole point of the systems layer is to keep the per-message processing cost a small
fraction of the 1–100µs budget. To reason about that, you need the rough cost of each memory
operation: an L1 hit is ~4–5 cycles (~1–2ns), L2 ~12–15 cycles (~4–5ns), L3/LLC ~40 cycles
(~10–17ns), and a DRAM access ~100+ cycles (~50–100ns). A branch mispredict costs ~15 cycles
(pipeline depth dependent). At a 3GHz core, 100ns is ~300 cycles — so a single DRAM miss is a
real fraction of a tight per-message budget. Everything in this area is about staying in L1/L2
and not paying the cliff costs (DRAM, TLB walk, page fault, false-sharing bounce).
**Key concepts:** cache hierarchy latency, cycles vs ns, the 64-byte cache line, latency cliffs
**Anchor:** A book update that should cost ~50ns instead costing 250ns means ~4 unexpected DRAM/TLB hits — measurable directly with `perf stat -e L1-dcache-load-misses,dTLB-load-misses`.
**Drill:** Your per-message latency p50 is 60ns but p99 is 800ns. Name three microarchitectural events that produce that gap (none are "the algorithm") and the counter that confirms each.
**Tags:** latency-budget, cache-hierarchy, cache-line, hot-path
**See:** `/perf mem` (memory hierarchy), `/perf cpu` (pipeline latencies).
[src: cppreference hardware_interference_size; public Intel/cache-latency references]

### The 64-byte cache line contract
Everything on x86-64 moves between caches in 64-byte lines (on AArch64 the line size is
implementation-defined — 64B on most Cortex-A/Neoverse cores, 128B on Apple Silicon). This is the
single most important number for data layout. A `PriceLevel` at 32 bytes packs 2 per line; at
48 bytes you waste 16 bytes/line and halve effective cache capacity; at 72 bytes every access
touches 2 lines. Struct field ordering matters: a `bool` next to a `double` forces 7 bytes of
alignment padding — 8 bytes of a 64-byte line gone. `static_assert(sizeof(PriceLevel)==N)` and
`-Wpadded` are your guardrails.
**Key concepts:** 64-byte line, struct packing, alignment padding, effective cache capacity
**Anchor:** 50 instruments × 20 levels × 64B = 64KB of hot book data — fits L1 (32–48KB) only if one instrument dominates; an all-instrument burst spills to L2 (~256KB).
**Drill:** You shrink `PriceLevel` from 48B to 32B. What two distinct wins do you expect, and which `perf` counter shows each?
**Tags:** cache-line, struct-layout, padding, alignment, sizeof
**See:** `/perf mem` (cache-line / data layout).
[src: cppreference; public x86 cache-line references]

### Implicit-lifetime types and overlaying bytes as a struct
The flyweight pattern (overlay a typed accessor on a raw buffer with no copy) is the core of
the SBE codec and the shm bus. In pre-C++23, `reinterpret_cast<const Msg*>(buf+off)` is
undefined behavior — the bytes contain no live object of type `Msg` even if the
representation is valid, and `std::launder` does not fix it. C++23 `std::start_lifetime_as<T>(p)`
implicitly creates a `T` in existing storage (no constructor runs), returns a usable `T*`, and
is defined behavior — provided `T` is an implicit-lifetime type and `p` meets `alignof(T)`.
**Key concepts:** implicit object creation, `start_lifetime_as`, UB of reinterpret_cast, alignment precondition
**Anchor:** SBE message root (100+ bytes) → `start_lifetime_as` returns a pointer into the receive buffer (no copy). For tiny structs (≤ register width), `std::bit_cast` copies to a local and is often optimized away — benchmark both.
**Drill:** Why is `reinterpret_cast` + `std::launder` still UB for a network buffer, and what precondition must hold before `start_lifetime_as` is legal?
**Tags:** start_lifetime_as, flyweight, zero-copy, c++23, implicit-lifetime, alignment
**See:** `/sbe` area (flyweight decode), `/perf mem` (aliasing).
[src: cppreference std::start_lifetime_as; WG21 P2590/P0593]

### Pre-allocate everything: zero allocation on the hot path
`malloc`/`new` on the hot path is a latency bomb: even `jemalloc`/`tcmalloc` cost ~50–200ns and
can occasionally trap into the kernel (`mmap`/`brk`) for microseconds. The rule is: allocate
zero bytes after init. Pre-size book arrays, ring buffers, staging and timestamp buffers at
startup; construct in place with placement-`new` or `start_lifetime_as`. SBE var-data is bounded
(typically <256B) so fixed buffers or a slab/free-list cover it.
**Key concepts:** allocator latency, kernel trap on grow, pre-allocation, placement new, slab/pool
**Anchor:** A single hot-path `malloc` that hits `mmap` is a multi-µs spike — directly visible in p99.
**Drill:** Describe an `LD_PRELOAD` interposer that aborts if `malloc` is called from the hot thread, and explain why "no allocation after init" is a stronger invariant than "fast allocator".
**Tags:** allocator, no-alloc-hot-path, pre-allocation, slab-allocator, p99
**See:** `/perf mem` (allocators).
[src: public allocator docs; jemalloc/tcmalloc design notes]

### Page faults and `mlockall`
A page fault on the hot path costs ~1–10µs and shows up directly in p99. `mlockall(MCL_CURRENT |
MCL_FUTURE)` locks all current and future pages into RAM so they are never paged out, and
`MCL_FUTURE` also locks pages mapped later. But locking is not faulting-in: for the stack you
must additionally **pre-fault** by touching a large automatic array at startup so copy-on-write
and demand-zero faults can't fire mid-message. Never `fork()` after `mlockall` — CoW reintroduces
faults; locks are not inherited and are cleared on `execve`.
**Key concepts:** demand paging, `mlockall`, MCL_CURRENT/MCL_FUTURE, stack pre-faulting, CoW
**Anchor:** A ~5µs fault in a 10µs budget is a 50% blowout for that message — and it's a tail event you only see at p99/p999.
**Drill:** You `mlockall(MCL_CURRENT|MCL_FUTURE)` and still see rare ~6µs spikes on the first deep recursion. What did you forget, and how do you fix it without changing the algorithm?
**Tags:** page-fault, mlockall, pre-fault, MCL_FUTURE, p99, real-time
**See:** `/lowlat-net` (host tuning).
[src: mlock(2)/mlockall(2) man pages]

### What false sharing is
Two variables on the same 64-byte line written by different cores trigger the cache-coherence
(MESI) "bouncing" protocol: the line ping-pongs between L1 caches over the interconnect, ~40–70ns
per round-trip vs ~1ns for an uncontended L1 hit. In the SPSC ring this is the canonical bug:
`head_` (written by the consumer) and `tail_` (written by the producer) on the same line means
every push/pop invalidates the other core's copy. The fix is to put them on separate lines.
**Key concepts:** false sharing, MESI bouncing, interconnect round-trip, producer/consumer separation
**Anchor:** On a 2-core SPSC setup, `head_`/`tail_` on the same line vs 64B apart can show a 3–10x throughput difference — the most dramatic false-sharing demo you can build.
**Drill:** Producer and consumer each run at full tilt but throughput is far below memory bandwidth and IPC is low. Which two counters distinguish false sharing from a genuine cache-capacity problem?
**Tags:** false-sharing, MESI, cache-coherence, spsc, throughput
**See:** `/perf concurrency` (false sharing), `/measurement` (`perf c2c`).
[src: cppreference hardware_destructive_interference_size; public MESI references]

## intermediate

### `alignas(64)` and hardware_destructive_interference_size
The portable, manual fix for false sharing is `alignas(64)` on each contended field so each lands
on its own line. C++17 added `std::hardware_destructive_interference_size` (the "minimum offset to
avoid false sharing") and `..._constructive_interference_size` (the max size to promote true
sharing), both in `<new>`, both 64 on x86-64. Caveat: GCC warns
(`-Winterference-size`) when you use the constant in a header or module export because its value
can vary between compiler versions or with `-mtune`/`-march` (pin it via
`--param destructive-interference-size=64` if you need ABI stability); generic AArch64 uses 64
(constructive) / 256 (destructive, driven by the A64FX 256B line). In practice many shops just
hardcode 64 on x86.
**Key concepts:** `alignas(64)`, `hardware_destructive_interference_size`, ABI stability, GCC interference-size warning
**Anchor:** Pad BOTH the SPSC `head_`/`tail_` AND the per-instrument book pointers in the dispatch array — if pointers for instruments 0–7 share a line, a burst hitting all 8 invalidates the dispatch line repeatedly.
**Drill:** Why does GCC warn about `hardware_destructive_interference_size` in a public header, and when is hardcoding 64 the right call?
**Tags:** alignas, interference-size, false-sharing, c++17, abi
**See:** `/perf concurrency`.
[src: cppreference; GCC interference-size patch discussion]

### SPSC ring: x86-TSO and the acquire/release contract
A correct lock-free SPSC ring needs only `acquire`/`release` atomics, not `seq_cst`. On x86-TSO
the only reordering the hardware allows is store→load (a later load passing an earlier store to a
different address); load→load, store→store, and load-with-older-store are already ordered. So
plain atomic loads/stores compile to ordinary `MOV` — acquire/release are "free" on x86 (only the
compiler is constrained from reordering). `seq_cst` is the one ordering that costs an instruction
(`XCHG`/`LOCK`-prefixed store, or `MFENCE`) because it must forbid store→load. For a ring,
producer publishes the slot then `store-release`s `tail_`; consumer `load-acquire`s `tail_` then
reads the slot — that release/acquire pair is the entire correctness argument.
**Key concepts:** x86-TSO, store→load reorder, acquire/release = MOV, seq_cst = fence, publish/observe
**Anchor:** The handler→codec and book→shm-bus hops are SPSC; getting the memory order minimal keeps the publish cost in the single-digit-ns range.
**Drill:** Why is `seq_cst` overkill for SPSC, and what is the cheapest correct ordering on the consumer's read of the data slot after it has acquired `tail_`?
**Tags:** spsc, x86-tso, acquire-release, seq_cst, memory-order, lock-free
**See:** `/perf concurrency` (memory model).
[src: x86-TSO (Owens/Sarkar/Sewell); cppreference memory_order; LLVM Atomics]

### MPSC and the CAS retry tradeoff
Extending SPSC to multiple producers requires a CAS loop on the producer-side index: each
producer reads `tail_`, computes its slot, and `compare_exchange`s; on failure it retries. Under
contention, retries waste cycles and the `LOCK`-prefixed CAS itself is more expensive than a plain
store. The design question for the feed handler is whether one MPSC ring (e.g., several receive
threads under `SO_REUSEPORT` feeding one book thread) beats N independent SPSC rings — the latter
has no CAS and no cross-producer contention but needs the consumer to fan-in. Measure CAS retry
count under realistic producer counts before choosing.
**Key concepts:** MPSC, CAS loop, retry count, LOCK overhead, N×SPSC alternative
**Anchor:** 4 producers × 1M msg/s each: at that rate CAS contention may dominate — N×SPSC + a consumer-side merge is often the lower-latency answer.
**Drill:** Under 4 producers at 1M msg/s, how would you measure whether the MPSC CAS retries are actually costing you, and what's the crossover that makes N×SPSC win?
**Tags:** mpsc, cas, contention, so_reuseport, retry
**See:** `/perf concurrency` (CAS/contention).
[src: public lock-free queue references; crossbeam/Folly PCQ design]

### Shared-memory IPC over `mmap` with overwrite policy
The book→consumer bus is a lock-free ring placed in `mmap`'d shared memory so multiple processes
(C++ strategy, Python monitor) read it without a syscall per message. The correct market-data
policy is **overwrite, not backpressure**: the producer never blocks; a slow consumer that falls
behind skips to the latest via a `latest_sequence` atomic. Stale data is worse than dropped data
for market data, and a blocked producer would back-pressure the whole pipeline. Reading typed
data out of `mmap`'d bytes is exactly the "reinterpret raw bytes as T" case — use
`start_lifetime_as` on cache-line-aligned slots.
**Key concepts:** mmap shm, lock-free ring cross-process, overwrite vs backpressure, latest_sequence, start_lifetime_as on slots
**Anchor:** Sequence numbers per slot let a consumer detect it was lapped (gap in sequence) and resync to `latest_sequence` rather than reading a torn/stale slot.
**Drill:** A consumer falls behind by 3 slots in a burst. With overwrite policy, how does it detect the lap and where does it resume — and why is that the correct behavior for MD?
**Tags:** shm, mmap, overwrite-policy, lock-free, ipc, start_lifetime_as
**See:** `/feed-handler` (backpressure), `/perf concurrency`.
[src: mmap(2)/madvise(2) man pages; public shm-ring designs]

### Late-joining consumer: where to start reading
A consumer that attaches to the shm ring mid-session must not start at slot 0 (ancient data) or
blindly at the write head (might read a slot the producer is mid-write). The pattern: the producer
publishes a monotonically increasing `latest_sequence` after each fully-written slot; a joining
consumer reads `latest_sequence` with acquire, snaps its read cursor to that slot, and proceeds.
For cross-process correctness the sequence and the slot data are ordered by the same
release/acquire pair as the in-process ring.
**Key concepts:** late join, latest_sequence handshake, read cursor init, torn-read avoidance
**Anchor:** This is the shm analogue of CME snapshot recovery — start from a known-good "latest", then follow incrementally (cross-link `/cme-mdp` snapshot recovery).
**Drill:** A monitoring process restarts mid-trading-day and reattaches to the shm bus. Write the exact handshake (which atomic, which memory order, which slot) that lets it start without reading a half-written slot.
**Tags:** late-join, shm, sequence, handshake, recovery
**See:** `/cme-mdp` (snapshot↔incremental), `/feed-handler`.
[src: public shm-ring designs; analogous to MDP recovery]

### AoS vs SoA for the order book
Array-of-Structs (`PriceLevel levels[20]` with price/qty/implied/num_orders/ts) loads the whole
struct into cache on any field access — the fields you don't need for a price compare ride along.
Struct-of-Arrays (`int64_t prices[20]`, `int32_t qtys[20]`, …) lets a price search touch only the
price array (20×8B = 160B ≈ 2.5 lines) vs AoS touching 20×40B = 800B ≈ 12.5 lines for the same
search — but once you find the level, SoA needs 4–5 separate array indexes (4–5 potential misses),
while AoS has all fields in one line. The tradeoff turns on the message mix: search-dominated
(more trades) favors SoA; update-dominated (more modifies) favors AoS.
**Key concepts:** AoS, SoA, hot-field locality, search vs update, message mix
**Anchor:** Same 1M-message trace through both layouts: L1 miss-rate difference is often 30–50%. SoA also enables SIMD price scans (contiguous prices).
**Drill:** For a trade-heavy instrument (many price searches, few modifies), which layout wins and why — and what counter would prove it on your trace?
**Tags:** aos, soa, order-book, data-layout, cache-miss
**See:** `/orderbook` (layout), `/perf mem`.
[src: public data-layout references; seed plan]

### Prefetching the next instrument's book
Hardware prefetchers handle sequential/strided access for free — your linear scan of a flat price
array is perfectly sequential, so the prefetcher already covers it; binary search is not, so it
defeats the prefetcher. Where software prefetch actually pays is the instrument-dispatch step: when
a burst arrives for instruments 7, 23, 41, 2, the book for the *next* SecurityID is probably not in
L1. Issue `__builtin_prefetch(books[next_id])` while processing the current message to hide the L2
access (~5ns) behind useful work. `rw=0,locality=3` for data reused (book levels); `locality=0` for
touch-once data (message header).
**Key concepts:** HW prefetcher, sequential vs random, software prefetch, dispatch-ahead, locality hints
**Anchor:** Shuffled instrument stream: expect ~10–20% per-message improvement with next-book prefetch; near-zero when the stream is sequential (HW prefetcher already wins).
**Drill:** Why does prefetching help the dispatch array but usually not the 20-level price scan? What measurement tells you whether to bother?
**Tags:** prefetch, builtin_prefetch, dispatch, hardware-prefetcher, locality
**See:** `/perf mem` (prefetching), `/orderbook` (dispatch).
[src: public prefetch references; seed plan]

### Huge pages and TLB reach
A TLB miss costs a page walk (~7–10ns, up to 4 levels). With 4KB pages a small TLB covers only a
few MB; 50 instruments × ~64KB of book data needs ~800 4KB pages — far beyond the L1 dTLB (~64
entries). A single 2MB huge page can cover that whole working set with one TLB entry → no hot-path
page walks. Two mechanisms: `mmap(MAP_HUGETLB | MAP_HUGE_2MB)` guarantees huge pages from a
pre-reserved pool (best for the shm ring); `madvise(MADV_HUGEPAGE)` is a hint the kernel may ignore
(THP, 2MB only, anonymous/tmpfs). Reserve huge pages near boot — memory fragments over uptime.
**Key concepts:** TLB reach, page walk, 2MB pages, MAP_HUGETLB vs MADV_HUGEPAGE, pre-reservation
**Anchor:** Full pipeline under 50-instrument burst: expect ~5–10x fewer `dTLB-load-misses` with huge pages (`perf stat -e dTLB-load-misses`). A 64MB shm ring is 32 huge pages vs 16,384 4KB pages.
**Drill:** Your book data is 64KB × 50 instruments. Compute the 4KB-page TLB pressure, explain why MAP_HUGETLB beats MADV_HUGEPAGE for the shm ring, and name the counter that proves the win.
**Tags:** huge-pages, tlb, MAP_HUGETLB, MADV_HUGEPAGE, page-walk
**See:** `/lowlat-net` (hugepages), `/perf mem` (TLB).
[src: kernel hugetlbpage.rst / transhuge.rst; madvise(2)]

### Branch behavior in template-ID dispatch
The SBE template-ID `switch` over ~4 message types is predicted well *because the distribution is
skewed* (~80% MDIncrementalRefreshBook (46), ~15% trade (48), ~5% other) — the predictor locks on
in <100 iterations. The dangerous branches are the almost-never-taken ones (error checks, rare
message types): the predictor assumes "not taken" and pays ~15 cycles the one time it fires. This
is why "branch on schema version" fails — a v1→v2 rollout starts at 0.01% v2, mispredicting every
v2 message. Use `[[likely]]`/`[[unlikely]]` to keep the hot path contiguous (I-cache locality),
not to fix the dynamic predictor.
**Key concepts:** skewed branch = predictable, rare-branch tax, version-branch antipattern, likely/unlikely
**Anchor:** Uniform 25/25/25/25 dispatch has ~2x the `branch-misses` of an 80/15/4/1 skew — measure with `perf stat -e branch-misses`.
**Drill:** A schema v2 rollout is at 0.5% of messages and your p99 just got worse. Explain the mechanism and give a dispatch design that doesn't mispredict every v2 message.
**Tags:** branch-prediction, dispatch, schema-version, likely-unlikely, misprediction
**See:** `/perf cpu` (branch prediction), `/sbe` (version dispatch).
[src: public branch-prediction references; seed plan]

## advanced

### Function-pointer / jump-table dispatch for schema versions
When you must dispatch on something that interleaves badly for the conditional predictor (schema
version, large template space), replace the branch tree with an indirect call through a table
indexed by version/template-ID. An indirect call is predicted by the BTB (target history), not the
conditional PHT — and because versions don't interleave per-instrument (an instrument sends one
version at a time), the BTB target is stable and the call predicts well. The cost is an extra load
+ indirect call (~a few cycles when predicted) vs the ~15-cycle mispredict you'd otherwise pay on
every minority-version message. Pre-register all known template IDs at startup; count unknowns on a
background thread (never log on the hot path).
**Key concepts:** indirect call, BTB vs PHT, jump table, stable target, unknown-ID handling
**Anchor:** Compare `perf stat -e branch-misses` for switch-dispatch vs table-dispatch on a v1/v2 mixed stream; the table removes the per-v2 mispredict at the cost of one predictable indirect call.
**Drill:** Why does an indirect call through a version table predict *better* than a `switch` during a v1→v2 transition, given that both "branch"? Which predictor structure handles each?
**Tags:** indirect-call, btb, jump-table, schema-version, dispatch
**See:** `/perf cpu` (branch prediction advanced), `/sbe`.
[src: public branch-prediction references; seed plan]

### Branchless select: when it helps and when it hurts
A `cmov` (or arithmetic select) removes a branch but introduces a data dependency: the CPU computes
both sides and selects, so it can't speculate past an expensive side. SBE null-value checks
(sentinels like `INT64_MAX` for null price) are the right place for branchless select *only if the
null rate is unpredictable* — at 0% or 50% the branch predictor is already perfect and branchless
is pure overhead; around ~10% unpredictable, branchless wins. Counted loops (shift-right on level
insertion) should stay branched — the predictor handles counted loops perfectly, and `cmov` would
serialize them.
**Key concepts:** cmov, data dependency vs speculation, sentinel/null check, predictability crossover
**Anchor:** Benchmark branched vs branchless SBE null check at 0/1/10/50% null rate — find the crossover on your hardware; it's not "branchless is always faster".
**Drill:** Your null price appears ~10% of the time, unpredictably. Branched or branchless? Now the null rate is 50% — does your answer change, and why?
**Tags:** branchless, cmov, sentinel, null-value, sbe, crossover
**See:** `/perf cpu` (branchless techniques).
[src: public micro-optimization references; seed plan]

### I-cache locality and code layout
The L1 instruction cache is ~32KB/core. The hot loop (receive → parse → dispatch → book update)
must fit, or you stall on I-cache misses (~15 cycles each, frontend-bound). Template-heavy SBE
codecs are the risk: 4 message types × ~10 inlined accessors can be a few KB (fine) or tens of KB
if error handling/logging is inlined (doesn't fit). Keep cold paths out of the hot loop with
`[[gnu::noinline]]` (gap recovery, snapshot processing, error logging); hint hot placement with
`[[gnu::hot]]`. LTO+PGO reorders functions by call frequency — a real I-cache win, and Buck2
supports both.
**Key concepts:** L1i 32KB, frontend stall, template bloat, noinline cold paths, LTO/PGO layout
**Anchor:** `perf stat -e L1-icache-load-misses` and TMA frontend-bound% before/after pulling error handling out-of-line; over-inlining shows up as rising I-cache misses with no IPC gain.
**Drill:** Adding detailed gap-recovery logging inline pushes your hot loop from 12KB to 48KB of code and p99 worsens. What's the mechanism (which TMA bucket), and what's the fix that keeps the logging?
**Tags:** icache, code-layout, inlining, noinline, lto, pgo, frontend-bound
**See:** `/perf cpu` (I-cache/iTLB), `/measurement` (TMA).
[src: public I-cache references; seed plan]

### SIMD where it pays (and where it doesn't)
SIMD shines on contiguous bulk data, not on variable-length pointer-chasing. SBE parsing is mostly
scalar pointer arithmetic at computed offsets — SIMD rarely helps the decode itself. Where it pays:
(1) a price-level scan over a *contiguous* `int64_t prices[]` (SoA only) — load 4 prices into a
256-bit AVX2 register and `_mm256_cmpeq_epi64` all 4 at once, ~5 iterations for 20 levels vs 20
scalar compares; (2) cross-instrument signal computation (e.g., spreads across 50 instruments) in
SoA layout. Beware AVX-512 frequency throttling: a single AVX-512 instruction in a rarely-run path
can drop core frequency for hundreds of microseconds — keep wide SIMD to bulk paths and `vzeroupper`
before returning to scalar.
**Key concepts:** AVX2 compare, SoA prerequisite, gather is slow, AVX-512 license/frequency throttle, vzeroupper
**Anchor:** Scalar vs AVX2 price scan at 10/20/40 levels: scalar often wins at 10 (setup overhead), AVX2 at 40 — find the crossover.
**Drill:** Why does SIMD price-search require SoA, and why can a stray AVX-512 instruction in an error path hurt your scalar p99?
**Tags:** simd, avx2, avx-512, soa, frequency-throttle, vzeroupper
**See:** `/perf cpu` (SIMD/ports, AVX-512 throttling).
[src: public Intel SIMD references; seed plan]

### Unaligned overlay and aligned staging buffers
`start_lifetime_as<T>(p)` requires `p` aligned to `alignof(T)` — UB otherwise. CME concatenates
messages tightly in a datagram: message N starts at `off + size(N-1)`, often not 8-byte aligned,
while structs with `int64_t` fields want `alignof==8`. Two options: (a) `#pragma pack(1)` /
`alignof(1)` flyweights (then field loads may be unaligned and possibly non-atomic), or (b) align
the receive buffer to 64B (first message aligned) and `memcpy` any unaligned subsequent message to
an aligned, L1-hot staging buffer before overlay. On modern Intel, unaligned access *within* a line
is free; crossing a cache line costs ~5ns; crossing a page ~20ns — so the staging `memcpy` (a few
ns to L1-hot memory) is often cheaper than repeated unaligned penalties.
**Key concepts:** alignment precondition, packed structs, aligned staging buffer, line/page-crossing cost
**Anchor:** Bench `start_lifetime_as` on aligned vs unaligned buffers with `-fsanitize=undefined` (catch UB) then without (measure); validate with the boundary costs above.
**Drill:** A datagram has 5 concatenated SBE messages; messages 2–5 are unaligned. Give the exact buffer strategy that keeps overlay defined behavior without an unaligned penalty on every message.
**Tags:** alignment, start_lifetime_as, packed, staging-buffer, line-crossing, ub
**See:** `/sbe` (alignment), `/perf mem`.
[src: cppreference start_lifetime_as; public x86 alignment references]

### NUMA and shared-memory placement
On multi-socket hosts each CPU has local DRAM; remote-socket DRAM costs ~2x (~100ns vs ~40ns
local). `mmap`'d shm is placed by first-touch: whichever process faults a page owns its node. If
the producer faults the ring and the consumer is on another node, the consumer pays the remote
penalty on every read — visible in p50 if you read book data from shm. Pin both ends to one node
(`numactl --membind=0 --cpunodebind=0`) or budget the penalty explicitly. Verify with
`numastat -p <pid>` and `perf stat -e node-load-misses`.
**Key concepts:** NUMA, local vs remote DRAM, first-touch, numactl pinning, node-load-misses
**Anchor:** Producer node 0 / consumer node 1 vs both on node 0: expect ~60ns/access difference — directly in your shm-read p50.
**Drill:** Cross-node shm reads doubled your shm-read latency. Explain first-touch, give the pinning command, and name the counter that confirms remote DRAM traffic.
**Tags:** numa, first-touch, numactl, shm, remote-dram, node-load-misses
**See:** `/lowlat-net` (NUMA), `/perf mem` (NUMA), `/perf concurrency`.
[src: numa(7)/numactl; public NUMA references; seed plan]

### Cursor-based access for post-group SBE fields
SBE lays a message out as: root block, then each repeating-group iteration, then var-data, in that
fixed order. Fixed root fields have compile-time offsets, but the first variable-length group makes
all following offsets *runtime*-dependent — so post-group fields can't use constexpr offsets. The
Aeron-style solution is a cursor: direct accessors for fixed root fields, and a `next()`-style
cursor that advances through group iterations (and nested groups), with var-data read last because
it mutates the internal position. Out-of-order access silently corrupts decode; SBE can generate
optional access-order ("precedence") checks (`-Dsbe.generate.access.order.checks=true`) — but they
have significant overhead, so enable them in tests, not production. Deducing `this` (C++23) removes
CRTP boilerplate in the accessor mixin.
**Key concepts:** root/group/var-data order, runtime offsets after first group, cursor/next(), precedence checks, deducing this
**Anchor:** This is why the codec is single-pass and ordered — random field access defeats both the zero-copy design and the predictability of the hot loop.
**Drill:** After the first repeating group, why can't fixed offsets be used for later fields, and what is the cursor's job? When do you turn on SBE precedence checks?
**Tags:** sbe, cursor, repeating-group, var-data, precedence-checks, deducing-this
**See:** `/sbe` area (groups/var-data), `/perf cpu` (I-cache).
[src: Real Logic SBE C++ user guide / Safe Flyweight Usage wiki]

### `recvmmsg` batching as an amortization primitive
`recvmmsg(2)` receives up to `vlen` datagrams in one syscall (array of `mmsghdr`), amortizing
syscall entry/exit across many messages — the systems-level lever for the receive stage. It returns
the number actually filled (3 if only 3 are ready), so it's not "wait for N". The win appears when
the NIC ring is full (high pps); below ~100k pps, batching can *add* latency by waiting. Two known
semantics: `MSG_WAITFORONE` flips to `MSG_DONTWAIT` after the first message; and the `timeout`
argument is checked only after each datagram, so with up to `vlen-1` received it can block forever
— for hot paths use a 0/NULL non-blocking call and busy-poll in userspace instead.
**Key concepts:** batched receive, vlen/mmsghdr, returns count not vlen, pps break-even, timeout bug, MSG_WAITFORONE
**Anchor:** This is the systems half of the receive strategy; the I/O-strategy comparison (epoll vs io_uring vs SO_BUSY_POLL) lives in `/feed-handler` and `/lowlat-net`.
**Drill:** At 30k pps your `recvmmsg(vlen=32)` made p50 *worse*. Explain why batching can hurt below the break-even, and what receive call you'd use instead at that rate.
**Tags:** recvmmsg, batching, syscall-amortization, pps, busy-poll
**See:** `/feed-handler` (receive strategies), `/lowlat-net`.
[src: recvmmsg(2) man page]
