# PMC Events Quick Reference

Performance Monitoring Counter events organized by bottleneck category.
Event names are Intel Skylake/Ice Lake conventions; AMD equivalents often differ.

---

## 1. TMA Level 1 — Top-Down Microarchitecture Analysis

Base events needed:

```bash
perf stat -e '{cpu_clk_unhalted.thread,idq_uops_not_delivered.core,uops_issued.any,uops_retired.retire_slots,int_misc.recovery_cycles}' ./a.out
```

| Metric          | Formula                                                                  |
|-----------------|--------------------------------------------------------------------------|
| Frontend Bound  | `idq_uops_not_delivered.core / (4 * cpu_clk_unhalted.thread)`            |
| Bad Speculation | `(uops_issued.any - uops_retired.retire_slots + 4 * int_misc.recovery_cycles) / (4 * cpu_clk_unhalted.thread)` |
| Retiring        | `uops_retired.retire_slots / (4 * cpu_clk_unhalted.thread)`             |
| Backend Bound   | `1 - Frontend_Bound - Bad_Speculation - Retiring`                        |

The `4` is pipeline width (adjust for your microarch: 5 for Golden Cove, 6 for Zen 4).

Or just use:
```bash
perf stat --topdown ./a.out          # auto-computes L1 TMA metrics
perf stat --topdown -l2 ./a.out      # L1+L2 breakdown (kernel 5.14+)
```

---

## 2. Frontend Events

```bash
# DSB vs MITE vs MS delivery
perf stat -e '{idq.dsb_uops,idq.mite_uops,idq.ms_uops}' ./a.out

# Frontend stalls and icache pressure
perf stat -e '{stalled-cycles-frontend,icache_64b.iftag_miss,dsb2mite_switches.penalty_cycles}' ./a.out
```

| Event                              | What it measures                                  |
|------------------------------------|---------------------------------------------------|
| `idq.dsb_uops`                    | uops delivered from DSB (uop cache) -- fast path  |
| `idq.mite_uops`                   | uops delivered from MITE (legacy decode) -- slow  |
| `idq.ms_uops`                     | uops from microcode sequencer (complex insns)     |
| `icache_64b.iftag_miss`           | L1 instruction cache misses                       |
| `dsb2mite_switches.penalty_cycles`| penalty cycles from DSB-to-MITE fallback          |
| `stalled-cycles-frontend`         | cycles the frontend produced no uops              |

**Diagnosis:** high `mite_uops / (dsb_uops + mite_uops)` ratio means code is too large or misaligned for the uop cache. High `ms_uops` means heavy use of microcoded instructions (e.g., `rep movsb`, `div`).

---

## 3. Backend Events

```bash
# Resource stalls
perf stat -e '{stalled-cycles-backend,resource_stalls.any,resource_stalls.sb,resource_stalls.rob}' ./a.out

# Memory-induced stalls by cache level
perf stat -e '{cycle_activity.stalls_mem_any,cycle_activity.stalls_l1d_miss,cycle_activity.stalls_l2_miss,cycle_activity.stalls_l3_miss}' ./a.out

# Execution port utilization (Skylake ports 0-7)
perf stat -e '{uops_dispatched_port.port_0,uops_dispatched_port.port_1,uops_dispatched_port.port_2,uops_dispatched_port.port_3,uops_dispatched_port.port_4,uops_dispatched_port.port_5,uops_dispatched_port.port_6,uops_dispatched_port.port_7}' ./a.out

# Store-bound detection
perf stat -e exe_activity.bound_on_stores ./a.out
```

| Event                              | What it measures                                   |
|------------------------------------|----------------------------------------------------|
| `stalled-cycles-backend`           | cycles backend could not accept uops               |
| `resource_stalls.any`              | stalls due to any resource exhaustion               |
| `resource_stalls.sb`               | store buffer full                                   |
| `resource_stalls.rob`              | reorder buffer full                                 |
| `cycle_activity.stalls_mem_any`    | execution stalls waiting on any memory              |
| `cycle_activity.stalls_l1d_miss`   | stalls due to L1d misses                            |
| `cycle_activity.stalls_l2_miss`    | stalls due to L2 misses                             |
| `cycle_activity.stalls_l3_miss`    | stalls due to L3 misses (going to DRAM)             |
| `exe_activity.bound_on_stores`     | cycles stores cannot retire (store-bound)           |
| `uops_dispatched_port.port_N`      | uops dispatched to port N (identify port pressure)  |

---

## 4. Memory Events — Cache, TLB, Bandwidth

```bash
# Generic cache hierarchy
perf stat -e '{cache-references,cache-misses,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses}' ./a.out

# Precise memory retirement (use for sampling — supports PEBS)
perf stat -e '{mem_load_retired.l1_hit,mem_load_retired.l2_hit,mem_load_retired.l3_hit,mem_load_retired.l3_miss,mem_load_retired.fb_hit}' ./a.out

# TLB misses
perf stat -e '{dTLB-load-misses,dTLB-store-misses,iTLB-load-misses}' ./a.out

# Offcore and special
perf stat -e '{offcore_response.all_reads.any_response,ld_blocks.store_forward}' ./a.out
```

| Event                                       | What it measures                        |
|---------------------------------------------|-----------------------------------------|
| `cache-references`                          | LLC accesses (generic)                  |
| `cache-misses`                              | LLC misses (generic)                    |
| `L1-dcache-loads` / `-load-misses`          | L1 data cache loads / misses            |
| `LLC-loads` / `-load-misses`                | last-level cache loads / misses         |
| `dTLB-load-misses` / `-store-misses`        | data TLB misses on loads / stores       |
| `iTLB-load-misses`                          | instruction TLB misses                  |
| `mem_load_retired.l1_hit`                   | loads retired hitting L1d               |
| `mem_load_retired.l2_hit`                   | loads retired hitting L2                |
| `mem_load_retired.l3_hit`                   | loads retired hitting L3                |
| `mem_load_retired.l3_miss`                  | loads retired missing L3 (went to DRAM) |
| `mem_load_retired.fb_hit`                   | loads hitting line fill buffer          |
| `offcore_response.all_reads.any_response`   | all offcore read transactions           |
| `ld_blocks.store_forward`                   | failed store-to-load forwarding         |

---

## 5. Branch Events

```bash
perf stat -e '{branches,branch-misses,br_misp_retired.all_branches,br_misp_retired.near_taken,br_misp_retired.conditional}' ./a.out

perf stat -e '{baclears.any,br_inst_retired.near_call,br_inst_retired.near_return}' ./a.out
```

| Event                              | What it measures                                   |
|------------------------------------|----------------------------------------------------|
| `branches`                         | total branch instructions retired                  |
| `branch-misses`                    | total mispredicted branches                        |
| `br_misp_retired.all_branches`     | mispredicted branches (precise, PEBS-capable)      |
| `br_misp_retired.near_taken`       | mispredicted near taken branches                   |
| `br_misp_retired.conditional`      | mispredicted conditional branches                  |
| `baclears.any`                     | branch address calculator clears (early mispredict)|
| `br_inst_retired.near_call`        | near call instructions retired                     |
| `br_inst_retired.near_return`      | near return instructions retired                   |

---

## 6. Speculation & Machine Clears

```bash
perf stat -e '{machine_clears.count,machine_clears.memory_ordering,machine_clears.smc,int_misc.recovery_cycles}' ./a.out
```

| Event                              | What it measures                                   |
|------------------------------------|----------------------------------------------------|
| `machine_clears.count`             | total pipeline clears (all causes)                 |
| `machine_clears.memory_ordering`   | clears from memory ordering violations             |
| `machine_clears.smc`              | clears from self-modifying code detection          |
| `int_misc.recovery_cycles`        | cycles spent in pipeline recovery after clear      |

High `memory_ordering` clears: check for false sharing (`perf c2c`) or missing fences.
High `smc` clears: JIT/runtime code patching hitting the wrong path.

---

## 7. Raw Event Encoding

When `perf list` does not expose an event by name:

```bash
# Format: rUUEE (UU = umask, EE = event select)
perf stat -e r04C4 ./a.out           # machine_clears.count (event 0xC4, umask 0x04)
perf stat -e r01C4 ./a.out           # machine_clears.smc   (event 0xC4, umask 0x01)

# With modifiers
perf stat -e r04C4:u ./a.out         # user-space only
perf stat -e r04C4:k ./a.out         # kernel only
```

**Finding raw codes:**
- Intel SDM Volume 3B, Chapter 19 (per-microarch event tables)
- `perf list` — show named events available on this kernel/CPU
- `ocperf.py list` — pmu-tools extended names (maps friendly names to raw codes)
- `/sys/bus/event_source/devices/cpu/events/` — kernel-exported event definitions

---

## 8. Event Groups

Group events with `{}` to ensure they are read from PMU counters simultaneously (no multiplexing skew between them):

```bash
# Counting group — ratios between these events are accurate
perf stat -e '{cycles,instructions,cache-misses}' ./a.out

# Multiple groups
perf stat -e '{cycles,instructions}' -e '{cache-references,cache-misses}' ./a.out

# Sampling group — leader event triggers, all group members recorded
perf record -e '{cycles,cache-misses}:S' ./a.out

# Named group
perf stat -e '{cycles,instructions}:G=ipc_group' ./a.out
```

**Why it matters:** without grouping, perf multiplexes events across time slices. Ratios between multiplexed events have error bars. Grouped events are always co-scheduled.

PMU counter limit: typically 4 GP + 3 fixed counters. Groups exceeding this will not schedule.

---

## 9. Common Derived Metrics

| Metric                  | Formula                                                     |
|-------------------------|-------------------------------------------------------------|
| IPC                     | `instructions / cycles`                                     |
| CPI                     | `cycles / instructions`                                     |
| L1 miss rate            | `L1-dcache-load-misses / L1-dcache-loads`                   |
| LLC miss rate           | `LLC-load-misses / LLC-loads`                                |
| Branch mispredict rate  | `branch-misses / branches`                                  |
| MPKI (misses per Ki)    | `(misses * 1000) / instructions`                            |
| DSB coverage            | `idq.dsb_uops / (idq.dsb_uops + idq.mite_uops)`           |
| Store fwd fail rate     | `ld_blocks.store_forward / L1-dcache-loads`                 |

**Quick IPC + cache check:**
```bash
perf stat -e '{instructions,cycles,L1-dcache-loads,L1-dcache-load-misses,LLC-loads,LLC-load-misses,branch-misses,branches}' ./a.out
```

**Rules of thumb:**
- IPC > 2.0 = compute-bound, look at port pressure
- IPC < 1.0 = likely memory or branch bound
- L1 miss rate > 5% = review data layout / access patterns
- Branch mispredict > 2% = consider branchless alternatives
- MPKI > 10 for LLC = significant DRAM traffic
