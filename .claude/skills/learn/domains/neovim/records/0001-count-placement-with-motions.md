# 0001 — Count goes before the operator/motion, not inside it
date: 2026-06-12
area: core
type: misconception
trigger: mm / "Word motions" — review (count placement) + drill follow-ups

## What happened
Placed the count in the wrong spot — reached for `dt2` when the intent was "delete to the
2nd occurrence". Tracked weak area `core/count-placement-with-motions`.

## Correct model / resolution
The count attaches to the **motion** (or operator), before it: `d2t<char>` = delete up to
the **2nd** `<char>`; `2dt<char>` and `d2t<char>` both work (counts multiply), but the
count belongs *before* the `t`, never after it (`dt2` searches for the literal `2`).
General rule: `[count]operator[count]motion` — counts precede what they modify.

## Revisit
Re-drill `d2t<x>`, `2fw`, `c3w`, `"a3yy` until count-before-motion is automatic; watch for
the "count after the motion char" slip.
