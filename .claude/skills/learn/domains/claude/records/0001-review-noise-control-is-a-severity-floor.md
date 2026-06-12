# 0001 — Review noise control is a severity floor, not a count cap
date: 2026-06-12
area: prompt
type: misconception
trigger: mm / "Prompting for code review" — review question on noise control

## What happened
When asked how to keep a code-review prompt from returning noise, I reached for a
**count cap** ("return at most N findings"). The better lever is a **severity floor**.

## Correct model / resolution
Capping the *count* can drop real high-severity issues to hit the number. A **severity
floor** ("only report issues at or above <severity>; exclude nits/style") filters by what
matters and lets the count fall out naturally. Pair with named domain failure modes
(for lock-free C++: memory ordering, false sharing) and explicit exclusions. A review is
worth what its criteria are worth.

## Revisit
Re-test: "make this review prompt return less noise" — confirm severity-floor + named
failure modes + exclusions, not a bare count cap.
