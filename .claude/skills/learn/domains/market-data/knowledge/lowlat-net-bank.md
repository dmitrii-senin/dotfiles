# Low-Latency Networking & Host Tuning Topic Bank
Updated: 2026-06-12

> Scope: the **host / kernel / NIC layer** beneath a CME feed handler — the tuning
> that decides whether the wire→recv stage is a predictable few µs or a p99 spike.
> NIC tuning (`ethtool` coalescing, RSS/flow-steering), CPU isolation (`isolcpus`,
> affinity, `SCHED_FIFO`, IRQ steering), `mlockall`/prefault, hugepages, NUMA,
> hardware timestamping/PTP, and kernel-bypass awareness (Onload/ef_vi/DPDK).
> Anchored to the **1–100µs** hot path: a single page fault (1–10µs) or a stray
> interrupt on the hot core is a visible tail. This bank pairs with `/feed-handler`
> (the socket/receive-strategy side) and cross-links to `/perf` (mem, concurrency,
> methodology) for the deepest CPU/cache/TLB theory rather than re-deriving it here.
> Sources: Linux kernel docs (`scaling.rst`, `timestamping.rst`, HugeTLB, NO_HZ),
> man pages (`ethtool(8)`, `mlockall(2)`, `mmap(2)`, `sched(7)`, `socket(7)`),
> Red Hat RHEL-RT / RHEL perf-tuning guides, linuxptp (`ptp4l`/`phc2sys`),
> AMD/Solarflare Onload & ef_vi docs, DPDK docs.

## beginner

### Why the host stack is on the critical path
On a CME feed handler the wire→book hot path lives in **1–100µs**, and a large fraction of the *tail* comes not from your code but from the OS and NIC: an interrupt arriving on your hot core, a page fault (1–10µs to service), a `malloc` that touches the kernel (5–50µs), a frequency transition, a remote-NUMA memory access (~2x local DRAM). The host-tuning discipline is to make every one of these go away *before* the trading day, so steady-state receive is dominated by your code and the NIC, not by jitter sources. The mental model: p50 is mostly about throughput and cache layout; p99 is mostly about *what the OS does to you*.
**Key concepts:** jitter sources, page fault, interrupt, frequency transition, NUMA penalty, p50 vs p99, pre-trading-day tuning
**Tip:** Tune in dependency order — a faster `recv` strategy is wasted if a page fault or a stray softirq on the hot core puts a 5µs spike in p99 first.
**Tool anchor:** `perf record -e cycles -C <hot-core>` plus per-stage HdrHistogram (`/measurement`); watch the tail, not the mean.
**Drill:** p50 wire-to-book is 6µs but p99 is 45µs and the spikes recur. Name four host-layer (not code) causes and the one measurement that isolates each.
**Tags:** lowlat-net, host-tuning, jitter, latency-budget, p99

### Interrupt-driven receive vs. the latency it costs
The default Linux receive path is interrupt-driven: a packet arrives, the NIC raises an IRQ, the kernel runs the hardware-IRQ handler, schedules a softirq (NAPI), the softirq polls the ring and pushes frames up the stack, and eventually your blocked thread is woken. Each hop adds latency and — worse for trading — *variance* (the IRQ may land on a busy core, the wakeup may queue behind other work). The two structural responses are (a) **interrupt moderation/coalescing** to trade a little latency for far fewer interrupts, and (b) **busy-polling / kernel-bypass** to remove the interrupt-to-wakeup hop entirely. NAPI already mitigates interrupt storms by switching to polling under load, but the interrupt still exists.
**Key concepts:** hardware IRQ, softirq, NAPI poll, interrupt-to-wakeup latency, moderation vs busy-poll, variance
**Tip:** Interrupts are a *jitter* problem as much as a latency problem — the same path takes a different number of ns depending on where the IRQ lands. Pinning IRQs (below) is half the battle.
**Tool anchor:** `cat /proc/interrupts` (per-core IRQ counts), `ethtool -S <nic>` for rx counters; `mpstat -I CPU 1` to see which cores take softirqs.
**Drill:** Trace a UDP datagram from NIC to your `recvmmsg` return and list every hop where latency or variance can be injected.
**Tags:** lowlat-net, interrupts, napi, softirq, receive-path

### ethtool interrupt coalescing: rx-usecs and rx-frames
`ethtool -C <dev>` controls interrupt **coalescing** (a.k.a. moderation). The two basic RX triggers are `rx-usecs` (microseconds to wait after a packet arrives before raising an RX interrupt) and `rx-frames` (max frames to accumulate before interrupting); they act as an **OR** — whichever fires first delivers the interrupt. For lowest latency you push toward per-packet interrupts: `ethtool -C <dev> rx-usecs 0 rx-frames 1` (min latency, max CPU/interrupt rate). Relaxing to e.g. `rx-usecs 10 rx-frames 16` trades a small amount of added latency for a large drop in interrupt load — acceptable when the overall budget is generous. The `*-usecs-irq`/`*-frames-irq` variants apply *while the host is already servicing an interrupt*.
**Key concepts:** rx-usecs, rx-frames, OR semantics, usecs-irq/frames-irq, latency vs CPU tradeoff
**Tip:** The µs timer typically starts counting only *after* the first packet arrives; an idle link still delivers the first packet's interrupt promptly. Settings are **not** persistent across reboots/link events — bake them into a NetworkManager/systemd profile.
**Tool anchor:** `ethtool -c <dev>` to read current values; `ethtool -C <dev> rx-usecs 0 rx-frames 1` to set per-packet IRQs.
**Drill:** Your budget is 100µs and CPU is scarce. Justify `rx-usecs 8` over `rx-usecs 0`. Now the budget is 5µs — what changes and why?
**Tags:** lowlat-net, ethtool, coalescing, rx-usecs, nic-tuning

### Adaptive coalescing — and why HFT usually disables it
`ethtool -C <dev> adaptive-rx on` lets the driver auto-compute coalescing values from the live packet rate (low rate → low latency, high rate → high throughput), tuned by `pkt-rate-low/high`, `*-low/*-high`, and `sample-interval`. It is a good *default* for general servers, but for sub-50µs latency-sensitive paths the recommendation is to **turn it off** and pin fixed (usually minimal) values: the adaptive algorithm introduces its own variance as it ramps coalescing up and down, and the up-ramp during a burst is exactly when you least want added delay. Note that not all drivers honor every parameter — an unsupported option is silently ignored or returns an error (e.g. `igb` rejecting `adaptive-rx on`).
**Key concepts:** adaptive-rx/tx, pkt-rate thresholds, ramp variance, driver support caveat, fixed minimal coalescing
**Tip:** For a feed handler, prefer deterministic fixed coalescing over adaptive — predictability beats the average-case win. Always re-read with `ethtool -c` to confirm the driver actually applied your request.
**Tool anchor:** `ethtool -C <dev> adaptive-rx off adaptive-tx off rx-usecs 0 rx-frames 1`.
**Drill:** With adaptive-rx on, your p99 during the open is worse than midday despite lower midday volume. Explain the mechanism and the one-line fix.
**Tags:** lowlat-net, ethtool, adaptive-rx, coalescing, determinism

### CPU affinity: pinning the hot thread
By default the scheduler load-balances threads across all cores, which is poison for latency: a migrated thread arrives on a cold core (cold L1/L2, cold branch predictors) and pays cache-refill cost. The fix is to **pin** the receive/processing thread to one specific core with `pthread_setaffinity_np` / `sched_setaffinity` (or launch under `taskset -c N`). Pinning keeps the thread's working set hot in that core's caches and removes migration jitter. It pairs with `isolcpus` (next): pin *to* an isolated core so nothing else lands there. Pick the core deliberately — same NUMA node as the NIC, and not a hyperthread sibling of another busy core.
**Key concepts:** sched_setaffinity, pthread_setaffinity_np, taskset, migration cost, cold-cache penalty, core selection
**Tip:** Pinning alone isn't isolation — the scheduler still *can* place other threads on your pinned core unless you also isolate it. Pin + isolate together.
**Tool anchor:** `taskset -cp <pid>` to inspect/set; `/proc/<pid>/task/*/stat` field 39 shows last-run CPU.
**Drill:** A pinned thread still shows occasional cold-cache spikes. Name two reasons the core isn't actually exclusive and how to confirm each.
**Tags:** lowlat-net, cpu-affinity, taskset, pinning, scheduler

### mlockall and pre-faulting: no page faults on the hot path
A page fault on the hot path costs ~1–10µs and lands squarely in p99. `mlockall(MCL_CURRENT | MCL_FUTURE)` locks all current and future pages of the process (code, data, stack, shared libs, mmaps) resident in RAM so they cannot be reclaimed. Crucially, **locking is needed even with no swap**: clean read-only pages (program text) can still be dropped under memory pressure and re-faulted from disk. Locking is also not enough by itself — you must **pre-fault**: at startup, touch (write to) every buffer and grow+touch the stack with a large dummy array so the pages are actually mapped *before* the time-critical phase. The goal is **zero major/minor faults** once trading starts.
**Key concepts:** mlockall, MCL_CURRENT, MCL_FUTURE, prefault, touch pages, swap-independent, RLIMIT_MEMLOCK
**Tip:** `MCL_FUTURE` makes a later `mmap`/`malloc` *fail* if it would exceed the lock limit — so still do all allocation at startup; don't rely on `MCL_FUTURE` to make hot-path allocation safe. Locks are dropped on `execve` and not inherited across `fork`.
**Tool anchor:** `/proc/<pid>/status` `VmLck`; `perf stat -e minor-faults,major-faults -p <pid>` should read ~0 in steady state.
**Drill:** You call `mlockall` but p99 still has 4µs spikes correlated with first-touch of a buffer. What did you forget, and what's the startup fix?
**Tags:** lowlat-net, mlockall, page-faults, prefault, zero-alloc

## intermediate

### isolcpus / nohz_full / rcu_nocbs: true CPU isolation
`isolcpus=` alone only removes cores from the scheduler's load-balancing domain — the **timer tick and RCU callbacks still fire** on them, polluting L1i and adding context-switch overhead. Full isolation is three knobs together: `isolcpus=` (no general scheduling there), `nohz_full=` (adaptive/"tickless" — drop the periodic timer tick when exactly one task is runnable on the core), and `rcu_nocbs=` (offload RCU callbacks to housekeeping cores). A typical boot line: `isolcpus=4-7 nohz_full=4-7 rcu_nocbs=4-7`. Caveats: `nohz_full` only silences the tick if a *single* task runs on the core (a second runnable thread re-enables the tick); the tick can't be eliminated 100% (expect a ~1 Hz residual); and `nohz_full` is incompatible with a varying `intel_pstate` — fix the frequency.
**Key concepts:** isolcpus, nohz_full (tickless), rcu_nocbs, housekeeping cores, single-task rule, residual tick, intel_pstate conflict
**Tip:** On kernel 6.6+ the syntax shifted to `isolcpus=managed_irq,domain,<list>`. `rcu_nocbs` is largely implied by `nohz_full`, but most guides set all three for clarity. Don't isolate CPU 0.
**Tool anchor:** `cat /sys/devices/system/cpu/isolated`; watch `LOC` (local timer interrupts) in `/proc/interrupts` on isolated cores stay nearly frozen.
**Drill:** You set `isolcpus` but the hot core still shows ~1000 timer interrupts/sec. Which two parameters are missing, and what extra condition must hold for the tick to actually stop?
**Tags:** lowlat-net, isolcpus, nohz_full, rcu_nocbs, cpu-isolation

### IRQ affinity: steer interrupts off the hot core
Even on an isolated core, hardware IRQs (and the softirqs/timers/workqueues they spawn) can land there and steal cycles and trash cache. Move all device IRQs — especially the NIC's — to **housekeeping** (non-isolated) cores by writing the CPU mask to `/proc/irq/<n>/smp_affinity` (or `smp_affinity_list`). Disable `irqbalance` (or exclude the isolated set with `IRQBALANCE_BANNED_CPUS`) so it doesn't migrate IRQs back. The canonical feed pattern is **two cores per feed**: one housekeeping core takes the NIC IRQ + softirq, one isolated core runs the pinned processing thread. This keeps the receive interrupt and the receive *processing* from contending.
**Key concepts:** smp_affinity, smp_affinity_list, irqbalance, IRQBALANCE_BANNED_CPUS, housekeeping core, two-core-per-feed
**Tip:** Pinning the NIC IRQ to the *same* core as the processing thread (under `SCHED_FIFO`) can starve the softirq and stall receive — separate them. This is exactly why the two-core pattern exists.
**Tool anchor:** find the NIC IRQs in `/proc/interrupts`, then `echo <mask> > /proc/irq/<n>/smp_affinity`; verify counts only grow on the housekeeping core.
**Drill:** Under `SCHED_FIFO 99`, your handler intermittently stops receiving for milliseconds. The NIC IRQ shares the hot core. Explain the starvation and give the fix.
**Tags:** lowlat-net, irq-affinity, smp_affinity, irqbalance, two-core-pattern

### SCHED_FIFO and the softirq-starvation hazard
`SCHED_FIFO` is a POSIX real-time scheduling policy: a `SCHED_FIFO` thread runs until it blocks or yields and is never preempted by normal (`SCHED_OTHER`) tasks, eliminating scheduler-induced jitter. Set it with `chrt -f 99 <cmd>` or `pthread_setschedparam`. The hazard: at high priority a busy-looping `SCHED_FIFO` thread can **starve kernel softirqs** (including the NIC's RX softirq) and per-core kernel threads on the same core, which can stall receive or trip the kernel's RT-throttling safety valve (`sched_rt_runtime_us`). The safe pattern is the two-core split — `SCHED_FIFO` processing on the isolated core, NIC softirq on a separate housekeeping core — so the RT thread can spin without choking the receive softirq.
**Key concepts:** SCHED_FIFO, priority 99, non-preemption, softirq starvation, RT throttling, chrt, sched_rt_runtime_us
**Tip:** Leave a little headroom: `SCHED_FIFO 99` for your thread but keep the NIC softirq on a different core, or you re-create the starvation you're trying to avoid. Consider `priority < 99` so kernel RT threads (e.g. watchdog) can still run.
**Tool anchor:** `chrt -p <pid>` shows policy/priority; `sysctl kernel.sched_rt_runtime_us` is the throttle (-1 disables, risky).
**Drill:** Why does `SCHED_FIFO 99` on the *same* core as the NIC softirq make latency worse, not better? Tie it to the two-core pattern.
**Tags:** lowlat-net, sched-fifo, real-time, softirq-starvation, chrt

### RSS, single-flow multicast, and flow steering
Receive-Side Scaling (RSS) spreads incoming packets across multiple NIC RX queues (and thus cores) by hashing header fields (typically a 4-tuple Toeplitz hash) into an indirection table. The catch for market data: **RSS cannot split a single flow** — every packet with the same hashed tuple lands on one queue/one core. A CME multicast group is effectively one src/dst tuple, so RSS pins it to a single core, which becomes the bottleneck during a microburst. Levers: change `ethtool -N <dev> rx-flow-hash udp4 sd` to hash on IPs only (more entropy across groups), use **n-tuple flow steering** (`ethtool -U <dev> flow-type udp4 ... action <queue>`) to place specific groups on specific queues/cores, or run multiple receivers with `SO_REUSEPORT` (see `/feed-handler`). Each of those parallel paths then has its own book-contention question.
**Key concepts:** RSS, RX queues, Toeplitz hash, indirection table, single-flow limit, rx-flow-hash, n-tuple steering, SO_REUSEPORT
**Tip:** RSS is NUMA-blind: a queue may be serviced on a core far from the consuming thread. Steer the queue's IRQ to the NIC-local node and pin the consumer there too.
**Tool anchor:** `ethtool -x <dev>` (indirection table), `ethtool -n <dev> rx-flow-hash udp4`, `ethtool -L <dev> combined N` (queue count).
**Drill:** One CME channel's multicast saturates a single core during the open. Give three distinct mechanisms to spread it and the new correctness/contention problem each introduces.
**Tags:** lowlat-net, rss, multicast, flow-steering, rx-flow-hash

### Hugepages: cutting TLB misses on the hot data
With 4 KiB pages, a 2 MiB working set needs 512 page-table entries and the dTLB (often ~64 entries on Intel) can't cover it — each TLB miss triggers a page-table walk (~7–10ns). A 2 MiB hugepage covers the same region with **one** TLB entry and no walks on the hot path. Two routes: **explicit HugeTLB** via `mmap(..., MAP_HUGETLB | MAP_HUGE_2MB, ...)` (or hugetlbfs), which reserves non-swappable pages from a pre-allocated pool — deterministic, the right choice for the order-book arrays and the shm IPC ring; and **Transparent Hugepages (THP)** via `madvise(MADV_HUGEPAGE)`, which is best-effort and the kernel may decline or later split/merge. For the book data and shm ring, prefer explicit hugepages for predictability.
**Key concepts:** TLB reach, page-table walk, MAP_HUGETLB, MAP_HUGE_2MB, hugetlbfs, THP, MADV_HUGEPAGE, non-swappable reserve
**Tip:** Allocate explicit hugepages **early** (near boot) before memory fragments; 1 GiB pages must be reserved on the boot line (`hugepagesz=1G`). THP can *add* jitter via background split/merge and TLB shootdowns — many low-latency shops disable system-wide THP and use explicit pages.
**Tool anchor:** `/proc/meminfo` (`HugePages_*`, `Hugepagesize`), `perf stat -e dTLB-load-misses -p <pid>` before/after.
**Drill:** Your 50-instrument book (~3 MiB) shows high `dTLB-load-misses` under burst. Compare MAP_HUGETLB vs MADV_HUGEPAGE for fixing it, and say why THP might *not* fix it reliably.
**Tags:** lowlat-net, hugepages, tlb, map_hugetlb, thp

### NUMA: keep memory, NIC, and thread on one node
On a multi-socket box each CPU has local DRAM; reaching the other socket's DRAM crosses the interconnect and costs roughly **~2x** local latency. For a feed handler that means three things must live on the same NUMA node: the **NIC** (its PCIe slot is attached to one socket), the **receive/processing thread**, and the **memory** it touches (socket buffers, book arrays, shm ring). Pin all three with `numactl --cpunodebind=N --membind=N ./handler` (or per-thread affinity + first-touch allocation on the right node). The classic trap is the shm IPC ring: Linux uses **first-touch** allocation, so whichever process faults the pages decides their node — a consumer on the other socket then pays the remote penalty on every read.
**Key concepts:** NUMA node, local vs remote DRAM (~2x), NIC PCIe locality, numactl, cpunodebind/membind, first-touch, cross-node shm penalty
**Tip:** Read the NIC's node from `/sys/class/net/<dev>/device/numa_node` and place everything there. For shm, fault the pages from a thread pinned to the intended node so first-touch lands them locally.
**Tool anchor:** `numactl --hardware` (topology/distances), `numastat -p <pid>` (per-node allocation), `perf stat -e node-load-misses` (remote DRAM hits).
**Drill:** Producer on node 0, consumer on node 1, shm ring faulted by the producer. Where do the pages live, who pays, and how much per read? Two fixes.
**Tags:** lowlat-net, numa, numactl, first-touch, locality

### Hardware timestamping and SO_TIMESTAMPING
To measure *true* wire latency you need a timestamp taken by the NIC at the moment the packet hits the wire/PHY, not when your code finally reads it. `SO_TIMESTAMPING` with `SOF_TIMESTAMPING_RX_HARDWARE | SOF_TIMESTAMPING_RAW_HARDWARE` enables NIC hardware RX timestamps, delivered as ancillary data (`recvmsg` control message, `cmsg_level=SOL_SOCKET`, `cmsg_type=SCM_TIMESTAMPING`); the hardware stamp arrives in `ts[2]` of the `scm_timestamping` struct (`ts[0]` software, `ts[1]` deprecated). Use the `_NEW` variant (`scm_timestamping64`) for y2038 safety. Check support with `ethtool -T <dev>`, which reports the hardware tx/rx capabilities and the PTP Hardware Clock (PHC) index that maps to `/dev/ptp*`. RX hardware stamps require an enabling flag to be set or the kernel won't generate them.
**Key concepts:** SO_TIMESTAMPING, RX_HARDWARE, RAW_HARDWARE, SCM_TIMESTAMPING, ts[2], scm_timestamping64, ethtool -T, PHC index
**Tip:** The NIC stamp lets you separate *network* latency (wire→NIC) from *host* latency (NIC→your code) — invaluable for proving a tail is yours vs the network's. Combine with per-stage `CLOCK_MONOTONIC_RAW` stamps from `/measurement`.
**Tool anchor:** `ethtool -T <dev>` to confirm `hardware-receive`; read `ts[2]` from the `SCM_TIMESTAMPING` cmsg in `recvmsg`.
**Drill:** Your software receive timestamp says 8µs wire-to-recv but the NIC hardware stamp implies 1µs network + 7µs host. What does that tell you, and where do you look next?
**Tags:** lowlat-net, so-timestamping, hardware-timestamp, scm-timestamping, measurement

### PTP: ptp4l, phc2sys, and a disciplined clock
A NIC hardware timestamp is only as useful as the clock behind it. **PTP (IEEE 1588)** disciplines the NIC's PTP Hardware Clock (PHC) to a grandmaster over the network — far tighter than NTP. `linuxptp` provides two daemons: `ptp4l` synchronizes the **PHC** to the master (run `ptp4l -H -s` for hardware-timestamped slave mode; sub-100ns offsets indicate good sync, logged states `s0`→`s1`→`s2`=locked), and `phc2sys` synchronizes the **system clock** to the PHC because they are independent clocks (`phc2sys -s <dev> -w` waits for `ptp4l` and pulls the TAI↔UTC offset). PTP/TAI runs on the atomic timescale; the system clock is UTC, currently a 37-second offset (the `-w`/`-a` options handle it). For cross-host latency comparison, every box must be PTP-disciplined to the same source.
**Key concepts:** PTP/IEEE 1588, grandmaster, PHC, ptp4l (-H/-s), phc2sys (-s/-w/-a), s0/s1/s2 states, TAI vs UTC offset
**Tip:** Only one `ptp4l`/`phc2sys` instance per interface — multiple writers fight over the clock. Power-management (C-states/ASPM) can cost 100µs+ to wake the NIC/PCIe and wreck PHC accuracy; pin C-states for timing-critical hosts.
**Tool anchor:** `ptp4l -H -s -m` (watch offset → `s2`); `phc2sys -a -r -m`; `pmc` for management queries.
**Drill:** Two hosts show a 50µs cross-host latency you can't explain; both run `ptp4l` reporting `s2`. Name two clock-discipline problems that still produce a phantom skew.
**Tags:** lowlat-net, ptp, linuxptp, ptp4l, phc2sys

### Kernel-bypass awareness: Onload, ef_vi, TCPDirect, DPDK
The standard kernel stack struggles past ~1M pps and adds syscall/copy/interrupt overhead; **kernel bypass** moves the network datapath into user space. The Solarflare/AMD family, ranked roughly by latency and integration effort: **Onload** — userspace TCP/UDP/multicast stack injected via `LD_PRELOAD`, *no application changes*, ~1µs; **TCPDirect** — zero-copy BSD-like API, lower latency than Onload, moderate code changes; **ef_vi** — lowest-level raw-frame API, direct datapath, lowest latency (hardware path into the hundreds-of-ns), most code (Onload itself is built on it). **DPDK** is the vendor-neutral industry standard (~2–3µs typical), poll-mode drivers, but it *takes exclusive control of the NIC* (the interface disappears from normal Linux tools). The decision is a tradeoff of latency vs integration cost vs operational complexity — for a feed handler, Onload often wins because it needs no code changes.
**Key concepts:** kernel bypass, Onload (LD_PRELOAD, ~1µs), TCPDirect, ef_vi (raw, lowest), DPDK (~2–3µs, exclusive NIC), poll-mode driver
**Tip:** Bypass removes interrupt-to-wakeup but **burns a core busy-polling** and changes your operational picture (NIC no longer visible to standard tools under DPDK; Onload still cooperates with the kernel). Profile the *whole* path first — if 80% of latency is the book update, bypass is premature.
**Tool anchor:** `onload --version`; `onload ./feed_handler` to preload; for DPDK, `dpdk-devbind.py --status` to see bound NICs.
**Drill:** You can switch from kernel UDP to Onload for ~6µs → ~1µs on receive. Profiling shows receive is 20% of the path. Is it worth it? What would change your answer?
**Tags:** lowlat-net, kernel-bypass, onload, ef_vi, dpdk

### NIC ring buffer sizing and the loss/latency tradeoff
The NIC RX **ring** (descriptor count, set via `ethtool -G <dev> rx N`) is the hardware-side buffer between the NIC and the kernel/softirq. Too small and a microburst overruns the ring → drops *before* the packet ever reaches your socket buffer (counted as NIC rx_dropped/rx_missed, not `SO_RCVBUF` errors). Too large and a deep backlog can add latency and lets stale data queue during a stall. For market data you size the ring (and `SO_RCVBUF`, see `/feed-handler`) for the *burst*, not the average — the opening or a news spike can hit 500k–1M msgs/sec. Ring overruns and socket-buffer overruns are *different* drop sites with *different* counters; diagnosing loss means checking both.
**Key concepts:** RX ring, descriptor count, ethtool -G, rx_dropped/rx_missed, ring vs socket-buffer drops, burst sizing
**Tip:** Distinguish the two loss layers: NIC ring overrun shows in `ethtool -S` (`rx_missed_errors`/`rx_no_buffer`); socket overrun shows in `netstat -su` `RcvbufErrors`. Raising `SO_RCVBUF` won't fix a ring overrun.
**Tool anchor:** `ethtool -g <dev>` (current/max ring), `ethtool -G <dev> rx 4096`, `ethtool -S <dev> | grep -i drop`.
**Drill:** Drops appear only at the open. `RcvbufErrors` is zero but `ethtool -S` `rx_missed_errors` is climbing. Which buffer overflowed, and what's the fix?
**Tags:** lowlat-net, nic-ring, ethtool-g, packet-loss, burst-sizing

## advanced

### Offloads (GRO/LRO/checksum) — keep them OFF for low latency
NIC offloads improve *throughput* but hurt *latency* and can break market-data correctness. **GRO/LRO** (Generic/Large Receive Offload) coalesce multiple received segments into one large buffer before delivery — great for bulk TCP, but it *adds latency* (waits to merge) and is wrong for UDP multicast where each datagram is an independent MDP packet you want delivered immediately. Disable with `ethtool -K <dev> gro off lro off`. Checksum/segmentation offloads (`rx/tx-checksumming`, `gso`, `tso`) matter less for small UDP but are commonly disabled in low-latency setups to keep the path lean and predictable. The general rule on a latency NIC: turn off everything that batches or defers, accept the higher CPU cost.
**Key concepts:** GRO, LRO, checksum offload, GSO/TSO, batching adds latency, ethtool -K, UDP correctness
**Tip:** LRO is lossy/irreversible (it can't reconstruct original frame boundaries) — never leave it on for a multicast feed. GRO is reversible but still adds merge latency; off for the hot path.
**Tool anchor:** `ethtool -k <dev>` (list features), `ethtool -K <dev> gro off lro off`.
**Drill:** With GRO on, your per-message receive timestamps cluster oddly (several messages share a near-identical recv time). Explain what GRO did and why it corrupts per-packet latency measurement.
**Tags:** lowlat-net, offloads, gro, lro, ethtool-k

### Busy-polling at the kernel boundary (SO_BUSY_POLL / NAPI)
Between full kernel-bypass and interrupt-driven receive sits kernel **busy-polling**: `SO_BUSY_POLL` (per-socket) or the global `net.core.busy_poll`/`busy_read` make the socket-read path spin polling the NIC driver's RX queue for a few µs instead of sleeping and waiting for the IRQ→softirq→wakeup chain — removing the interrupt-to-wakeup latency (~single-digit µs win) at the cost of a fully-burned core. Newer kernels expose this via the NAPI busy-poll interface (and `epoll`-based busy-poll with `EPIOCSPARAMS`). It's the cheapest "bypass-like" latency win because it needs no special NIC or userspace stack — but like real bypass it spends a core and is a *jitter reduction* tool (removes the scheduler wakeup variance) as much as a latency tool. See `/feed-handler` for how it interacts with `recvmmsg`/`epoll` receive strategies.
**Key concepts:** SO_BUSY_POLL, net.core.busy_poll, NAPI busy-poll, interrupt-to-wakeup elimination, core burn, epoll busy-poll
**Tip:** Busy-poll plus a pinned isolated core plus IRQs steered away gives most of the bypass latency benefit with zero application rewrite — try it before reaching for ef_vi/DPDK.
**Tool anchor:** `sysctl net.core.busy_poll net.core.busy_read`; set per-socket `setsockopt(SO_BUSY_POLL, ...)`.
**Drill:** SO_BUSY_POLL cuts p99 wakeup jitter but raises one core to 100%. Explain the mechanism it removed and why the core is now pegged even when idle.
**Tags:** lowlat-net, so-busy-poll, napi, busy-polling, jitter

### Hyperthreading, C-states, and frequency for predictability
Three CPU-level knobs decide whether the hot core is *predictable*. (1) **Hyperthreading**: an HT sibling shares L1/L2/DSB/execution ports with your hot thread; a noisy sibling adds ~15–30% tail jitter — disable the sibling of the pinned core (`echo 0 > /sys/devices/system/cpu/cpuN/online`) to give your thread the full ROB and private L1d. (2) **C-states**: deep idle states save power but cost µs to *exit* — a core that briefly idles between packets wakes slowly; cap with `intel_idle.max_cstate=1`/`processor.max_cstate=1` or hold a core busy (busy-poll keeps it in C0). (3) **Frequency**: pin the governor to `performance` and disable turbo variability so cycle timing is stable; `schedutil` adds 10–50µs frequency-transition latency that pollutes both production and benchmarks. These are deep `/perf` topics — applied here to the receive core.
**Key concepts:** HT sibling sharing, C-state exit latency, max_cstate, governor=performance, turbo variability, frequency transition jitter
**Tip:** Busy-polling doubles as a C-state defense — a spinning core never enters a deep C-state, so the first packet after an idle gap isn't penalized by a slow wake.
**Tool anchor:** `cpupower frequency-set -g performance`; `turbostat` (C-state residency, frequency); `lscpu -e` (sibling map).
**Drill:** The first packet after a quiet period is consistently 9µs slower than mid-burst packets. Two CPU-level causes, and the one tuning change that fixes both.
**Tags:** lowlat-net, hyperthreading, c-states, frequency, perf-crosslink

### Where does my latency live? — network vs host decomposition
The decisive measurement is splitting wire-to-application latency into **network** (wire→NIC) and **host** (NIC→your code). Take the NIC hardware RX timestamp (`SCM_TIMESTAMPING` `ts[2]`) at one end and a `CLOCK_MONOTONIC_RAW` stamp the instant your thread returns from `recv` at the other; their difference is the *host* receive cost (softirq + wakeup + copy or busy-poll spin). A growing host fraction points at jitter sources covered in this bank (interrupts on the hot core, page faults, C-state wakeups, NUMA-remote socket buffers); a growing network fraction points off-box (switch, path, exchange). Without this split you can't tell whether to tune the host or escalate to the network team — and you risk optimizing receive when the real cost is elsewhere (`/measurement`).
**Key concepts:** network vs host split, NIC hw stamp vs sw stamp, host receive cost, attribution, escalation, CLOCK_MONOTONIC_RAW
**Tip:** Add a *third* anchor — switch/aggregation timestamps if available — to localize a network tail to a specific hop. The host fraction is the only part *you* own.
**Tool anchor:** `ts[2]` (NIC) vs `clock_gettime(CLOCK_MONOTONIC_RAW)` (app) per packet, both into HdrHistogram (`/measurement`).
**Drill:** p99 wire-to-book jumped 10µs overnight. Your NIC-stamp-to-recv (host) split is unchanged but wire-to-NIC grew. Where is the problem and who do you call?
**Tags:** lowlat-net, latency-decomposition, hardware-timestamp, attribution, measurement

### A tuned-host checklist as a system, not a list
The knobs in this bank compound and can *fight* each other — they are one system. A coherent low-latency receive box: isolate cores (`isolcpus`+`nohz_full`+`rcu_nocbs`), pin the processing thread there (`SCHED_FIFO`, no HT sibling), steer NIC IRQs to a housekeeping core on the **NIC-local NUMA node**, set fixed minimal coalescing (`rx-usecs 0 rx-frames 1`, adaptive off) and disable GRO/LRO, size the RX ring + `SO_RCVBUF` for the burst, `mlockall`+prefault at startup, back hot data with explicit hugepages, `numactl`-bind memory+CPU+NIC to one node, pin governor `performance` + cap C-states, and discipline the clock with PTP. The order matters because a missing piece masks the others — e.g. perfect coalescing tuning is invisible if an un-steered IRQ still lands on the hot core. Validate the *whole* stack by measurement, not by assuming each knob worked.
**Key concepts:** systemic tuning, interaction effects, ordering, NIC-local node, validate-don't-assume, full checklist
**Tip:** Re-read each `ethtool`/sysctl value after setting it — drivers silently ignore unsupported options, and a "set" knob may not have taken. Capture the whole config as code so the box is reproducible.
**Tool anchor:** a startup script that sets every knob then *reads it back* and asserts; per-core `perf stat`/`turbostat`/`/proc/interrupts` snapshot before market open.
**Drill:** You applied the full checklist but p99 didn't improve. Give a disciplined order of investigation (which knob to verify first) and why guessing is the wrong approach.
**Tags:** lowlat-net, checklist, systemic-tuning, validation, methodology
