# `flash` mode — Leitner Spaced Repetition (Knowledge retention)

Spaced retrieval practice over the domain's flashcards. Read `pedagogy.md` first:
hide the answer (retrieval), space by box, and **interleave across areas** by default.

Invoked as `/learn <domain> flash [area] [box|stats]`.

---

## Initialization / injection

On a `flash` run, ensure `data/flashcards.json` exists (create `{ "deck": [], "version": 1 }`
or a flat array if missing). Then inject from the read-only banks in `flashcards/`:

- **Eligibility:**
  - If `domain.md` declares a **schedule**, a bank file is eligible only once its
    scheduled weeks have fully passed (week-gated — see the domain's schedule rules).
  - If there is **no schedule**, all bank files are eligible immediately.
- For each eligible bank file `flashcards/<area>.json`, for each card whose `id` is not
  already in the deck, inject it with: `domain` = active domain, `area` = filename stem,
  carry `front/back/tags/difficulty/source`, and set `box: 1`, `due_date: <today>`,
  `created: <today>`, `last_reviewed: null`, `last_result: null`, `consecutive_resets: 0`.

---

## Box intervals

| Box | Interval |
|-----|----------|
| 1 | Daily |
| 2 | Every 3 days |
| 3 | Weekly |
| 4 | Every 2 weeks |
| 5 | Monthly |

---

## Review flow

1. Read `data/flashcards.json`. Select cards with `due_date <= today`. **Interleave:**
   draw across all areas by default; only restrict to one area if `[area]` was given.
2. If >25 cards are due, ask: *"25+ cards due. Focus on: (a) wrongs first, (b) new
   cards, (c) oldest-due, or (d) all?"*
3. Present each card one at a time:
   - Show the **front**. **Wait** for the user's attempt (retrieval).
   - Show the **back** (include its `source` if present).
   - Ask: `Rate: (a)gain | (h)ard | (g)ood | (e)asy`
   - Apply grading:
     - **again** → box 1, due tomorrow; `consecutive_resets += 1`.
     - **hard** → same box, due tomorrow; `consecutive_resets = 0`.
     - **good** → box +1 (max 5), due per interval; `consecutive_resets = 0`.
     - **easy** → box +2 (max 5), due per interval; `consecutive_resets = 0`.
   - Update `last_reviewed`, `last_result`.
4. **Leech detection:** if `consecutive_resets >= 3`, flag: *"Leech — reset 3+ times.
   Consider rephrasing or splitting this card."*
5. End: summary — reviewed N, again X, hard Y, good Z, easy W.

---

## `flash box` / `flash stats`

Filter the deck (by `[area]` if given, else whole domain) and display:

```
<DOMAIN> flashcards — N total

Box 1 (daily):     ████████████████ 42
Box 2 (3 days):    ████████░░░░░░░░ 18
Box 3 (weekly):    ██████░░░░░░░░░░ 15
Box 4 (2 weeks):   ████░░░░░░░░░░░░ 12
Box 5 (monthly):   ██████░░░░░░░░░░ 13

Due today: 8  |  Due this week: 23  |  Mastered (box 5): 13
Retention rate: 72% (good+easy / total reviews)
Leeches: 2 cards
```
