# perf cheatsheet

## perf stat — counting mode

```bash
perf stat ./a.out                          # default counters (cycles, instructions, branches, cache refs/misses)
perf stat -d ./a.out                       # detailed: adds L1/LLC cache, branch, TLB counters
perf stat -dd ./a.out                      # very detailed: adds L1-icache, dTLB, iTLB
perf stat -r 5 ./a.out                     # run 5 times, report mean +/- stddev
perf stat --topdown ./a.out                # top-down microarch analysis (frontend/backend bound)
perf stat -e cycles,instructions ./a.out   # specific events
perf stat -e '{cycles,instructions}' ./a.out  # event group (counted together, enables reliable ratios)
perf stat -C 0,2 sleep 5                   # count on CPUs 0 and 2 system-wide for 5s
perf stat -t 1234                          # attach to thread TID 1234
perf stat -p 1234 sleep 10                 # attach to PID 1234, count for 10s
perf stat -I 1000 ./a.out                  # print counts every 1000ms
perf stat -e 'cache-misses,cache-references' -a sleep 5  # system-wide for 5s
```

## perf record — sampling mode

```bash
perf record ./a.out                        # sample at default frequency, write perf.data
perf record -F 99 ./a.out                  # sample at 99 Hz (use 99, not 100 — avoids lockstep aliasing)
perf record -g ./a.out                     # record call graphs (frame-pointer based)
perf record --call-graph dwarf ./a.out     # DWARF unwinding (works without -fno-omit-frame-pointer)
perf record --call-graph dwarf,16384 ./a.out  # DWARF with 16K stack dump (default 8K, increase if stacks truncated)
perf record -e cache-misses -g ./a.out     # sample on cache misses with call graphs
perf record -p 1234 -g sleep 30            # profile running PID for 30s
perf record -C 0-3 -a sleep 10             # sample CPUs 0-3 system-wide for 10s
perf record -o my.data ./a.out             # custom output file
perf record -e '{cycles,instructions}:S' ./a.out  # group sampling (leader-based)
```

## perf report — analyzing samples

```bash
perf report                                # interactive TUI browser of perf.data
perf report --stdio                        # text output (scriptable, no TUI)
perf report --sort comm,dso,sym            # sort by command, DSO, symbol
perf report --percent-limit 1              # hide entries below 1%
perf report -g callee                      # callee-based call graph (default)
perf report -g caller                      # caller-based call graph (top-down)
perf report -g graph,0.5,caller            # caller graph, hide branches below 0.5%
perf report --no-children                  # show self cost only (no accumulated children cost)
perf report -i my.data                     # read from custom file
perf report --dsos=libfoo.so               # filter to samples in libfoo.so
perf report --comms=myapp                  # filter to samples from myapp
```

## perf annotate — instruction-level

```bash
perf annotate                              # annotate hottest symbol (TUI)
perf annotate --stdio                      # text output: interleaved source + asm
perf annotate -s my_function               # annotate specific symbol
perf annotate -s my_function --stdio       # specific symbol, text output
perf annotate --source --asm               # show both source lines and assembly
perf annotate -M intel --stdio             # Intel syntax (default is AT&T)
```

Requires debuginfo (`-g` at compile time). For best results: compile with `-g -O2`.

## perf top — live profiling

```bash
perf top                                   # live system-wide profile (like top, but for functions)
perf top -e cache-misses                   # live profile on cache misses
perf top -g                                # live with call graph
perf top -p 1234                           # live profile for PID 1234
perf top -C 0                              # live profile CPU 0 only
```

## perf c2c — false sharing detection

```bash
perf c2c record -a sleep 10               # record memory accesses system-wide for 10s
perf c2c record -p 1234 sleep 10          # record for specific PID
perf c2c report --stdio                   # text report
perf c2c report --stdio --stats           # show summary statistics
```

Key columns in report:
- **HITM** (Hit In Modified): cross-cache-line contention. High local HITM = same-socket; high remote HITM = cross-socket.
- **Snoop** column shows cache coherence traffic type.
- Sort by `Tot Hitm` to find worst contenders. Look at cacheline offset to confirm false sharing vs true sharing.

## perf mem — memory access profiling

```bash
perf mem record ./a.out                    # record memory load/store samples
perf mem record -t load ./a.out            # loads only
perf mem record -t store ./a.out           # stores only
perf mem report --stdio                    # text report with access latency
perf mem report --sort mem,sym             # sort by memory level then symbol
```

Key columns: `Local Weight` = access latency in cycles, `Data Src` = L1/L2/L3/DRAM.

## perf probe — dynamic tracepoints

```bash
perf probe -x ./a.out -a 'my_func'                    # add probe at function entry
perf probe -x ./a.out -a 'my_func arg1 arg2'          # capture function arguments
perf probe -x ./a.out -a 'my_func:5 localvar'         # probe at line 5 of function, capture local
perf probe -x ./a.out -a 'my_func%return $retval'     # probe at function return, capture retval
perf probe -L my_func                                  # list probeable lines in function
perf probe -V my_func                                  # list available variables at function entry
perf probe -d 'probe_a_out:my_func'                   # delete probe
perf record -e 'probe_a_out:my_func' ./a.out          # record hits on the probe
```

Kernel probes (kprobes):
```bash
perf probe -a 'tcp_sendmsg size'           # probe kernel function, capture arg
perf record -e probe:tcp_sendmsg -a sleep 5
```

## perf trace — strace-like tracing

```bash
perf trace ./a.out                         # trace all syscalls (like strace, lower overhead)
perf trace -e open,read,write ./a.out      # trace specific syscalls only
perf trace -p 1234                         # trace running PID
perf trace --summary ./a.out               # only print per-syscall summary at exit
perf trace --duration 10 ./a.out           # only show syscalls taking >10ms
perf trace -e sched:sched_switch -a sleep 5  # trace tracepoint events system-wide
```

## perf sched — scheduling analysis

```bash
perf sched record ./a.out                  # record scheduling events
perf sched record -a sleep 10              # system-wide for 10s
perf sched latency                         # per-task scheduling latency summary
perf sched map                             # ASCII map of CPUs vs time (which task ran where)
perf sched timehist                        # timeline of context switches with timestamps
perf sched timehist -s                     # include summary with idle time
```

Key columns in `latency`: `max` = worst-case wakeup-to-run delay, `avg` = mean.

## perf lock — lock contention

```bash
perf lock record ./a.out                   # record lock events (needs CONFIG_LOCKDEP/LOCK_STAT)
perf lock record -a sleep 10               # system-wide
perf lock report                           # report lock contention
perf lock contention                       # BPF-based lock contention (newer kernels, no lockdep needed)
perf lock contention -a sleep 5            # system-wide BPF contention analysis
```

Key columns in `report`: `wait total` = total time threads waited, `contention` = acquisition failures.

## Common event names

### Hardware events
- `cycles` (or `cpu-cycles`) — CPU clock cycles
- `instructions` — retired instructions
- `cache-references` — last-level cache accesses
- `cache-misses` — last-level cache misses
- `branch-instructions` (or `branches`) — branch instructions retired
- `branch-misses` — mispredicted branches

### Hardware cache events
- `L1-dcache-load-misses` — L1 data cache load misses
- `L1-icache-load-misses` — L1 instruction cache misses
- `LLC-load-misses` — last-level cache load misses
- `LLC-store-misses` — last-level cache store misses
- `dTLB-load-misses` — data TLB load misses
- `iTLB-load-misses` — instruction TLB load misses

### Software events
- `context-switches` (or `cs`) — context switches
- `cpu-migrations` — task migrated to different CPU
- `page-faults` (or `faults`) — page faults
- `minor-faults` / `major-faults` — minor (in memory) / major (from disk)

### Listing available events
```bash
perf list                                  # all available events
perf list hw                               # hardware events
perf list sw                               # software events
perf list cache                            # hardware cache events
perf list tracepoint                       # kernel tracepoints
```

## Tips

**Why 99 Hz, not 100 Hz?**
Using a prime-ish frequency avoids lockstep aliasing with periodic application behavior (timers, scheduling ticks). 97 or 99 are standard choices.

**Frame pointers vs DWARF unwinding:**
- `--call-graph fp` requires `-fno-omit-frame-pointer` at compile time. Fast, low overhead.
- `--call-graph dwarf` works without recompilation. Higher overhead (dumps stack each sample). Use `dwarf,16384` if stacks are truncated.
- `--call-graph lbr` uses hardware Last Branch Record. Very low overhead, limited depth (~8-32 frames).

**Compile flags for best profiling:**
```
-g -O2 -fno-omit-frame-pointer
```
`-g` for debuginfo (source annotation), `-fno-omit-frame-pointer` for reliable `fp` unwinding.

**Build ID cache:**
```bash
perf buildid-cache --add ./a.out           # cache binary's build ID for later analysis
perf buildid-list                          # list cached build IDs
```
Ensures `perf report` can resolve symbols even if the binary changes after recording.

**Multiplexing warning:**
When you specify more events than available PMU counters, perf time-multiplexes. Watch for `<not counted>` or `<not supported>` in `perf stat` output. Use event groups `{}` to force co-scheduling of related events.

**Useful one-liners:**
```bash
perf stat -e 'instructions,cycles' -a sleep 5 | grep insn  # quick IPC check
perf record -F 99 -g -p $(pgrep myapp) -- sleep 30         # profile running app for 30s
perf report --stdio --percent-limit 2 --no-children         # concise hotspot list
```
