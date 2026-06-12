# Concurrency & Synchronization Topic Bank
Updated: 2026-05-28

## beginner

### x86-TSO memory model
x86 processors implement Total Store Order, the strongest memory model of any mainstream architecture. Stores are buffered in a per-core store buffer and can be reordered after later loads, but loads are never reordered with other loads and stores are never reordered with other stores. This single relaxation (store-load reorder) is the only deviation from sequential consistency, which is why most lock-free code that works on x86 breaks on ARM.
**Key concepts:** Total Store Order, store buffer, store-load reorder, sequential consistency
**Tip:** The store buffer is the only source of relaxation on x86: a core can read its own store before it becomes globally visible, which means a classic Dekker/Peterson lock algorithm fails without an mfence between the store and the subsequent load.
**Tool anchor:** `perf stat -e machine_clears.memory_ordering -p $(pgrep md_feed) -- sleep 10` to detect memory ordering machine clears caused by store buffer speculation failures
**Drill:** Two threads each set their own flag and read the other's flag (Dekker pattern) without any fence. On x86-TSO, both threads can see the other's flag as 0. Explain why using the store buffer model, then show which single instruction insertion on each thread fixes it.
**Tags:** x86-TSO, memory-model, store-buffer, sequential-consistency

### Atomics and the LOCK prefix
`std::atomic` operations on x86 compile to instructions with a LOCK prefix (e.g., `lock cmpxchg`, `lock add`, `lock xadd`) which locks the cache line, drains the store buffer, and provides full sequential consistency. An uncontended locked instruction costs around 20 cycles on modern Intel, but under contention the cost rises to 100+ cycles as the cache line bounces between cores via the coherence protocol.
**Key concepts:** LOCK prefix, cache-line locking, store-buffer drain, contended vs uncontended cost
**Tip:** On x86, `lock add` (used by `fetch_add`) is faster than `lock cmpxchg` (used by `compare_exchange`) because it always succeeds in one round trip; CAS can fail and retry, doubling the coherence traffic.
**Tool anchor:** `perf stat -e mem_inst_retired.lock_loads -p $(pgrep md_feed) -- sleep 5` to count locked memory operations; high counts indicate atomic contention paths
**Drill:** Disassemble a `std::atomic<int>::fetch_add(1, std::memory_order_relaxed)` on x86-64. Explain why the compiler still emits `lock xadd` even though you requested relaxed ordering, and what would change on ARM.
**Tags:** atomics, LOCK-prefix, cmpxchg, fetch-add, x86-codegen

### std::memory_order on x86
On x86-TSO, `memory_order_acquire` loads and `memory_order_release` stores compile to plain `mov` instructions with no fences, because x86 hardware already guarantees load-load and store-store ordering. Only `memory_order_seq_cst` stores require a barrier, compiled as either `mov` + `mfence` or `xchg` (which implies a lock). This means switching from `seq_cst` to `acq/rel` on x86 eliminates a costly fence on every store.
**Key concepts:** acquire, release, seq_cst, mfence, xchg, free ordering on x86
**Tip:** On x86, changing a `seq_cst` store to `release` can save 20-40 cycles per store by eliminating the `mfence`/`xchg`; but the same change on ARM changes nothing because ARM already emits barrier instructions for `release`.
**Tool anchor:** `objdump -d -M intel ./md_handler | grep -A2 -B2 'mfence\|lock\|xchg'` to find all barrier and locked instructions in your binary
**Drill:** You have a seq_cst flag store followed by a seq_cst flag load in a hot loop, compiled on x86. Show the generated assembly, identify the expensive instruction, and determine if switching to release/acquire changes correctness for a single-producer/single-consumer scenario.
**Tags:** memory-order, acquire-release, seq-cst, mfence, x86-ordering

### Mutex vs spinlock: when to use which
A mutex (`pthread_mutex`, `std::mutex`) puts the thread to sleep on contention, saving CPU but incurring a ~1-10us wakeup latency through the kernel. A spinlock keeps the thread spinning, wasting CPU cycles but responding within nanoseconds when the lock is released. The critical section length, contention level, and whether threads can be preempted determine the right choice.
**Key concepts:** sleep vs spin, critical section length, contention level, preemption risk, priority inversion
**Tip:** If your critical section is shorter than the cost of two context switches (~10us), a spinlock wins; but if a spinlocking thread gets preempted while holding the lock, all other spinners burn CPU for the entire scheduling quantum (~4ms).
**Tool anchor:** `bpftrace -e 'kprobe:mutex_lock { @lock_contention[ustack(5)] = count(); }' -p $(pgrep md_feed)` to identify which mutexes are contended and from where
**Drill:** Your market data handler has a mutex protecting a 50-nanosecond stats counter update. Under load, `perf` shows 15% of CPU time in `__pthread_mutex_lock`. Propose a fix, explain why a spinlock is not the best answer here either, and suggest the optimal synchronization primitive.
**Tags:** mutex, spinlock, contention, critical-section, preemption

### Thread creation overhead and thread pools
Creating a thread via `pthread_create` costs 10-50us (stack allocation, kernel data structures, TLB setup), making it unacceptable for per-message or per-connection threading in a high-frequency system. Thread pools amortize this cost by reusing a fixed set of threads that pull work from a queue. Work-stealing pools add per-thread deques where idle threads steal from busy threads' tails, improving cache locality and load balance.
**Key concepts:** pthread_create cost, stack allocation, thread pool, work queue, work-stealing
**Tip:** A thread pool sized to the number of hardware threads minimizes contention; more threads than cores means context switches, fewer means idle cores. Pin pool threads to cores for cache stability in latency-sensitive paths.
**Tool anchor:** `bpftrace -e 'kprobe:kernel_clone { @thread_creates[ustack(5)] = count(); }'` to detect unexpected thread creation in hot paths (the symbol was `_do_fork` before kernel 5.10)
**Drill:** Your CME feed handler spawns a new thread for each multicast channel reconnection, and during a market-wide reconnect event you see 200 threads created in 500ms. Measure the overhead with `perf stat`, then redesign using a thread pool and explain the expected latency improvement.
**Tags:** thread-pool, pthread-create, work-stealing, thread-reuse, overhead

### volatile is not atomic
The `volatile` keyword in C++ prevents only compiler optimizations (reordering, elision, caching in registers); it provides no atomicity, no hardware memory ordering, and no protection against data races. Using `volatile` for inter-thread communication is undefined behavior. It exists for memory-mapped I/O and signal handlers, not for concurrency.
**Key concepts:** compiler optimization barrier only, no atomicity, no ordering, MMIO use case, UB
**Tip:** `volatile int flag` compiled on x86 looks identical to a plain `int` in assembly; it only prevents the compiler from optimizing away repeated reads. Two threads writing to it can tear on non-naturally-aligned accesses and is UB regardless of alignment.
**Tool anchor:** `objdump -d -M intel ./test | grep -A5 'volatile_flag'` to compare codegen of volatile vs atomic; note the absence of LOCK prefix or fences for volatile
**Drill:** A colleague wrote `volatile bool running = true;` as a shutdown flag read by a hot loop and written by a signal handler thread. Explain why this is UB under the C++ memory model, show the correct fix using `std::atomic`, and identify a scenario where the volatile version would actually fail observably.
**Tags:** volatile, UB, atomic, compiler-barrier, memory-mapped-IO

### Data races and undefined behavior
The C++11 memory model defines a data race as two threads accessing the same memory location where at least one is a write and there is no happens-before relationship between them. Any data race is undefined behavior, which means the compiler can assume it never happens and optimize accordingly (hoisting loads out of loops, eliminating checks, merging stores). ThreadSanitizer (TSan) instruments memory accesses at compile time to detect data races dynamically.
**Key concepts:** data race, happens-before, undefined behavior, TSan, compiler exploitation of UB
**Tip:** TSan adds 5-15x slowdown and 5-10x memory overhead, so run it in CI on representative tests, not production; it catches races that only manifest under specific interleaving and would take months to reproduce manually.
**Tool anchor:** `clang++ -fsanitize=thread -g -O1 -o md_handler_tsan md_handler.cpp && ./md_handler_tsan` to build with TSan; use -O1 not -O0 for realistic optimization behavior
**Drill:** TSan reports a data race between your stats-printing thread reading `msg_count` and your decode thread incrementing it. Both are `uint64_t`. Explain why this is UB even on x86 where 64-bit aligned loads/stores are atomic in hardware, and show the minimal fix.
**Tags:** data-race, UB, TSan, happens-before, C++-memory-model

### Cache coherence basics: why sharing is expensive
Modern CPUs maintain coherent caches through a protocol that tracks ownership of each cache line. Reading shared data (S state) is cheap because multiple caches can hold copies simultaneously. Writing to shared data requires an exclusive copy (M state), triggering a Read-For-Ownership (RFO) message that invalidates all other copies. This RFO round-trip costs 40-100ns depending on whether the line is in another core's L1/L2 (same socket) or a remote socket's cache (cross-NUMA).
**Key concepts:** cache line, shared vs exclusive, RFO, invalidation, cross-core latency
**Tip:** Read-sharing a cache line across 16 cores is essentially free after the initial miss; write-sharing the same line across just 2 cores can cost 40ns per write due to the ping-pong invalidation pattern.
**Tool anchor:** `perf stat -e offcore_response.demand_rfo.l3_miss.snoop_hitm -p $(pgrep md_feed) -- sleep 5` to measure cross-core cache line transfers caused by write sharing
**Drill:** Two cores each increment their own counter in a shared `struct Stats { uint64_t core0_count; uint64_t core1_count; };`. Both counters fit in one 64-byte cache line. Explain the coherence traffic pattern, estimate the throughput degradation, and propose two fixes.
**Tags:** cache-coherence, RFO, invalidation, sharing, cross-core-latency

## intermediate

### MESI/MOESI cache coherence protocol
The MESI protocol tracks each cache line in one of four states: Modified (dirty, exclusive), Exclusive (clean, exclusive), Shared (clean, multiple holders), Invalid. AMD's MOESI adds Owned (dirty, shared) to allow dirty-to-dirty transfers without writing back to memory first. Understanding state transitions reveals why write-sharing is expensive (S->I on remote, I->M on writer requires RFO) and why read-sharing scales (one E->S transition, then free reads).
**Key concepts:** Modified, Exclusive, Shared, Invalid, Owned, state transitions, RFO
**Tip:** On Intel (MESI without O), a dirty cache line requested by another core must be written back to L3 before sharing; on AMD (MOESI), the dirty line can be forwarded directly, saving ~20ns for producer-consumer patterns.
**Tool anchor:** `perf stat -e l2_rqsts.rfo_hit,l2_rqsts.rfo_miss -p $(pgrep md_feed) -- sleep 10` to measure Read-For-Ownership requests hitting or missing L2
**Drill:** Thread A writes to address X (line in M state in core 0's L1). Thread B on core 4 reads address X. Trace the exact MESI state transitions on both cores, identify each bus message, and calculate the approximate latency assuming a 40ns L3 snoop.
**Tags:** MESI, MOESI, cache-coherence, state-transitions, RFO

### False sharing detection and elimination
False sharing occurs when logically independent variables occupy the same cache line and are written by different cores, causing unnecessary coherence traffic indistinguishable from true sharing at the hardware level. It can degrade throughput by 10-100x and is invisible without cache-line-level analysis. `perf c2c` detects it by recording data addresses and identifying cache lines with high HITM (Hit In Modified) counts from multiple cores.
**Key concepts:** cache-line alignment, padding, alignas(64), perf c2c, HITM events
**Tip:** `alignas(std::hardware_destructive_interference_size)` is the portable C++17 way to pad against false sharing, but many compilers define it as 64; verify with `static_assert` because some ARM platforms use 128-byte lines.
**Tool anchor:** `perf c2c record -p $(pgrep md_feed) -- sleep 10 && perf c2c report --stdio -d lcl --call-graph=no` to identify hot cache lines with cross-core write contention
**Drill:** Your per-channel statistics struct has `uint64_t packets_received` and `uint64_t bytes_received` updated by channel thread 1, and `uint64_t packets_decoded` and `uint64_t bytes_decoded` updated by decoder thread 2, all in a single struct. perf c2c shows 50K HITM events on this cache line. Fix the layout and predict the performance improvement.
**Tags:** false-sharing, perf-c2c, alignas, HITM, cache-line-padding

### Lock-free SPSC queue design
A single-producer single-consumer (SPSC) queue is the simplest practical lock-free data structure: a fixed-size ring buffer where the producer writes to `tail` and the consumer reads from `head`, with each index owned exclusively by one thread. The key insight is that only acquire/release ordering is needed (no seq_cst, no CAS), and separating `head` and `tail` onto different cache lines eliminates false sharing.
**Key concepts:** ring buffer, power-of-two masking, cache-line separation, acquire/release ordering
**Tip:** Keep the queue size a power of two so you can use `index & (size - 1)` instead of modulo; the bitwise AND is a single cycle while modulo is 20-40 cycles, and in a tight poll loop this matters.
**Tool anchor:** `perf stat -e l1d_pend_miss.pending_cycles,mem_inst_retired.lock_loads -- ./spsc_bench` to verify the SPSC queue generates zero locked instructions and measure memory stall cycles
**Drill:** You need a queue between your multicast receive thread and your SBE decode thread, handling 10M messages/sec with messages of 64-256 bytes. Design the SPSC queue layout, choose the element size (fixed vs variable), explain your cache line padding strategy, and predict the throughput bottleneck.
**Tags:** SPSC, lock-free, ring-buffer, acquire-release, producer-consumer

### Futex and the Linux locking stack
A futex (Fast Userspace muTEX) is the kernel primitive underlying `pthread_mutex`, `std::mutex`, `std::condition_variable`, and most Linux synchronization. The fast path is entirely in userspace: an atomic CAS on a 32-bit integer to acquire the lock. Only on contention does the thread make a `futex(FUTEX_WAIT)` syscall to sleep in the kernel. This two-level design gives uncontended locking at the cost of a single atomic operation (~20 cycles) while still providing proper OS-level sleeping under contention.
**Key concepts:** futex word, userspace fast path, kernel slow path, FUTEX_WAIT/WAKE, syscall cost
**Tip:** An uncontended `std::mutex::lock()` on Linux never enters the kernel; it is a single `lock cmpxchg` in userspace. The syscall overhead (~200-400ns) only hits when another thread already holds the lock.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_futex /comm == "md_feed"/ { @op = lhist(args->op & 0xF, 0, 15, 1); @[ustack(5)] = count(); }'` to track which futex operations your process makes and from where
**Drill:** Your mutex-protected order book shows 0.1% of lock acquisitions taking >100us. Use bpftrace to histogram the time spent in the futex syscall, determine what percentage of acquisitions actually enter the kernel, and explain the bimodal latency distribution.
**Tags:** futex, mutex-internals, userspace-fast-path, kernel-slow-path, contention

### Reader-writer locks and scalability
Reader-writer locks (`pthread_rwlock`, `std::shared_mutex`) allow multiple concurrent readers or one exclusive writer. In theory they scale reads perfectly, but in practice the lock's internal counter is a shared cache line that every `rdlock()` writes to, creating coherence traffic that limits read scalability beyond ~8-16 cores. SeqLock is an alternative for read-dominated workloads: readers never acquire the lock, they just read a sequence counter before and after, retrying if it changed.
**Key concepts:** shared_mutex, read scalability limit, writer starvation, SeqLock, read-retry pattern
**Tip:** `std::shared_mutex` scales reads only until the cache-line bouncing of its internal reader count exceeds the cost of just using a regular mutex; benchmark before assuming rwlock helps.
**Tool anchor:** `perf c2c record -- ./rwlock_bench -t 16 && perf c2c report --stdio` to observe the rwlock's internal counter as a false-sharing hot spot under read contention
**Drill:** Your order book is read by 8 strategy threads and written by 1 feed thread. You switch from `std::mutex` to `std::shared_mutex` and see no improvement. Use `perf c2c` output to diagnose why, then design a SeqLock-based alternative and explain when readers must retry.
**Tags:** rwlock, shared-mutex, SeqLock, read-scalability, writer-starvation

### Condition variables and spurious wakeups
`std::condition_variable` (backed by `pthread_cond`) allows a thread to sleep until another thread signals a state change. The POSIX specification permits spurious wakeups (returning from `wait()` without a signal), mandating a while-loop predicate check. The thundering herd problem occurs when `notify_all()` wakes N threads but only one can proceed, causing N-1 unnecessary context switches.
**Key concepts:** wait-loop predicate, spurious wakeup, notify_one vs notify_all, thundering herd, lost wakeup
**Tip:** A lost wakeup (signal before wait) is a deadlock bug, not just a performance issue; always hold the mutex when modifying the predicate and signaling, and always check the predicate before waiting.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_futex /comm == "md_feed" && (args->op & 0xF) == 0/ { @wait_stacks[ustack(5)] = count(); }'` to trace all futex wait calls (condvar waits) and their call sites
**Drill:** Your market data pipeline has a consumer thread doing `cv.wait(lock, [&]{ return !queue.empty(); })`. Occasionally the consumer appears stuck even though the producer is pushing data. Identify three possible causes (spurious wakeup handling, lost wakeup, lock ordering) and instrument with bpftrace to distinguish them.
**Tags:** condition-variable, spurious-wakeup, thundering-herd, lost-wakeup, notify

### Thread-local storage (TLS) performance
Thread-local variables (`thread_local` / `__thread`) give each thread its own copy, eliminating synchronization entirely. On x86-64 Linux, TLS uses the `fs` segment register for direct access at ~1 cycle overhead for initial-exec model (statically linked) or ~10-20 cycles for general-dynamic model (dynamically loaded). The access model depends on whether the library is loaded at startup or via `dlopen`.
**Key concepts:** thread_local, __thread, initial-exec, general-dynamic, fs segment register, dlopen
**Tip:** Neither `__thread` nor `thread_local` selects the access model — the keyword is just a storage-class specifier, and under `-fPIC` both default to general-dynamic. To get the fast initial-exec model for hot-path TLS variables, force it with `-ftls-model=initial-exec` or `__attribute__((tls_model("initial-exec")))` (safe only if the object is not `dlopen`'d).
**Tool anchor:** `objdump -d -M intel ./md_handler | grep -B2 -A2 'fs:'` to identify TLS accesses and verify they use the fast initial-exec model (direct fs-relative load) vs general-dynamic (call to __tls_get_addr)
**Drill:** You move a per-thread message counter from an atomic global to `thread_local uint64_t msg_count`. Throughput improves 5x. But when you load a plugin via `dlopen`, the TLS access in the plugin takes 20 cycles instead of 1. Explain the access model difference and propose a fix.
**Tags:** TLS, thread-local, initial-exec, general-dynamic, fs-segment

### Atomic fetch-and-add vs CAS patterns
`fetch_add` (compiled to `lock xadd` on x86) always succeeds in a single atomic operation, making it scale better under contention than CAS (`lock cmpxchg`), which can fail and retry in a loop. However, `fetch_add` only supports simple arithmetic, while CAS enables arbitrary read-modify-write operations. Under high contention, CAS loops degrade because every retry doubles the coherence traffic.
**Key concepts:** fetch_add, compare_exchange, retry loop, contention scaling, lock xadd vs lock cmpxchg
**Tip:** If your atomic operation can be expressed as addition, subtraction, or bitwise OR/AND/XOR, always use the corresponding `fetch_*` instead of a CAS loop; CAS loops under contention exhibit O(n^2) total work with n threads.
**Tool anchor:** `perf stat -e mem_inst_retired.lock_loads,machine_clears.count -- ./cas_bench -t 16` to measure lock instruction count and machine clears (which spike during CAS retry storms)
**Drill:** You have a CAS loop updating a 64-bit statistics bitmask: `while (!flags.compare_exchange_weak(old, old | new_flag))`. Under 8-thread contention, throughput drops 10x. Rewrite using `fetch_or` and measure the improvement, then explain a scenario where CAS cannot be replaced.
**Tags:** fetch-add, CAS, compare-exchange, contention-scaling, retry-loop

### Lock-free stack (Treiber stack)
The Treiber stack is the canonical lock-free data structure: push and pop use a CAS on the head pointer. Push: create node, set node->next to head, CAS head from old to node. Pop: read head, CAS head from old to old->next. The ABA problem arises when a popped node is reused and placed back at the head between another thread's read and CAS, making the CAS succeed incorrectly.
**Key concepts:** CAS-based push/pop, ABA problem, tagged pointer, memory reclamation
**Tip:** On x86-64, you can use the upper 16 bits of a pointer (currently unused in userspace) as a monotonic tag to prevent ABA, giving you a tagged pointer in a single 64-bit `cmpxchg` without needing 128-bit `cmpxchg16b`.
**Tool anchor:** `perf stat -e mem_inst_retired.lock_loads -p $(pgrep md_feed) -- sleep 5` to count CAS operations; a lock-free stack with high contention will show millions of locked loads per second
**Drill:** Implement a Treiber stack for recycling SBE message buffer objects between your receive thread and decode thread. Identify where the ABA problem can occur during pop, demonstrate a concrete interleaving that triggers it, and add a 16-bit tag to the pointer to prevent it.
**Tags:** Treiber-stack, lock-free, ABA, CAS, tagged-pointer

### Scalable counters and per-CPU data
A single `std::atomic<uint64_t>` counter becomes a bottleneck beyond ~4 cores because every increment bounces the cache line. Scalable alternatives include per-thread/per-CPU counters (sum on read), combining trees (hierarchical reduction), and approximate counters (allow bounded staleness). Linux's `percpu` allocator provides per-CPU memory that avoids all coherence traffic for updates.
**Key concepts:** distributed counting, per-CPU, combining tree, approximate counting, read vs write tradeoff
**Tip:** Per-thread counters with `thread_local` make increments zero-cost but reads expensive (must iterate all threads); this is the right tradeoff when increments are millions/sec and reads are once/sec for monitoring.
**Tool anchor:** `perf c2c record -- ./counter_bench -t 16 && perf c2c report --stdio` to show the single atomic counter as the dominant HITM source, then compare with the per-thread version showing zero HITMs
**Drill:** Your market data handler increments `atomic<uint64_t> total_messages` on every message (10M/sec) and a monitoring thread reads it once per second. Profile the atomic version, redesign with `thread_local` counters, and implement a `read_total()` function that sums across threads.
**Tags:** scalable-counters, per-CPU, per-thread, combining-tree, distributed-counting

### Memory barriers: compiler vs hardware
Compiler barriers (`asm volatile("" ::: "memory")`, `std::atomic_signal_fence`) prevent the compiler from reordering memory operations across the barrier but generate no machine instructions. Hardware barriers (`mfence`, `sfence`, `lfence`, `std::atomic_thread_fence`) emit actual fence instructions that constrain the CPU's out-of-order memory system. On x86, you rarely need explicit hardware barriers because TSO provides most ordering, but compiler barriers are frequently needed to prevent optimization.
**Key concepts:** compiler barrier, hardware barrier, asm volatile, atomic_thread_fence, atomic_signal_fence
**Tip:** `std::atomic_thread_fence(memory_order_acquire)` on x86 compiles to nothing (just a compiler barrier) because x86 loads already have acquire semantics; the same fence on ARM emits a `dmb` instruction. Always use the `std::atomic` fences instead of raw `asm` for portability.
**Tool anchor:** `objdump -d -M intel ./md_handler | grep -c 'mfence\|sfence\|lfence'` to count hardware barriers in your binary; a high count suggests over-synchronization
**Drill:** You have a non-atomic flag `bool ready` and a non-atomic data buffer. You insert `asm volatile("" ::: "memory")` between writing the buffer and setting the flag. Explain why this prevents the compiler from reordering the two stores but does not guarantee another core sees them in order, and what you actually need on x86 vs ARM.
**Tags:** compiler-barrier, hardware-barrier, mfence, atomic-thread-fence, ordering

### Lock elision and Intel TSX (historical)
Intel Transactional Synchronization Extensions (TSX) attempted to optimize lock-based code by speculatively executing critical sections without acquiring the lock (HLE) or in an explicit transaction (RTM). If no conflict occurred, the transaction committed atomically without cache line bouncing. TSX was deprecated due to repeated security vulnerabilities (TAA, Zombieload) and microcode disabling. The lesson is that hardware lock elision is attractive but fragile.
**Key concepts:** HLE, RTM, speculative execution, transaction abort, security vulnerabilities
**Tip:** Even though TSX is dead, its design lesson stands: if your critical section rarely conflicts, you can implement software-level optimistic concurrency (try-lock, do work, validate, retry on conflict) that captures 80% of TSX's benefit.
**Tool anchor:** `perf stat -e tx-abort,tx-commit,tx-start -- ./tsx_bench` (only on CPUs with TSX enabled; most modern Intel has it disabled via microcode)
**Drill:** You have a mutex protecting an order book update that conflicts on less than 1% of acquisitions. Design a software optimistic concurrency scheme inspired by TSX: try-lock, perform update on a shadow copy, validate, commit or retry. Compare the expected throughput under 1% vs 20% conflict rates.
**Tags:** TSX, HLE, RTM, lock-elision, transactional-memory

## advanced

### CAS loops, ABA problem, and hazard pointers
CAS-based algorithms face the ABA problem when a value changes from A to B and back to A between a thread's read and CAS, making the CAS succeed on stale state. Tagged pointers (appending a monotonic counter) detect ABA but do not solve the underlying reclamation problem: when can a removed node be freed? Hazard pointers solve this by having each thread publish pointers it is currently accessing; a thread wanting to free a node checks all hazard pointers and defers reclamation until no thread references it.
**Key concepts:** ABA problem, tagged pointer, hazard pointer publication, deferred reclamation, scan-then-free
**Tip:** Hazard pointers have O(N*K) scan cost where N is threads and K is hazard pointers per thread; for low thread counts (under 16) this is fast, but for higher counts consider epoch-based reclamation instead.
**Tool anchor:** `bpftrace -e 'uprobe:./md_handler:hazard_scan { @scan_latency = hist(nsecs - @start[tid]); @start[tid] = nsecs; }' -p $(pgrep md_feed)` to histogram hazard pointer scan latency
**Drill:** Your lock-free order book uses a Treiber stack for recycling price level nodes. Under high update rates, a thread pops node A, another thread pops and pushes node A back, and the first thread's CAS succeeds with corrupted data. Implement hazard pointer protection for the pop operation and determine the maximum number of unreclaimed nodes.
**Tags:** ABA, hazard-pointers, CAS-loop, tagged-pointer, deferred-reclamation

### NUMA-aware locking and data partitioning
On multi-socket systems, acquiring a lock held by a thread on a remote NUMA node costs 100-300ns (cross-socket cache coherence) vs 40-80ns within the same socket. NUMA-aware (cohort) locks prefer handing ownership to threads on the same node, reducing cross-socket transfers. Data partitioning by NUMA node, with each partition having its own lock, eliminates cross-node coherence entirely for the partitioned data.
**Key concepts:** NUMA node, cross-socket latency, cohort lock, data partitioning, lock migration
**Tip:** `numactl --cpunodebind=0 --membind=0` pins both threads and memory to node 0; for a dual-socket market data system, partition channels across sockets and ensure each channel's data structures are allocated on the same node as its processing thread.
**Tool anchor:** `perf stat -e offcore_response.demand_rfo.l3_miss.remote_hitm,offcore_response.demand_rfo.l3_miss.snoop_hitm -p $(pgrep md_feed) -- sleep 10` to measure local vs remote cross-core cache transfers
**Drill:** Your order book is on NUMA node 0 but three of eight decode threads run on node 1. Profile the cross-node coherence traffic with `perf stat`, then redesign with per-node order book partitions and a merge step. Calculate the expected latency improvement for a lock acquisition.
**Tags:** NUMA, cohort-lock, data-partitioning, cross-socket, memory-locality

### Memory fences on x86: when you actually need them
On x86-TSO, `mfence` (full barrier), `sfence` (store barrier), and `lfence` (load barrier) serve specific purposes beyond the TSO guarantees. `sfence` is needed only after non-temporal (NT) stores (`movntdq`, `movnti`) which bypass the cache and are not ordered by TSO. `lfence` was repurposed as a speculation barrier for Spectre mitigation and serializes instruction execution. `mfence` provides sequential consistency for the store-load reorder case.
**Key concepts:** mfence, sfence, lfence, NT stores, Spectre, store-load reorder
**Tip:** You almost never need `sfence` unless you use NT stores (streaming writes for large memcpy); if your code does not contain `_mm_stream_*` intrinsics or `movnt*` instructions, every `sfence` in your codebase is dead weight.
**Tool anchor:** `objdump -d -M intel ./md_handler | grep -E 'mfence|sfence|lfence|movnt'` to audit fence usage and verify each fence has a corresponding NT store or seq_cst requirement
**Drill:** Your SBE decoder uses `_mm_stream_si128` to write decoded messages to a shared buffer, followed by setting an atomic flag. Without `sfence`, the consumer can see the flag set before the NT stores are visible. Insert the minimal fencing and explain why `sfence` (not `mfence`) suffices here.
**Tags:** mfence, sfence, lfence, NT-stores, Spectre, x86-fencing

### Epoch-based reclamation
Epoch-based reclamation (EBR) divides time into epochs. Each thread announces which epoch it is in when accessing shared data. A retired node can be freed when all threads have passed through at least one epoch since the node was retired (meaning no thread could hold a reference). EBR is simpler than hazard pointers (no per-access publication) but has the weakness that a single stalled thread can prevent all reclamation, causing unbounded memory growth.
**Key concepts:** epoch counter, grace period, quiescent state, stalled-thread problem, RCU comparison
**Tip:** EBR is essentially userspace RCU: the kernel's `synchronize_rcu()` is an epoch advance that waits for all CPUs to pass through a quiescent state. If your threads never block inside a read-side critical section, EBR works perfectly.
**Tool anchor:** `bpftrace -e 'uprobe:./md_handler:epoch_retire { @retire_rate = count(); } uprobe:./md_handler:epoch_reclaim { @reclaim_rate = count(); }' -p $(pgrep md_feed)` to compare retire vs reclaim rates and detect memory accumulation from stalled threads
**Drill:** Your lock-free order book retires price level nodes into an epoch-based reclamation queue. During a burst of 1M updates, you see memory grow by 500MB because one slow analytics thread is stuck in epoch 42 while the system is at epoch 100. Diagnose the stalled-thread problem and implement an epoch advance mechanism that handles this case.
**Tags:** epoch-reclamation, grace-period, quiescent-state, RCU, memory-reclamation

### Seqlock implementation and use cases
A SeqLock uses a sequence counter (even = unlocked, odd = write-in-progress) to allow readers to proceed without any locking or atomic operations. Readers save the counter, read the data, check the counter again; if it changed or is odd, they retry. Writers increment the counter to odd, write, increment to even. This is ideal for small, frequently-read, rarely-written data like timestamps or configuration snapshots.
**Key concepts:** sequence counter, read-retry, writer-favoring, no reader blocking, small data only
**Tip:** SeqLock readers must use `volatile` reads or `atomic_load(relaxed)` for the data itself to prevent the compiler from hoisting the data read above or sinking it below the counter checks; without this, the compiler can break the retry logic.
**Tool anchor:** `perf stat -e branch-misses -- ./seqlock_bench` to verify that reader retries (branch mispredictions from the retry loop) are rare under low write contention
**Drill:** Your market data handler has a `struct MarketSnapshot { double bid; double ask; uint64_t timestamp; }` updated by 1 writer at 100K updates/sec and read by 12 strategy threads at 1M reads/sec each. Implement a SeqLock, explain why `std::shared_mutex` is inferior here, and calculate the expected reader retry rate.
**Tags:** SeqLock, sequence-counter, reader-retry, writer-favoring, read-copy

### RCU concepts for userspace
Read-Copy-Update provides zero-overhead reads by never blocking readers. Writers create a new version of the data, atomically swing a pointer, and defer freeing the old version until all pre-existing readers have finished (a grace period). In the kernel, RCU is fundamental to networking and VFS. In userspace, the `liburcu` library provides similar semantics. Read-side critical sections have zero synchronization overhead; write-side pays for allocation and grace period waiting.
**Key concepts:** read-side zero overhead, publish-subscribe pointer swap, grace period, liburcu, deferred free
**Tip:** Userspace RCU's `rcu_read_lock()/rcu_read_unlock()` in `liburcu`'s QSBR flavor are literally no-ops (empty inline functions — just a debug assert that optimizes away, not even a compiler barrier) if you call `rcu_quiescent_state()` periodically in your event loop; this is perfect for market data handlers with a natural per-message quiescent point.
**Tool anchor:** `bpftrace -e 'uprobe:/usr/lib/liburcu-qsbr.so:synchronize_rcu_memb { @grace_period_latency = hist(nsecs - @start[tid]); @start[tid] = nsecs; }'` to histogram grace period duration
**Drill:** Your order book is read by 8 strategy threads on every market data update and modified by 1 feed thread. Redesign the update path using RCU: the writer clones the relevant price level, modifies the clone, publishes the new pointer with `rcu_assign_pointer`, and calls `synchronize_rcu`. Analyze the memory overhead and the grace period latency impact on the writer.
**Tags:** RCU, read-copy-update, grace-period, liburcu, zero-overhead-reads

### Wait-free vs lock-free vs obstruction-free
These are formal progress guarantees for concurrent algorithms. Wait-free: every thread completes in a bounded number of steps regardless of other threads. Lock-free: at least one thread makes progress (but individual threads can starve). Obstruction-free: a thread makes progress if it runs in isolation (but can livelock under contention). Most practical "lock-free" data structures are lock-free but not wait-free; true wait-freedom requires helping mechanisms that add significant complexity.
**Key concepts:** progress guarantees, bounded steps, starvation, livelock, helping mechanism
**Tip:** A CAS retry loop is lock-free (someone always succeeds) but not wait-free (one thread can be unlucky indefinitely); in practice, starvation under CAS contention is astronomically rare on modern hardware with randomized backoff.
**Tool anchor:** `bpftrace -e 'uprobe:./md_handler:cas_retry_loop { @retries = hist(@retry_count[tid]); @retry_count[tid] = 0; }'` to histogram CAS retry counts and detect potential starvation
**Drill:** Your lock-free order book uses a CAS loop to update the best bid. Under extreme contention (32 threads), one thread's update takes 10x longer than average due to repeated CAS failures. Determine whether this is a progress violation, implement exponential backoff to mitigate it, and explain why this does not upgrade the guarantee from lock-free to wait-free.
**Tags:** wait-free, lock-free, obstruction-free, progress-guarantee, starvation

### MPMC queue designs and tradeoffs
Multi-producer multi-consumer queues are significantly harder than SPSC due to coordination between multiple writers and multiple readers. Major designs include: bounded array-based (Dmitry Vyukov's MPMC, using per-slot sequence counters), unbounded linked-list (Michael-Scott queue), and fetch-and-add based (LCRQ). Each trades off between bounded memory, contention scaling, wait-freedom, and implementation complexity.
**Key concepts:** Vyukov MPMC, Michael-Scott queue, LCRQ, per-slot sequence counter, FAA-based
**Tip:** Vyukov's bounded MPMC queue uses a per-slot sequence counter (not CAS on head/tail) so producers and consumers contend only on adjacent slots, not on a single head or tail pointer; this gives near-linear scaling up to ~16 threads.
**Tool anchor:** `perf stat -e mem_inst_retired.lock_loads,machine_clears.count -- ./mpmc_bench -p 4 -c 4` to compare locked instruction counts across MPMC queue implementations under identical load
**Drill:** You need a queue between 4 multicast receive threads and 4 SBE decode threads. Evaluate three designs (mutex + `std::deque`, Vyukov bounded MPMC, Michael-Scott unbounded) on: throughput at 10M msg/sec, memory usage, tail latency, and implementation risk. Select one and justify.
**Tags:** MPMC, Vyukov, Michael-Scott, FAA-queue, bounded-unbounded

### Asymmetric synchronization patterns
Some synchronization problems have inherently asymmetric frequency: a fast path executed millions of times per second and a slow path executed rarely (configuration change, statistics read, thread registration). Optimizing the fast path to zero cost while accepting high cost on the slow path is the goal. Techniques include `membarrier()` (fast path does plain loads/stores, slow path issues IPIs to force barriers on remote CPUs), epoch-based schemes, and signal-based quiescent state detection.
**Key concepts:** fast path/slow path asymmetry, membarrier(), IPI, signal-based fence, biased locking
**Tip:** `membarrier(MEMBARRIER_CMD_PRIVATE_EXPEDITED, 0)` forces all threads of the calling process to serialize memory operations, effectively giving you a free acquire barrier on the fast path at the cost of a ~10us IPI storm on the slow path.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_membarrier { @[comm, ustack(5)] = count(); }'` to detect membarrier usage and verify it is only called on the slow path
**Drill:** Your market data handler reads a `config_version` counter on every message (fast path, 10M/sec) and a management thread updates the config once per minute (slow path). Design an asymmetric scheme using `membarrier()` where the fast path reads `config_version` with a plain non-atomic load and the slow path uses `membarrier()` after updating, then analyze the correctness argument.
**Tags:** asymmetric-synchronization, membarrier, fast-path, slow-path, IPI

### Formal verification of lock-free algorithms
Lock-free algorithms are notoriously difficult to get right because bugs depend on specific thread interleavings that may never occur in testing. Formal verification tools can exhaustively check all interleavings: TLA+ models the algorithm at a high level and checks invariants and liveness properties; `herd7` and `litmus7` test specific memory ordering litmus tests against hardware memory models; CBMC (C Bounded Model Checker) verifies actual C code for bounded inputs.
**Key concepts:** TLA+, model checking, litmus tests, herd7, CBMC, state space explosion
**Tip:** Start with litmus tests (`herd7`) for the specific memory ordering question (can these two stores be reordered?), then graduate to TLA+ for full algorithm verification; do not jump straight to TLA+ for a simple ordering question.
**Tool anchor:** `herd7 -model x86tso my_test.litmus` to check whether a specific memory access pattern can produce a forbidden outcome under x86-TSO; `litmus7 my_test.litmus -o test_dir && cd test_dir && make && ./run.sh` to empirically test on hardware
**Drill:** You implemented a custom SeqLock and want to verify it handles the reader-retry edge case where a writer wraps the sequence counter. Write a litmus test for the store-load ordering between the writer's counter increment and data store, run it against x86-TSO and ARM models using herd7, and explain the difference in outcomes.
**Tags:** formal-verification, TLA+, litmus-test, herd7, model-checking
