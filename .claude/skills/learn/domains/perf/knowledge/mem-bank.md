# Memory Hierarchy Topic Bank
Updated: 2026-05-28

## beginner

### Cache line anatomy: 64 bytes and what fits
The CPU cache operates in 64-byte cache lines, the fundamental unit of data transfer between cache and memory. Understanding what fits in a single cache line determines how efficiently your structs traverse the memory hierarchy. For SBE message decoding, a poorly padded struct that spans two cache lines doubles the cache pressure for every field access.
**Key concepts:** cache line (64B), sets, ways, tag/index/offset bits, struct packing vs padding
**Tip:** An SBE message header is 8 bytes; if you follow it with a 56-byte body struct, the entire message fits in one cache line, but adding a single `bool` with default alignment pushes it to two lines due to padding.
**Tool anchor:** `perf stat -e L1-dcache-loads,L1-dcache-load-misses -- ./sbe_decoder < capture.pcap`
**Drill:** You have a struct with fields: `uint64_t seq_num; uint32_t msg_size; uint16_t template_id; char body[48]; uint8_t flags;`. Calculate its sizeof with default alignment, determine if it fits in one cache line, and propose a reordering or packing strategy to guarantee single-line residency.
**Tags:** cache-line, struct-layout, padding, SBE, L1-cache

### L1/L2/L3 latencies and the memory wall
Modern CPUs have a deep memory hierarchy with dramatically increasing latencies: L1 ~4 cycles (~1ns), L2 ~12 cycles (~3ns), L3 ~40 cycles (~10ns), and DRAM ~200+ cycles (~60-100ns). The "memory wall" refers to the growing gap between CPU speed and memory speed, meaning a single cache miss can cost as much as 50-200 instructions. For hot-path SBE decoding, every LLC miss is a latency spike visible at the microsecond level.
**Key concepts:** L1/L2/L3 latency tiers, memory wall, cycles per access, bandwidth vs latency
**Tip:** At 3 GHz, a 200-cycle DRAM access is ~67ns; if your SBE decode loop touches 4 cache lines that all miss to DRAM, you burn ~270ns just waiting for data, which dominates a decode that otherwise takes ~50ns of compute.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,l2_rqsts.miss,LLC-load-misses,cycle_activity.stalls_l1d_miss,cycle_activity.stalls_l2_miss,cycle_activity.stalls_l3_miss -- ./sbe_decoder < capture.pcap`
**Drill:** perf stat on your SBE decoder shows: 1.2B instructions, 400M cycles, IPC 3.0 in a microbenchmark. After switching from a flat array to an `std::unordered_map` lookup, it shows: 1.4B instructions, 2.8B cycles, IPC 0.5, LLC-load-misses jumps from 0.1% to 18%. Explain what happened in terms of the memory hierarchy.
**Tags:** latency, memory-wall, cache-miss, IPC, DRAM

### TLB and page table walks
The TLB (Translation Lookaside Buffer) caches virtual-to-physical address translations. L1 dTLB holds ~64 entries (for 4KB pages), L2 sTLB holds ~1536 entries. A TLB miss triggers a page table walk through 4 levels of page tables (PML4, PDPT, PD, PT), costing ~7ns best case (page table in cache) to ~100ns+ if page table entries miss to DRAM. Using 2MB huge pages increases TLB coverage: on Skylake the L1 dTLB has a separate 32-entry pool for 2MB pages, so coverage goes from 256KB (64 x 4KB) to 64MB (32 x 2MB).
**Key concepts:** dTLB, sTLB, page table walk, 4KB vs 2MB pages, TLB reach
**Tip:** With 4KB pages, 64 dTLB entries cover only 256KB; a market data application touching a 16MB ring buffer will TLB-miss constantly, but switching to 2MB huge pages makes the 32-entry 2MB dTLB pool cover 64MB, eliminating the walks entirely.
**Tool anchor:** `perf stat -e dTLB-loads,dTLB-load-misses,dtlb_load_misses.walk_completed,dtlb_load_misses.walk_active -- ./md_handler`
**Drill:** Your feed handler's perf stat shows dTLB-load-misses at 4.2% of dTLB-loads and dtlb_load_misses.walk_active is 22% of total cycles. The application uses a 32MB hash table with 4KB pages. Calculate the TLB reach, explain why the miss rate is high, and propose a fix.
**Tags:** TLB, page-table-walk, huge-pages, dTLB, address-translation

### Memory access patterns: sequential vs random
Sequential access at ~4 cycles per element benefits from hardware prefetching that recognizes stride patterns and preloads cache lines before the CPU requests them. Random access at ~200+ cycles per element defeats prefetchers because the next address is unpredictable. Working set size determines which cache level absorbs the misses: if your random-access structure fits in L2, the penalty is ~12 cycles, not 200.
**Key concepts:** spatial locality, temporal locality, stride patterns, working set size, prefetch-friendly
**Tip:** Iterating a `std::vector<MDUpdate>` sequentially processes ~8-16 updates per cache line (depending on struct size), while chasing `std::list<MDUpdate>` nodes allocated by `new` fetches one node per cache line miss because the allocator scatters them across the heap.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,LLC-load-misses,instructions -- ./bench_sequential && perf stat -e L1-dcache-load-misses,LLC-load-misses,instructions -- ./bench_random`
**Drill:** You have two order book implementations: one stores price levels in a sorted `std::vector<Level>` (12 bytes each) and one in an `std::map<Price, Level>`. For a snapshot rebuild that inserts 5000 levels and then iterates all of them, estimate the cache line fetches for each approach and explain the performance difference.
**Tags:** sequential-access, random-access, locality, prefetching, working-set

### Stack vs heap allocation performance
Stack allocation is nearly free (just a pointer decrement) and provides excellent locality because the stack hot zone lives in L1 cache. Heap allocation (malloc/new) involves metadata management, potential system calls, and scatters objects across address space, hurting locality. For hot paths, pool allocators pre-allocate contiguous memory to get heap flexibility with stack-like locality.
**Key concepts:** stack pointer, malloc overhead, page faults, pool allocator, arena allocation
**Tip:** A `std::array<SBEField, 64>` on the stack is allocated in 0 cycles and lives in cache; a `std::vector<SBEField>` with 64 elements requires a malloc (~20-50ns), a possible page fault (~1us), and the data may land on a cold cache line.
**Tool anchor:** `perf stat -e cache-misses,page-faults,cpu-cycles -- ./bench_stack_alloc && perf stat -e cache-misses,page-faults,cpu-cycles -- ./bench_heap_alloc`
**Drill:** Your SBE decoder allocates a `std::vector<Field>` per message to hold decoded fields (typically 8-12 fields per message) and processes 5M messages/sec. Each allocation triggers malloc and each deallocation triggers free. Calculate the overhead at 5M msg/sec assuming 40ns per malloc+free pair and propose an alternative allocation strategy.
**Tags:** stack, heap, malloc, pool-allocator, allocation

### Struct layout and padding basics
The compiler inserts padding bytes to satisfy alignment requirements: a `uint32_t` must start at a 4-byte boundary, a `uint64_t` at 8-byte boundary. This means `struct { char a; uint64_t b; }` is 16 bytes (7 bytes of padding), not 9. Reordering fields by decreasing alignment or using `__attribute__((packed))` reduces size, but packed access on some paths can cause misaligned loads. Understanding `sizeof` vs actual data content is critical for cache efficiency.
**Key concepts:** alignment requirements, padding insertion, field reordering, packed attribute, offsetof
**Tip:** Run `pahole` on your SBE message struct to visualize every padding hole; a 128-byte struct with 40 bytes of padding wastes 31% of every cache line it occupies.
**Tool anchor:** `pahole -C SBEMessageHeader ./sbe_decoder` to show struct layout with padding holes
**Drill:** Given `struct Msg { uint8_t type; uint64_t timestamp; uint16_t size; uint32_t seq; uint8_t flags; };`, calculate sizeof with default alignment, draw the byte layout with padding, and reorder fields to minimize padding without using packed.
**Tags:** padding, alignment, struct-layout, pahole, sizeof

### Data alignment and its performance impact
When a data type straddles a cache line boundary (misaligned access), the CPU must fetch two cache lines and merge the result, adding latency and consuming extra bandwidth. Natural alignment (address divisible by size) prevents this. Using `alignas(64)` ensures a struct starts at a cache line boundary, which is critical for arrays of structs that are iterated in hot loops and for avoiding false sharing.
**Key concepts:** natural alignment, split cache line load, alignas, SSE/AVX alignment (16/32 bytes), cacheline alignment
**Tip:** An `__m256i` AVX2 load from a non-32-byte-aligned address silently works on modern CPUs but crosses cache line boundaries half the time, doubling L1 bandwidth consumption; always use `alignas(32)` for SIMD buffers.
**Tool anchor:** `perf stat -e mem_inst_retired.split_loads,mem_inst_retired.split_stores -- ./sbe_decoder < capture.pcap`
**Drill:** perf stat on your SBE decoder shows 12M split loads out of 800M total loads (1.5%). The decoder processes fixed-size 64-byte messages from a network buffer, but the buffer starts at an arbitrary offset after the UDP header (which is 42 bytes into the packet). Explain why splits occur and propose a fix.
**Tags:** alignment, split-load, alignas, cache-line-boundary, SIMD

### Virtual memory and physical address translation
x86-64 uses a 4-level page table (PML4 -> PDPT -> PD -> PT) to translate 48-bit virtual addresses to physical addresses. Each level is a 4KB page with 512 entries, and walking all four levels on a TLB miss requires up to 4 memory accesses. PCID (Process Context Identifier) tags TLB entries per-process so context switches do not flush the entire TLB, which matters when your market data handler shares a core with other processes.
**Key concepts:** PML4, PDPT, PD, PT, 4-level walk, PCID, CR3, canonical addresses
**Tip:** Each page table walk can itself miss in cache, so a TLB miss in the worst case costs 4 sequential DRAM accesses (~800 cycles); this is why huge pages are so impactful, they eliminate one or two levels from the walk.
**Tool anchor:** `perf stat -e dtlb_load_misses.walk_completed_4k,dtlb_load_misses.walk_completed_2m_4m,dtlb_load_misses.walk_completed_1g -- ./md_handler`
**Drill:** Your market data handler processes messages from 200 instruments, each with its own order book object. The objects are scattered across a 2GB virtual address range. With 4KB pages and 1536 sTLB entries, calculate the TLB reach and explain why accessing all 200 books causes repeated page table walks. What PCID-related concern arises if the handler is not pinned to a dedicated core?
**Tags:** virtual-memory, page-table, PML4, PCID, address-translation

## intermediate

### Hardware prefetching
Modern CPUs have multiple hardware prefetchers: the L1 streaming (DCU) prefetcher detects sequential access, the adjacent-line prefetcher fetches the neighboring cache line, the L1 IP-based stride prefetcher detects constant-stride patterns per load instruction (up to 2KB stride on Intel), and the L2 streamer follows forward/backward streams within a 4KB page. These prefetchers can sustain near-L1 throughput for predictable patterns but waste bandwidth on irregular access. Knowing when they are active (and when they fail) is the key to understanding memory-bound performance.
**Key concepts:** streaming prefetcher, adjacent-line prefetcher, L2 stride prefetcher, prefetch distance, training
**Tip:** The L2 stride prefetcher needs ~2 consecutive accesses with the same stride to start prefetching; if your SBE messages vary in size between 32 and 128 bytes, the stride changes every message and the prefetcher never engages.
**Tool anchor:** `perf stat -e l2_lines_in.all,l2_rqsts.prefetch_miss,l2_rqsts.all_pf -- ./sbe_decoder < capture.pcap`
**Drill:** Your SBE decoder processes fixed-size 64-byte messages from a contiguous ring buffer and shows near-zero L1 misses. You change to variable-length messages (32-256 bytes) and L1 miss rate jumps to 8%. Hardware prefetch counters show l2_rqsts.all_pf dropped by 90%. Explain the connection and propose a data layout that re-enables hardware prefetching.
**Tags:** hardware-prefetch, stride-prefetcher, streaming, adjacent-line, cache-miss

### Software prefetching: __builtin_prefetch
`__builtin_prefetch(addr, rw, locality)` inserts a prefetch instruction that begins loading a cache line without stalling the pipeline. The `rw` hint (0=read, 1=write) and `locality` hint (0=non-temporal through 3=keep in all levels) guide placement. The critical parameter is prefetch distance: how many iterations ahead to prefetch, calculated as (miss_latency / loop_body_time). Prefetching too early evicts the line before use; too late and the load still stalls.
**Key concepts:** prefetch distance, temporal vs non-temporal, prefetch into L1/L2/L3, diminishing returns, instruction overhead
**Tip:** For a loop body of ~20ns and an L3 miss latency of ~40ns, prefetch 2 iterations ahead; but measure, because adding prefetch instructions to a loop that hardware prefetching already handles just wastes instruction bandwidth.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,instructions -- ./bench_no_prefetch && perf stat -e L1-dcache-load-misses,instructions -- ./bench_with_prefetch`
**Drill:** You are iterating an array of pointers to order book levels, dereferencing each to read the price. The array is sequential (hardware-prefetched) but the pointed-to levels are scattered on the heap. Write a loop that software-prefetches the Level object N iterations ahead. What value of N would you start with if the loop body takes ~15ns and you expect L3 misses (~40ns)?
**Tags:** software-prefetch, builtin-prefetch, prefetch-distance, pointer-chasing, loop-optimization

### False sharing: hidden cache line contention
False sharing occurs when two threads write to different variables that share the same 64-byte cache line: the coherence protocol bounces the line between cores at ~40-70ns per bounce, even though the data is logically independent. This is invisible in the source code and can reduce multi-threaded throughput by 10-50x. Aligning per-thread data to cache line boundaries with `alignas(64)` eliminates it.
**Key concepts:** MESI protocol, cache line bouncing, alignas(64), perf c2c, per-thread padding
**Tip:** `struct ThreadCtx { uint64_t counter; };` in a `ThreadCtx contexts[NUM_THREADS]` array puts all counters in 1-2 cache lines; adding `alignas(64)` to the struct or padding to 64 bytes gives each thread its own line.
**Tool anchor:** `perf c2c record -F 99 -a -- sleep 10 && perf c2c report --stdio --call-graph none` to identify cache lines with cross-core contention
**Drill:** Your feed handler has 4 threads, each incrementing its own `stats.msg_count` field. All 4 ThreadStats structs (16 bytes each) sit in a contiguous array. perf c2c shows the cache line containing these structs has 850K HITM events/sec. Calculate why all 4 structs share a line and show the alignas fix.
**Tags:** false-sharing, cache-coherence, MESI, perf-c2c, multi-threaded

### Store buffers and store-to-load forwarding
The store buffer (~56 entries on modern Intel) holds pending stores so the CPU does not stall waiting for cache coherence. When a load reads from the same address as a pending store, store-to-load forwarding provides the data directly from the store buffer (~4-5 cycles) instead of waiting for the store to commit. Forwarding fails when the load is wider than the store, partially overlapping, or unaligned relative to the store, causing a ~13-cycle penalty because the load stalls until the store reaches L1 (it is a stall, not a pipeline flush).
**Key concepts:** store buffer entries, forwarding rules, forwarding failure, load stall, memory ordering
**Tip:** Writing a `uint32_t` and then reading the containing `uint64_t` (e.g., via a union or type-pun) causes a store-forwarding failure because the load is wider than the store; the load is blocked until the store drains to L1 cache, then re-issues.
**Tool anchor:** `perf stat -e ld_blocks.store_forward -- ./sbe_decoder < capture.pcap`
**Drill:** Your SBE encoder writes message fields as individual typed stores (uint16_t, uint32_t, uint64_t) into a buffer, then copies the entire buffer with a memcpy that reads 128-bit (16-byte) chunks. perf stat shows 2.4M ld_blocks.store_forward events/sec. Explain why forwarding fails and propose two solutions.
**Tags:** store-buffer, store-forwarding, forwarding-failure, pipeline-flush, memory-ordering

### Cache associativity and conflict misses
A cache with N-way set associativity maps each address to one of S sets, each holding N lines. If N+1 addresses map to the same set, one line is evicted even if other sets are empty (conflict miss). On a 32KB 8-way L1, there are 64 sets (32KB / 64B / 8), and addresses separated by exactly 32KB alias to the same set. Power-of-two array strides are particularly prone to conflict misses.
**Key concepts:** set index bits, N-way associative, conflict eviction, capacity miss vs conflict miss, power-of-two aliasing
**Tip:** If you have 9 arrays of 4096 doubles (32KB each) and iterate them in lockstep, all 9 will map to the same L1 sets, causing conflict misses despite the total working set fitting in L2; adding 64 bytes of padding to each array's base address shifts the set mapping.
**Tool anchor:** `perf stat -e l1d.replacement,l2_rqsts.miss -- ./bench_conflict && perf stat -e l1d.replacement,l2_rqsts.miss -- ./bench_padded`
**Drill:** You have 8 price level arrays, each 4KB (64 doubles), that you iterate simultaneously in a tight loop. L1 is 32KB 8-way. Calculate the number of sets, show that all 8 arrays can map to different sets, then add a 9th array and explain why L1 miss rate spikes from 0.1% to 15%.
**Tags:** associativity, conflict-miss, set-index, N-way, power-of-two

### Write-back vs write-through policies
In write-back caching, stores update only the cache line and mark it dirty; the line is written to the next level only on eviction. Write-through sends every store to the next level immediately, consuming bandwidth but keeping the hierarchy consistent. x86 uses write-back (WB) for normal memory, write-combining (WC) for frame buffers and I/O, and uncacheable (UC) for MMIO. The PAT (Page Attribute Table) and MTRRs control memory type per-region.
**Key concepts:** dirty bit, writeback on eviction, write-combining, UC/WC/WB/WT memory types, PAT, MTRR
**Tip:** Write-combining (WC) memory fills a 64-byte buffer before issuing a single bus write, which is why MMIO to NIC registers should be WC when doing batched doorbell writes, but UC when ordering matters.
**Tool anchor:** `sudo rdmsr 0x277` to read IA32_PAT MSR and decode memory type assignments; `cat /proc/mtrr` to see MTRR ranges
**Drill:** Your NIC DMA ring uses write-back memory and you notice high L3 traffic from dirty evictions when the NIC writes packet data. You switch the ring's pages to WC. Explain what changes in cache behavior, why descriptor reads might break, and what memory type is actually appropriate for a DMA receive ring.
**Tags:** write-back, write-through, write-combining, PAT, memory-type

### Memory-level parallelism (MLP)
MLP is the CPU's ability to have multiple cache misses outstanding simultaneously, tracked by Line Fill Buffers (LFBs, ~10-12 on Intel). If code has independent loads that all miss, the hardware can issue them in parallel, amortizing the latency. But if loads depend on each other (pointer chasing), only one miss is in flight at a time. Maximizing MLP means restructuring code so independent memory accesses are visible to the out-of-order engine simultaneously.
**Key concepts:** Line Fill Buffers (LFBs), outstanding misses, independent loads, superqueue, miss clustering
**Tip:** A loop doing 4 independent hash table lookups per iteration can overlap all 4 DRAM accesses (~200 cycles each) to complete in ~250 cycles total instead of 800, a 3.2x speedup from MLP alone.
**Tool anchor:** `perf stat -e l1d_pend_miss.pending,l1d_pend_miss.pending_cycles,l1d_pend_miss.fb_full -- ./bench_mlp`
**Drill:** You process 4 incoming market data messages per batch. Each requires a hash table lookup (`instrument_map[msg.symbol]`). Version A decodes and looks up each message sequentially. Version B decodes all 4, issues all 4 lookups, then processes results. If each lookup misses to DRAM (200 cycles) and LFBs are available, estimate the cycle savings of version B and explain what limits MLP.
**Tags:** MLP, LFB, outstanding-misses, parallelism, miss-overlap

### Cache-oblivious vs cache-aware algorithms
Cache-aware algorithms explicitly tile/block computations to fit specific cache sizes (e.g., matrix multiply with 32KB tile). Cache-oblivious algorithms use recursive decomposition that automatically adapts to any cache size without knowing it (e.g., recursive matrix multiply, Z-order/Morton curve traversal). Cache-oblivious approaches are more portable across hardware but cache-aware tuning can extract the last 10-20% on known hardware.
**Key concepts:** loop tiling, blocking factor, Z-order curves, Morton codes, recursive decomposition, optimal cache complexity
**Tip:** For order book operations that scan price levels, converting a sorted array to a Van Emde Boas layout (BFS tree in an array) makes binary search cache-oblivious: every search touches O(log N / log B) cache lines instead of O(log N).
**Tool anchor:** `perf stat -e L1-dcache-load-misses,LLC-load-misses -- ./bench_linear_search && perf stat -e L1-dcache-load-misses,LLC-load-misses -- ./bench_veb_layout`
**Drill:** You have a sorted array of 10,000 price levels (16 bytes each, ~160KB total, fits in L2 but not L1). A binary search touches O(log2 10000) = ~13 random positions. Calculate how many cache lines are touched, estimate the L1 miss count, and explain how a Van Emde Boas layout reduces misses.
**Tags:** cache-oblivious, cache-aware, tiling, Z-order, recursive-blocking

### Pointer chasing and linked data structures
Linked lists, trees, and node-based hash tables require following pointers from one heap-allocated node to the next. Each pointer dereference is a dependent load that cannot overlap with the next, serializing cache misses. Hardware prefetchers cannot predict the next address because it is data-dependent. This makes linked structures 10-50x slower than contiguous arrays for iteration-heavy workloads.
**Key concepts:** dependent loads, pointer dereference serialization, prefetch defeat, cache miss serialization, node-based vs flat
**Tip:** Replacing `std::map<Price, Level>` (red-black tree with pointer chasing) with a sorted `std::vector<std::pair<Price, Level>>` with binary search can make order book lookups 5-10x faster because the binary search data is contiguous and partially prefetchable.
**Tool anchor:** `perf stat -e l1d_pend_miss.pending_cycles,L1-dcache-load-misses -- ./bench_list_walk && perf stat -e l1d_pend_miss.pending_cycles,L1-dcache-load-misses -- ./bench_vector_walk`
**Drill:** Your order book uses `std::map` with 500 price levels (each Level is 32 bytes). An L3-resident tree walk touches ~9 nodes (log2 500). Each node is a separate allocation. Calculate the expected cache misses per lookup, the total latency assuming L3 hits (~40 cycles each), and compare to a sorted vector binary search where the entire 16KB fits in L1.
**Tags:** pointer-chasing, linked-list, dependent-load, cache-miss, data-structure

### Data-oriented design for performance
Data-oriented design (DOD) reorganizes data layout to match access patterns rather than object-oriented abstraction boundaries. Struct-of-arrays (SoA) stores each field in a separate contiguous array, so iterating one field loads only that data with no padding waste. Hot/cold splitting separates frequently accessed fields from rarely accessed ones so hot fields pack densely in cache. ECS (Entity Component System) is the game-industry embodiment of DOD.
**Key concepts:** struct-of-arrays, array-of-structs, hot/cold splitting, ECS, data access patterns
**Tip:** If your market data update loop reads only `price` and `quantity` from a 128-byte `Instrument` struct, SoA layout crams 8 prices per cache line instead of 1, an 8x improvement in cache utilization for that loop.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,cache-misses -- ./bench_aos && perf stat -e L1-dcache-load-misses,cache-misses -- ./bench_soa`
**Drill:** You have 10,000 instruments, each with a struct: `{ uint64_t seq; double bid; double ask; double last; uint32_t volume; char name[64]; char exchange[32]; uint64_t last_update; }` (128 bytes). Your hot loop only reads bid/ask to compute mid-price. Calculate cache lines touched per full scan in AoS vs SoA for just the bid/ask fields.
**Tags:** data-oriented-design, SoA, AoS, hot-cold-splitting, cache-utilization

### Non-temporal stores and streaming writes
Non-temporal stores (`_mm_stream_si128`, `_mm_stream_si64`) write directly to memory bypassing the cache hierarchy, using write-combining buffers to coalesce full cache lines. This avoids polluting caches with data that will not be read again soon (e.g., writing log entries, archiving old market data). The store must write full cache lines; partial writes cause read-for-ownership traffic that negates the benefit.
**Key concepts:** write-combining buffers, cache pollution, streaming store, sfence, full-line writes
**Tip:** Non-temporal stores require an `_mm_sfence()` afterwards to guarantee ordering, because they bypass the cache coherence protocol and can appear out-of-order to other cores without the fence.
**Tool anchor:** `perf stat -e offcore_response.demand_rfo.any_response,l2_lines_out.non_silent -- ./bench_normal_store && perf stat -e offcore_response.demand_rfo.any_response,l2_lines_out.non_silent -- ./bench_nt_store`
**Drill:** Your market data logger writes 200-byte records to a 1GB memory-mapped file at 5M records/sec. The write-heavy workload evicts hot order book data from L3. Implement a non-temporal write strategy: explain why records must be padded to 256 bytes (4 cache lines), why you need sfence, and estimate the L3 pollution reduction.
**Tags:** non-temporal, streaming-store, write-combining, cache-pollution, sfence

### Memory allocation: malloc, mmap, pool allocators
`malloc` manages a user-space heap with free lists and size classes; `mmap` requests pages directly from the kernel. glibc malloc's overhead is ~20-50ns, but it can degrade with fragmentation and contention. jemalloc and tcmalloc use thread-local caches and size-class arenas to reduce contention. For latency-sensitive paths, pool allocators pre-allocate fixed-size blocks and hand them out in O(1) with zero fragmentation.
**Key concepts:** malloc free lists, mmap threshold, jemalloc/tcmalloc, thread-local caches, pool/arena allocators
**Tip:** glibc malloc uses mmap for allocations above 128KB (tunable via `M_MMAP_THRESHOLD`), which means every large allocation involves a syscall and page fault; for a pre-allocated message buffer pool, mmap once at startup and manage internally.
**Tool anchor:** `bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { @alloc_sizes = hist(arg0); } uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc /comm == "md_handler"/ { @count = count(); }'`
**Drill:** Your SBE decoder allocates a `std::string` for each of 5M messages/sec to hold the decoded output. strace shows 800 mmap/munmap syscalls/sec (large strings exceeding 128KB trigger mmap). malloc tracing shows 5M allocations/sec averaging 40ns each (200ms/sec total). Design a pool allocator that eliminates these allocations using a free list of pre-allocated 256-byte buffers.
**Tags:** malloc, mmap, jemalloc, pool-allocator, allocation-overhead

## advanced

### NUMA topology and memory placement
Non-Uniform Memory Access (NUMA) means each CPU socket has local DRAM (~100ns) and must traverse the interconnect for remote DRAM (~180-200ns). Memory placement follows first-touch policy by default: the thread that first writes a page determines which NUMA node owns it. For market data handlers pinned to a specific core, ensuring the ring buffer, order book, and hash tables all reside on the local node is critical.
**Key concepts:** local vs remote access latency, first-touch policy, numactl, mbind(), interleaving, NUMA balancing
**Tip:** If your main thread initializes all data structures but the hot worker thread runs on a different NUMA node, every access pays the remote penalty; either initialize on the worker thread or use `numactl --membind` to force placement.
**Tool anchor:** `numastat -p $(pgrep md_handler) && perf stat -e numa-loads,numa-load-misses,numa-stores,numa-store-misses -p $(pgrep md_handler) -- sleep 10`
**Drill:** Your 2-socket server runs the feed handler on socket 0, core 4. During startup, the main thread (on socket 1, core 32) pre-allocates a 4GB hash table. perf stat shows 38% of LLC misses are satisfied by remote DRAM. Calculate the latency penalty per remote access, the aggregate overhead at 2M lookups/sec, and show how to fix placement with mbind() or first-touch initialization.
**Tags:** NUMA, memory-placement, first-touch, numactl, remote-access

### numactl policy modes and binding in practice
`numactl` sets a process's NUMA policy at exec time; CPU binding and memory binding are independent knobs. `--cpunodebind=N` confines threads to *all* cores of node N (the scheduler may still migrate within the node), while `--physcpubind=C` pins exact cores; `--membind=N` allocates strictly on node N (OOM if it fills), `--preferred=N` is a soft preference that falls back, `--interleave=nodes` round-robins pages for bandwidth, and `--localalloc` allocates on whichever node faults the page. Critically, `numactl` only sets the *default policy inherited by the process and its children at allocation time* — it does **not** relocate pages already touched, so it must wrap the process from launch. For a feed handler, the latency-optimal default is co-located compute and memory (`--cpunodebind=0 --membind=0`), reserving `--interleave` for read-mostly structures whose access is uniform across threads.
**Key concepts:** --membind, --cpunodebind, --physcpubind, --preferred, --interleave, --localalloc, --show, first-touch interaction
**Tip:** `numactl --show` prints the *effective* policy of the current context — run it inside your launcher wrapper to confirm the policy actually applied before `exec`, since a policy set on a parent that already faulted its pages silently does nothing for that memory.
**Tool anchor:** `numactl --cpunodebind=0 --membind=0 --show ./md_feed`
**Drill:** Your handler must run on socket 0 with all hot allocations local, but a shared read-mostly instrument dictionary (accessed uniformly by all worker threads) bottlenecks one memory controller. Choose a per-structure policy — process-wide `--membind=0` plus an interleaved dictionary via `mbind(MPOL_INTERLEAVE)` — justify why a single global policy is wrong here, and show both the numactl invocation and the code-level placement.
**Tags:** numactl, membind, cpunodebind, interleave, first-touch, determinism

### Diagnosing NUMA imbalance: numastat, numa_maps, autonuma
`numastat -p <pid>` is the first stop: `numa_hit` (allocated on the intended node), `numa_miss`/`numa_foreign` (intended here but served elsewhere / vice-versa), and `other_node` (run here, memory elsewhere) reveal placement drift in a few lines. `/proc/<pid>/numa_maps` attributes per-VMA page residency to nodes, and `perf c2c` exposes cross-node HITM. The hidden variable is **AutoNUMA** (`kernel.numa_balancing=1`): it samples access via NUMA hinting faults and migrates pages toward the accessing node — helpful for throughput servers but a jitter source for a pinned hot path, because each migration is a hinting-fault stall plus a window of transient remote access. Low-latency shops set `numa_balancing=0` and place memory explicitly with `libnuma` (`numa_alloc_onnode`, `numa_run_on_node`, `set_mempolicy`, runtime `move_pages`), then verify the placement stuck.
**Key concepts:** numastat (numa_foreign/other_node), /proc/<pid>/numa_maps, kernel.numa_balancing, numa_alloc_onnode, move_pages, perf c2c
**Tip:** After pinning and placing memory, confirm `numastat -p` shows `other_node` ≈ 0 and that `cat /proc/sys/kernel/numa_balancing` is `0`; a nonzero `other_node` that *drifts over time* is the fingerprint of AutoNUMA fighting your explicit placement.
**Tool anchor:** `numastat -p $(pgrep md_feed); grep . /proc/sys/kernel/numa_balancing`
**Drill:** `numastat -p` on your handler shows 30% `other_node` and the figure creeps upward over minutes. Decide between a first-touch fix (initialize on the worker thread) and explicit `numa_alloc_onnode`/`mbind`, determine whether AutoNUMA is the cause, disable it if so, and show the before/after `numastat` you would expect.
**Tags:** numastat, numa_maps, autonuma, numa_balancing, libnuma, jitter

### Memory bandwidth saturation
Memory bandwidth is a finite shared resource (~50-80 GB/s per socket for DDR4). When multiple cores saturate it, individual thread throughput drops non-linearly. Measuring achieved bandwidth with the STREAM benchmark and comparing to theoretical peak reveals headroom. SIMD code that processes 256 or 512 bits per instruction can saturate bandwidth with fewer cores, making bandwidth the bottleneck before compute.
**Key concepts:** STREAM benchmark, achieved vs peak bandwidth, multi-channel DDR, bandwidth per core, SIMD bandwidth amplification
**Tip:** On a typical dual-channel DDR4-3200 system, peak bandwidth is ~51 GB/s, but a single core can typically sustain only ~12-15 GB/s; if your SBE decoder on one core streams through 10 GB/s of message data, you are already at 60-80% of single-core bandwidth capacity.
**Tool anchor:** `perf stat -e uncore_imc/data_reads/,uncore_imc/data_writes/ -a -- sleep 5` to measure actual DRAM bandwidth; or `bpftrace -e 'hardware:cache-misses:1000000 { @bw_proxy = count(); }'`
**Drill:** Your market data system processes 40 Gbps of raw network data. After UDP/IP stripping, ~30 Gbps of payload reaches the SBE decoder. The decoder reads each byte once and writes ~10 Gbps of decoded output. Calculate the total memory bandwidth demand (read + write), compare to your single-core bandwidth limit (~15 GB/s), and determine if bandwidth is the bottleneck.
**Tags:** bandwidth, STREAM, saturation, DDR4, uncore-counters

### Huge pages in practice
Transparent Huge Pages (THP) automatically promote 4KB pages to 2MB in the background, but can cause latency spikes during compaction (khugepaged). Explicit huge pages via `MAP_HUGETLB` or `madvise(MADV_HUGEPAGE)` are deterministic but require pre-allocation via `/sys/kernel/mm/hugepages`. For latency-sensitive market data applications, explicit huge pages avoid the compaction jitter of THP while providing 512x more TLB coverage per entry.
**Key concepts:** THP vs explicit, MAP_HUGETLB, MADV_HUGEPAGE, khugepaged compaction, /proc/meminfo HugePages, fragmentation
**Tip:** THP compaction (`khugepaged`) can stall an allocation for 1-10ms while it evacuates 512 small pages to form one huge page; for a feed handler that must respond in <10us, this is catastrophic, so disable THP and use explicit huge pages.
**Tool anchor:** `perf stat -e dTLB-load-misses,iTLB-load-misses,dtlb_load_misses.walk_active -- ./md_handler` and `grep -i huge /proc/meminfo`
**Drill:** Your feed handler uses a 256MB ring buffer with 4KB pages. perf shows dtlb_load_misses.walk_active is 15% of cycles. You switch to THP and the walk percentage drops to 0.3%, but p99.9 latency spikes from 20us to 8ms every ~30 seconds. Explain the tradeoff, identify khugepaged as the cause, and implement explicit huge page allocation with MAP_HUGETLB.
**Tags:** huge-pages, THP, MAP_HUGETLB, TLB, latency-spikes

### Cache partitioning (Intel CAT/MBA)
Intel Cache Allocation Technology (CAT) lets you assign cache ways to classes of service (CLOS), preventing noisy neighbors from evicting your hot data. Memory Bandwidth Allocation (MBA) similarly throttles bandwidth per-CLOS. For a market data handler sharing a server with logging, analytics, or other processes, CAT can reserve 4-8 L3 ways exclusively for the feed handler, guaranteeing its working set stays resident.
**Key concepts:** CLOS (Class of Service), CAT bitmask, MBA percentage, pqos/resctrl, noisy neighbor isolation
**Tip:** On a 20-way L3 (e.g. a 20-core Broadwell-EP Xeon with 2.5MB inclusive slices), reserving 8 ways (40%) for your feed handler via CAT guarantees ~20MB of dedicated L3 (from a 50MB total), preventing the analytics process from evicting order book data. (Note: post-Skylake-SP server L3 is 11-way per slice at 1.375MB/core, so a 27.5MB part exposes only 11 CAT ways, not 20.)
**Tool anchor:** `sudo pqos -s` to show current CAT/MBA configuration; `sudo pqos -e "llc:1=0x00FF;"` to assign 8 ways to CLOS 1; `sudo pqos -a "llc:1=$(pgrep md_handler)"`
**Drill:** Your market data handler and a log compression process share a 20-way 30MB L3. Without CAT, perf shows LLC-load-misses spike 3x when the compressor runs. Design a CAT configuration: assign 12 ways to the handler (CLOS 1), 6 ways to the compressor (CLOS 2), and 2 shared ways (CLOS 0). Write the pqos commands and calculate the MB guaranteed to each process.
**Tags:** CAT, MBA, cache-partitioning, CLOS, noisy-neighbor

### Memory ordering and store buffer (hardware view)
The store buffer decouples stores from the memory hierarchy for performance, but this creates a gap between program order and visibility order. x86 TSO (Total Store Order) guarantees loads are not reordered with other loads and stores are not reordered with other stores, but a load CAN read a stale value if a prior store to a different address has not yet drained. Machine clears from memory ordering violations (load speculation past a store to the same address) are expensive pipeline flushes; Intel's VTune impact model estimates ~500 cycles per event.
**Key concepts:** TSO, store buffer draining, load speculation, memory ordering machine clear, LFENCE/SFENCE/MFENCE
**Tip:** x86 TSO means you almost never need `std::atomic` fences between same-type operations, but a producer-consumer pattern where thread A stores data then stores a flag needs the flag store to be `std::memory_order_release` to prevent the compiler from reordering (the hardware already provides TSO ordering).
**Tool anchor:** `perf stat -e machine_clears.memory_ordering -- ./md_handler` to count ordering-violation pipeline flushes
**Drill:** Your lock-free SPSC queue for market data messages uses a shared `write_index` and `read_index`. The producer stores the message, then increments `write_index`. The consumer reads `write_index`, then reads the message. On x86 TSO, explain why this works without hardware fences, identify the scenario (non-x86 or compiler reordering) where it breaks, and show the correct `std::atomic` memory orders.
**Tags:** memory-ordering, TSO, store-buffer, machine-clear, lock-free

### Page coloring and cache index conflicts
On physically-indexed L3 caches, the physical address bits used for set indexing can cause systematic conflict misses depending on which physical pages the OS assigns. Page coloring is an OS technique that controls physical page allocation so that virtual pages that are accessed together do not map to the same cache sets. While modern Linux does not do explicit page coloring, understanding the phenomenon explains mysterious L3 miss patterns.
**Key concepts:** physical index bits, page color, 2^N stride conflicts, OS page allocator, cache set distribution
**Tip:** With a 16MB 16-way L3 and 64B lines, there are 16384 sets; the set index uses bits 6-19 of the physical address, but the OS controls only bits 12+ (page frame), so bits 6-11 are determined by the virtual offset within a page and are identical for same-offset accesses across different pages.
**Tool anchor:** `perf stat -e longest_lat_cache.miss,l2_rqsts.miss -- ./bench_page_conflict && perf stat -e longest_lat_cache.miss,l2_rqsts.miss -- ./bench_page_offset`
**Drill:** You allocate 1024 4KB pages and store a counter at offset 0 of each page. All counters share bits 6-11 = 000000, meaning they all map to the same L3 set modulo the remaining index bits. If 1024 pages span only 64 unique L3 set indices (determined by physical bits 12-19), and the L3 is 16-way, calculate the expected conflict miss rate and propose offsetting each counter by `i * 64` bytes.
**Tags:** page-coloring, cache-index, physical-address, conflict-miss, L3

### DRAM internals: rows, banks, channels, rank interleaving
DRAM is organized into channels, DIMMs, ranks, banks, rows, and columns. A row buffer hit (~15ns) is 3-5x faster than a row buffer miss (~50ns) because the miss requires a precharge-activate-read sequence. Bank conflicts occur when consecutive accesses target different rows in the same bank. Multi-channel interleaving distributes addresses across channels for bandwidth, but can create predictable bank conflict patterns with power-of-two strides.
**Key concepts:** row buffer hit/miss, precharge/activate/CAS, bank conflicts, channel interleaving, rank interleaving
**Tip:** Accessing an array with a stride equal to the row size (typically 8KB) causes every access to hit a different row in the same bank, forcing precharge-activate on every access and nearly tripling DRAM latency compared to sequential access that stays in the open row.
**Tool anchor:** `sudo perf stat -e uncore_imc/cas_count_read/,uncore_imc/cas_count_write/,uncore_imc/act_count/ -a -- sleep 5` to measure DRAM activations vs CAS commands (high act/cas ratio = row buffer misses)
**Drill:** Your order book rebuild reads 8,000 price levels from a flat array (16 bytes per level, 128KB total). Version A reads them sequentially. Version B reads them in a random permutation. With a DRAM row size of 8KB, calculate how many row buffer hits version A gets vs version B, and estimate the DRAM-level latency difference assuming row hit = 15ns and row miss = 50ns.
**Tags:** DRAM, row-buffer, bank-conflict, channel-interleaving, activate

### Snoop filters and directory-based coherence
In a multi-core system, cache coherence ensures all cores see a consistent view of memory. Snoop-based protocols (broadcast a snoop to all cores on every miss) do not scale beyond ~8 cores. Snoop filters track which cores cache which lines, reducing broadcast traffic. Directory-based protocols (used in mesh interconnects like Intel's post-Skylake) maintain a directory entry per cache line, enabling scalable coherence at the cost of directory storage and indirection latency.
**Key concepts:** snoop filter, directory-based coherence, MESIF protocol, mesh interconnect, scalability, home agent
**Tip:** On a mesh interconnect, a cache miss must first query the directory slice (determined by address hash) to find the home agent, then the home agent responds or redirects to the owning core; this adds 10-20ns of directory lookup latency that did not exist in ring-based topologies.
**Tool anchor:** `perf stat -e offcore_response.demand_data_rd.l3_miss.snoop_hitm,offcore_response.demand_data_rd.l3_miss.snoop_miss -p $(pgrep md_handler) -- sleep 10`
**Drill:** On a 28-core mesh Xeon, your feed handler on core 0 reads a cache line last written by the analytics thread on core 27. Trace the coherence protocol steps: directory lookup (which slice?), snoop to core 27, data transfer, and state transitions. Estimate the total latency assuming 10ns per mesh hop and the cores are 6 hops apart.
**Tags:** coherence, snoop-filter, directory, MESIF, mesh-interconnect

### Memory prefetch tuning for SBE message parsing
SBE (Simple Binary Encoding) messages have fixed-size headers and known field offsets, making them ideal for prefetch optimization. When processing messages from a ring buffer, the next message address is predictable (current + message_length). Batch prefetching multiple messages ahead while processing the current one overlaps decode compute with memory fetch. The optimal prefetch distance depends on message size, decode time, and cache hierarchy latencies.
**Key concepts:** fixed-stride prefetch, ring buffer patterns, batch prefetch, decode-fetch overlap, message framing
**Tip:** For 64-byte SBE messages decoded in ~30ns, prefetching 3 messages ahead (3 * 64 = 192 bytes, 3 cache lines) at L1 temporal gives the memory system ~90ns to fetch, comfortably covering an L3 miss; but for variable-length messages, prefetch the length field first, then the body.
**Tool anchor:** `perf stat -e L1-dcache-load-misses,l1d_pend_miss.pending_cycles -- ./sbe_decoder_no_prefetch < capture.pcap && perf stat -e L1-dcache-load-misses,l1d_pend_miss.pending_cycles -- ./sbe_decoder_prefetch < capture.pcap`
**Drill:** Your CME MDP 3.0 decoder processes messages from a 16MB ring buffer. Messages are 64-128 bytes. The decode loop currently processes one message at a time. The hot loop shows 6% L1 dcache misses with l1d_pend_miss.pending_cycles at 25%. Add `__builtin_prefetch` calls to prefetch N messages ahead. Calculate N for 64-byte messages with a 25ns decode time targeting L3 coverage (~40ns). Then handle the variable-length case.
**Tags:** SBE, prefetch-tuning, ring-buffer, CME-MDP, decode-optimization

### Measuring and profiling memory access patterns
Precise memory profiling uses PMU events like `mem_inst_retired.all_loads` with PEBS to record the address, latency, and data source (L1/L2/L3/DRAM/remote) of sampled loads. `perf mem record` captures this data and `perf mem report` shows a latency histogram broken down by cache level. Combined with `perf c2c` for sharing analysis and `numastat` for placement, this gives a complete picture of where memory time is spent.
**Key concepts:** PEBS load latency, data source (L1/L2/L3/LFB/DRAM), perf mem, load latency histogram, cache-line-level profiling
**Tip:** `perf mem record -t load` samples only loads with their latency; sorting by latency in `perf mem report --sort=mem,sym` immediately shows which symbols suffer the slowest memory accesses, pointing you to the exact function and data structure to optimize.
**Tool anchor:** `perf mem record -t load -p $(pgrep md_handler) -- sleep 30 && perf mem report --sort=mem,sym,dso --stdio | head -40`
**Drill:** You run `perf mem report` on your order book and see: 45% of sampled loads hit L1 (5ns), 20% hit L2 (12ns), 10% hit L3 (40ns), and 25% miss to DRAM (180ns). Calculate the weighted average load latency. The top symbol for DRAM misses is `OrderBook::findLevel`. The order book uses `std::unordered_map`. Propose a data structure change and predict the new latency distribution.
**Tags:** perf-mem, PEBS, load-latency, profiling, memory-access-pattern
