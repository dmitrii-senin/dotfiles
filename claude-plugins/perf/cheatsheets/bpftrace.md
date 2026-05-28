# bpftrace Cheatsheet

## Probe Types

```
kprobe:vfs_read                    # kernel function entry
kretprobe:vfs_read                 # kernel function return
uprobe:/bin/bash:readline          # user-space function entry
uretprobe:/lib/libc.so.6:malloc   # user-space function return
tracepoint:syscalls:sys_enter_read # static kernel tracepoint
usdt:/path/bin:provider:probe      # user-space static tracepoint
software:page-faults:1             # software event, count trigger
hardware:cache-misses:1000000      # hardware PMC, sample period
profile:hz:99                      # timed sampling per CPU
interval:s:1                       # timed fire on one CPU
BEGIN                              # script start
END                                # script end
```

Multiple probes: `kprobe:vfs_read, kprobe:vfs_write { ... }`
Wildcard: `kprobe:vfs_* { ... }`

## Builtin Variables

```
arg0..argN   function arguments (probe-type dependent)
retval       return value (kretprobe/uretprobe)
comm         process name (16 char)
pid          process ID (tgid)
tid          thread ID
uid          user ID
gid          group ID
nsecs        nanosecond timestamp
elapsed      ns since bpftrace start
cpu          current CPU ID
kstack       kernel stack trace
ustack       user stack trace
func         current function name
probe        full probe name
curtask      pointer to current task_struct
cgroup       cgroup ID
args         tracepoint args struct (args.filename, etc.)
```

## Map Operations

```
@count[comm] = count();             # count occurrences
@bytes[pid] = sum(arg2);            # sum values
@avg_sz = avg(arg2);                # average
@min_lat = min($delta);             # minimum
@max_lat = max($delta);             # maximum
@stat_lat = stats($delta);          # count, avg, total

@hist_sz = hist(arg2);              # power-of-2 histogram
@hist_lat = lhist($d, 0, 1000, 100); # linear histogram (min, max, step)

@map[key] = val;                    # assign
delete(@map[key]);                  # delete single key
clear(@map);                        # clear entire map

print(@map);                        # print map
print(@map, 10);                    # top 10
print(@map, 10, 1000);              # top 10, values / 1000
```

## Essential One-Liners

```bash
# 1. Syscall count by process
bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# 2. Read size distribution
bpftrace -e 'tracepoint:syscalls:sys_exit_read /args.ret > 0/ { @bytes = hist(args.ret); }'

# 3. Function latency (libc read)
bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:read { @start[tid] = nsecs; }
  uretprobe:/lib/x86_64-linux-gnu/libc.so.6:read /@start[tid]/ { @ns = hist(nsecs - @start[tid]); delete(@start[tid]); }'

# 4. Page fault count by process
bpftrace -e 'software:page-faults:1 { @[comm, pid] = count(); }'

# 5. Block I/O latency histogram
bpftrace -e 'tracepoint:block:block_rq_issue { @start[args.dev, args.sector] = nsecs; }
  tracepoint:block:block_rq_complete /@start[args.dev, args.sector]/ {
  @usecs = hist((nsecs - @start[args.dev, args.sector]) / 1000);
  delete(@start[args.dev, args.sector]); }'

# 6. TCP connect latency (ns)
bpftrace -e 'kprobe:tcp_v4_connect { @start[tid] = nsecs; }
  kretprobe:tcp_v4_connect /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'

# 7. Open file snoop
bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%-6d %-16s %s\n", pid, comm, str(args.filename)); }'

# 8. Malloc size tracking
bpftrace -e 'uprobe:/lib/x86_64-linux-gnu/libc.so.6:malloc { @bytes[comm] = hist(arg0); }'

# 9. Signal delivery
bpftrace -e 'tracepoint:signal:signal_deliver { printf("%-6d %-16s signal %d\n", pid, comm, args.sig); }'

# 10. Cache miss sampling
bpftrace -e 'hardware:cache-misses:1000000 { @[comm, kstack(5)] = count(); }'

# 11. Context switch tracing
bpftrace -e 'tracepoint:sched:sched_switch { @[args.prev_comm] = count(); }'

# 12. Off-CPU time histogram (us)
bpftrace -e 'tracepoint:sched:sched_switch { @off[tid] = nsecs; }
  tracepoint:sched:sched_switch /@off[args.next_pid]/ {
  @us = hist((nsecs - @off[args.next_pid]) / 1000); delete(@off[args.next_pid]); }'

# 13. CPU profiling -- user stacks at 99 Hz
bpftrace -e 'profile:hz:99 { @[ustack] = count(); }'

# 14. Kernel stack on page fault
bpftrace -e 'software:page-faults:1 { @[kstack, comm] = count(); }'

# 15. VFS read latency (us)
bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; }
  kretprobe:vfs_read /@start[tid]/ { @us = hist((nsecs - @start[tid]) / 1000); delete(@start[tid]); }'

# 16. New process tracing
bpftrace -e 'tracepoint:syscalls:sys_enter_execve { printf("%-6d %-16s %s\n", pid, comm, str(args.filename)); }'

# 17. Filesystem sync latency (ms)
bpftrace -e 'kprobe:vfs_fsync { @start[tid] = nsecs; }
  kretprobe:vfs_fsync /@start[tid]/ { @ms = hist((nsecs - @start[tid]) / 1000000); delete(@start[tid]); }'

# 18. Scheduler run-queue latency (us)
bpftrace -e 'tracepoint:sched:sched_wakeup { @qstart[args.pid] = nsecs; }
  tracepoint:sched:sched_switch /@qstart[args.next_pid]/ {
  @us = hist((nsecs - @qstart[args.next_pid]) / 1000); delete(@qstart[args.next_pid]); }'

# 19. Socket accept tracing
bpftrace -e 'kretprobe:inet_csk_accept { printf("%-6d %-16s fd=%d\n", pid, comm, retval); }'

# 20. Timer interrupt frequency by CPU
bpftrace -e 'hardware:cpu-cycles:10000000 { @[cpu] = count(); }'
```

## Script Patterns

### Latency Measurement

```
kprobe:do_sys_openat2
{
    @start[tid] = nsecs;
}

kretprobe:do_sys_openat2
/@start[tid]/
{
    $dur = nsecs - @start[tid];
    @lat_us = hist($dur / 1000);
    @slow = $dur > 1000000 ? count() : @slow;  // >1ms
    delete(@start[tid]);
}

END { clear(@start); }
```

### Histogram with Filtering

```
tracepoint:syscalls:sys_exit_read
/args.ret > 0 && comm == "myapp"/
{
    @read_bytes = hist(args.ret);
    @total = sum(args.ret);
}

interval:s:5
{
    print(@read_bytes);
    clear(@read_bytes);
}
```

### State Machine (tracking across events)

```
tracepoint:syscalls:sys_enter_write
/comm == "myapp"/
{
    @wstart[tid] = nsecs;
    @wbuf[tid] = args.count;
}

tracepoint:syscalls:sys_exit_write
/@wstart[tid]/
{
    $lat = nsecs - @wstart[tid];
    printf("tid=%d wrote %d bytes in %d us\n", tid, @wbuf[tid], $lat / 1000);
    delete(@wstart[tid]);
    delete(@wbuf[tid]);
}
```

### Interval Summary Printing

```
profile:hz:99
{
    @stacks[ustack, comm] = count();
}

interval:s:10
{
    print(@stacks, 10);
    clear(@stacks);
}

END { clear(@stacks); }
```

## Tips

```
--unsafe                         enable system(), signal(), override()
-c 'CMD'                        run CMD and attach probes to it
-p PID                          attach to existing PID
-o FILE                         redirect output to file
-e 'prog'                       inline program
-l 'probe:pattern'              list matching probes
-lv 'tracepoint:sched:*'        list with argument details

BPFTRACE_STRLEN=200              max string length (default 64)
BPFTRACE_MAP_KEYS_MAX=8192       max map keys (default 4096)
BPFTRACE_MAX_PROBES=1024         max number of probes
BPFTRACE_STACK_MODE=bpftrace     stack output: bpftrace|perf|raw
BPFTRACE_NO_CPP_DEMANGLE=1       disable C++ demangling

printf("%d %s %lld\n", pid, comm, nsecs);   # formatted output
str(arg0)                        cast char* to string
buf(arg0, 32)                    binary buffer, 32 bytes
ksym(addr)                       kernel address to symbol
usym(addr)                       user address to symbol
kaddr("symbol")                  symbol to kernel address
cgroupid("/path")                cgroup path to ID
join(args.argv)                  join argv array (tracepoints)
sizeof(struct task_struct)       struct size
```
