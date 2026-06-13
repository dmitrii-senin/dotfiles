# 0001 — Summary prefix anchors at 0, not at the lower endpoint
date: 2026-06-13
area: subnetting
type: misconception
trigger: subnet --mixed drill, problem 6 — summarize 10.7.{6,7,8,9}.0/24

## What happened
When asked for the smallest single summary covering a range that **straddles a
power-of-two boundary** (6–9 straddles the /22 boundary at 8), I picked
`10.7.16.0/20` — anchoring the summary near the *upper* end of the range. That
prefix actually covers 3rd-octet 16–31 and contains none of the target networks.

This is the 3rd recurring miss on `subnetting:summarization-boundary`
(misses 3 / attempts 8, last_score 0.0). The earlier two showed the same shape:
treating the lower endpoint as the anchor instead of rounding it down to the
block-aligned boundary.

## Correct model / resolution
A `/N` summary prefix has block size `2^(32-N)` and is **aligned** at multiples
of that block size. To find the smallest single covering summary:

1. Take the lower bound (here `.6` in the 3rd octet) and round it **down** to
   the alignment of the candidate prefix.
2. Start at `/22` (block 4). Does `floor(6/4)*4 = 4` give a block that contains
   both 6 and 9? Block is 4–7. No — 8 and 9 are outside.
3. Try `/21` (block 8). `floor(6/8)*8 = 0`. Block is 0–7. Still misses 8, 9.
4. Try `/20` (block 16). `floor(6/16)*16 = 0`. Block is 0–15. ✓ contains 6–9.

→ Summary: `10.7.0.0/20` (collateral: 12 extra /24s — .0–.5 and .10–.15).

The anchor of *any* covering summary is the lower bound **rounded down** to the
prefix's alignment. It is never the lower bound as-given, unless the lower
bound happens to be on the boundary.

When collateral is unacceptable, split: `10.7.6.0/23` + `10.7.8.0/23` covers
exactly {6,7,8,9} with zero extras.

## Revisit
Re-test in the next `subnet` session with at least one boundary-straddling
summarization problem; if scored ≥ 1.0 two sessions in a row, downgrade this
from recurring. Vary the straddle octet (3rd vs 4th) and the straddle width
(/22, /21, /20 alignments).
