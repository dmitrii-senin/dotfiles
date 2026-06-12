# Mission: perf

## Why
I'm a C++ core-infrastructure engineer on a market-data team (SBE + CME MDP 3.0) at a
hedge fund. Hot-path latency and throughput are the product. I need to *reason from
first principles* about what the hardware is doing — pipeline stalls, cache/TLB
behavior, branch misprediction, coherence traffic, codegen quality — not just read a
profiler and guess. The goal is to turn "the profile looks bad" into a specific,
defensible microarchitectural diagnosis and a fix.

## What success looks like
- Given `perf stat` / `toplev.py` / `llvm-mca` output, name the dominant bottleneck and
  the right next diagnostic step, with the *why*.
- Connect each concept to the real workload: SBE decode pipelines, message-type dispatch
  branch patterns, field-extraction SIMD opportunities, NUMA/affinity for feed handlers.
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
