# 0002 — Accumulator count = chain latency ÷ reciprocal throughput
date: 2026-06-04
area: cpu
type: misconception
trigger: mm / "Instruction latency vs throughput" — review (accumulator-count question)

## What happened
Confused **reciprocal throughput 0.5** (= 2 ops/cycle) with "0.5/cycle", and sized the
accumulator split as K=2 when the correct answer was K=8. This is the tracked weak area
`cpu/accumulator-sizing`.

## Correct model / resolution
To hide a latency-bound dependency chain, the number of independent accumulators you
need is **K = (dependency-chain latency) ÷ (reciprocal throughput of the op)**. E.g. an
FP add with latency 4 and reciprocal throughput 0.5 needs K = 4 / 0.5 = **8** to
saturate the unit. Reciprocal throughput is *cycles per op* (0.5 ⇒ two per cycle), not
ops per cycle. (Verify per-op latency/throughput against Agner Fog's tables.)

## Revisit
Re-drill with different latency/throughput pairs until the K = lat / recip-tput formula
is automatic; watch for the reciprocal-throughput direction error.
