# 0001 — DSB is indexed by 32-byte code regions, not by uop count
date: 2026-05-29
area: cpu
type: misconception
trigger: mm / "uop cache (DSB) and decode bottlenecks" — drill + review Q4

## What happened
Estimated DSB working set using a **uop count** instead of **32-byte aligned code
regions**, and on review couldn't articulate the DSB→MITE switch cost (the 2–3 cycle
bubble). Also defaulted to `[[unlikely]]` for cold-code separation but missed
`__attribute__((cold))` and BOLT as the stronger tools.

## Correct model / resolution
The DSB (µop cache) is indexed by **32-byte-aligned instruction-stream regions**, so
interleaving hot and cold code causes set conflicts even when the cold code never
executes. Separate cold paths physically (`__attribute__((cold))`, section placement,
BOLT/PGO). Switching DSB→MITE costs a few cycles. (Verify exact figures against the
Intel Optimization Manual — µop cache section.)

## Revisit
Re-test: "given a hot loop with interleaved cold branches and high MITE%, what's the
cause and the fix?" Confirm the 32B-region framing and name BOLT/PGO.
