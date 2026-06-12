# `progress` mode (ccna) — exam-readiness trajectory

Answers *"am I on pace for the exam?"* — deeper than `status`/`schedule`. Invoked as
`/learn ccna progress` (alias `/ccna progress`). Read-only.

## Inputs
- `ccna.md` — plan start (2026-05-04) + exam target (~Week 30, 2026-11). Compute
  `current_week` and `weeks_to_exam`.
- `data/flashcards.json` — the active deck (use `jq` on scheduling metadata only; never read backs).
- `data/weak-areas.json` — the weak-topic ledger.
- `flashcards/` banks — total authored cards + each chapter's `weeks` (to compute the
  injection backlog).
- `records/` — recent recurring misconceptions.

## Compute
1. **Timeline:** `current_week` / 30 · `weeks_to_exam` · phase.
2. **Flashcard health:**
   - Deck: total · mastered (box 4+5) · due today · % mastered.
   - **Injection backlog:** authored cards in chapters already finished (`current_week > max(weeks)`)
     that are *not yet in the deck* → are you injecting on schedule? Cards still locked (future chapters).
   - **Retention** (good+easy / reviews) from `last_result`.
3. **Weak-area burndown:** count topics with `misses/attempts > 0.4 AND attempts >= 3`
   (the "still weak" set); list the worst 3–5; note any improving (recent `last_score` up).
4. **Mock trend:** if mock scores were logged (records/ or a future mock log), show the last
   few + delta vs the ~825/1000 pass bar; if none, flag "no mock taken yet — run `/ccna quiz mock`".
5. **Verdict:** on-pace / slightly behind / behind — from backlog vs weeks-left, weak-area
   count, and mock trend. Be honest, not cheerleading.

## Output
```
CCNA readiness — Week 6/30 · exam in 24 weeks (~2026-11)

Flashcards:  129 deck · 31 mastered (24%) · 8 due today · retention 77%
             injection: on schedule (0 finished-chapter cards un-injected)
Weak areas:  4 still weak — subnetting:summarization, ipv6:eui-64, ospf:lsa-types, stp:roles
             improving: subnetting:network-broadcast-range (0.4→0.7)
Mocks:       none yet — run /ccna quiz mock for a real baseline

Verdict:     On pace. Priorities: (1) clear summarization weak area, (2) first mock by week 8.
```

End with 1–3 concrete next actions (a weak-area quiz, a mock, or catch-up on due cards).
