# Profiling Methodology Topic Bank
Updated: 2026-05-28

## beginner

### The USE method for system resources
A systematic framework for checking every resource (CPU, memory, network, disk) for three signals: Utilization (how busy), Saturation (queue depth / backlog), and Errors (fault counts). Instead of randomly poking at metrics, USE gives you a checklist that catches problems you would otherwise miss. For a market data path, saturated NICs or error-ridden receive queues are invisible unless you look.
**Key concepts:** utilization, saturation, errors, resource-oriented analysis
**Tip:** Saturation is the metric most engineers skip, but it is the one that explains latency spikes: a CPU at 70% utilization can still have a run-queue depth of 4 if two cores are pinned.
**Tool anchor:** `perf stat -e 'sched:sched_switch' -a -- sleep 5` to check CPU saturation via context-switch rate; pair with `sar -n EDEV 1 5` for NIC errors
**Drill:** Given mpstat, vmstat, and ethtool -S output for a system running an SBE decoder, identify which resource is saturated and which shows errors; classify each finding as U, S, or E.
**Tags:** USE-method, methodology, systematic, resource-analysis

### Flame graphs: reading and generating
Flame graphs visualize sampled stack traces so the widest boxes reveal where CPU time is spent. Understanding the x-axis (alphabetical, not time) and y-axis (stack depth) prevents common misreadings. Generating them from `perf script` output through Brendan Gregg's stackcollapse/flamegraph.pl pipeline is the standard workflow.
**Key concepts:** stack sampling, frame folding, width-proportional-to-samples, alphabetical x-axis
**Tip:** The x-axis is sorted alphabetically, not chronologically, so two adjacent boxes have no temporal relationship; only width matters.
**Tool anchor:** `perf record -F 99 -g -p $(pgrep my_app) -- sleep 30 && perf script | stackcollapse-perf.pl | flamegraph.pl > flame.svg`
**Drill:** You are given a flame graph SVG from a CME MDP decoder. Identify the hottest user function, the deepest call chain, and explain why a narrow-but-tall tower is less concerning than a wide plateau at the same depth.
**Tags:** flame-graph, visualization, stack-sampling, perf-script

### perf stat fundamentals
`perf stat` counts hardware events without sampling, giving you IPC, cache miss rates, branch misprediction rates, and cycle counts with minimal overhead. Knowing which default counters matter (instructions, cycles, cache-references, cache-misses, branches, branch-misses) and how to interpret IPC as a first-pass health metric is the foundation of PMC-based analysis.
**Key concepts:** IPC, counting mode, cache miss rate, branch misprediction rate, repeat runs
**Tip:** An IPC below 1.0 on a modern superscalar core almost always means the workload is stalled on memory or branch mispredictions, not compute-bound.
**Tool anchor:** `perf stat -r 5 -d -- ./decode_mdp3 < capture.pcap` to get detailed counters with 5 repeat runs and coefficient of variation
**Drill:** You run `perf stat` on your SBE message decoder and see IPC 0.4, LLC-load-misses at 38%, branch-misses at 0.2%. Diagnose the bottleneck and propose the next investigation step.
**Tags:** perf-stat, IPC, counters, PMC, cache-miss

### Choosing the right profiling tool
Each tool occupies a niche: `perf` for PMC sampling and counting, `bpftrace` for dynamic tracing with in-kernel filtering, `cachegrind`/`callgrind` for deterministic simulation (no PMC needed), `strace` for syscall tracing, and `ftrace` for kernel function tracing. Picking the wrong tool wastes hours and can mislead with inappropriate overhead or wrong abstraction level.
**Key concepts:** PMC sampling, dynamic tracing, simulation, decision tree, overhead profiles
**Tip:** If you need exact cache-miss counts on a VM without PMC access, use `valgrind --tool=cachegrind`; it simulates the cache hierarchy entirely in software.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_enter_recvmsg /comm == "md_feed"/ { @[ustack(5)] = count(); }'` to trace recv paths in your feed handler
**Drill:** You need to profile a market data application in four different scenarios: (1) production server, (2) dev VM without PMC passthrough, (3) investigating a kernel scheduling issue, (4) tracing a specific function's latency. Select the right tool for each and justify.
**Tags:** tool-selection, perf, bpftrace, cachegrind, decision-tree

### Measuring latency vs throughput
Latency (time per operation) and throughput (operations per time) require different measurement approaches, tools, and mental models. A system can have excellent throughput while hiding terrible tail latency. Understanding percentiles (p50, p99, p99.9), coordinated omission, and Little's Law prevents flawed benchmarks.
**Key concepts:** percentiles, coordinated omission, Little's Law, throughput saturation
**Tip:** Averaging latency measurements hides outliers; a p99 of 500us with a mean of 50us means 1% of your market data updates arrive 10x late, which matters for trading.
**Tool anchor:** `bpftrace -e 'uprobe:./md_handler:process_message { @start[tid] = nsecs; } uretprobe:./md_handler:process_message { @latency_ns = hist(nsecs - @start[tid]); delete(@start[tid]); }'`
**Drill:** Your feed handler processes 2M messages/sec with mean latency 5us. After a code change, throughput stays at 2M msg/sec but p99.9 jumps from 50us to 800us. Explain why throughput alone missed this regression and which tool you would use to investigate.
**Tags:** latency, throughput, percentiles, coordinated-omission, Little's-Law

### CPU utilization: what it really means
CPU utilization (%user, %sys, %idle, %iowait, %steal) is the most-checked and most-misunderstood metric. High utilization does not mean the CPU is doing useful work (it may be spinning on locks or stalled on memory), and %iowait is not a reliable indicator of I/O problems. Per-core breakdown via `mpstat` reveals imbalances hidden by aggregate numbers.
**Key concepts:** %user, %sys, %iowait, %steal, per-core breakdown, spin-wait ambiguity
**Tip:** A core at 100% user with IPC 0.3 is spending most of its cycles stalled on cache misses, not computing; utilization alone cannot distinguish compute from memory-bound.
**Tool anchor:** `mpstat -P ALL 1 10` to see per-core utilization; correlate with `perf stat -C 3 -e cycles,instructions,cache-misses -- sleep 5` for a specific core
**Drill:** mpstat shows core 3 at 99% user while all other cores are at 5%. Your SBE decoder is pinned to core 3. Is this good (dedicated processing) or bad (bottleneck)? What two follow-up measurements would you take?
**Tags:** CPU-utilization, mpstat, per-core, iowait, misleading-metrics

### Profiling workflow: observe, hypothesize, measure, verify
Performance analysis is a scientific method: observe symptoms (latency spike), form a hypothesis (L3 cache thrashing from hash-map resizing), measure with targeted tools (perf stat cache counters during resize), and verify by changing one variable (pre-allocate the map). Skipping steps leads to premature optimization or chasing phantom bottlenecks.
**Key concepts:** scientific method, hypothesis-driven, controlled experiment, one-variable-at-a-time
**Tip:** Write down your hypothesis before measuring; if you skip this, you will unconsciously interpret ambiguous data to confirm whatever you already believe.
**Tool anchor:** `perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses -- ./bench_before && perf stat -e LLC-loads,LLC-load-misses,LLC-stores,LLC-store-misses -- ./bench_after`
**Drill:** Your market data handler's p99 latency spiked 3x after a deployment. Walk through the four-step workflow: what do you observe first, what hypotheses do you form, what specific measurements distinguish them, and how do you verify the fix?
**Tags:** methodology, scientific-method, hypothesis, verification, workflow

### Reading /proc/stat, /proc/meminfo, /proc/vmstat
These pseudo-files are the raw data behind every monitoring tool. Knowing key fields (cpu line format in /proc/stat, MemAvailable vs MemFree in /proc/meminfo, pgfault/pgmajfault and pswpin/pswpout in /proc/vmstat) lets you build lightweight monitoring without installing anything and debug cases where high-level tools disagree.
**Key concepts:** /proc/stat CPU accounting, MemAvailable, page faults, swap activity, numa_hit/miss
**Tip:** `MemFree` is almost always near zero on a healthy Linux system because the kernel uses free RAM for page cache; `MemAvailable` is the metric that tells you if you are actually short on memory.
**Tool anchor:** `awk '/MemAvailable|MemFree|Buffers|Cached|SwapTotal|SwapFree/ {print}' /proc/meminfo` and `awk '/pgfault|pgmajfault|pswpin|pswpout|numa/ {print}' /proc/vmstat`
**Drill:** You see MemFree at 200MB on a 128GB server running your market data stack. A teammate panics about memory pressure. Using /proc/meminfo and /proc/vmstat, determine whether the system is actually under pressure and explain your reasoning.
**Tags:** proc-filesystem, meminfo, vmstat, memory, monitoring

## intermediate

### perf record and perf report
`perf record` samples at a configurable frequency (99Hz avoids lock-step aliasing with timer interrupts) and stores samples with optional call graphs. `perf report` provides an interactive TUI for navigating the profile: sorting by overhead, expanding call chains, filtering by DSO or symbol, and switching between caller/callee views. Mastering `--call-graph dwarf` vs `fp` vs `lbr` determines whether your call stacks are accurate.
**Key concepts:** sampling frequency, call-graph modes (dwarf/fp/lbr), report navigation, DSO filtering
**Tip:** Always use `--call-graph dwarf` for C++ code compiled with `-fomit-frame-pointer` (the default on x86-64); frame-pointer-based unwinding gives broken stacks otherwise.
**Tool anchor:** `perf record -F 99 --call-graph dwarf -p $(pgrep md_feed) -- sleep 30 && perf report --no-children --sort=dso,symbol`
**Drill:** You profile your SBE decoder with `perf record -g` and the call graph shows `[unknown]` frames above your hot function. Diagnose why the stacks are broken and fix the recording command.
**Tags:** perf-record, perf-report, call-graph, dwarf, sampling

### perf annotate: source and assembly correlation
`perf annotate` maps samples to individual instructions (and source lines with debug info), showing exactly which instruction is hot within a function. This reveals whether time is spent on loads (memory-bound), branches (control-flow), or arithmetic. For C++ template-heavy code like SBE codecs, it disambiguates which template instantiation is the bottleneck.
**Key concepts:** instruction-level sampling, hot instruction, source-line mapping, compiler optimization visibility
**Tip:** A `mov` instruction with 40% of samples is not slow itself; it is stalled waiting for a prior cache-miss load to complete. Look at the instruction 1-3 lines above it for the true culprit.
**Tool anchor:** `perf annotate -s decode_field --no-source --stdio` (`--source`, which interleaves source with assembly, is the default; use `--no-source` for pure assembly when source mapping is misleading due to inlining)
**Drill:** perf annotate shows 35% of samples on a `mov rax, [rbx+0x40]` inside your SBE message decoder's hot loop. The instruction above is `cmp` with 0% samples. Explain what is happening at the microarchitectural level and propose a fix.
**Tags:** perf-annotate, assembly, instruction-level, source-correlation, cache-miss

### bpftrace one-liners and probe types
bpftrace provides concise one-liner tracing programs across four probe types: kprobe/kretprobe (kernel functions), uprobe/uretprobe (user functions), tracepoint (stable kernel events), and USDT (user statically defined tracing). Map aggregation (@[key] = count/hist/sum) enables in-kernel summarization with near-zero overhead. The 12 essential one-liners cover syscall counting, latency histograms, stack frequency, and per-process breakdowns.
**Key concepts:** kprobe, uprobe, tracepoint, USDT, map aggregation, in-kernel summarization
**Tip:** Always prefer tracepoints over kprobes for syscalls: tracepoints are stable across kernel versions, while kprobes break when internal function names change.
**Tool anchor:** `bpftrace -e 'tracepoint:syscalls:sys_exit_read /comm == "md_feed"/ { @bytes = hist(args->ret); @latency_us = hist((nsecs - @start[tid]) / 1000); }'`
**Drill:** Your market data feed handler is experiencing intermittent latency spikes. Write a bpftrace one-liner that captures a histogram of time spent in each recvmmsg syscall, filtered to only your process, and explain what the histogram shape would tell you.
**Tags:** bpftrace, one-liners, kprobe, uprobe, tracepoint, USDT

### Workload characterization methodology
Before optimizing anything, classify your workload: is it CPU-bound (high IPC, saturated core), memory-bound (low IPC, high cache misses), I/O-bound (high %iowait, frequent syscalls), or mixed? Intel's Top-down Microarchitecture Analysis (TMA) Level 1 splits cycles into Frontend Bound, Backend Bound, Bad Speculation, and Retiring, giving a definitive first-pass classification that guides all subsequent analysis.
**Key concepts:** CPU/memory/IO-bound, TMA Level 1, Frontend/Backend/BadSpec/Retiring, iterative drill-down
**Tip:** If TMA shows >50% Backend Bound, do not waste time optimizing branch prediction or instruction fetch; your bottleneck is cache/memory and you need to fix data access patterns.
**Tool anchor:** `perf stat -M TopdownL1 -C 3 -- sleep 10` (requires perf 5.8+ and an Intel CPU exposing the `slots` fixed counter, i.e. Ice Lake or newer; use `--topdown` on older perf)
**Drill:** TMA Level 1 for your SBE decoder shows: Retiring 15%, Bad Speculation 5%, Frontend Bound 10%, Backend Bound 70%. What does this tell you? What TMA Level 2 breakdown would you examine next, and what specific perf events would you measure?
**Tags:** workload-characterization, TMA, CPU-bound, memory-bound, classification

### Differential analysis: before vs after
Comparing profiles across code changes, configurations, or time windows isolates regressions. Diff flame graphs overlay two profiles and color code increases (red) vs decreases (blue). `perf diff` compares two perf.data files at the symbol level. The key discipline is controlling variables: same input data, same system state, same CPU frequency governor.
**Key concepts:** A/B profiling, diff flame graphs, perf diff, variable control, regression attribution
**Tip:** Always set the CPU governor to `performance` before A/B profiling; `powersave`/`schedutil` introduces frequency scaling noise that dwarfs real code differences.
**Tool anchor:** `perf diff perf_before.data perf_after.data --sort=dso,symbol --percentage=relative` and `difffolded.pl out_before.folded out_after.folded | flamegraph.pl > diff.svg`
**Drill:** After optimizing your CME MDP3 decoder, `perf diff` shows your target function dropped from 18% to 6%, but a previously-unseen function `__memmove_avx_unaligned_erms` appeared at 14%. Explain what likely happened and whether the optimization was actually a net win.
**Tags:** differential-analysis, diff-flame-graph, perf-diff, regression, A/B-profiling

### perf c2c for false sharing detection
False sharing occurs when different cores write to different variables that share the same cache line, causing expensive cache-to-cache (HITM) transfers. `perf c2c` records load/store samples tagged with data source (L1/L2/L3/remote) and reports cacheline-level sharing patterns, identifying the exact data addresses and code locations involved.
**Key concepts:** false sharing, HITM events, cache-line granularity, c2c report, data-source tagging
**Tip:** A `struct` with a read-mostly field and a frequently-written counter on the same 64-byte cache line is the classic false-sharing pattern; `alignas(64)` or padding fixes it.
**Tool anchor:** `perf c2c record -g -p $(pgrep md_feed) -- sleep 10 && perf c2c report --stdio --call-graph=none -d lcl`
**Drill:** perf c2c shows a cache line with 12,000 HITM events. The line contains two fields from a shared statistics struct: `uint64_t msg_count` (written by core 2) and `uint64_t byte_count` (written by core 5). Propose two different fixes and explain the tradeoff.
**Tags:** false-sharing, perf-c2c, HITM, cache-line, padding

### perf mem for memory access profiling
`perf mem` samples load and store instructions and records the data source for each access (L1 hit, L2 hit, L3 hit, local DRAM, remote DRAM). This reveals whether your hot data fits in cache and identifies specific data structures causing DRAM accesses. Weight-based sampling prioritizes high-latency accesses, focusing attention where it matters most.
**Key concepts:** load/store sampling, data source attribution, weight sampling, DRAM vs cache hits
**Tip:** Sort by weight (latency) not count; 100 DRAM accesses at 200 cycles each cost more than 10,000 L1 hits at 4 cycles each.
**Tool anchor:** `perf mem -t load record -p $(pgrep md_feed) -- sleep 10 && perf mem report --sort=mem,sym,dso --stdio`
**Drill:** perf mem report shows your order book's `std::unordered_map::operator[]` with 60% of accesses hitting DRAM and average weight 180 cycles. The map has 500K entries. Propose a data structure change and predict its effect on the data source distribution.
**Tags:** perf-mem, memory-access, data-source, weight-sampling, DRAM

### Tracepoints vs kprobes vs uprobes
Static tracepoints (compiled into kernel/user code) have near-zero overhead and stable interfaces. Dynamic kprobes/uprobes attach to any function at runtime but can break across versions and have higher overhead from the trap mechanism. USDT probes (user statically defined tracing) offer the best of both worlds for user-space. Understanding when each is available, its overhead profile, and its stability contract determines which to use in production.
**Key concepts:** static vs dynamic probes, trap overhead, interface stability, USDT, production safety
**Tip:** Run `bpftrace -l 'tracepoint:*'` to see available kernel tracepoints and `bpftrace -l 'usdt:/path/to/binary:*'` for USDT probes; if a stable tracepoint exists for your event, always prefer it over a kprobe.
**Tool anchor:** `bpftrace -l 'tracepoint:sched:*'` to list scheduler tracepoints; `perf probe -x ./md_handler -F` to list probable uprobe targets
**Drill:** You want to trace context switches affecting your pinned feed handler thread. You have three options: tracepoint:sched:sched_switch, kprobe:__schedule, and a custom uprobe on your yield function. Rank them by overhead, stability, and information available, then write the bpftrace probe for your chosen option.
**Tags:** tracepoint, kprobe, uprobe, USDT, overhead, stability

### Flame graph variants
Beyond standard CPU flame graphs, several variants illuminate different bottleneck types: differential (red/blue for before/after), off-CPU (why threads are sleeping), memory (allocation stack traces), hot/cold (separating on-CPU and off-CPU), and icicle graphs (inverted, root at top). Each variant answers a distinct question and requires different data collection.
**Key concepts:** differential, off-CPU, memory, hot/cold, icicle, data collection differences
**Tip:** Off-CPU flame graphs often reveal more than on-CPU ones for I/O-heavy workloads; a thread spending 80% of wall time blocked on a mutex will show nothing interesting in a CPU flame graph.
**Tool anchor:** `bpftrace -e 'kprobe:finish_task_switch { @[ustack(perf), comm] = sum(nsecs - @start[tid]); } kprobe:deactivate_task { @start[tid] = nsecs; }' > offcpu.bt` (simplified; production version filters by pid)
**Drill:** Your market data handler has acceptable CPU utilization (30%) but high p99 latency. A CPU flame graph shows nothing unusual. Which flame graph variant would you generate next, what data would you collect, and what pattern in the resulting graph would confirm your hypothesis?
**Tags:** flame-graph-variants, off-CPU, differential, memory, icicle

### Event multiplexing and counting accuracy
Modern CPUs have only 4-8 general-purpose PMC registers, but `perf stat` can measure dozens of events simultaneously by time-multiplexing: rapidly switching which events are counted and scaling the results. This introduces statistical error that grows with the number of events. Understanding the `<not counted>` and scaling percentage warnings is critical for trusting your numbers.
**Key concepts:** PMC register limit, time multiplexing, scaling factor, counting error, event groups
**Tip:** If perf stat shows a scaling percentage above 30%, your counts are unreliable; reduce the number of simultaneous events or use event groups to pin critical events to dedicated counters.
**Tool anchor:** `perf stat -e '{cycles,instructions,cache-misses}' -- ./bench` (the braces create a group scheduled together, avoiding multiplexing between these three events; the `:S` group-leader-sampling modifier is a `perf record`/PERF_SAMPLE_READ concept, not needed for counting)
**Drill:** You run `perf stat` with 15 events and notice `cache-misses` shows `(23.07%)` next to it while `cycles` shows `(100.00%)`. Explain what these percentages mean, why they differ, and how to restructure the command to get 100% accuracy on cache-misses.
**Tags:** multiplexing, PMC-registers, scaling, event-groups, accuracy

### Profiling overhead and observer effect
Every profiling tool perturbs what it measures. Sampling at 99Hz adds ~1% overhead; tracing every function call via uprobes can add 100x overhead; `strace` serializes all syscalls. Understanding each tool's overhead profile lets you choose production-safe settings and recognize when measurements are distorted by the measurement itself.
**Key concepts:** observer effect, sampling overhead, tracing overhead, production-safe frequency, perturbation
**Tip:** For production profiling, 49Hz or 99Hz sampling is safe (under 1% overhead); never use 999Hz or higher unless you are on an isolated benchmark machine and accept 5-10% perturbation.
**Tool anchor:** `perf stat -e task-clock -- perf record -F 99 -g -p $(pgrep md_feed) -- sleep 30` (measure the overhead of profiling itself by wrapping perf record in perf stat)
**Drill:** You are asked to profile a production market data feed handler that processes 5M msg/sec with a 10us p99 latency SLA. Evaluate three approaches (perf record at 99Hz, bpftrace uprobe on hot function, strace -c) for overhead impact and recommend a production-safe plan.
**Tags:** overhead, observer-effect, production-safe, sampling-frequency, perturbation

### perf probe for dynamic tracepoints
`perf probe` creates dynamic tracepoints on kernel or user-space functions, optionally capturing function arguments, return values, and local variables (when DWARF debug info is available). This enables targeted tracing of specific functions without recompilation, bridging the gap between sampling (statistical) and tracing (event-driven) analysis.
**Key concepts:** dynamic tracepoint creation, variable capture, DWARF dependency, line probes, function entry/return
**Tip:** `perf probe -x ./binary -V function_name` shows which variables are available for capture at that probe point; this depends on optimization level and DWARF quality.
**Tool anchor:** `perf probe -x ./md_handler 'decode_message msg_type:u32 seq_num:u64' && perf record -e probe_md_handler:decode_message -p $(pgrep md_handler) -- sleep 10`
**Drill:** You want to trace every call to your SBE decoder's `decodeField()` function and capture the field ID and template ID arguments. Write the perf probe and perf record commands, then explain what would prevent variable capture from working and how to fix it.
**Tags:** perf-probe, dynamic-tracepoint, variable-capture, DWARF, line-probe

## advanced

### Benchmarking statistics
Arithmetic mean is the wrong summary statistic for latency distributions because latency is bounded below but unbounded above, producing right-skewed distributions. Percentiles (p50, p99, p99.9), coefficient of variation (CV), confidence intervals, and steady-state detection (excluding warm-up) are the tools for rigorous benchmarking. Without statistical discipline, you will ship "optimizations" that are noise.
**Key concepts:** percentiles, coefficient of variation, warm-up exclusion, steady-state, confidence intervals
**Tip:** If your CV exceeds 5% across runs, you have an environmental variable you have not controlled (turbo boost, NUMA placement, background load); fix the environment before trusting comparisons.
**Tool anchor:** `perf stat -r 10 -- ./bench 2>&1 | tail -1` (the last line shows mean +/- stddev; if stddev/mean > 5%, investigate variance sources before drawing conclusions)
**Drill:** You benchmark your SBE decoder with 5 runs and get mean 12.3us, stddev 4.1us (CV=33%). A colleague says "the optimization saved 2us." Explain why this claim is unsupported, list three likely sources of the variance, and describe how to reduce CV below 5%.
**Tags:** statistics, percentiles, coefficient-of-variation, warm-up, confidence-interval

### Off-CPU analysis and scheduling delays
When a thread is not running, it is either voluntarily sleeping (I/O, mutex, condition variable) or involuntarily preempted (scheduler). Off-CPU analysis traces the time between a thread being descheduled and rescheduled, attributing that time to the blocking stack trace. This is essential for latency investigations where CPU profiles show no bottleneck because the problem is the thread not running at all.
**Key concepts:** off-CPU flame graph, voluntary vs involuntary sleep, perf sched, wakeup chains, runqueue latency
**Tip:** `perf sched timehist` shows per-wakeup scheduling latency; if your latency-sensitive thread shows >5us runqueue latency, check for competing threads on the same core and consider `isolcpus` or `SCHED_FIFO`.
**Tool anchor:** `perf sched record -p $(pgrep md_feed) -- sleep 5 && perf sched timehist -Mwn --state` to see scheduling delays with waker info and state
**Drill:** Your feed handler thread on an isolated core occasionally shows 200us latency spikes. CPU flame graphs are clean. perf sched timehist shows the thread was preempted for 180us by `ksoftirqd/3`. Explain the mechanism and propose two fixes at different layers (kernel config vs application architecture).
**Tags:** off-CPU, scheduling, perf-sched, runqueue, preemption, isolcpus

### Custom PMC event programming
Beyond the pre-defined events perf knows about, Intel CPUs support hundreds of raw performance events documented in the Software Developer's Manual (SDM) Volume 3B. Raw event codes (event select + umask) let you measure specific microarchitectural behaviors like offcore response events, memory bandwidth, or specific TLB miss types that have no perf alias.
**Key concepts:** raw event codes, event select, umask, offcore response MSR, Intel SDM
**Tip:** Offcore response events (`OCR.*`) are the most powerful raw events for memory analysis: they let you filter loads by data source (L3 hit vs DRAM vs remote) at the PMC level, without `perf mem`'s sampling overhead.
**Tool anchor:** `perf stat -e 'cpu/event=0xd0,umask=0x81,name=all_loads/' -e 'cpu/event=0xd0,umask=0x82,name=all_stores/' -- ./bench` (MEM_INST_RETIRED.ALL_LOADS/ALL_STORES from Skylake SDM)
**Drill:** You need to count the exact number of loads that miss all cache levels and go to DRAM for your SBE decoder. Find the raw event code for MEM_LOAD_RETIRED.L3_MISS from the Intel SDM (or perfmon events JSON), write the perf stat command using the raw encoding, and validate it against the perf alias.
**Tags:** raw-PMC, event-codes, offcore-response, Intel-SDM, microarchitecture

### TMA with toplev.py: Level 1-3 analysis
Intel's Top-down Microarchitecture Analysis (TMA) decomposes CPU pipeline utilization into a tree: Level 1 splits into Frontend Bound, Backend Bound, Bad Speculation, and Retiring; each splits further (e.g., Backend Bound into Memory Bound and Core Bound). Andi Kleen's `toplev.py` from pmu-tools automates this multi-level analysis, measuring the right PMC events and reporting bottleneck percentages with actionable descriptions.
**Key concepts:** TMA tree, pmu-tools/toplev.py, bottleneck hierarchy, actionable recommendations, Level 2/3 drill-down
**Tip:** TMA Level 1 tells you where to look; Level 2 tells you what is wrong; Level 3 tells you exactly which hardware unit to blame. Never skip to Level 3 directly because you need the higher levels to interpret it.
**Tool anchor:** `toplev.py -l3 --no-desc -C 3 -- sleep 10` (Level 3 analysis on core 3; requires pmu-tools installed and MSR access)
**Drill:** toplev.py Level 2 reports Backend Bound > Memory Bound at 55%, and Level 3 breaks it down as L3_Bound 8%, DRAM_Bound 42%, Store_Bound 5%. Your SBE decoder uses pointer-chasing through a large hash map. Explain why DRAM_Bound dominates, propose a data structure change, and predict how the TMA breakdown would shift after the fix.
**Tags:** TMA, toplev, pmu-tools, bottleneck-tree, memory-bound

### Continuous profiling in production
Always-on profiling at low frequency (1-11Hz) provides fleet-wide CPU profiles without noticeable overhead. Aggregating samples across thousands of servers reveals systemic inefficiencies invisible in single-server profiles. Tools like Parca, Pyroscope, and Google-Wide Profiling (GWP) store profiles as time-series data, enabling regression detection, cross-version comparisons, and long-term optimization tracking.
**Key concepts:** low-frequency always-on, fleet aggregation, time-series profiles, regression detection, overhead budget
**Tip:** At 1Hz sampling for 60 seconds you get only 60 samples per core, which is useless for a single server but statistically powerful when aggregated across 1,000 servers: 60,000 samples per core across the fleet.
**Tool anchor:** `perf record -F 11 -g --call-graph dwarf -a -o /tmp/perf_$(date +%s).data -- sleep 60` (production-safe continuous collection; ship perf.data to aggregation backend)
**Drill:** Your team runs 200 market data servers. You deploy a new SBE decoder version and want to detect a 3% CPU regression within 24 hours. Design the continuous profiling pipeline: collection frequency, aggregation method, comparison baseline, and statistical threshold for alerting.
**Tags:** continuous-profiling, production, fleet-wide, Parca, regression-detection

### Kernel vs userspace tracing tradeoffs
eBPF programs run inside the kernel, filtering and aggregating trace data at the source before copying results to userspace. This contrasts with perf's ring-buffer model, where all samples are copied to userspace for post-processing. For high-frequency events, eBPF's in-kernel filtering can reduce overhead by 100x compared to dumping raw events. Understanding ring buffer pressure, lost events, and the BPF verifier's constraints shapes your tracing architecture.
**Key concepts:** eBPF in-kernel filtering, ring buffer pressure, lost events, BPF verifier, perf_event overhead
**Tip:** If `perf record` reports lost samples, increase the buffer size with `-m 256` (256 pages) or reduce the event rate with filtering; lost samples silently bias your profile toward shorter stacks.
**Tool anchor:** `perf record -m 512 --overwrite -e cycles -F 99 -g -p $(pgrep md_feed) -- sleep 30 2>&1 | grep -i lost` (check for lost events; --overwrite uses flight-recorder mode to avoid backpressure)
**Drill:** You need to trace every network packet received by your feed handler (5M packets/sec). Compare implementing this with: (1) perf record on raw_syscalls:sys_enter for recvmsg, (2) a bpftrace program with in-kernel filtering and aggregation. Estimate the data volume per second for each approach and explain which is feasible in production.
**Tags:** eBPF, kernel-tracing, ring-buffer, lost-events, BPF-verifier, overhead

### Writing custom bpftrace scripts
Beyond one-liners, multi-probe bpftrace scripts correlate events across time and threads: measuring the latency between two function calls, building state machines that track request lifecycles, and aggregating metrics by custom keys. Map data structures (@start, @hist, @count) persist across probe firings, enabling complex in-kernel analysis.
**Key concepts:** multi-probe correlation, state machine tracing, map persistence, timing between events, printf vs aggregation
**Tip:** Use maps for aggregation (@latency = hist(...)) instead of printf for per-event output; printf at 100K events/sec will overflow the perf ring buffer and lose data, while map aggregation has near-zero overhead.
**Tool anchor:** `bpftrace -e 'uprobe:./md_handler:on_packet { @start[tid] = nsecs; } uprobe:./md_handler:send_update { @e2e_us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); } interval:s:5 { print(@e2e_us); clear(@e2e_us); }'`
**Drill:** Write a bpftrace script that measures the end-to-end latency from network packet arrival (tracepoint:net:netif_receive_skb) to your application's on_message uprobe, filtering by your process. The script should output a histogram every 10 seconds and track the maximum latency seen. Explain how map cleanup prevents memory leaks.
**Tags:** bpftrace-scripts, multi-probe, state-machine, correlation, map-aggregation

### perf event groups and leader sampling
Event groups ensure that multiple PMC events are measured simultaneously on the same set of cycles, eliminating multiplexing error for derived metrics (like IPC = instructions/cycles). The group leader determines when all members are scheduled, and leader sampling tags each sample with values from all group members, enabling per-sample derived metrics rather than just aggregates.
**Key concepts:** group semantics, leader mode, simultaneous counting, multiplexing avoidance, per-sample derived metrics
**Tip:** For reliable IPC measurement, always group cycles and instructions: `{cycles,instructions}`. Without grouping, multiplexing can make IPC appear to fluctuate between 0.5 and 3.0 when the true value is stable at 1.2.
**Tool anchor:** `perf stat -e '{cycles,instructions,cache-misses,LLC-load-misses}' -- ./bench` (group scheduling ensures all four counted on exactly the same cycles; no scaling needed)
**Drill:** You measure IPC for your SBE decoder two ways: (1) `perf stat -e cycles,instructions` (ungrouped) reports IPC 1.8 with both at 50% scaling; (2) `perf stat -e '{cycles,instructions}'` (grouped) reports IPC 0.9 at 100%. Explain why the ungrouped result is wrong and what multiplexing artifact caused the 2x error.
**Tags:** event-groups, leader-sampling, multiplexing, derived-metrics, IPC

### Hardware trace (Intel PT) for control flow
Intel Processor Trace (PT) records the complete control flow of a program with minimal overhead (~5%) by encoding only branch decisions (taken/not-taken) into highly compressed trace packets. When decoded against the binary, this reconstructs every instruction executed, enabling exact cycle-accurate analysis, coverage analysis, and debugging of non-deterministic bugs that sampling-based tools miss entirely.
**Key concepts:** Processor Trace, branch packets, full control flow, decoding, cycle-accurate timing
**Tip:** Intel PT generates 100MB-1GB/sec of trace data depending on branch density; always use snapshot mode (`--snapshot`) for production to capture only the last N seconds into a ring buffer, triggered by a signal when the interesting event occurs.
**Tool anchor:** `perf record -e intel_pt//u --snapshot -p $(pgrep md_feed) -- sleep 60` then `kill -USR2 $(pgrep perf)` to trigger snapshot; decode with `perf script --itrace=bep --ns`
**Drill:** Your SBE decoder occasionally takes 500us instead of 5us for identical messages, but the bug is not reproducible under a profiler. Design an Intel PT capture strategy: what mode would you use, how would you trigger the snapshot, and how would you decode the trace to find the divergent branch that caused the slowdown?
**Tags:** Intel-PT, hardware-trace, control-flow, snapshot, cycle-accurate

### Building a performance regression detection pipeline
Automated performance regression detection requires: a reproducible benchmark suite, baseline management (versioned reference profiles), statistical comparison with appropriate thresholds (avoiding both false positives and missed regressions), and alerting integration. The pipeline must account for system noise, warm-up periods, and the multiple-comparison problem when testing many metrics simultaneously.
**Key concepts:** CI integration, baseline management, statistical thresholds, Bonferroni correction, alert fatigue
**Tip:** Use a threshold of 3x the historical coefficient of variation (CV) for each metric; if your benchmark's CV is 2%, alert on changes >6%. This adapts to each metric's natural noise level instead of using a fixed percentage.
**Tool anchor:** `perf stat -r 30 -x',' --log-fd 3 3>perf_results.csv -- ./bench_suite` (CSV output with 30 repetitions for statistical power; parse and compare against baseline with a t-test or Mann-Whitney U test)
**Drill:** Design a CI pipeline for your market data decoder: specify the benchmark command, number of runs, warm-up strategy, baseline storage format, statistical test for comparison, threshold for alerting, and how to handle a flaky test that triggers 2 false positives per week. Write the shell commands for the critical path.
**Tags:** regression-detection, CI, baseline, statistical-testing, alert-fatigue, pipeline
