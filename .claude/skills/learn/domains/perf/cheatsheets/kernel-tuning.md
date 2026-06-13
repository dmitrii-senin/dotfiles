# Linux Kernel Tuning for Low-Latency C++

Quick reference for sysctl, boot params, and runtime settings targeting sub-microsecond determinism.

---

## 1. CPU Isolation and Affinity

**Boot parameters** (add to GRUB_CMDLINE_LINUX):

| Parameter | Example | Effect |
|-----------|---------|--------|
| `isolcpus` | `isolcpus=2-7` | Remove cores from general scheduler |
| `nohz_full` | `nohz_full=2-7` | Disable timer ticks on isolated cores (tickless) |
| `rcu_nocbs` | `rcu_nocbs=2-7` | Offload RCU callbacks to housekeeping cores |
| `irqaffinity` | `irqaffinity=0-1` | Restrict hardware IRQs to housekeeping cores |

**Runtime:**

```bash
taskset -c 3 ./program              # pin process to core 3
taskset -c 3,5 ./program            # pin to cores 3 and 5
chrt -f 90 ./program                # SCHED_FIFO priority 90 (1-99, higher = more urgent)
cpupower frequency-set -g performance  # lock CPU governor to max freq (all cores)
cpupower -c 2-7 frequency-set -g performance  # specific cores only
```

---

## 2. Scheduling

| Sysctl | Recommended | Default | Effect |
|--------|-------------|---------|--------|
| `kernel.sched_min_granularity_ns` | `10000000` | `750000` | Min timeslice before preemption (raise to reduce context switches) |
| `kernel.sched_latency_ns` | `24000000` | `6000000` | Target CFS scheduling period |
| `kernel.sched_migration_cost_ns` | `5000000` | `500000` | Raise to reduce cross-core migrations (cache thrashing) |
| `kernel.sched_rt_runtime_us` | `-1` | `950000` | RT throttle limit; -1 disables RT throttling |
| `kernel.sched_nr_migrate` | `1` | `32` | Max tasks moved per migration event |

**Scheduler policies:**

| Policy | Use case |
|--------|----------|
| `SCHED_FIFO` | Hot-path threads: runs until it yields or is preempted by higher prio |
| `SCHED_RR` | Multiple same-priority RT threads needing round-robin timeslicing |
| `SCHED_DEADLINE` | Hard real-time with explicit period/deadline/runtime budgets |

For market data: `SCHED_FIFO` on the critical path, `SCHED_OTHER` for housekeeping.

---

## 3. Memory

| Setting | Value | Effect |
|---------|-------|--------|
| `vm.nr_hugepages` | `1024` | Preallocate N 2MB huge pages (set at boot for contiguous memory) |
| `vm.swappiness` | `0` | Minimize swap usage; kernel avoids swapping almost entirely |
| `vm.overcommit_memory` | `2` | Strict: fail allocations beyond commit limit (no OOM surprises) |
| `vm.zone_reclaim_mode` | `0` | Disable NUMA zone reclaim (avoids latency spikes on NUMA systems) |
| `vm.min_free_kbytes` | `262144` | Keep 256MB free to avoid direct reclaim stalls |
| `vm.dirty_ratio` | `5` | Reduce dirty page writeback storms |
| `vm.dirty_background_ratio` | `2` | Start background writeback earlier |

**In code:**

```cpp
#include <sys/mman.h>
mlockall(MCL_CURRENT | MCL_FUTURE);  // lock all pages, prevent page faults
madvise(ptr, size, MADV_HUGEPAGE);   // hint to use huge pages for this region
```

**Disable THP at boot:**

```bash
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

Or via boot param: `transparent_hugepage=never`

**NUMA placement (numactl):**

| Command | Effect |
|---------|--------|
| `numactl --hardware` (`-H`) | Show nodes, per-node CPUs, free memory, inter-node distances |
| `numactl --show` | Print the **effective** policy of the current context |
| `numactl --cpunodebind=0 --membind=0 ./app` | Run on node 0's CPUs, allocate strictly on node 0 |
| `numactl --physcpubind=2,3 --membind=0 ./app` | Pin to exact cores 2,3; memory on node 0 |
| `numactl --interleave=all ./app` | Round-robin pages across nodes (bandwidth) |
| `numactl --preferred=0 ./app` | Prefer node 0, fall back if full |

`--cpunodebind` allows migration within the node; `--physcpubind` is exact. numactl sets the
**default policy at exec** — it does not relocate already-touched pages.

**Diagnose placement:**

```bash
numastat -p $(pgrep app)              # numa_hit / numa_foreign / other_node per process
cat /proc/$(pgrep app)/numa_maps      # per-VMA node residency
sysctl kernel.numa_balancing          # 0 = AutoNUMA off (set 0 for low-latency: migration = jitter)
```

**In code (libnuma, `-lnuma`):**

```cpp
#include <numa.h>
numa_run_on_node(0);                       // bind calling thread's CPUs to node 0
void* p = numa_alloc_onnode(size, 0);      // allocate on node 0
// or per-region: mbind(p, len, MPOL_BIND, &nodemask, maxnode, MPOL_MF_MOVE);
```

---

## 4. Network

| Sysctl | Value | Effect |
|--------|-------|--------|
| `net.core.busy_read` | `50` | Busy-poll microseconds for socket reads |
| `net.core.busy_poll` | `50` | Busy-poll microseconds for poll/select/epoll |
| `net.core.rmem_max` | `16777216` | Max receive buffer (16MB) |
| `net.core.wmem_max` | `16777216` | Max send buffer (16MB) |
| `net.core.rmem_default` | `1048576` | Default receive buffer (1MB) |
| `net.core.netdev_max_backlog` | `30000` | Increase for bursty multicast traffic |
| `net.core.somaxconn` | `4096` | Max listen backlog |
| `net.ipv4.tcp_timestamps` | `0` | Disable TCP timestamps (saves ~10 bytes/pkt) |
| `net.ipv4.tcp_sack` | `0` | Disable SACK for simpler TCP processing |

**Per-socket busy polling** (in code):

```cpp
int val = 50;
setsockopt(fd, SOL_SOCKET, SO_BUSY_POLL, &val, sizeof(val));
```

**Disable IRQ coalescing** (lowest latency, highest CPU):

```bash
ethtool -C eth0 rx-usecs 0 tx-usecs 0 rx-frames 1 tx-frames 1
ethtool -C eth0 adaptive-rx off adaptive-tx off
```

**Pin NIC queues to specific cores:**

```bash
ethtool -L eth0 combined 2          # set number of queues
echo 4 > /proc/irq/N/smp_affinity  # pin queue IRQ to core 2
```

**RX/TX rings — absorb bursts (raise before growing socket buffers):**

```bash
ethtool -g eth0                     # show current + preset-max ring sizes
ethtool -G eth0 rx 4096             # enlarge RX ring (drops show as rx_no_buffer_count)
```

**Offloads — disable aggregation for per-packet latency:**

```bash
ethtool -k eth0 | grep -E 'generic-receive|large-receive'
ethtool -K eth0 gro off lro off     # GRO/LRO hold packets tens of µs to coalesce
```

**RSS + deterministic flow steering:**

```bash
ethtool -x eth0                              # view hash + indirection table
ethtool -K eth0 ntuple on
ethtool -N eth0 flow-type udp4 dst-port 14310 action 3   # steer this feed to queue 3
# then pin queue 3's IRQ to a housekeeping core via /proc/irq/N/smp_affinity
```

**Hardware timestamping / PTP:**

```bash
ethtool -T eth0                     # report HW timestamp caps + PHC index (verify before use)
ptp4l -i eth0 -m &                  # discipline /dev/ptp0 to grandmaster
phc2sys -s eth0 -w -m &             # copy PHC time into the system clock
```

**Drop localization (`ethtool -S` NIC counters vs kernel/socket):**

| Counter / source | Layer implicated |
|------------------|------------------|
| `ethtool -S` `rx_no_buffer_count`, `rx_missed_errors` | Host RX ring empty (sw too slow / ring too small) |
| `ethtool -S` `rx_fifo_errors` | NIC on-chip FIFO overflow (PCIe/host-bandwidth bound) |
| `/proc/net/udp` `drops`, `netstat -su` | Socket receive buffer overflow (kernel/app) |
| `/proc/net/softnet_stat` col 2 | Per-CPU backlog drops (NET_RX saturation) |
| Seq gap with **no** local counters moving | Upstream / wire / A-B feed arbitration |

---

## 5. Interrupts

```bash
service irqbalance stop             # disable automatic IRQ balancing
systemctl disable irqbalance

# Pin IRQ N to core 1 (bitmask: 0x2)
echo 2 > /proc/irq/N/smp_affinity

# Pin IRQ N to core 0 and 1 (bitmask: 0x3)
echo 3 > /proc/irq/N/smp_affinity

# View current IRQ distribution
cat /proc/interrupts | grep eth
```

**NAPI tradeoffs:** NAPI batches interrupt processing (good for throughput, adds latency). For lowest latency, disable coalescing and keep NAPI budget low:

```bash
sysctl -w net.core.netdev_budget=50
```

---

## 6. Transparent Huge Pages (THP)

| Path | Values | Recommendation |
|------|--------|----------------|
| `/sys/kernel/mm/transparent_hugepage/enabled` | `always`, `madvise`, `never` | `never` |
| `/sys/kernel/mm/transparent_hugepage/defrag` | `always`, `defer`, `defer+madvise`, `madvise`, `never` | `never` |

**Why THP causes latency spikes:**
- `khugepaged` compaction daemon runs in background, takes mmap_lock
- Direct reclaim triggered when kernel tries to assemble 2MB pages under memory pressure
- THP splits/collapses cause unpredictable stalls (100us-10ms observed)

**Recommendation:** Set `never` globally. Use explicit huge pages (`mmap` with `MAP_HUGETLB`) for known large allocations (order books, ring buffers).

---

## 7. Timer and Clock

| Setting | Value | Effect |
|---------|-------|--------|
| `CONFIG_HZ` | `1000` | Kernel tick rate; 1000 = 1ms resolution (compile-time) |
| `CONFIG_NO_HZ_FULL` | `y` | Enable adaptive-ticks / tickless (compile-time) |
| `CONFIG_HIGH_RES_TIMERS` | `y` | Nanosecond-resolution timers (compile-time) |
| `tsc=reliable` | boot param | Trust TSC stability even if kernel is unsure |

**Verify clocksource is TSC:**

```bash
cat /sys/devices/system/clocksource/clocksource0/current_clocksource
# should output: tsc
```

If not TSC: `echo tsc > /sys/devices/system/clocksource/clocksource0/current_clocksource`

---

## 8. Power Management

| Parameter | Type | Effect |
|-----------|------|--------|
| `intel_pstate=disable` | boot | Use acpi-cpufreq driver (finer control) |
| `processor.max_cstate=1` | boot | Disable deep C-states (C1 only) |
| `intel_idle.max_cstate=0` | boot | Disable intel_idle driver entirely |
| `idle=poll` | boot | Never enter any C-state (highest power, lowest wake latency) |

**Runtime frequency pinning:**

```bash
# Disable turbo boost (reduces frequency variance)
echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo
# Or with acpi-cpufreq:
cpupower frequency-set -d 3400MHz -u 3400MHz  # pin to exact frequency
```

C-state wake latencies: C1 ~1us, C3 ~50us, C6 ~100-200us. For ultra-low-latency, `idle=poll` eliminates all wake-up cost at the expense of burning full power.

---

## 9. Complete Low-Latency Boot Cmdline

Example for a market data system (8-core, cores 0-1 housekeeping, 2-7 isolated):

```
GRUB_CMDLINE_LINUX="isolcpus=2-7 nohz_full=2-7 rcu_nocbs=2-7 irqaffinity=0-1 \
  intel_pstate=disable processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll \
  transparent_hugepage=never tsc=reliable nosoftlockup skew_tick=1 \
  default_hugepagesz=2M hugepagesz=2M hugepages=1024"
```

| Param | Purpose |
|-------|---------|
| `nosoftlockup` | Suppress false lockup warnings on busy-spinning cores |
| `skew_tick=1` | Offset timer ticks across cores to avoid simultaneous interrupts |

After editing `/etc/default/grub`, run `update-grub && reboot`.

---

## 10. Verification Commands

```bash
# Boot params
cat /proc/cmdline

# Isolated cores
cat /sys/devices/system/cpu/isolated

# Clocksource
cat /sys/devices/system/clocksource/clocksource0/current_clocksource

# Huge pages
grep -i huge /proc/meminfo

# CPU frequency and C-states
turbostat --Summary --show Avg_MHz,Busy%,Bzy_MHz --interval 1

# THP status
cat /sys/kernel/mm/transparent_hugepage/enabled

# Scheduling latency measurement
cyclictest -m -p 90 -i 1000 -l 10000
# Target: max latency < 10us on isolated cores

# IRQ affinity check
for i in $(ls /proc/irq/); do
  [ -f /proc/irq/$i/smp_affinity ] && \
    echo "IRQ $i: $(cat /proc/irq/$i/smp_affinity) $(cat /proc/irq/$i/smp_affinity_list 2>/dev/null)"
done

# NUMA topology
numactl --hardware
lscpu | grep -i numa
```
