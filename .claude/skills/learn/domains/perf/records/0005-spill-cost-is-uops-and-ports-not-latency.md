# 0005 — Spill cost is uops + ports + OoO window, not memory latency

date: 2026-06-12
area: cpu
type: misconception
trigger: mm session "x86-64 register file and calling convention" — drill (b) and review Q1

## What happened
When asked *why* spill/fill `mov [rsp+X]` traffic costs cycles, explained it as the
*cause* of spilling ("only 14 GPRs, ran out of registers") rather than the *cost
mechanism*. Implicit assumption that the cost is memory access latency. Same gap on
stack-passed 7th argument (called it "spill/fill of a register" — no register is
allocated for it).

## Correct model / resolution
A spilled value reloaded soon after hits **store-to-load forwarding (~5 cyc on
Skylake ⚠ Agner Fog)** or L1 (~4–5 cyc) — the latency is largely *hidden*. The real
cost is **resource pressure**:
- each spill+fill is **extra uops** occupying ROB/RS entries → **shrinks the effective
  OoO window**, so less unrelated latency gets hidden;
- fills are **loads competing for the two load ports** (2 & 3 on Skylake ⚠) — in a
  decode loop already streaming bytes, that port contention is usually the dominant tax;
- code-size inflation can pressure DSB/L1i.
A 7th `long` arg passes **on the stack**: caller stores it before the call, callee
loads it — memory traffic per call, never register-resident across the boundary.
Source: System V AMD64 psABI §3.2; Agner Fog, microarchitecture & calling-conventions.

## Revisit
Re-test the *cost-in-resources* framing (not "memory is slow") inside the upcoming
"Out-of-order execution and the ROB" and "SIMD execution units and port pressure"
sessions — both reinforce why extra uops/loads shrink the window. See [[0002-accumulator-sizing]].
