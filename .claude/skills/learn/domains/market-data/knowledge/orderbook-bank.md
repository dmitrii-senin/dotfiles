# Order Book — Topic Bank
Updated: 2026-06-12

Scope: building and maintaining L2/L3 books from CME MDP 3.0 incrementals on the
hot path (1–100µs), the data-structure and cache tradeoffs that decide whether a
book update is 4ns or 200ns, and the correctness invariants (snapshot↔incremental
transition, gap recovery). Cross-links to `/perf` for the deepest CPU/cache/concurrency
theory; here everything is applied to the feed pipeline.

Sources: CME Globex MDP 3.0 client wiki (cmegroupclientsite.atlassian.net / cmegroup.com
confluence), CME Group MBO FAQ, Larry Harris *Trading and Exchanges*, cppreference
(`std::flat_map`), and the `/perf` cpu/mem banks. Precise CME tag numbers and enum
values are attributed inline.

## beginner

### What an order book is, and the three book "views" CME ships
A limit order book is the live ledger of resting buy (bid) and sell (offer) interest for one
instrument, split into two sides sorted by price: bids descending (best = highest), offers
ascending (best = lowest). The gap between best bid and best ask is the **spread**; the volume
at each level is the **depth** (Harris). CME disseminates three granularities you may have to
build: **Market by Price (MBP)** — quantity aggregated per price level, capped at a max depth
(commonly 10, "MBP-10"); **Market by Order Full Depth (MBOFD)** — every individual order at
every price level with an anonymous OrderID; and **Market by Order Limited Depth (MBOLD)** —
top 10 orders per side. Your feed handler's book engine is the stage that turns the decoded
SBE message stream into one of these views, per instrument, in place.
**Key concepts:** bid/offer side, best bid/offer, spread, depth, MBP vs MBO, aggregate vs order-level
**Tip:** MBP collapses all orders at a price into `{price, total_qty, num_orders}` — you lose
individual queue position. If the strategy needs queue position you must build MBO, which is
far more memory and message traffic per instrument.
**Tool anchor:** CME wiki "Central Limit Order Book" / "Market by Order (MBO)" FAQ
**Drill:** A strategy stub asks "how many contracts are ahead of mine at the best bid?" Which book
view can answer this exactly, and why can MBP-10 only estimate it?
**Tags:** orderbook, mbp, mbo, depth, spread, microstructure

### MDUpdateAction and MDEntryType — the verbs and the side
Every MBP book mutation in `MDIncrementalRefreshBook` (template 46) carries two control fields.
**MDUpdateAction (tag 279)** is the verb: `0=New`, `1=Change`, `2=Delete`, `3=DeleteThru`,
`4=DeleteFrom`, `5=Overlay`, null=255 (per the CME schema / EPAM open-source handler). **New**
inserts a level (shift levels down, drop anything past max depth), **Change** updates the
quantity at a level, **Delete** removes a level (shift up). **MDEntryType (tag 269)** is the
side/kind: `0=Bid`, `1=Offer`, plus trade and statistics types. Your book engine is fundamentally
a `switch(action)` over a sorted per-side array, dispatched per repeating-group entry.
**Key concepts:** tag 279 MDUpdateAction, tag 269 MDEntryType, New/Change/Delete/Overlay, repeating group
**Tip:** CME requires handlers to process *all* valid tag-279 values, not just New/Change/Delete —
DeleteThru/DeleteFrom/Overlay must be handled or your book silently desyncs. Pre-register the full
enum and `std::unreachable()` only the truly impossible default.
**Tool anchor:** CME wiki "Market Data Incremental Refresh - MBP and MBOFD"
**Drill:** You only implemented New/Change/Delete. The first book-clear event arrives as
DeleteThru. What goes wrong, and when do you notice — at the event, or three updates later?
**Tags:** orderbook, mdupdateaction, mdentrytype, tag-279, tag-269, cme-mdp

### MDPriceLevel — the 1-based depth index that drives the shift
`MDPriceLevel` (tag 1023) tells you *which* depth position the action applies to: 1 = best, 2 =
second-best, etc. (1-based). This field is what lets the book engine avoid searching for the
price: on **New** at level N, shift levels N..maxdepth−1 down by one and write the new level at
index N−1; on **Delete** at level N, shift levels N+1.. up and clear the tail; on **Change**, just
overwrite index N−1's quantity. Because CME hands you the level index directly, an MBP book update
is O(depth) array shifting, not O(log depth) search — the price ordering is maintained *by the
exchange*, and you trust it.
**Key concepts:** tag 1023 MDPriceLevel, 1-based index, shift-down on insert, shift-up on delete, max depth
**Tip:** This is why a flat array beats `std::map` for MBP-10: the exchange already gives you the
insertion index, so a tree's O(log n) search buys nothing — you pay node-chasing cache misses for
a lookup you didn't need.
**Tool anchor:** CME wiki "Central Limit Order Book" (Add/Change/Delete data blocks)
**Drill:** A New at MDPriceLevel=1 on a 10-deep book. Which array indices move, and what happens to
the order that was at level 10? Write the memmove in terms of indices.
**Tags:** orderbook, mdpricelevel, tag-1023, array-shift, max-depth

### Why flat sorted array beats std::map for an L2 book
For a bounded MBP book (≤10 levels per side), store each side as a contiguous
`std::array<PriceLevel, MAXDEPTH>` (a flat sorted array), not `std::map<Price, Level>`. The whole
side fits in 1–2 cache lines, so a scan or shift touches L1 only. `std::map` is a red-black tree:
each node is a separate heap allocation reached by pointer-chasing, so even an O(log n) lookup
incurs multiple cache misses (~hundreds of cycles each from `/perf mem`), and you allocate/free on
the hot path — a latency bomb. The flat array's "shift on insert" is O(depth) but on 10 contiguous
elements it's a single cache-resident memmove, far cheaper than one DRAM miss.
**Key concepts:** flat sorted array, std::array, std::map red-black tree, pointer chasing, allocation on hot path
**Tip:** "Asymptotically worse, empirically faster" is the recurring order-book lesson: O(n) shift on
10 cache-hot elements beats O(log n) on a pointer-chased tree. Always benchmark, don't assume Big-O.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,LLC-load-misses ./book_bench`; see `/perf mem`
**Drill:** At what depth N does `std::map`'s O(log n) lookup start beating the flat array's O(n) shift?
For CME MBP-10, is N ever reached? What would change at MBO full-depth (hundreds of levels)?
**Tags:** orderbook, flat-array, std-map, cache, big-o-vs-cache, perf-mem

### Instrument dispatch — SecurityID to book in O(1) without a hash map
A channel carries many instruments; each message names its instrument via SecurityID. CME
SecurityIDs are dense-ish 32-bit integers, so a pre-allocated `std::array<OrderBook*, MAX_ID>` (or
contiguous `OrderBook` array indexed by a compact id) gives O(1) dispatch with zero hash cost. The
seed's "array-indexed, not hash map" is the right call for a known, dense id space: no hashing, no
collision chains, no rehash. For a sparse id space you'd map SecurityID→compact-slot once at
startup (when Security Definitions arrive) and index the dense slot array.
**Key concepts:** SecurityID dispatch, dense integer ids, array indexing vs hash map, compact slot mapping
**Tip:** Store books contiguously and index by offset rather than storing `OrderBook*` pointers — a
pointer array can put 8 instruments' pointers on one cache line, so a burst across them bounces that
dispatch line (subtle false-sharing-like invalidation); contiguous storage sidesteps it.
**Tool anchor:** CME Security Definition (tag 35=d) carries SecurityID and depth (tag 264-MarketDepth)
**Drill:** 50 instruments, SecurityIDs in the millions. Allocating `array<OrderBook*, 4_000_000>` is
sparse but small. What's the actual memory cost, and when is a SecurityID→slot remap worth it instead?
**Tags:** orderbook, instrument-dispatch, securityid, array-index, tag-264

### Price representation — scaled integers, never floats
CME wire prices are integers: a signed mantissa scaled by the instrument's display factor (a power
of ten from the Security Definition), not IEEE doubles. Keep prices as `int64_t` ticks all the way
through the book — comparisons are exact and cheap, sorting is integer-stable, and you avoid the
floating-point divide (and possible denormal microcode assist, ~160 cycles, see `/perf cpu`) that
`mantissa / pow(10, exp)` would cost per access. Only convert to a human/display double at the very
edge (logging, the Python analytics consumer), never inside the book hot loop.
**Key concepts:** integer mantissa, display/price factor, int64 ticks, exact comparison, defer float conversion
**Tip:** Storing price as a scaled int also keeps the `PriceLevel` struct tight and makes the
"strictly descending bids / ascending offers" invariant a trivial integer compare — no epsilon, no
NaN edge cases. If you must expose a double, multiply by a precomputed reciprocal, never divide.
**Tool anchor:** CME Security Definition display factor; cppreference fixed-point; `/perf cpu` divider/denormal
**Drill:** A colleague stores price as `double` and the book occasionally fails the "strictly
descending" assert by a hair. What floating-point property causes it, and why does int64 fix it for free?
**Tags:** orderbook, price-representation, scaled-integer, fixed-point, invariants, perf-cpu

## intermediate

### Snapshot → incremental transition without double-counting or gaps
On startup or after an unrecoverable gap you join the snapshot/recovery feed
(`SnapshotFullRefresh`, template 52) and apply incrementals in parallel. The join key is
**LastMsgSeqNumProcessed (tag 369)** on the snapshot: it equals the incremental-feed packet
sequence number the snapshot reflects. Algorithm: buffer incrementals while snapshotting; build the
book from the snapshot; then **drop every buffered incremental with packet seq < tag 369** (CME's rule
is strictly less-than: "drop all cached Incremental feed updates with a packet sequence number < tag
369-LastMsgSeqNumProcessed" — CME wiki "MBP and MBOFD Market Recovery"), and apply the rest in order.
This is the exact line between double-counting (applying an incremental the snapshot already includes)
and a gap (dropping one it doesn't) — get the `<` vs `≤` boundary wrong and you reintroduce the very bug.
**Key concepts:** tag 369 LastMsgSeqNumProcessed, buffer-then-replay, drop < snapshot seq, recovery feed
**Tip:** Snapshot loop iterations aren't ordered and you must process a full iteration starting at
the snapshot's own packet seq=1 to guarantee completeness; compare tag 911-TotNumReports across
iterations to detect instruments that appeared mid-recovery (CME wiki "MBP and MBOFD Market Recovery").
**Tool anchor:** CME wiki "Market Data Snapshot - Full Recovery" / "MBP and MBOFD Market Recovery"
**Drill:** You build from a snapshot with tag 369 = 10000 but forget to drop buffered incrementals
with packet seq < 10000. The book's best-bid quantity ends up too high. Trace exactly which message got applied twice.
**Tags:** orderbook, snapshot, recovery, tag-369, transition, correctness

### Two levels of gap detection: packet seq vs RptSeq (tag 83)
CME gives you two sequence numbers. The **packet sequence number** (binary packet header) is
per-channel: a gap means *some* book on the channel may be stale — coarse. **RptSeq (tag 83)** is
**per-instrument**: it increments per instrument, so a gap in instrument X's RptSeq means only X is
stale, and messages for other instruments in the same lost packet's neighborhood remain valid. Track
RptSeq per book to do **selective recovery** — recover only the affected instruments instead of
resynchronizing every book on the channel.
**Key concepts:** packet sequence number, RptSeq tag 83, per-instrument gap, selective recovery, channel reset
**Tip:** RptSeq resets to 1 per instrument on a channel reset (CME wiki). Treat the reset as
"discard and rebuild," not as a gap — don't fire snapshot recovery for a reset-to-1.
**Tool anchor:** CME wiki "Market Data Incremental Refresh"; OnixS gap-detection guide
**Drill:** A packet is lost containing updates for 2 of 10 instruments on the channel. With only
packet-seq detection you'd recover all 10. With RptSeq you recover 2. Quantify the recovery-time and
book-staleness difference under a 500k-msg/sec burst.
**Tags:** orderbook, gap-detection, rptseq, tag-83, packet-seq, selective-recovery

### AoS vs SoA for the price-level array
Layout decides cache traffic. **AoS** (`PriceLevel levels[N]` with `{price, qty, num_orders, ...}`)
loads the whole struct on any field access — a price-only scan drags qty/num_orders along, touching
~N×sizeof(level) bytes. **SoA** (`int64_t prices[N]; int32_t qtys[N]; ...`) lets a price scan touch
only the prices array (N×8B), so a 10-level scan is ~80B = 1.25 lines instead of 10×40B = 6.25 lines.
But SoA splits an update across 2–5 arrays (2–5 potential misses) while AoS keeps a level's fields on
one line. Rule of thumb: search-dominated mix → SoA; update-dominated mix → AoS. Benchmark under your
real message mix (more trades = more searches, more modifies = more updates).
**Key concepts:** AoS, SoA, price scan, cache lines touched, search vs update dominance
**Tip:** For CME MBP-10 (≤10 levels, ~one cache line per side) the AoS/SoA gap nearly vanishes — the
whole side is L1-resident either way. The layout fight matters far more for wide MBO books. Measure
before refactoring. See `/perf mem` for the cache-line math.
**Tool anchor:** `perf stat -e L1-dcache-load-misses ./book_bench` AoS vs SoA build; `/perf mem`
**Drill:** SoA enables an AVX2 `_mm256_cmpeq_epi64` price scan (4 prices/compare) only because prices
are contiguous. At 10 levels does SIMD beat scalar, or is setup overhead too high? Find the crossover.
**Tags:** orderbook, aos, soa, cache-layout, simd, perf-mem

### PriceLevel struct layout — the 64-byte contract
Everything moves in 64-byte cache lines. A `PriceLevel` at 32B packs 2 per line; at 40B you get 1.6
per line (wasted tail); at 72B every access spans 2 lines. Field ordering matters: a `bool` before a
`double` forces 7 bytes of alignment padding — 8 bytes of a 64B line gone. `static_assert(sizeof(
PriceLevel)==expected)` and `-Wpadded` catch regressions. For a 10-deep book, a tight 32B level keeps
a full side in one line; a bloated 64B level spreads it across 10 lines and tanks your scan.
**Key concepts:** 64-byte cache line, struct packing, alignment padding, static_assert sizeof, -Wpadded
**Tip:** Encode price as a scaled int64 (CME prices are integer mantissa × 10^exponent), not a double
you re-derive each access — and never store a re-computable field on the hot level if it costs you a
cache line. Keep the level to the fields the hot path actually reads.
**Tool anchor:** `pahole ./libbook.so` or `clang -Wpadded`; `offsetof` checks; `/perf mem`
**Drill:** A teammate adds a `uint64_t timestamp` to PriceLevel "for debugging," pushing it 32B→40B.
Predict the L1 miss-rate change on a 10-level scan and confirm with `perf stat`.
**Tags:** orderbook, struct-layout, cache-line, padding, static-assert, perf-mem

### Implied prices — one book or two?
CME computes **implied** liquidity for spread/strategy instruments from their legs and disseminates
it as separate entry types: **MDEntryType E = Implied Bid, F = Implied Offer** (CME wiki "Implied
Book"); implied-eligible instruments are flagged in the Security Definition. CME provides a 2-deep
implied best bid/ask. Design question (seed): merge implied + outright into one book, or keep two?
Merging doubles the effective book width (more cache footprint per instrument) but gives the
strategy a single consolidated top-of-book; keeping them separate halves the width but pushes the
merge to the consumer. Implied is **MBP-only** — not sent in MBO/MBOFD/MBOLD format.
**Key concepts:** implied bid/offer, MDEntryType E/F, implied book 2-deep, merge vs separate, book width
**Tip:** Because implied is MBP-only and 2-deep, the merged-book cache cost is small — the real
tradeoff is *semantic* (does the strategy want consolidated or separated top-of-book), not perf.
Decide on the consumer's need, then measure the cache delta to confirm it's negligible.
**Tool anchor:** CME wiki "MDP 3.0 - Implied Book" (tag 269 = E/F)
**Drill:** Merge implied into the outright book and your "best bid" sometimes flips between an outright
and an implied price tick-to-tick. Is that a bug or correct behavior? How does the strategy tell which?
**Tags:** orderbook, implied-prices, mdentrytype, implied-book, book-width, cme-mdp

### Overlay and the best-price fast path
`MDUpdateAction=5 (Overlay)` lets CME restate a level in one instruction — notably used when the best
price changes, sent as a single overlay at MDPriceLevel=1 (CME wiki). Separately, **MBOLD** uses an
*overlay book-management* model entirely: each conflated Market Data Snapshot (FIX tag 35=W, which for
MBOLD maps to the `SnapshotRefreshTopOrders` SBE template — distinct from MBP's `SnapshotFullRefresh`
template 52) fully restates the top-10 order book rather than applying deltas. Knowing which view is delta-driven (MBP, MBOFD via
incrementals) vs overlay-driven (MBOLD) changes your engine: delta books need gap detection +
recovery; overlay books just take the latest full restatement (stale > lost still applies).
**Key concepts:** Overlay action (279=5), best-price restatement, MBOLD overlay model, snapshot 35=W restate
**Tip:** Don't write gap-recovery machinery for an overlay-managed view — a missed overlay is simply
corrected by the next full restatement. Recovery complexity belongs to the delta-managed views.
**Tool anchor:** CME wiki "Market By Order Limited Depth Book Processing" (overlay approach)
**Drill:** You apply MBOLD overlays as if they were incremental deltas (adding instead of replacing).
The book quantity grows unbounded. Where in the loop is the replace-vs-merge confusion?
**Tags:** orderbook, overlay, mbold, snapshot-restate, book-management, cme-mdp

### Branchless and the template-ID/action dispatch
The per-entry `switch(MDUpdateAction)` and per-message template-ID switch are predicted *well* when
the action mix is skewed (most updates are Change/New) — the predictor locks the pattern in <100
iterations (`/perf cpu`). The danger is rare-but-real branches: an almost-never-taken error or
rare-action check costs ~15 cycles the one time it fires. Don't make counted shift-loops branchless
(the predictor nails counted loops); do consider branchless for unpredictable SBE null checks (CME
uses sentinels like INT64_MAX for null price/qty) when the null rate sits in the misprediction-prone
~10–50% band.
**Key concepts:** switch dispatch prediction, skewed action mix, 15-cycle mispredict, branchless null check, sentinels
**Tip:** SBE null sentinels (e.g., max-value = "field absent") appear unpredictably; a branchless
select `x ^ (-(x==NULL)&(x^default))` wins only in the mispredict-prone band. At 0% or near-100% null,
the branch is perfectly predicted and branchless is pure overhead — measure the null rate first.
**Tool anchor:** `perf stat -e branch-misses ./book_bench`; see `/perf cpu` branch-prediction topics
**Drill:** Your action `switch` shows 12% branch-miss under a uniform action mix but 2% under the
real skewed mix. Explain the gap and decide whether a function-pointer table would help or hurt here.
**Tags:** orderbook, branch-prediction, dispatch, branchless, sbe-null, perf-cpu

### Book lifecycle events — channel reset, clear, and trading-day boundaries
A book isn't only built up; it's torn down and rebuilt at known points. A **channel reset** (CME
sends a Channel Reset / Admin event) resets RptSeq to 1 per instrument and signals "discard all
books on this channel and start fresh" — distinct from a packet gap. **Book-clear** semantics arrive
through the delete-family actions (Delete / DeleteThru / DeleteFrom) which can wipe a level range in
one instruction. Across the trading day, market-state transitions (pre-open, open, close) reshape or
empty books; SecurityStatus messages (template 30) carry these state changes. The book engine must
treat reset/clear as first-class control flow, not as anomalies to recover from.
**Key concepts:** channel reset, RptSeq reset to 1, DeleteThru/DeleteFrom clear, market state, SecurityStatus, trading-day
**Tip:** A common bug: firing snapshot recovery on a channel reset (you "see a gap" to seq 1) instead
of just clearing books. Detect the reset event explicitly and short-circuit the gap-recovery path —
otherwise you waste a recovery cycle every reset and may rebuild from a snapshot you didn't need.
**Tool anchor:** CME wiki "Channel Reset" / "Market Data Incremental Refresh - Channel Reset"; SecurityStatus (30)
**Drill:** At the open, RptSeq for every instrument jumps back to 1. Your gap detector flags 50
simultaneous gaps and storms the recovery feed. What event did you miss, and how do you handle it cleanly?
**Tags:** orderbook, channel-reset, book-clear, securitystatus, market-state, lifecycle

## advanced

### std::flat_map vs hand-rolled flat array
`std::flat_map` (C++23) is the stdlib's cache-friendly sorted container: it holds **two parallel
sorted vectors** (keys, values) instead of a tree, so lookup is O(log n) binary search over
contiguous memory and iteration is cache-linear — but **insert/erase are O(n)** because elements
shift, and it offers O(1) append only for already-sorted back-insertion (cppreference). For an MBP
book this is close to your hand-rolled array, *except* `flat_map` searches by price (O(log n)) while
your engine already has the level index from tag 1023 (O(1) to the slot). So `flat_map` reintroduces
a search CME already did for you. Use it as the *baseline to beat*; the hand-rolled index-addressed
array should win on the MBP hot path. For wide MBO books where you must search by OrderID/price,
`flat_map` becomes genuinely attractive.
**Key concepts:** std::flat_map, parallel sorted vectors, O(log n) lookup, O(n) insert, index-addressed vs search
**Tip:** `flat_map` can't hold non-movable types and has weaker exception safety (it moves elements,
not pointers). For a trivially-copyable PriceLevel that's fine — but the real reason to hand-roll is
that tag-1023 gives you the index, making any search-based container strictly more work.
**Tool anchor:** cppreference `std::flat_map`; Google Benchmark flat_map vs hand-rolled array
**Drill:** Benchmark `std::flat_map<int64_t,Level>` against your index-addressed `std::array` on the
same 1M-update CME trace. Where does flat_map lose — the binary search, the shift, or both? Quantify.
**Tags:** orderbook, flat-map, cpp23, sorted-vector, benchmark-crossover

### MBO book building — OrderID, MDOrderPriority, and sorting
A Market-by-Order book stores individual orders, not aggregated levels. Each order has an anonymous
**OrderID** (assigned sequentially by the match engine, **stable for the life of the order**) and an
**MDOrderPriority (tag 37707)** used to position it among same-instrument, same-side, same-price
orders, lowest→highest (CME MBO docs). Critical correctness rule: **priority is not globally
sequential across prices** — you must sort **by price first, then by tag 37707** within a price. The
book mutation verbs come from either `MDUpdateAction (279)` or `OrderUpdateAction (37708)` depending
on the SBE template (MBOFD updates are carried in the Market Data Incremental Refresh message, which
maps to the `MDIncrementalRefreshBook` template; which action tag applies depends on the template
variant — CME wiki "Market by Order - Book Management"). Native iceberg refreshes keep the same
OrderID, so don't treat a refresh as a new order.
**Key concepts:** OrderID stable, MDOrderPriority tag 37707, sort price-then-priority, OrderUpdateAction 37708, iceberg refresh
**Tip:** Building MBO correctly requires a price-level index *and* an in-level order queue keyed by
priority — a `flat_map<price, sorted-order-list>` or a flat array of levels each holding a small
sorted vector of orders. This is where contiguous-but-searchable containers finally earn their keep.
**Tool anchor:** CME "Market by Order (MBO)" FAQ; CME wiki "Market by Order - Book Management"
**Drill:** You sort the whole MBO book by tag 37707 globally (ignoring price). Two orders at different
prices get interleaved wrong. Show the failing case and fix it with the price-then-priority rule.
**Tags:** orderbook, mbo, orderid, mdorderpriority, tag-37707, book-management

### Price-time priority and queue position — why book correctness has economic value
CME's default matching is **price-time priority (FIFO)**: best price fills first, ties broken by
arrival time, and the trade prints at the resting (maker's) price (Harris). Some CME products use
**pro-rata** (fill proportional to size at a price) instead. This is *why* MBO and accurate queue
modeling matter: under FIFO, queue position is a real economic asset — being earlier in the queue at
a price means you fill first, and faster order submission buys better position. A feed handler that
mis-models queue position (e.g., from a desync'd MBO book) directly mis-prices the strategy's edge.
**Key concepts:** price-time priority, FIFO, maker price, pro-rata, queue position value, adverse selection
**Tip:** Top-of-book quote alone is misleading for size: effective fill price depends on depth and
queue depletion. A correct multi-level book (and queue model for MBO) is what lets the strategy
estimate slippage before sending — book correctness isn't pedantry, it's PnL.
**Tool anchor:** Harris *Trading and Exchanges* (price priority, time precedence, allocation rules)
**Drill:** Under FIFO, an aggressive order sweeps the best ask and walks up two levels. Trace which
resting orders fill, at what prices, and how your book must update — then redo it under pro-rata.
**Tags:** orderbook, price-time-priority, fifo, pro-rata, queue-position, microstructure

### Multi-instrument cache pressure and prefetch under burst
Per-instrument the book is tiny; the problem is *aggregate working set* under a burst. 50 instruments
× ~20 levels × ~64B ≈ 64KB of hot book data — fits L1 (~32–48KB) only if one instrument dominates; a
market-open burst that updates all 50 simultaneously spills to L2 (~256KB). When messages arrive for
instruments 7, 23, 41, 2 in sequence, book 41 is likely not in L1, so **software-prefetch the next
message's book** (`__builtin_prefetch(books[next_id])`) to hide the L2 latency (~5ns) behind the
current update. The dispatch array's own line can also bounce if 8 books' pointers share it — store
books contiguously and index by offset (see beginner dispatch topic).
**Key concepts:** aggregate working set, L1/L2 spill under burst, prefetch next book, dispatch-line bouncing, hugepages
**Tip:** Prefetch helps ~10–20% when instrument order is random (defeats the HW prefetcher), near-zero
when sequential (HW prefetcher already handles it). Measure first — and consider 2MB hugepages so the
whole 64KB book region needs one TLB entry, not 16 (see `/perf mem` TLB topics).
**Tool anchor:** `perf stat -e L1-dcache-load-misses,dTLB-load-misses ./pipeline`; `perf c2c`; `/perf mem`
**Drill:** Measure L1 miss rate at 1 vs 50 active instruments under a burst. At what active-instrument
count does the book working set leave L1, and does prefetch recover the lost time?
**Tags:** orderbook, cache-pressure, prefetch, working-set, hugepages, perf-mem

### The book is hot-path: zero-allocation, measurement, and budget
The book engine sits in the 1–100µs hot path, so it must allocate **zero bytes after init** —
pre-allocate every book array, every per-side level array, at startup; any `new`/`malloc` here risks
a 50–200ns allocator call or a 5–50µs kernel `mmap`/page-fault visible in p99. Pre-fault and
`mlockall` the book memory. Stamp `t_book_updated` with a cheap monotonic clock to attribute the book
stage's latency in HdrHistogram (`clock_gettime` is vDSO-accelerated to a userspace read for clocks like
`CLOCK_MONOTONIC` when the clocksource is the TSC; note `CLOCK_MONOTONIC_RAW` — which is not subject to
NTP/`adjtime` slewing, man clock_gettime(2) — only gained vDSO acceleration in newer kernels, x86 ≈ Linux
5.3, and was a syscall before), and only optimize the book if the stage
profile says it dominates — "if 80% of latency is receive, optimizing the book is premature" (seed).
**Key concepts:** zero-allocation hot path, pre-fault, mlockall, per-stage timestamp, HdrHistogram, latency attribution
**Tip:** Interpose `malloc` via `LD_PRELOAD` that aborts if called from the book thread after init —
if it fires, you have a hidden allocation bug. Then use `perf stat -M TopdownL1` on the book stage:
Backend-Bound → data layout (cache), Frontend-Bound → code layout (I-cache). See `/perf methodology`.
**Tool anchor:** `clock_gettime(CLOCK_MONOTONIC_RAW)`; HdrHistogram; `perf stat -M TopdownL1`; `/perf methodology`
**Drill:** p99 of the book stage spikes every ~10ms while p50 is flat. Is it allocation, a page fault,
the OS scheduler, or a cache effect? Design the experiment (timestamps + perf counters) that isolates it.
**Tags:** orderbook, hot-path, zero-allocation, measurement, hdrhistogram, perf-methodology

### Correctness invariants and verification
A book engine's correctness is checkable, not vibes. Invariants to assert (cheaply in debug, sampled
in prod): bids strictly descending, offers strictly ascending, no crossed book (best bid < best
offer) outside a transient event, depth ≤ instrument's tag-264 MarketDepth, total per-level qty ≥ 0,
RptSeq monotonic per instrument. Verification (seed): run a known message trace and compare the final
book to the expected snapshot; replay real CME pcaps (DataMine); inject `tc netem` loss and confirm
gap recovery rebuilds the identical book. A crossed or negative book usually means a missed
Delete/DeleteThru, a double-applied incremental across the snapshot boundary, or an ignored
MDUpdateAction value.
**Key concepts:** book invariants, crossed book, monotonic RptSeq, trace-vs-snapshot diff, pcap replay, fault injection
**Tip:** A persistent crossed book after recovery is the signature of the snapshot-transition bug
(forgot to drop incrementals with packet seq < tag 369) or an unhandled action. Diff the reconstructed book against
the next clean snapshot to localize which instrument and level diverged.
**Tool anchor:** CME DataMine pcaps; `tc netem` loss injection; trace-vs-expected-snapshot diff harness
**Drill:** After injecting 0.1% packet loss your end-of-day book matches the expected snapshot for 48
of 50 instruments. Which two failed, what's the most likely cause, and which RptSeq gap confirms it?
**Tags:** orderbook, correctness, invariants, verification, pcap, fault-injection
