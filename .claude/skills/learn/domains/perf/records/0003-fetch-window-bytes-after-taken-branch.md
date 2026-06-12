# 0003 — Usable fetch-window bytes after a taken branch
date: 2026-06-04
area: cpu
type: misconception
trigger: mm / "The fetch-decode frontend" — review (byte-counting question)

## What happened
Miscounted the usable bytes in the 16-byte fetch window after a taken branch — said 10,
correct is 9. Tracked weak area `cpu/fetch-window-byte-counting`.

## Correct model / resolution
The legacy decode front-end fetches in **16-byte aligned windows**. After a taken
branch, usable bytes depend on the **target's offset within its 16-byte window** —
only the bytes from the target to the end of that aligned window are usable on that
cycle, so a target landing mid-window leaves fewer than 16 (here, 9). Alignment of
branch targets affects front-end throughput. (Verify the exact window mechanics and any
JCC-erratum interaction against the Intel Optimization Manual — legacy decode / fetch.)

## Revisit
Re-test with a few target offsets; confirm the "bytes = window_end − target_offset"
reasoning and the role of target alignment.
