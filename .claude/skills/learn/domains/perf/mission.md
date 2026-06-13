# Mission: perf

## Why
I'm a C++ core-infrastructure engineer on a market-data team (SBE + CME MDP 3.0) at a
hedge fund. Hot-path latency and throughput are the product. I need to *reason from
first principles* about what the hardware is doing — pipeline stalls, cache/TLB
behavior, branch misprediction, coherence traffic, codegen quality — not just read a
profiler and guess. The goal is to turn "the profile looks bad" into a specific,
defensible microarchitectural diagnosis and a fix. Reliability is half the product:
**determinism** — bounded tail latency, no jitter, no dropped packets — matters as much as
average speed, and is governed as much by how the runtime is *configured* (NUMA placement,
core isolation, NIC tuning) as by the code itself.

## What success looks like
- Given `perf stat` / `toplev.py` / `llvm-mca` output, name the dominant bottleneck and
  the right next diagnostic step, with the *why*.
- Connect each concept to the real workload: SBE decode pipelines, message-type dispatch
  branch patterns, field-extraction SIMD opportunities, NUMA/affinity for feed handlers.
- Diagnose and eliminate **tail-latency/jitter and packet drops**: given `numastat`,
  `ethtool -S`, or `/proc` drop counters, localize the cause (NUMA imbalance, NET_RX on an
  isolated core, AutoNUMA migration, NIC-ring vs kernel vs wire loss) and apply the right
  *configuration* lever for reliable p99.9 — not just average throughput.
- Comfortable across all six areas (cpu, mem, compiler, concurrency, methodology, kernel),
  not just cpu.
- Retain it — pass spaced flashcard review and scenario drills weeks later, not just in
  the moment.

## Deadline
No hard exam date — this is continuous mastery for the day job. Pace by consistency,
not by a deadline. (No `schedule` ⇒ all flashcards inject immediately.)

## Constraints / style
Skip basics. Prefer real tool output, concrete numbers, and a runnable command anchor.
Be honest about uncertainty — flag anything unsourced (exact ROB sizes, port counts,
predictor table sizes) so I can verify it.
All disassembly examples must use **Intel syntax** (destination-first, no `%`/`$` sigils).
Use `-M intel` with objdump/perf, `.intel_syntax noprefix` in inline asm examples.
