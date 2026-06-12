# Record 0004 — jump table: misprediction vs cache miss

**Area:** methodology | **Date:** 2026-06-12

## Misconception

Attributed 38% samples on a jump table `movsxd` to a cache miss. The jump table
had ≤33 entries (132 bytes, 2 cache lines) — far too small to miss L1d in a hot
loop. The real cause: indirect branch misprediction on the `jmp [rdx]` that
follows, with samples retiring back to the feeding load.

## Rule

Before assuming cache miss on a hot load, check the **data structure size**. If
it fits in 2–3 cache lines and the loop is hot, it's L1-resident. Then check
what the loaded value *feeds* — if it feeds an indirect branch, the bottleneck
is branch prediction, not memory.

## Key event

`BR_MISP_RETIRED.INDIRECT` — directly counts mispredicted indirect branches.
Use instead of cache-miss counters when the loaded data is small.

## Revisit

Drill on distinguishing cache-miss loads from misprediction-feeding loads in
`perf annotate` output. Practice sizing data structures against cache line counts.
