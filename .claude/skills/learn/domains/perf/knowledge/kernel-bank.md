# OS & Kernel Interaction Topic Bank
Updated: 2026-05-28

## beginner

### Syscall overhead and the vDSO
Every user-to-kernel transition via the SYSCALL instruction costs 100-200ns due to register saving, kernel stack switch, KPTI page table switch, and speculative execution mitigations. The vDSO (virtual dynamic shared object) maps a kernel-provided shared library into every process's address space, allowing functions like `clock_gettime()` and `gettimeofday()` to execute entirely in user space by reading a kernel-maintained page of timing data. For market data timestamping, the vDSO reduces clock reads from ~200ns to ~20ns, which compounds across millions of messages per second.
**Key concepts:** SYSCALL instruction, vDSO, clock_gettime, gettimeofday
**Tip:** Verify your libc is using the vDSO path by running `perf stat -e 'syscalls:sys_enter_clock_gettime' -- ./md_feed` for 10 seconds; if the count is near zero but your code calls `clock_gettime()` millions of times, the vDSO is working.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_clock_gettime /comm == "md_feed"/ { @count = count(); } interval:s:5 { print(@count); clear(@count); }'`
**Drill:** Your SBE decoder timestamps every message with `clock_gettime(CLOCK_MONOTONIC)`. Profile it and determine whether the calls go through the vDSO or hit the kernel. If they are hitting the kernel, identify why (wrong clock ID, kernel version, or platform) and fix it.
**Tags:** syscall, vDSO, clock_gettime, latency

### Context switches: voluntary vs involuntary
A context switch saves and restores CPU registers, TLB state, and pipeline state, costing 1-10us of direct overhead plus indirect costs from polluting L1/L2 caches and branch predictor state. Voluntary context switches occur when a thread blocks on I/O, a mutex, or calls `sched_yield()`; involuntary switches happen when the scheduler preempts a running thread because its time slice expired or a higher-priority thread woke up. For latency-critical market data paths, involuntary switches are the enemy because they are unpredictable and flush warm caches.
**Key concepts:** voluntary context switch, involuntary context switch, cache pollution, scheduler preemption
**Tip:** Check `/proc/<pid>/status` for `voluntary_ctxt_switches` and `nonvoluntary_ctxt_switches`; if involuntary switches exceed a few per second on an isolated core, something is wrong with your CPU isolation setup.
**Tool anchor:** `perf stat -e 'sched:sched_switch' -e context-switches -p $(pgrep md_feed) -- sleep 10`
**Drill:** Your feed handler pinned to core 3 shows 500 involuntary context switches per second. Identify the source using `perf sched record` and `perf sched timehist`, determine whether they come from kernel threads, IRQ handlers, or competing user threads, and propose a fix.
**Tags:** context-switch, scheduling, cache-pollution, latency

### Page faults: minor vs major
A minor page fault (~1us) occurs when a virtual page is valid but not yet mapped to a physical frame in the page table, typically on first access to a freshly `mmap`'d region or a heap allocation. A major page fault (~1ms+) occurs when the page must be read from disk (swap or memory-mapped file). For latency-sensitive applications, even minor faults on the hot path are unacceptable; pre-faulting memory with `mlock()` or `MAP_POPULATE` eliminates them at startup cost.
**Key concepts:** minor fault, major fault, mlock, MAP_POPULATE
**Tip:** Call `mlockall(MCL_CURRENT | MCL_FUTURE)` early in your process to pre-fault and pin all current and future pages, but ensure your `ulimit -l` is high enough or it will silently fail.
**Tool anchor:** `perf stat -e 'page-faults,minor-faults,major-faults' -p $(pgrep md_feed) -- sleep 30`
**Drill:** Your market data handler shows periodic 1-2ms latency spikes every few minutes. You suspect page faults. Use `perf record -e page-faults -g` to capture stacks during faults, identify whether they are minor or major, and trace them to the allocating code path. Propose a pre-faulting strategy.
**Tags:** page-fault, mlock, MAP_POPULATE, latency-spike

### User space vs kernel space boundary
x86-64 CPUs enforce privilege levels via ring 0 (kernel) and ring 3 (user). Crossing this boundary via the SYSCALL instruction triggers a mode switch that saves registers, switches stacks, and on KPTI-enabled kernels swaps page tables to mitigate Meltdown. Each direction of the crossing costs 50-100ns just for the hardware transition, before any kernel code executes. Understanding this cost explains why batching syscalls and using kernel bypass (DPDK, io_uring) yield such large performance gains.
**Key concepts:** ring 0, ring 3, SYSCALL instruction, KPTI, Meltdown mitigation
**Tip:** KPTI (Kernel Page Table Isolation) roughly doubles syscall entry/exit cost because it flushes TLB entries on every transition; check `dmesg | grep -i isolation` to see if it is enabled and `cat /sys/devices/system/cpu/vulnerabilities/meltdown` for the mitigation status.
**Tool anchor:** `bpftrace -e 'tracepoint:raw_syscalls:sys_enter /pid == cpid/ { @syscall_count[@args[1]] = count(); } interval:s:5 { print(@syscall_count); clear(@syscall_count); }' -c './md_feed'`
**Drill:** Benchmark `clock_gettime()` in a tight loop with and without KPTI enabled (boot with `nopti` kernel parameter on a test machine). Measure the per-call cost difference using `perf stat` and explain why production systems keep KPTI enabled despite the cost.
**Tags:** ring-0, ring-3, KPTI, Meltdown, syscall-cost

### File descriptor overhead and epoll
Each file descriptor is an index into the kernel's per-process FD table, which references an open file description with associated state. Legacy `select()` is O(n) on the FD set size per call, while `epoll` maintains a kernel-side interest list and returns only ready FDs, making it O(1) per event. Edge-triggered (`EPOLLET`) mode avoids redundant wakeups but requires draining the socket completely on each notification, which is critical for high-throughput multicast market data feeds.
**Key concepts:** FD table, select O(n), epoll O(1), edge-triggered, level-triggered
**Tip:** With level-triggered epoll and a busy multicast socket, `epoll_wait` will return immediately every time because data is always available; edge-triggered mode fires only on state transitions, reducing syscall rate by 10-100x on saturated feeds.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_epoll_wait /comm == "md_feed"/ { @calls = count(); } tracepoint:syscalls:sys_exit_epoll_wait /comm == "md_feed"/ { @ready_fds = hist(args->ret); }'`
**Drill:** Your market data feed handler uses level-triggered epoll on 20 multicast sockets receiving 5M packets/sec total. Profile the epoll_wait call frequency and its return values. Determine whether switching to edge-triggered mode would reduce syscall overhead, and identify the code changes required to drain sockets correctly.
**Tags:** epoll, file-descriptor, edge-triggered, level-triggered, multicast

### Process vs thread: kernel perspective
In Linux, both processes and threads are represented by `task_struct` and scheduled by the same scheduler. `clone()` with different flags controls what is shared: threads share address space (`CLONE_VM`), file descriptors (`CLONE_FILES`), and signal handlers (`CLONE_SIGHAND`), while processes get independent copies. From the kernel's perspective, a "thread" is just a task that shares its `mm_struct` with its parent, making context switches between threads cheaper because no TLB flush or page table switch is needed.
**Key concepts:** task_struct, clone() flags, CLONE_VM, shared mm_struct
**Tip:** Threads sharing the same `mm_struct` avoid TLB flushes on context switches between them, saving 1-5us per switch compared to switching between separate processes; this is why market data decoders use threads, not separate processes, for pipeline stages on the same core.
**Tool anchor:** `bpftrace -e 'tracepoint:sched:sched_switch /args->next_comm == "md_feed"/ { @from[args->prev_comm] = count(); }' `
**Drill:** You have two design options for your market data stack: a multi-threaded process with decoder, order book, and strategy threads, or three separate processes communicating via shared memory. Analyze the context-switch cost difference using `perf sched`, measure TLB miss rates with `perf stat -e dTLB-load-misses`, and recommend the better architecture for sub-10us latency.
**Tags:** task_struct, clone, thread, process, TLB

### Signal handling and its overhead
When the kernel delivers a signal, it saves the interrupted context onto the user stack (the `ucontext_t` sigframe), switches to the signal handler, and on return restores context via the `rt_sigreturn` syscall. This round-trip costs 2-5us and can preempt any code path unpredictably, including in the middle of lock-free data structures. For latency-critical paths, replacing signal-based notification with `signalfd()` or `eventfd()` converts asynchronous signal delivery into a pollable file descriptor.
**Key concepts:** signal delivery, ucontext_t, rt_sigreturn, signalfd, async-signal-safety
**Tip:** Only the functions on the POSIX async-signal-safe list (over 100, enumerated in `signal-safety(7)`) may be called from a signal handler; calling `malloc()`, `printf()`, or any mutex operation inside a signal handler causes undefined behavior. Use `signalfd()` to handle signals in your event loop instead.
**Tool anchor:** `bpftrace -e 'tracepoint:signal:signal_deliver /args->sig != 0 && args->sa_handler != 0/ { @[args->sig, comm] = count(); }'`
**Drill:** Your feed handler uses `SIGUSR1` to trigger a configuration reload, and you observe occasional 10us latency spikes that correlate with reload events. Trace signal delivery with bpftrace, measure the overhead of the signal handler round-trip, and refactor the reload mechanism to use `signalfd()` integrated with your epoll loop.
**Tags:** signal, signalfd, async-signal-safety, latency, eventfd

### /proc and /sys for performance observability
The `/proc` pseudo-filesystem exposes per-process and system-wide kernel data structures as readable files: `/proc/<pid>/stat` for CPU time, `/proc/<pid>/status` for memory and context switch counts, `/proc/<pid>/smaps` for per-mapping memory details, and `/proc/interrupts` for IRQ counts. `/sys/devices/system/cpu/` exposes CPU topology, frequency, and vulnerability mitigations. These files are the raw data source behind every monitoring tool and can be parsed with zero tool installation.
**Key concepts:** /proc/stat, /proc/status, /proc/smaps, /proc/interrupts, /sys/devices
**Tip:** Reading `/proc/<pid>/smaps` is expensive (kernel walks all VMAs under mmap_lock); use `/proc/<pid>/smaps_rollup` for aggregate RSS/PSS without the per-VMA overhead when you just need totals.
**Tool anchor:** `awk '/^voluntary_ctxt_switches|nonvoluntary_ctxt_switches|VmRSS|VmSwap|Threads/ {print}' /proc/$(pgrep md_feed)/status`
**Drill:** Without installing any tools, monitor your market data handler's RSS growth, context switch rate, and thread count over 60 seconds by polling /proc files. Write a shell loop that captures these metrics every second and identify any anomalies in the output.
**Tags:** proc-filesystem, sys-filesystem, observability, monitoring

## intermediate

### CPU affinity and isolcpus
`taskset` and `pthread_setaffinity_np()` pin threads to specific CPU cores, but without kernel cooperation, kernel threads, interrupts, and timers still run on those cores. The `isolcpus` boot parameter removes cores from the scheduler's general-purpose pool, while `irqaffinity` steers hardware interrupts away. Together, they create truly dedicated cores where your market data thread is the only code running, eliminating involuntary preemption and cache pollution from unrelated work.
**Key concepts:** taskset, pthread_setaffinity_np, isolcpus, irqaffinity
**Tip:** `isolcpus` alone is not sufficient: check `/proc/interrupts` after isolation to verify no IRQs are still targeting your isolated cores, and use `tuna --cpus=3 --isolate` to also move kernel threads away.
**Tool anchor:** `bpftrace -e 'tracepoint:sched:sched_switch /cpu == 3/ { @[args->next_comm] = count(); }' ` 
**Drill:** Pin your SBE decoder to core 3 with `taskset -c 3`, then use bpftrace to monitor everything that runs on core 3 for 30 seconds. Identify non-application tasks, IRQ handlers, and kernel threads that contaminate the core, then apply `isolcpus=3` and compare the results.
**Tags:** CPU-affinity, isolcpus, irqaffinity, core-pinning, latency

### CFS and EEVDF schedulers
CFS (Completely Fair Scheduler) uses per-task `vruntime` to ensure fair CPU time distribution, but "fair" means latency-critical threads can be preempted by unimportant ones with lower vruntime. Linux 6.6+ replaces CFS with EEVDF (Earliest Eligible Virtual Deadline First), which adds deadline awareness to improve latency for interactive and short-running tasks. For deterministic scheduling, `SCHED_FIFO` (real-time policy) bypasses both schedulers entirely, running the thread until it blocks or a higher-priority FIFO thread arrives.
**Key concepts:** vruntime, EEVDF, SCHED_FIFO, scheduling policy, priority
**Tip:** Setting `SCHED_FIFO` priority 50 for your feed handler thread guarantees it preempts all CFS tasks, but if it enters an infinite loop it will lock the core permanently; always pair with a watchdog on another core.
**Tool anchor:** `bpftrace -e 'tracepoint:sched:sched_switch /args->prev_comm == "md_feed"/ { @preempted_by[args->next_comm] = count(); @latency_ns = hist(nsecs - @wakeup[args->prev_pid]); }'`
**Drill:** Your feed handler runs under the default CFS policy and experiences occasional 50-100us scheduling delays. Switch it to `SCHED_FIFO` with `chrt -f 50` and measure the change in scheduling latency with `perf sched timehist`. Compare involuntary context switch counts before and after.
**Tags:** CFS, EEVDF, SCHED_FIFO, scheduling-policy, vruntime

### Interrupts and softirqs
Hardware interrupts (top-half) preempt all user-space and most kernel code to service device events with minimal latency. The kernel defers expensive processing to softirqs (bottom-half): network packet processing via `NET_RX_SOFTIRQ`, timer callbacks via `TIMER_SOFTIRQ`, and block I/O completion. On a busy NIC, softirq processing can consume entire cores via `ksoftirqd` threads, and if a softirq runs on your latency-critical core, it steals cycles unpredictably.
**Key concepts:** hardware IRQ, softirq, ksoftirqd, NET_RX_SOFTIRQ, IRQ affinity
**Tip:** Use `/proc/softirqs` to see cumulative softirq counts per CPU; if `NET_RX` softirqs concentrate on your isolated core, the NIC's RSS (Receive Side Scaling) hash is directing queues there. Fix with `ethtool -X` or `/proc/irq/<N>/smp_affinity`.
**Tool anchor:** `bpftrace -e 'tracepoint:irq:softirq_entry /cpu == 3/ { @start[cpu] = nsecs; @type[args->vec] = count(); } tracepoint:irq:softirq_exit /cpu == 3/ { @duration_us = hist((nsecs - @start[cpu]) / 1000); }'`
**Drill:** Your feed handler on core 3 shows periodic 100us latency spikes. Profile softirq activity on core 3 using bpftrace, identify which softirq type is firing, measure its duration, and steer the responsible IRQ to a different core using `/proc/irq/*/smp_affinity`.
**Tags:** interrupt, softirq, ksoftirqd, IRQ-affinity, NET_RX

### Huge pages configuration
Standard 4KB pages require a 4-level page table walk on TLB miss (~7ns per level), and with a 50MB working set, that is 12,800 pages competing for ~1,500 TLB entries. 2MB huge pages reduce the page count by 512x, dramatically lowering TLB miss rates. Explicit huge pages via `hugetlbfs` and `mmap(MAP_HUGETLB)` are deterministic, while Transparent Huge Pages (THP) promote pages opportunistically but can cause compaction stalls. Market data applications with large order books benefit enormously from explicit huge pages.
**Key concepts:** TLB miss, 2MB huge page, 1GB huge page, hugetlbfs, MAP_HUGETLB
**Tip:** Reserve huge pages at boot time via `hugepages=512` kernel parameter, not at runtime via `vm.nr_hugepages`, because runtime allocation may fail due to memory fragmentation even when there is plenty of free RAM.
**Tool anchor:** `perf stat -e 'dTLB-load-misses,dTLB-store-misses,iTLB-load-misses' -p $(pgrep md_feed) -- sleep 10`
**Drill:** Your order book engine processes 2M updates/sec and accesses a 200MB flat hash map. Measure TLB miss rates with `perf stat`, then allocate the hash map on explicit 2MB huge pages using `mmap(MAP_HUGETLB)`. Compare TLB miss rates before and after and calculate the latency improvement.
**Tags:** huge-pages, TLB, hugetlbfs, MAP_HUGETLB, THP

### Memory-mapped I/O and DMA
Memory-Mapped I/O (MMIO) maps device registers into the CPU's physical address space, allowing device control via regular load/store instructions instead of special I/O port instructions. DMA (Direct Memory Access) allows devices to read/write system memory without CPU involvement, freeing the CPU for computation while the NIC transfers packets into pre-allocated ring buffers. The IOMMU provides address translation and isolation for DMA, preventing devices from accessing arbitrary physical memory.
**Key concepts:** MMIO, DMA, ring buffer, IOMMU, bus mastering
**Tip:** DMA transfers require physically contiguous memory; if the kernel cannot allocate large contiguous regions at runtime, pre-allocate DMA buffers at boot time with `memmap=` or CMA (Contiguous Memory Allocator) to avoid allocation failures under pressure.
**Tool anchor:** `bpftrace -e 'tracepoint:dma:dma_map_page { @size = hist(args->size); @direction[args->direction] = count(); }'`
**Drill:** Your NIC uses DMA to deliver multicast market data packets into kernel ring buffers. Trace DMA mapping events with bpftrace to measure the size and frequency of DMA transfers. Compare this overhead with the CPU cycles saved by not copying data through the CPU, and explain when DMA becomes less efficient than programmed I/O for small packets.
**Tags:** MMIO, DMA, IOMMU, ring-buffer, NIC

### Kernel bypass: DPDK and AF_XDP
DPDK's poll-mode drivers map NIC hardware registers and DMA ring buffers directly into user space, eliminating all kernel involvement in the packet receive path. AF_XDP provides a lighter-weight bypass by using the kernel's XDP (eXpress Data Path) framework to redirect packets to user-space ring buffers while keeping the kernel's driver model. For multicast market data, DPDK eliminates the 5-15us kernel network stack latency entirely, reducing wire-to-application latency to under 1us.
**Key concepts:** poll-mode driver, zero-copy, DPDK EAL, AF_XDP, XDP redirect
**Tip:** DPDK dedicates an entire core to polling the NIC (100% CPU utilization by design); this is not waste but a deliberate trade of one core's compute for deterministic sub-microsecond packet delivery latency.
**Tool anchor:** `bpftrace -e 'tracepoint:xdp:xdp_redirect /args->act == 4/ { @redirected = count(); } interval:s:1 { print(@redirected); clear(@redirected); }'`
**Drill:** Compare three receive paths for a 10Gbps CME multicast feed: (1) standard socket with `recvmsg()`, (2) AF_XDP with zero-copy, (3) DPDK poll-mode driver. Measure per-packet latency overhead for each using timestamping at NIC vs application, and justify which approach your infrastructure supports.
**Tags:** DPDK, AF_XDP, kernel-bypass, poll-mode, zero-copy

### cgroups and resource limits
cgroups v2 provides hierarchical resource control for CPU (`cpu.max` for bandwidth limiting, `cpu.weight` for proportional sharing), memory (`memory.max`, `memory.high`), I/O (`io.max`), and CPU set isolation (`cpuset.cpus`). While essential for multi-tenant systems, cgroups introduce overhead: the CPU bandwidth controller enforces quota over a 100ms period by default (`cpu.max` period; run-time is doled out to per-CPU silos in 5ms slices set by `sched_cfs_bandwidth_slice_us`), and memory accounting adds atomic counter updates on every allocation. For latency-critical workloads, misconfigured cgroups are a hidden source of throttling.
**Key concepts:** cgroups v2, cpu.max, memory.max, cpuset, throttling
**Tip:** Check `/sys/fs/cgroup/<your-group>/cpu.stat` for `nr_throttled` and `throttled_usec`; if your feed handler shows any throttling, either raise `cpu.max` or move it to an unrestricted cgroup.
**Tool anchor:** `bpftrace -e 'kprobe:throttle_cfs_rq { @throttles[cgroup] = count(); }'` (there is no `cgroup:cgroup_throttled` tracepoint; CFS throttling is hit via the `throttle_cfs_rq()` scheduler function or read from `cpu.stat`)
**Drill:** Your market data handler in a container occasionally experiences 5ms latency spikes. Investigate whether cgroup CPU throttling is the cause by checking `cpu.stat` for throttling events, then adjust `cpu.max` or move the handler to a dedicated cpuset to eliminate contention.
**Tags:** cgroups, throttling, cpu-max, cpuset, container

### CPU frequency scaling and governors
The CPU frequency governor dynamically adjusts clock speed to balance performance and power consumption. The `powersave` governor runs at minimum frequency and ramps up reactively (100-200us transition latency), while `performance` locks at maximum frequency with no transition overhead. The `intel_pstate` driver in `active` mode handles frequency transitions in hardware (HWP) with lower latency than software governors. For latency-critical applications, frequency ramp-up during idle-to-busy transitions adds jitter.
**Key concepts:** performance governor, powersave, intel_pstate, HWP, frequency transition latency
**Tip:** Even with the `performance` governor, turbo boost can cause frequency variation between cores; disable turbo with `echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo` for maximum determinism at the cost of peak throughput.
**Tool anchor:** `bpftrace -e 'tracepoint:power:cpu_frequency /cpu == 3/ { @freq = hist(args->state); }' `
**Drill:** Your feed handler on core 3 shows bimodal latency: most messages process in 3us, but 5% take 8us. Trace CPU frequency on core 3 and correlate with message processing latency. Determine whether frequency scaling is the cause and configure the governor for deterministic performance.
**Tags:** CPU-frequency, governor, intel_pstate, turbo-boost, latency-jitter

### Network stack overhead and kernel bypass
A packet arriving at the NIC traverses: driver interrupt, NAPI softirq poll, GRO aggregation, protocol stack (IP/UDP), socket buffer allocation, and copy to user space via `recvmsg()`. Each layer adds latency and CPU cycles. `SO_BUSY_POLL` reduces latency by spinning in the kernel for new packets instead of sleeping, while XDP (eXpress Data Path) hooks into the driver's NAPI poll loop to process or redirect packets before the full stack runs.
**Key concepts:** NAPI, GRO, socket buffer, SO_BUSY_POLL, XDP
**Tip:** Set `SO_BUSY_POLL` to 50us on your multicast socket to avoid the 5-20us latency of going through the sleep/wakeup path; the cost is ~50us of CPU spinning per epoll_wait call, which is worthwhile for feeds with high message rates.
**Tool anchor:** `bpftrace -e 'kprobe:__netif_receive_skb_core { @start[arg0] = nsecs; } kprobe:sock_recvmsg { @stack_latency_us = hist((nsecs - @start[tid]) / 1000); }'`
**Drill:** Measure end-to-end kernel network stack latency for your CME multicast feed using tracepoints from NIC driver to `recvmsg()` completion. Then enable `SO_BUSY_POLL` and re-measure. Quantify the improvement and identify which layer of the stack contributed the most latency.
**Tags:** network-stack, SO_BUSY_POLL, XDP, NAPI, GRO

### Transparent Huge Pages: benefits and pitfalls
THP automatically promotes 4KB pages into 2MB huge pages, reducing TLB misses without application changes. However, the `khugepaged` kernel thread scans for promotion opportunities and can trigger memory compaction, which involves moving pages to create contiguous 2MB regions. Compaction holds the `mmap_lock`, stalling all page faults and `mmap`/`munmap` calls for the process. THP's `defrag` setting controls how aggressively the kernel compacts: `always` blocks allocations for compaction, `madvise` only promotes pages explicitly requested, and `never` disables THP.
**Key concepts:** khugepaged, compaction stalls, defrag modes, madvise, mmap_lock
**Tip:** Set THP to `madvise` mode and use `madvise(MADV_HUGEPAGE)` only on your large data structures (order books, hash maps); this gets THP benefits without the compaction stalls that `always` mode causes on the hot path.
**Tool anchor:** `perf stat -e 'compaction:mm_compaction_begin,compaction:mm_compaction_end' -a -- sleep 60`
**Drill:** Your market data system experiences 2-10ms latency spikes every few minutes. Correlate spikes with compaction events using perf tracepoints, check `/proc/vmstat` for `compact_stall` incrementing, and switch THP from `always` to `madvise` mode. Verify the spikes disappear and TLB miss rates remain low for your pre-advised regions.
**Tags:** THP, compaction, khugepaged, madvise, latency-spike

### Timer resolution and high-resolution timers
The default Linux timer tick (250Hz or 1000Hz) limits `nanosleep()` and timer precision to 1-4ms. High-resolution timers (`hrtimer`) bypass the tick and use per-CPU hardware timers (LAPIC, HPET) to achieve nanosecond resolution. `timerfd_create()` with `CLOCK_MONOTONIC` provides an epoll-compatible timer FD that fires with hrtimer precision, while `timer_create()` delivers timer signals. For market data applications that need periodic processing (e.g., heartbeat checks, batched updates), hrtimer-based timers provide precise wakeups.
**Key concepts:** hrtimer, timerfd, timer_create, HZ, LAPIC
**Tip:** `nanosleep()` for durations under 2ms will be rounded up to the next tick boundary unless `CONFIG_HIGH_RES_TIMERS=y` is enabled; verify with `cat /sys/devices/system/clocksource/clocksource0/available_clocksource` and check `dmesg | grep -i hrtimer`.
**Tool anchor:** `bpftrace -e 'kprobe:hrtimer_start { @timers[kstack(3)] = count(); } interval:s:5 { print(@timers); clear(@timers); }'`
**Drill:** Your feed handler uses a 100us periodic timer via `timerfd_create()` for batched order book snapshots. Measure actual timer accuracy by recording timestamps at each wakeup and computing the jitter histogram. If jitter exceeds 10us, diagnose whether the issue is timer resolution, scheduling delay, or interrupt interference.
**Tags:** hrtimer, timerfd, timer-resolution, nanosleep, HZ

### Kernel memory allocation: slab and SLUB
The kernel uses slab allocation to efficiently manage frequently allocated fixed-size objects (socket buffers, inodes, task_structs). The SLUB allocator (default since Linux 2.6.23) maintains per-CPU freelists for lock-free fast-path allocation and falls back to per-node partial lists under pressure. Monitoring `/proc/slabinfo` reveals cache sizes, active objects, and per-CPU slab counts, while `slabtop` provides a real-time view. For high-throughput networking, `skbuff_head_cache` and `kmalloc-*` slab utilization directly affects packet processing performance.
**Key concepts:** slab cache, SLUB allocator, per-CPU freelist, kmalloc, skbuff_head_cache
**Tip:** If `slabtop` shows `skbuff_head_cache` growing continuously, you have a socket buffer leak, usually from packets being queued faster than your application consumes them; check your socket receive buffer with `ss -m`.
**Tool anchor:** `bpftrace -e 'tracepoint:kmem:kmalloc /args->bytes_alloc > 4096/ { @large_allocs[kstack(5)] = count(); }'`
**Drill:** Under heavy multicast load, your system's SLUB allocator starts hitting the slow path. Monitor `skbuff_head_cache` in `/proc/slabinfo`, trace large kernel allocations with bpftrace, and correlate with packet drop counters in `ethtool -S` to determine whether the kernel is running out of slab objects.
**Tags:** slab, SLUB, kmalloc, skbuff, kernel-memory

## advanced

### TSC and clock sources
The Time Stamp Counter (TSC) is a per-CPU register incremented at a constant rate on modern CPUs with `constant_tsc` and `nonstop_tsc` flags. `rdtsc` reads it in ~20 cycles without a syscall, while `rdtscp` adds the CPU ID to detect cross-core migration. `CLOCK_MONOTONIC_RAW` in `clock_gettime()` reads the TSC without NTP adjustments, providing the most consistent timestamps for latency measurement. The kernel selects the best clocksource (`tsc` > `hpet` > `acpi_pm`) and the vDSO reads it from user space.
**Key concepts:** TSC, rdtsc, rdtscp, constant_tsc, CLOCK_MONOTONIC_RAW
**Tip:** Always use `rdtscp` (not `rdtsc`) for benchmarking because `rdtscp` is serializing on the read side, preventing out-of-order execution from reordering your timestamp read before the code you are measuring; pair with `lfence` before the first `rdtscp` for full serialization.
**Tool anchor:** `perf stat -e 'cycles:u' -e 'ref-cycles' -- taskset -c 3 ./tsc_bench` 
**Drill:** Write a C++ micro-benchmark that uses `rdtscp` to measure the latency of your SBE decode function. Handle the case where the thread migrates between cores mid-measurement (detect via the CPU ID from `rdtscp`). Compare results with `CLOCK_MONOTONIC_RAW` and explain the precision tradeoff.
**Tags:** TSC, rdtsc, rdtscp, clocksource, CLOCK_MONOTONIC_RAW

### io_uring for async I/O
io_uring provides a shared-memory submission queue (SQ) and completion queue (CQ) between user space and kernel, eliminating syscall overhead for I/O operations. Submissions are batched into the SQ ring, the kernel processes them asynchronously, and completions appear in the CQ ring without waking the application unless requested. Registered buffers and fixed files avoid per-operation kernel lookups. For market data logging and persistence, io_uring can write to disk without blocking the hot path.
**Key concepts:** submission queue, completion queue, io_uring_enter, registered buffers, fixed files
**Tip:** Use `IORING_SETUP_SQPOLL` to have a kernel thread poll the SQ, eliminating even the `io_uring_enter()` syscall; the kernel thread burns one core but provides zero-syscall I/O submission for your application.
**Tool anchor:** `bpftrace -e 'tracepoint:io_uring:io_uring_submit_req /comm == "md_feed"/ { @op[args->opcode] = count(); } tracepoint:io_uring:io_uring_complete { @latency_us = hist((nsecs - @submit_time[args->user_data]) / 1000); }'` (tracepoint was `io_uring_submit_sqe` before Linux 6.0)
**Drill:** Your market data handler logs every message to a file using synchronous `write()`, adding 2-5us to the hot path. Refactor to use io_uring with registered buffers and `IORING_SETUP_SQPOLL`. Measure the write latency before and after using bpftrace, and verify that SQ polling eliminates `io_uring_enter` syscalls.
**Tags:** io_uring, async-IO, SQ-poll, registered-buffers, zero-syscall

### Kernel preemption models and PREEMPT_RT
Linux supports three preemption models: `PREEMPT_NONE` (server, only voluntary preemption points), `PREEMPT_VOLUNTARY` (desktop, adds explicit preemption checks), and `PREEMPT` (the "Preemptible Kernel (Low-Latency Desktop)" Kconfig symbol, called "full" by `PREEMPT_DYNAMIC`'s `preempt=full` boot option — preempts anywhere except critical sections). The `PREEMPT_RT` patch set converts spinlocks to mutexes, makes interrupt handlers threaded (schedulable), and makes most kernel code preemptible, reducing worst-case kernel latency from milliseconds to tens of microseconds.
**Key concepts:** PREEMPT_NONE, PREEMPT_VOLUNTARY, PREEMPT (preempt=full), PREEMPT_RT, threaded interrupts
**Tip:** PREEMPT_RT reduces worst-case latency but increases average latency by 5-10% due to priority inheritance overhead on every lock acquisition; for market data systems that care about p99.9, this tradeoff is usually worth it.
**Tool anchor:** `bpftrace -e 'tracepoint:preemptirq:irq_disable { @start[tid] = nsecs; } tracepoint:preemptirq:irq_enable { @irq_off_us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'`
**Drill:** On a PREEMPT_NONE kernel, measure the longest non-preemptible section using the preemptirq tracepoints. Compare with the same measurement on a PREEMPT_RT kernel. Identify the kernel code path responsible for the worst-case non-preemptible duration and explain how PREEMPT_RT addresses it.
**Tags:** PREEMPT_RT, preemption-model, threaded-interrupts, worst-case-latency, real-time

### NOHZ_FULL and adaptive ticks
By default, the kernel sends periodic timer interrupts (ticks) to every CPU at HZ frequency (100-1000Hz) for scheduler accounting and timer expiry. `nohz_full=` boot parameter enables adaptive ticks on specified CPUs, stopping the periodic tick when only one runnable task exists on the core. This eliminates 1000 interruptions per second (at HZ=1000), each costing 1-5us of jitter. Combined with `isolcpus` and `rcu_nocbs`, it creates a nearly interrupt-free environment for latency-critical threads.
**Key concepts:** nohz_full, adaptive ticks, tick-free core, rcu_nocbs, jitter elimination
**Tip:** `nohz_full` only stops ticks when exactly one runnable task is on the core; if your isolated core has two threads (even a kernel thread), ticks resume. Verify with `perf stat -e 'irq_vectors:local_timer_entry' -C 3 -- sleep 10` that tick count is near zero.
**Tool anchor:** `bpftrace -e 'tracepoint:irq_vectors:local_timer_entry /cpu == 3/ { @tick_count = count(); } interval:s:5 { printf("ticks on core 3 in 5s: %d\n", @tick_count); @tick_count = 0; }'`
**Drill:** Configure `nohz_full=3` and `rcu_nocbs=3` in your kernel boot parameters, pin your feed handler to core 3, and measure tick frequency on that core before and after. If ticks do not stop, diagnose the cause using `/proc/sched_debug` to find stray runnable tasks on core 3.
**Tags:** nohz_full, adaptive-ticks, rcu_nocbs, tick-free, jitter

### RCU (Read-Copy-Update) in the kernel
RCU enables lock-free read-side access to shared kernel data structures by deferring destruction of old versions until all readers have completed. Read-side critical sections (`rcu_read_lock()`/`rcu_read_unlock()`) have near-zero overhead (just preemption disable on non-PREEMPT_RT kernels), while writers use `synchronize_rcu()` or `call_rcu()` to wait for grace periods. RCU callbacks run in softirq or dedicated `rcuog`/`rcuop` kernel threads, and stalls (reported in dmesg) indicate a CPU stuck in a read-side critical section.
**Key concepts:** grace period, rcu_read_lock, call_rcu, RCU stall, rcuog/rcuop threads
**Tip:** If `dmesg` shows "rcu: rcu_preempt detected stalls on CPUs/tasks", your application or a kernel module is holding an RCU read-side lock for too long (>21 seconds by default). On isolated cores with `rcu_nocbs`, the RCU callback thread runs on a housekeeping CPU instead.
**Tool anchor:** `bpftrace -e 'tracepoint:rcu:rcu_utilization { @[probe, str(args->s)] = count(); } interval:s:10 { print(@); clear(@); }'`
**Drill:** Your system logs an RCU stall warning on core 3 where your feed handler runs. Trace RCU grace period activity with bpftrace, check whether `rcu_nocbs=3` is properly configured, and verify that no RCU callbacks are executing on the isolated core by monitoring `rcuop` thread affinity.
**Tags:** RCU, grace-period, rcu_nocbs, RCU-stall, lock-free

### Memory compaction and fragmentation
The buddy allocator manages free pages in power-of-2 block sizes (order 0 = 4KB through order 10 = 4MB). Over time, free memory fragments into small blocks, making high-order allocations (needed for huge pages, DMA buffers, and kernel stacks) fail. The compaction daemon (`kcompactd`) and direct compaction migrate pages to create contiguous free regions, but this process holds locks and can stall allocating threads for milliseconds. Anti-fragmentation groups (movable, unmovable, reclaimable) mitigate fragmentation by grouping similar pages.
**Key concepts:** buddy allocator, free page orders, kcompactd, direct compaction, anti-fragmentation
**Tip:** Monitor `/proc/buddyinfo` to see free page counts at each order; if order-9 (2MB) free count drops to zero, huge page allocations will trigger direct compaction. Pre-allocate huge pages at boot before fragmentation develops.
**Tool anchor:** `bpftrace -e 'tracepoint:compaction:mm_compaction_begin { @start[tid] = nsecs; } tracepoint:compaction:mm_compaction_end { @compaction_us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'`
**Drill:** Your production system has been running for 30 days and can no longer allocate 2MB huge pages despite having 20GB free. Examine `/proc/buddyinfo` to diagnose fragmentation, measure compaction stall duration with bpftrace, and design a strategy to prevent this scenario (boot-time reservation, zone layout, or periodic manual compaction during maintenance windows).
**Tags:** buddy-allocator, compaction, fragmentation, kcompactd, buddyinfo

### BPF CO-RE and libbpf for portable tracing
Traditional BPF programs require kernel headers matching the running kernel, making deployment across different kernel versions fragile. CO-RE (Compile Once, Run Everywhere) uses BTF (BPF Type Format) type information embedded in the kernel to relocate struct field accesses at load time. libbpf handles the relocation, and `vmlinux.h` (generated from BTF) replaces kernel headers. This enables shipping pre-compiled BPF programs as part of your monitoring infrastructure without per-kernel compilation.
**Key concepts:** CO-RE, BTF, vmlinux.h, libbpf, field relocation
**Tip:** Generate `vmlinux.h` from your running kernel with `bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h`; this single header replaces all kernel headers for BPF programs and adapts to your kernel's exact struct layouts.
**Tool anchor:** `bpftool btf dump file /sys/kernel/btf/vmlinux format c > vmlinux.h && clang -O2 -target bpf -c trace_feed.bpf.c -o trace_feed.bpf.o`
**Drill:** Write a libbpf-based CO-RE program that traces context switches on your isolated core, capturing the previous and next task names. Compile it once and deploy it on two servers running different kernel versions (e.g., 5.15 and 6.6). Verify that BTF relocations handle struct layout differences automatically.
**Tags:** CO-RE, BTF, libbpf, vmlinux.h, portable-tracing

### Kernel lockdep and lock contention analysis
The lockdep validator (enabled with `CONFIG_PROVE_LOCKING`) dynamically verifies lock ordering at runtime, detecting potential deadlocks before they occur by building a lock dependency graph. For contention analysis, `perf lock record` traces lock acquire/release events and `perf lock report` shows per-lock contention counts, wait times, and hold times. `/proc/lock_stat` (requires `CONFIG_LOCK_STAT`) provides cumulative lock statistics without the overhead of tracing.
**Key concepts:** lockdep, lock ordering, perf lock, /proc/lock_stat, contention analysis
**Tip:** `perf lock contention` (perf 5.19+) uses BPF to trace lock contention with low overhead and shows the exact stack traces of both the holder and the waiter, pinpointing where your threads fight over shared state.
**Tool anchor:** `perf lock contention -p $(pgrep md_feed) -- sleep 10`
**Drill:** Your multi-threaded market data handler has a mutex protecting the order book that shows increasing contention under load. Use `perf lock contention` to measure wait time distribution, identify the hot lock, capture holder and waiter stacks, and evaluate whether switching to a reader-writer lock or lock-free design would reduce contention.
**Tags:** lockdep, lock-contention, perf-lock, lock_stat, deadlock-detection

### perf_event_open and the PMU driver
`perf_event_open()` is the Linux syscall underlying all `perf` tool functionality. It configures a PMU (Performance Monitoring Unit) event by specifying the event type, config bits (event select + umask), sampling parameters, and output ring buffer. The returned FD can be `mmap()`'d for zero-copy sample access and `ioctl()`'d for enable/disable/reset. Writing custom tools on top of `perf_event_open` provides maximum control over PMC programming, sampling behavior, and data consumption without `perf` tool limitations.
**Key concepts:** perf_event_open, perf_event_attr, PMU driver, mmap ring buffer, ioctl control
**Tip:** Set `PERF_FORMAT_GROUP` in the leader's `read_format` to atomically read all group members' counts in one `read()` call, avoiding the multiplexing skew that `perf stat` introduces when reading events sequentially.
**Tool anchor:** `bpftrace -e 'tracepoint:perf:perf_event_open { @events[args->type, args->config] = count(); }'`
**Drill:** Write a C++ program that uses `perf_event_open()` to create a grouped event set (cycles, instructions, cache-misses) on a specific core, enables counting for 1 second, and reads the results. Compare the output with `perf stat` and explain the advantages of the direct syscall approach for embedding PMC reading into your feed handler's monitoring loop.
**Tags:** perf_event_open, PMU, perf_event_attr, mmap-ring-buffer, custom-tooling

### Building a low-latency kernel configuration
A comprehensive low-latency kernel setup combines multiple features: `isolcpus=3` removes cores from the scheduler, `nohz_full=3` stops timer ticks, `rcu_nocbs=3` offloads RCU callbacks, `irqaffinity=0-2` steers interrupts away, `intel_pstate=disable` with `performance` governor pins frequency, `transparent_hugepage=madvise` prevents compaction stalls, and `skew_tick=1` offsets timer interrupts across cores. Each parameter addresses a specific jitter source, and they must be configured together for the combined effect.
**Key concepts:** isolcpus, nohz_full, rcu_nocbs, irqaffinity, tuned profiles
**Tip:** Use `tuned` with the `latency-performance` or `network-latency` profile as a starting point, then customize: `tuned-adm profile network-latency` sets sysctl knobs, CPU governor, and IRQ balance, but you still need boot parameters for `isolcpus`/`nohz_full`/`rcu_nocbs` since `tuned` cannot configure those at runtime.
**Tool anchor:** `bpftrace -e 'tracepoint:irq_vectors:local_timer_entry /cpu == 3/ { @ticks = count(); } tracepoint:sched:sched_switch /cpu == 3/ { @switches[args->next_comm] = count(); } interval:s:10 { print(@ticks); print(@switches); clear(@ticks); clear(@switches); }'`
**Drill:** Starting from a stock kernel, apply the full low-latency parameter set to core 3 for your feed handler. At each step (isolcpus, nohz_full, rcu_nocbs, irqaffinity, governor, THP), measure the remaining jitter sources on core 3 with bpftrace. Produce a before/after comparison showing ticks/sec, context switches/sec, and IRQ count reduction at each stage.
**Tags:** low-latency-kernel, isolcpus, nohz_full, rcu_nocbs, irqaffinity, tuned
