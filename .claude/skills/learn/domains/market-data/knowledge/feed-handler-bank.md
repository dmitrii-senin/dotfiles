# Feed-Handler Topic Bank
Updated: 2026-06-12

> Scope: the **I/O + reliability boundary** of a CME feed handler — joining multicast,
> draining the socket without drops, arbitrating A/B, detecting sequence gaps, and
> recovering via snapshot/replay. Anchored to the hot-path budget (1–100µs). Where a
> topic is pure CPU/cache/concurrency theory, it is kept *applied to the receive path*
> and cross-linked to the `perf` domain rather than re-derived.
> Sources: CME Globex MDP 3.0 Client Systems Wiki (public), Linux man pages
> (`recvmmsg(2)`, `socket(7)`, `ip(7)`), kernel NAPI docs, LWN, `liburing`.

## beginner

### The feed handler's job and its latency budget
A CME feed handler sits between the wire and the book builder: it joins the exchange multicast groups, drains datagrams off the socket, arbitrates the redundant A/B feeds, detects sequence gaps, drives recovery, and hands clean SBE buffers downstream. The end-to-end hot path (wire → recv → SBE decode → book update → publish) lives in the **1–100µs** budget; the receive stage alone is typically single-digit µs on a tuned box. Everything in this area is judged against that budget: an optimization that saves 200ns matters, and a single page fault (1–10µs) or a `malloc` that hits the kernel (5–50µs) is a visible p99 spike.
**Key concepts:** receive stage, hot path, 1–100µs budget, A/B arbitration, gap detection, recovery, zero-alloc steady state
**Tip:** Before optimizing receive, profile the whole path. If 80% of latency is in the book update, a faster `recv` strategy is premature — see the receive-strategy topic.
**Tool anchor:** per-stage timestamps (`t_receive`, `t_parsed`, `t_book_updated`) into an HdrHistogram; see `/measurement`.
**Drill:** Your p99 wire-to-book is 40µs but p50 is 6µs. Name three receive-path causes of the tail (not the decode/book) and the one measurement that isolates each.
**Tags:** feed-handler, latency-budget, hot-path, pipeline

### CME multicast dissemination: A/B feeds and UDP
CME MDP 3.0 disseminates each channel's incremental market data over **UDP multicast on two independent feeds, A and B**, carrying identical packets. UDP has no retransmission, so the redundant feeds are the *first* line of defense against loss: a packet dropped on the path to Feed A is very likely still delivered on Feed B. The multicast group IPs, source/host IPs, and ports for every channel live in CME's published `config.xml` (FTP/SFTP site). A channel also carries separate Incremental, Instrument-Definition, and Market-Recovery (snapshot) feeds, each itself duplicated A/B.
**Key concepts:** UDP multicast, Feed A, Feed B, channel, config.xml, incremental feed, snapshot/recovery feed, instrument-definition feed
**Tip:** Each feed type (incremental, snapshot, definition) is its own multicast group on its own port — a handler joins several groups, not one.
**Tool anchor:** `tcpdump -i <nic> -n multicast` to confirm both A and B groups are arriving.
**Drill:** Feed A shows zero packets but the book stays current. What is happening, and what alert should fire even though clients are unaffected?
**Tags:** cme-mdp, multicast, A-B-feeds, channels, dissemination

### Joining a multicast group (IP_ADD_MEMBERSHIP)
To receive multicast you must (1) create a `SOCK_DGRAM` socket, (2) `bind()` to the port with the local address left as `INADDR_ANY`, then (3) join each group via `setsockopt(IPPROTO_IP, IP_ADD_MEMBERSHIP, &ip_mreq)`. The `struct ip_mreq` carries `imr_multiaddr` (the group) and `imr_interface` (which local NIC). Do **not** `connect()` to the multicast address — bind to the port and receive. Memberships are dropped automatically when the socket closes. `IP_MAX_MEMBERSHIPS` historically caps groups per socket at 20, so a many-channel handler uses several sockets.
**Key concepts:** SOCK_DGRAM, bind to INADDR_ANY, IP_ADD_MEMBERSHIP, ip_mreq, imr_interface, IP_MAX_MEMBERSHIPS=20
**Tip:** Pin the join to a specific NIC via `imr_interface` on multi-homed market-data hosts — `INADDR_ANY` picks the kernel's default multicast route, which may not be the kernel-bypass / timestamped NIC.
**Tool anchor:** `ip maddr show dev <nic>` lists joined groups; `netstat -gn` shows memberships.
**Drill:** You join 30 channels' incremental groups on one socket and the 21st `IP_ADD_MEMBERSHIP` fails. Why, and what's the fix?
**Tags:** multicast, ip-add-membership, ip_mreq, sockets, join

### SO_RCVBUF and silent UDP drops
When a datagram arrives and the socket receive buffer is full, the kernel **silently discards** it — no error to the application. The buffer must be large enough to absorb a burst while the handler is busy. Set it with `setsockopt(SO_RCVBUF, ...)`; on Linux the kernel **doubles** the value for bookkeeping and `getsockopt` returns the doubled number. The request is hard-capped at `net.core.rmem_max`, so raising the sysctl *and* setting the option are both required — otherwise the app-level increase silently has no effect.
**Key concepts:** SO_RCVBUF, silent drop, rmem_max cap, kernel doubling, burst absorption
**Tip:** A market-open or news burst can hit 500k–1M msgs/sec; size the buffer for the burst, not the average. 8 MiB is a common starting point for a busy feed.
**Tool anchor:** `netstat -su` "receive buffer errors" and `/proc/net/snmp` `Udp: RcvbufErrors` count overflow drops; `ss -uanm` shows current `Recv-Q`.
**Drill:** `RcvbufErrors` climbs only during the opening burst. You raise `SO_RCVBUF` to 64 MiB but the drops continue unchanged. Name the most likely cause.
**Tags:** so-rcvbuf, udp-drops, rmem_max, buffer-tuning, bursts

### Multiple messages per datagram, multiple packets per event
MDP 3.0 packets are framed: a **packet header** (4-byte packet sequence number + 8-byte sending time) followed by one or more SBE messages, each prefixed by a 2-byte (uint16) message size, then the SBE message header (block length / template ID / schema ID / version). One datagram can carry many messages, and — a deliberate MDP 3.0 design change — a single matching *event* can span several sequential packets, and one packet can contain several events. The receive loop must therefore parse a datagram as a *batch* of messages, not assume one-message-per-packet.
**Key concepts:** packet header, packet sequence number, sending time, 2-byte message size, batch parsing, event spans packets
**Tip:** Loop over messages within a datagram using the 2-byte size to advance the cursor; the SBE message header's block length tells you the fixed-block size for group/var-data cursoring (see `/sbe`).
**Tool anchor:** decode the first 12 bytes of any captured datagram to read seq# and sending time before the first message size.
**Drill:** Why can't the handler treat each UDP datagram as one atomic book event? Give the MDP 3.0 design reason and one correctness bug it would cause.
**Tags:** cme-mdp, packet-structure, batch-parsing, message-framing, sequence-number

## intermediate

### A/B arbitration by packet sequence number
The handler processes **both** A and B, ordered by the monotonic packet sequence number, and **discards any packet whose sequence number it has already processed**. This is duplicate-elimination, not failover: whichever feed delivers a given seq# first wins, the other copy is dropped. A *true* gap — one that requires recovery — exists only when the **same** sequence number is missing from **both** feeds. Robust handlers also keep per-feed state and a time-based fallback: if neither feed advances past the expected seq# within a wait window, declare the gap rather than block forever.
**Key concepts:** arbitration, dedup by packet seq#, last-processed seq#, gap = missing on both feeds, lostPacketWaitTime fallback
**Tip:** Track the highest contiguous processed seq# plus a small reorder window; a packet arriving with seq# ≤ last-processed is a dup, seq# = last+1 is in-order, seq# > last+1 is a candidate gap pending the other feed / timer.
**Tool anchor:** counters for {A-first, B-first, dups-dropped, gaps-declared}; healthy feeds show both A-first and B-first nonzero.
**Drill:** A is consistently ~30µs ahead of B. What do your A-first/B-first counters look like, and why is processing both feeds still worth the CPU?
**Tags:** arbitration, sequence-number, dedup, gap-detection, A-B-feeds

### Gap detection: packet seq# vs per-instrument RptSeq
There are two layers of gap detection. The **packet sequence number** detects loss on the channel as a whole. The **per-instrument sequence (tag 83, RptSeq)** detects whether a *specific instrument* missed an update. The payoff of the per-instrument layer: if a lost packet only affected 2 of 10 instruments, the other 8 are provably current and can keep flowing while only the 2 affected books recover. Without it, any gap forces a full channel resync.
**Key concepts:** packet seq# (channel-level), RptSeq tag 83 (instrument-level), per-instrument recovery, partial resync
**Tip:** On a declared gap, mark only instruments whose RptSeq is now discontinuous as "stale/recovering"; leave the rest live. This is the difference between a 50ms full resync and a sub-ms localized one.
**Tool anchor:** maintain `last_rptseq[security_id]`; a jump > 1 flags that instrument.
**Drill:** A channel gap is declared. 48 of 50 instruments show contiguous RptSeq across the gap boundary. What is the correct handler behavior for the 48 vs the 2?
**Tags:** gap-detection, rptseq, tag-83, per-instrument-recovery, correctness

### Snapshot recovery and the LastMsgSeqNumProcessed reconciliation
For a large gap, recovery uses the **Market Recovery (snapshot) feed**, which continuously replays a full book snapshot per instrument (template `SnapshotFullRefresh`, 52). The reconciliation is sequence-number based: while recovering, **queue** the live incremental feed; from the snapshot read **tag 369 LastMsgSeqNumProcessed**, which corresponds to the incremental packet sequence number that snapshot reflects; then **drop every queued incremental with packet seq# < 369** (CME's documented rule: drop cached increments with packet seq# *less than* tag 369), apply the snapshot, and replay the remaining queued increments on top. You must process one full snapshot loop iteration to recover an instrument. Overlap edge case: if an instrument appears in both the snapshot and the queued increments, compare tag 60 TransactTime — if the values do not match, recover that instrument on the next snapshot iteration.
**Key concepts:** snapshot feed, SnapshotFullRefresh (52), tag 369 LastMsgSeqNumProcessed, queue-then-reconcile, drop seq# < 369, tag 60 TransactTime
**Tip:** The bug to avoid is double-counting: applying both the snapshot *and* the increments it already contains. The `< 369` drop rule is exactly what prevents it.
**Tool anchor:** during recovery, log {snapshot 369, queued-min-seq, queued-max-seq, dropped count}.
**Drill:** Snapshot for instrument X has tag 369 = 10,000. Your queue holds increments with packet seq# 9,998…10,050. Which do you drop, which do you apply, and in what order?
**Tags:** snapshot-recovery, last-msg-seq-num-processed, tag-369, reconciliation, double-counting

### TCP replay vs snapshot recovery
For a *small, known* gap, CME offers **TCP historical replay**: request the exact missed packet range by start/end packet sequence number (Market Data Request, 35=V). Hard limits: **≤ 2000 packets per request** and **only the current 24 hours**. It is unicast and explicitly *not* a performance path — CME positions it as last-resort for small gaps, with snapshot/natural-refresh recovery as the primary mechanism. Snapshot recovery scales to "resync everything" but discards your queued history; TCP replay surgically fills a small hole without a full resync.
**Key concepts:** TCP replay, 35=V request, start/end seq#, ≤2000 packets, 24h window, not-a-perf-path
**Tip:** Decision rule: tiny contiguous gap and you can tolerate the round-trip → TCP replay; large/uncertain gap or many instruments → snapshot feed.
**Tool anchor:** count replay requests/day as a health metric — a rising trend means the receive path is dropping more than it should.
**Drill:** You missed packets 5,000–5,003 on both feeds. Replay or snapshot? Now you missed 5,000–9,500. Same question — justify each.
**Tags:** tcp-replay, recovery, 35-V, snapshot-vs-replay, limits

### recvmmsg: batching receives to amortize syscalls
`recvmmsg(2)` receives up to N datagrams in **one** syscall via an array of `mmsghdr`, amortizing the user/kernel crossing across the batch. The return value is how many slots were filled (may be < N). The win appears only when the NIC ring is genuinely full of packets — roughly above ~100k pps; below that, waiting to fill a batch *adds* latency. **Two sharp edges:** (1) the documented `timeout` BUG — the timeout is checked only *after each datagram*, so if N−1 arrive then traffic stops, the call blocks forever; (2) use `MSG_WAITFORONE` (since Linux 2.6.34) to get "block for one, then grab whatever else is ready" instead of relying on the buggy timeout.
**Key concepts:** recvmmsg, mmsghdr array, batch amortization, ~100k pps break-even, timeout BUG, MSG_WAITFORONE
**Tip:** Don't trust `recvmmsg` timeout as a deadline. For a hard deadline, gate with `epoll`/`poll` first or `SO_RCVTIMEO`; for burst draining, prefer `MSG_WAITFORONE`.
**Tool anchor:** histogram the per-call return value (datagrams-per-syscall) to see whether batching is actually engaging.
**Drill:** At 20k pps your `recvmmsg(N=32)` p99 latency is *worse* than a plain `recvmsg` loop. Explain why, and at what offered load batching starts to pay off.
**Tags:** recvmmsg, batching, syscall-amortization, timeout-bug, msg-waitforone

### Receive strategies: epoll vs SO_BUSY_POLL vs io_uring
Four common strategies trade latency for CPU. **epoll (+EPOLLET)** blocks until readable and frees the core when idle, at the cost of an interrupt-to-wake transition. **SO_BUSY_POLL** has the kernel poll the NIC in the recv path, eliminating that transition (lower latency, lower jitter) at the cost of burning a core; `SO_PREFER_BUSY_POLL` + `napi_defer_hard_irqs` + `gro_flush_timeout` keep IRQs masked for steadier polling, with a watchdog that falls back to softirq if you stop polling. **io_uring + SQPOLL** moves submission to a kernel poll thread (no submit syscall on the hot path); **multishot recv** lets one SQE yield many CQEs without re-arming — strongest for small datagrams. For UDP the evidence is genuinely mixed: io_uring often ties or modestly beats `SO_BUSY_POLL + recvmmsg` rather than dominating, and the answer flips with message size and load.
**Key concepts:** epoll/EPOLLET, SO_BUSY_POLL, SO_PREFER_BUSY_POLL, napi_defer_hard_irqs/gro_flush_timeout, io_uring SQPOLL, multishot recv
**Tip:** Busy-poll and SQPOLL both *cost a core*. On an isolated CPU dedicated to one feed that's the right trade; on a shared box it isn't. Always measure end-to-end, not the syscall in isolation.
**Tool anchor:** compare strategies on the *same* trace: p50/p99 wire-to-book + CPU% per strategy; see `/measurement` and `/perf methodology`.
**Drill:** Busy-poll gives the best p99 but you have only 4 cores for 6 feeds. Design a strategy and state the latency you're trading away.
**Tags:** receive-strategy, epoll, so-busy-poll, io_uring, sqpoll, busy-polling

### SO_REUSEPORT and scaling receivers
`SO_REUSEPORT` lets multiple sockets bind the same address/port; for **unicast UDP** the kernel hash-distributes datagrams across the group by the 4-tuple (src/dst IP+port). The catch for CME: a multicast feed is effectively a **single source → one tuple**, so default hashing pins all traffic to one socket and gives no parallelism. To split a hot channel across cores you need either `SO_ATTACH_REUSEPORT_[CE]BPF` to steer packets, or multiple receivers each owning a subset of channels — and then you inherit shared-book contention if those receivers update the same instruments. Note: for *multicast addresses* `SO_REUSEADDR` already behaves like `SO_REUSEPORT`.
**Key concepts:** SO_REUSEPORT, 4-tuple hash, single-source multicast pins one core, BPF steering, SO_REUSEADDR=REUSEPORT for multicast, shared-book contention
**Tip:** Don't reach for `SO_REUSEPORT` to parallelize a single multicast group — it won't split by default. Partition by *channel* across threads instead, keeping each book single-writer.
**Tool anchor:** `perf c2c` on the book structures to catch cross-core contention if you do split receivers; see `/perf concurrency`.
**Drill:** You add a second `SO_REUSEPORT` receiver to halve load on one busy channel, but one socket still gets ~100% of packets. Explain and propose two fixes.
**Tags:** so-reuseport, scaling, multicast-hashing, bpf-steering, contention

### Zero-allocation, pre-faulted receive path
The receive path must allocate **zero bytes** after init. `malloc`/`new` cost ~50–200ns even on a fast allocator and can occasionally trap to the kernel (`mmap`/`brk`) for 5–50µs — a guaranteed p99 spike. Pre-allocate every buffer at startup: the `mmsghdr` array, per-datagram receive buffers, the staging/aligned buffer, the gap-recovery queue, the timestamp ring. A page fault on a *touched-but-not-resident* buffer also costs ~1–10µs, so pre-fault with `mlockall(MCL_CURRENT|MCL_FUTURE)` and write-touch every page once at startup.
**Key concepts:** zero-alloc hot path, malloc latency, mmap/brk trap, page-fault cost, mlockall, pre-fault
**Tip:** Interpose `malloc` with `LD_PRELOAD` in a test build that aborts if called from the receive thread — if it fires, you have an allocation bug on the hot path.
**Tool anchor:** `perf stat -e page-faults -- ./handler` should show near-zero faults during the steady-state run; see `/perf mem` and `/lowlat-net`.
**Drill:** p99 shows a 9µs spike exactly once per recovery event. Allocation is "zero" in steady state but recovery allocates a queue. How do you fix it without per-event allocation?
**Tags:** zero-allocation, mlockall, pre-fault, page-fault, allocator, hot-path

### Backpressure: overwrite, not block, for slow downstream
When a downstream consumer (book builder, strategy, monitoring) falls behind, the feed handler must **never block** the receive loop — blocking means the kernel's socket buffer fills and the kernel silently discards packets. The correct market-data policy is **overwrite**: the producer keeps writing the latest data and a slow consumer skips ahead to the newest via a `latest_sequence` atomic. **Stale data is worse than dropped data** for market data — a consumer that's behind wants the *current* book, not a backlog of old updates. This is the inverse of a reliable queue, and it's why the inter-stage rings are overwrite/SPSC, not blocking.
**Key concepts:** overwrite policy, never block receive, latest_sequence atomic, stale > lost, SPSC ring backpressure
**Tip:** Size the inter-stage ring for normal jitter, but make overwrite the *correctness* fallback, not an error — a slow Python monitor consumer should degrade to sampling, not stall the hot path.
**Tool anchor:** expose producer-vs-consumer sequence lag; a growing lag means the consumer is being overwritten (acceptable for monitoring, a bug for the book builder). See `/systems` SPSC rings.
**Drill:** The monitoring consumer stalls for 200ms. With overwrite, what does it see when it resumes, and why is that the right outcome for a latency dashboard but wrong for the book builder?
**Tags:** backpressure, overwrite, spsc-ring, stale-vs-lost, latest-sequence

## advanced

### NIC interrupt coalescing on the receive path
`ethtool -C <nic> rx-usecs N rx-frames M` controls interrupt coalescing — how long / how many frames the NIC waits before raising an Rx interrupt. `rx-usecs 0 rx-frames 1` gives a per-packet interrupt: minimum latency, maximum CPU/IRQ rate. `rx-usecs 10 rx-frames 16` adds up to ~10µs of latency but roughly halves CPU — acceptable only if your overall budget is ~100µs, not if it's single-digit µs. This is a direct latency-vs-CPU knob and it interacts with busy-poll (which masks IRQs entirely). Tuning it wrong adds jitter that shows up only in p99.
**Key concepts:** interrupt coalescing, rx-usecs, rx-frames, latency-vs-CPU, IRQ rate, jitter
**Tip:** With `SO_BUSY_POLL`/`SO_PREFER_BUSY_POLL` you intend IRQs to stay masked — coalescing settings matter mainly for the fallback/idle path. Decide which regime you're in before tuning numbers.
**Tool anchor:** `ethtool -C <nic>` to set, `ethtool -S <nic>` for rx_packets/rx_dropped; correlate with feed p99. See `/lowlat-net`.
**Drill:** You set `rx-usecs 50` to cut CPU and p50 is unchanged but p99 jumps ~40µs. Explain the mechanism and the budget question it raises.
**Tags:** ethtool, interrupt-coalescing, rx-usecs, nic-tuning, jitter, lowlat-net

### CPU isolation and the two-core-per-feed pattern
A jitter-free receive path wants the processing thread alone on a core: `isolcpus` (or `cpuset`/`nohz_full`) removes the core from the scheduler, then `pthread_setaffinity_np` pins the thread, and `SCHED_FIFO` raises priority. But `SCHED_FIFO 99` can **starve softirqs** (including the network softirq) on the same core, stalling its own packet processing. The fix is the **two-core-per-feed** pattern: one core for NIC IRQs/softirq, a separate isolated core for the handler thread — IRQ affinity moved off the processing core via `/proc/irq/<n>/smp_affinity`. Combined with `mlockall` to keep pages resident, this is the baseline for predictable single-digit-µs receive.
**Key concepts:** isolcpus, affinity, SCHED_FIFO, softirq starvation, IRQ affinity, two-core-per-feed, nohz_full
**Tip:** Never run the busy-poll/handler thread at FIFO 99 on the *same* core handling its NIC IRQs — you starve the softirq that delivers the packets you're polling for.
**Tool anchor:** `cat /proc/interrupts` to see which core takes the NIC IRQ; `chrt -p <tid>` to verify scheduling policy. See `/lowlat-net`.
**Drill:** You pin the handler to an isolated core at FIFO 99 and throughput collapses under load though the core shows 100% busy. Diagnose and give the two-core fix.
**Tags:** isolcpus, cpu-affinity, sched-fifo, softirq, irq-affinity, lowlat-net

### Aligned staging buffers for safe SBE overlay
CME concatenates messages tightly in a datagram, so message N starts at `offset + size(N−1)` — frequently **not** 8-byte aligned, while SBE structs with `int64_t` fields need `alignof == 8`. Overlaying a flyweight (`std::start_lifetime_as<T>` in C++23, or `reinterpret_cast` pre-C++23) on a misaligned address is UB and can fault or misread on some microarchitectures. The production pattern: keep the **receive buffer 64-byte (cache-line) aligned** so the first message is aligned; for subsequent unaligned messages, `memcpy` the message into an aligned, L1-hot staging buffer before overlay. The copy is a few ns for a ~100-byte message. On modern x86 an unaligned access *within* a cache line is essentially free; the penalty appears when an access splits a cache-line boundary (a few cycles) and is larger again when it splits a page boundary (much costlier, especially for stores) — and the copy also removes the UB.
**Key concepts:** tight message packing, alignment requirement, start_lifetime_as, misaligned UB, aligned staging buffer, cache-line/page boundary cost
**Tip:** Align the receive buffer with `posix_memalign(64)` / `mmap`; copy only the messages that land unaligned, not every message — the first per datagram is already aligned.
**Tool anchor:** build with `-fsanitize=undefined` to catch the misaligned overlay, then measure aligned vs unaligned access cost on your CPU. See `/sbe` and `/perf mem`.
**Drill:** Overlaying directly on the receive buffer passes on x86 but UBSan flags message #2. Why is #1 fine and #2 not, and what's the minimal fix?
**Tags:** alignment, staging-buffer, start_lifetime_as, sbe-overlay, undefined-behavior, sbe

### Schema-version dispatch without mispredicting every message
CME evolves the schema by adding fields/messages; the SBE header carries a version, and during a rollout some instruments still send v1 while others send v2. The naive `if (version == 2)` branch **mispredicts every v2 message** at the start of a rollout (when v2 is ~0.01% of traffic), at ~15 cycles each — and again as the mix flips. Better: a **function-pointer table indexed by version** (or by template ID). The indirect call is well-predicted by the BTB because, per instrument, versions don't interleave — a given instrument's stream is all-v1 or all-v2. Same logic applies to template-ID dispatch: a `switch` over the 3–4 hot templates predicts well because the distribution is heavily skewed — CME documents that the *majority* of events carry only Market Data Incremental Refresh (35=X) messages, so the book-refresh template dominates — but a rare branch is the misprediction trap.
**Key concepts:** schema versioning, branch misprediction ~15 cycles, function-pointer table, BTB prediction, template-ID dispatch, skewed distribution
**Tip:** Reach for the pointer table specifically when the branch is *rare and changing* (a version rollout); for a stable skewed `switch`, the predictor already wins — measure before adding indirection.
**Tool anchor:** `perf stat -e branch-misses` across a simulated v1→v2 rollout, branch vs table; see `/perf cpu` (branch prediction) for the theory.
**Drill:** During a v1→v2 rollout your branch-miss rate spikes then settles. Explain the spike, the settle, and why an indirect call through a per-version table avoids both.
**Tags:** schema-evolution, branch-prediction, function-pointer-table, template-dispatch, btb, perf

### Unknown template IDs and never logging on the hot path
A `switch` over template IDs needs a `default` for unknown/new templates, but the handler must not (a) block, (b) silently skip something important (e.g. SecurityStatus / market-state), or (c) **log on the hot path** — a single log line can cost microseconds and stall the receive loop under burst. The pattern: pre-register all known template IDs at startup; on an unknown ID, bump a per-ID counter (a cheap increment) and continue; a background thread periodically inspects the counters and alerts. This keeps the hot path branch-light and allocation/IO-free while still surfacing protocol drift.
**Key concepts:** template-ID default case, no hot-path logging, pre-registered IDs, unknown-counter, background inspection, market-state messages
**Tip:** Treat "saw an unknown template ID" as telemetry, not an exception — increment and move on; the alert is the background thread's job, not the receive thread's.
**Tool anchor:** expose per-template-ID counts including the "unknown" bucket as a metric; a nonzero unknown bucket means a schema change you haven't deployed.
**Drill:** A new template ID appears mid-session. Walk through what the hot path does in the correct design, and what three tempting-but-wrong things it must not do.
**Tags:** template-id, unknown-message, hot-path-logging, telemetry, market-state, ownership

### Hardware timestamping for true receive latency
To measure wire-to-handler latency honestly you need a timestamp taken **at the NIC**, not in userspace after the packet has already traversed the stack. `SO_TIMESTAMPING` with hardware timestamps gives a NIC-level Rx timestamp; with PTP (`ptp4l`/`phc2sys`) the NIC clock is disciplined to a grandmaster so timestamps are comparable across hosts. Userspace `clock_gettime(CLOCK_MONOTONIC_RAW)` is ~20ns via the vDSO (`rdtsc`) and is right for *stage-to-stage* deltas inside the handler, but it cannot see the kernel/NIC portion. The gap between the HW Rx timestamp and your `t_receive` is exactly the stack + scheduling latency your tuning is trying to shrink.
**Key concepts:** SO_TIMESTAMPING, hardware Rx timestamp, PTP/ptp4l/phc2sys, CLOCK_MONOTONIC_RAW ~20ns vDSO, stack latency, cross-host comparability
**Tip:** Use HW timestamps for the wire→userspace segment and `MONOTONIC_RAW` for intra-process stage deltas; don't try to measure kernel latency with a userspace clock.
**Tool anchor:** `ethtool -T <nic>` shows timestamping capabilities; compare HW Rx ts vs `t_receive` to size stack latency. See `/lowlat-net` and `/measurement`.
**Drill:** Your intra-process p99 (t_receive→t_published) is flat, but a peer says you're 8µs slower than them wire-to-book. What measurement do you add, and what does it isolate?
**Tags:** hw-timestamping, so-timestamping, ptp, monotonic-raw, latency-measurement, lowlat-net

### False sharing across the receive→book ring
The handoff from the receive thread to the book builder is typically an SPSC ring. Its `head_` (written by the consumer/book builder) and `tail_` (written by the receive thread) **must be on different cache lines** — otherwise every producer write invalidates the consumer's line and vice versa, the MESI line ping-pongs across the interconnect (~40–70ns per round-trip vs ~1ns for an L1 hit), and your inter-stage handoff silently costs more than the work it carries. The fix is `alignas(64)` on each index (hardcode 64; `std::hardware_destructive_interference_size` is the "correct" name but GCC warns/omits it by default). A subtler case: per-instrument book pointers in the dispatch array sharing a line, so a burst across adjacent instruments bounces the dispatch line.
**Key concepts:** false sharing, head/tail separation, MESI ping-pong ~40–70ns, alignas(64), dispatch-array padding, SPSC ring
**Tip:** This is the single most dramatic latency bug you can both cause and fix in the handoff; `perf c2c` HITM events name the exact contended address.
**Tool anchor:** `perf c2c record/report` to find HITM on the ring indices or dispatch array; see `/perf concurrency` for the full theory.
**Drill:** Your receive→book handoff throughput is 5x lower than the ring's microbenchmark. `perf c2c` shows HITM on a single 64-byte address. What is it and what's the one-line fix?
**Tags:** false-sharing, spsc-ring, perf-c2c, alignas, dispatch-array, concurrency

### Memory-ordering machine clears in the A/B dedup path
The shared sequence-number state read by multiple threads (or a cross-feed dedup view touched by two cores) can trigger **memory-ordering machine clears**: a load speculatively executed before a store to the same line turns out to conflict, the CPU detects the violation, and **nukes the pipeline** — more expensive than a branch mispredict and *invisible* in branch-miss counters. The signature is high TMA Bad Speculation with low branch-miss rate and a high `machine_clears.memory_ordering` count, often on a shared `std::atomic<uint64_t> sequence`. The cleanest fix is a single-producer design for the contended state so the conflicting cross-core store/load pattern disappears.
**Key concepts:** memory-ordering machine clear, pipeline nuke, invisible to branch-miss, machine_clears.memory_ordering, shared atomic sequence, single-producer fix
**Tip:** If Bad Speculation is high but branch misses are ~1%, stop looking at branches and check machine clears — the culprit is usually a hot shared cache line, not a hard-to-predict branch.
**Tool anchor:** `perf stat -e machine_clears.count,machine_clears.memory_ordering,br_misp_retired.all_branches`; see `/perf cpu` (machine clears) and `/perf concurrency`.
**Drill:** TMA shows Bad Speculation 18%, branch-misses 1%, `machine_clears.memory_ordering` 500k/s on your dedup loop touching a shared seq atomic. Explain the mechanism and the redesign.
**Tags:** machine-clear, memory-ordering, bad-speculation, atomic-contention, perf, concurrency

### Profile the whole path before tuning the syscall
The recurring failure mode in this area is optimizing the receive syscall when receive isn't the bottleneck. Decompose latency by stage with embedded timestamps (`t_receive`, `t_parsed`, `t_book_updated`, `t_published`), find the hottest stage, then run **top-down microarchitecture analysis** (`perf stat -M TopdownL1`) on *that* stage to classify the bottleneck — Frontend/Backend/Bad-Spec/Retiring — before changing anything. A receive strategy that wins a syscall microbenchmark can lose end-to-end if it burns a core the book builder needed, or adds jitter the budget can't absorb. Measurement is the deliverable, not the optimization.
**Key concepts:** per-stage decomposition, top-down analysis, TopdownL1, end-to-end vs microbenchmark, measure-before-optimize
**Tip:** "io_uring is faster than epoll" is unanswerable in the abstract — it's true for some message sizes/loads and false for others. Settle it on *your* trace, end-to-end, with CPU accounted.
**Tool anchor:** `perf stat -M TopdownL1 -- ./handler` per hot stage; HdrHistogram p50/p99/p999 per stage. See `/perf methodology` and `/measurement`.
**Drill:** Receive is 1µs, decode 2µs, book update 30µs of a 40µs p99. You spend a week making receive 0.5µs. What happened to p99 and what should you have measured first?
**Tags:** methodology, top-down, per-stage-timestamps, measure-first, benchmarking, measurement
