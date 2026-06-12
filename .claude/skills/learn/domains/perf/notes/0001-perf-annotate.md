# perf annotate — source and assembly correlation

**Area:** methodology | **Difficulty:** intermediate | **Date:** 2026-06-12

## Core concept

`perf annotate` maps samples to individual instructions within a function,
bridging `perf report` (function-level) to instruction-level analysis. Works on
the same `perf.data` — no re-recording needed.

## Key commands

| Command | Use case |
|---------|----------|
| `perf annotate -s <sym> --stdio` | Quick single-function view |
| `perf annotate --source --stdio` | Interleave C++ source (needs `-g`) |
| `perf annotate --no-source --stdio` | Pure asm — best for inlined/template code |
| `perf annotate -M intel --stdio` | Intel syntax |
| Press `a` in `perf report` TUI | Annotate in place |

## Retirement-bias mental model

Samples land on the instruction waiting to **retire**, not the one that caused
the stall. On OoO x86, look 1–3 instructions **above** the hot instruction for
the true cause (a cache-miss load or a branch feeding a mispredict).

- **Hot load from memory** → likely the direct culprit (cache miss).
- **Hot ALU/register mov** → stalled behind an upstream load's cache miss.
- **Hot load feeding an indirect jump** → likely indirect branch misprediction,
  especially if the loaded data structure is small enough for L1 (< 2–3 cache lines).

## PEBS for precise attribution

`perf record -e cycles:pp` uses PEBS to reduce IP skid to near-zero. Without
`:pp`, samples can be 1–3 instructions off from the true stall point.

## Inlined functions

If a function is inlined, `perf annotate -s <func>` returns "symbol not found."
Fix: annotate the **caller** (`perf report` shows where samples landed), then
find the inlined code by its instruction pattern. `--no-source` helps here
because source-line mapping gets confused across inlining boundaries.

## Workflow position

```
perf stat -M TopdownL1  →  "Backend Bound 65%"
perf report             →  "decode_field() at 28%"
perf annotate           →  "mov (%rax,%rcx,8) at 35%"  ← YOU ARE HERE
perf stat -e BR_MISP_RETIRED.INDIRECT  or  perf mem  →  confirm mechanism
```

**Sources:** Intel Optimization Reference Manual §B.3.1; Intel SDM Vol. 3 §18.4.4 (PEBS);
Brendan Gregg, *Systems Performance* 2nd ed. §6.6; Agner Fog, *Microarchitecture* §3.15.
