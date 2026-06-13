# Resources: perf — vetted, citeable sources

Cite these in sessions. Prefer them over parametric memory for precise numbers
(latencies, port counts, ROB/buffer sizes, predictor tables, syscall costs, wire
behavior). Flag anything not attributable to one of these as `⚠ unsourced`.

## Primary / authoritative
- **Intel 64 & IA-32 Architectures Optimization Reference Manual** — microarchitecture,
  TMA, PMU events (cpu, mem, methodology, compiler).
- **Agner Fog** — microarchitecture docs + instruction tables (latency/throughput/ports)
  + optimizing-assembly/C++ guides (cpu, compiler).
- **AMD Software Optimization Guide** (per-family) — Zen microarchitecture (cpu, mem).
- **Intel SDM Vol 3** — memory ordering / x86-TSO, atomics, fences, TLB (concurrency, mem, kernel).
- **WikiChip** — per-uarch reference pages (cpu, mem).

## Memory & concurrency
- **Ulrich Drepper, "What Every Programmer Should Know About Memory"** (mem; dated but foundational).
- **Paul McKenney, "Is Parallel Programming Hard…"** + memory-barriers.txt (concurrency).
- **Preshing on Programming** — memory models, lock-free, atomics (concurrency).

## Methodology & profiling
- **Brendan Gregg** — *Systems Performance* (2e), USE method, flame graphs, BPF book (methodology, kernel).
- **Denis Bakhvalov, *Performance Analysis and Tuning on Modern CPUs*** (cpu, methodology).
- **`perf` wiki / man pages**, **Andi Kleen's pmu-tools / `toplev.py`** (methodology, cpu).
- **bpftrace reference guide** (methodology, kernel).
- **`llvm-mca` documentation** (cpu, compiler).

## Compiler & codegen
- **Compiler Explorer (godbolt)** — verify codegen claims directly (compiler).
- **GCC / Clang optimization & diagnostics docs** (`-fopt-info`, vectorization reports) (compiler).

## Kernel & OS
- **Linux kernel docs / source** — scheduler (CFS/EEVDF), io_uring, huge pages, preemption (kernel).
- **`man` pages** — syscalls, `vdso(7)`, `sched(7)`, `numa(7)` (kernel).

## System tuning (NUMA / affinity / NIC)
- **`numactl(8)`, `numa(7)`, `set_mempolicy(2)`/`mbind(2)`, libnuma `numa(3)`** — NUMA policy, placement, `numastat` (mem, kernel).
- **`ethtool(8)`** — NIC rings, coalescing, offloads, RSS/ntuple, `-S` counters, `-T` timestamping (kernel).
- **Linux kernel `Documentation/networking/scaling.rst`** — RSS / RPS / RFS / XPS steering (kernel).
- **Linux kernel `Documentation/networking/timestamping.rst`** + **linuxptp (`ptp4l`/`phc2sys`)** — SO_TIMESTAMPING, PHC, PTP (kernel).
- **Red Hat / SUSE low-latency tuning guides, `tuned` profiles** (`network-latency`, `latency-performance`) — consolidated knob sets (kernel).

> When a precise figure matters and isn't in the authored `knowledge/` banks, attribute
> it to one of the above. If you can't, say so and recommend which resource to check.
