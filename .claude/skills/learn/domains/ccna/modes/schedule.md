# `schedule` mode (ccna) — where am I in the plan

The default mode (bare `/ccna`). Reads `ccna.md` (the canonical study plan) and tells the
user where they are. Invoked as `/learn ccna schedule [week|next|overview|N]`.

**Subcommands:** `schedule` (current week) · `schedule week N` / `schedule N` (jump) ·
`schedule next` (preview) · `schedule overview` (all phases).

## Computing the current week
1. Read the **Plan start date** from `ccna.md` (`**Plan start date:** Monday **YYYY-MM-DD**`) — source of truth (currently 2026-05-04).
2. Today via `date +%Y-%m-%d`.
3. `current_week = floor((today − start) / 7) + 1`; `days_into_week = (today − start) % 7`.

## Output (current / specific week)
```
Week N of 26 — Phase X (Name) — D days into the week
Date: YYYY-MM-DD · Exam in W weeks (target: 2026-11-23)

This week's targets:
  Theory:  • Jeremy's IT Lab Day X-Y   • OCG Vol N Ch A-B
  Lab:     • <lab task from plan>
  Notes:   • <other bullets from the weekly section>

Cross-cutting habits:
  □ Daily subnetting (10) — last drill: <date or "never">
  □ Daily flashcards — N cards due today
  □ Weekly weak-area quiz (Sun) — last run: <date or "never">

Upcoming:  • Next milestone: <...>   • Next consolidation: Week M
```

## Edge cases
- today < start → `Pre-prep — week 1 starts YYYY-MM-DD (X days from now)…`
- current_week > 30 → `Past exam target. Did you take it? Update the plan / reset start date.`
- weeks 27–30 → show consolidation / light-review / exam-week sections instead of weekly content.

## Habit checks (best-effort; don't error if files missing)
- Flashcards due: count `data/flashcards.json` deck where `due_date <= today`.
- Subnet last drill / weekly quiz: from `data/weak-areas.json` `last_seen` (subnetting:* / overall).

## `overview`
Compact 5-phase table with done/current/pending markers:
```
Phase 1 (W1-5)   — Foundations          ✓/▶/☐
Phase 2 (W6-9)   — Switching            …
Phase 3 (W10-15) — Routing              …
Phase 4 (W16-21) — Services + Security  …
Phase 5 (W22-26) — Automation + Review  …
W27-28 Consolidation · W29 Light review · W30 Exam (~2026-11-23)
```
