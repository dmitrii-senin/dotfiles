# `flash` mode — Leitner Spaced Repetition (Knowledge retention)

Spaced retrieval practice over the domain's flashcards. Read `pedagogy.md` first:
hide the answer (retrieval), space by box, and **interleave across areas** by default.

Invoked as `/learn <domain> flash [area] [review|add|box|stats]`.

**Verbs** (the token after `flash`, order-independent with `[area]`):
- *(none)* or `review` → review due cards (the default; `flash` and `flash review` are identical)
- `add` → author a new card into the deck (see below)
- `box` / `stats` → the dashboard (see below)

---

## Initialization / injection

On a `flash` run, ensure `data/flashcards.json` exists (create `{ "deck": [], "version": 1 }`
if missing). Then inject from the read-only banks in `flashcards/`:

- **Eligibility:**
  - If `domain.md` declares a **schedule**, a bank file is eligible only once its
    scheduled weeks have fully passed (week-gated — follow the domain's schedule rules).
  - If there is **no schedule**, all bank files are eligible immediately.
- For each eligible bank file, for each card whose `id` is not already in the deck, inject
  it: carry the bank card's content (`front`/`back`/`tags`/`difficulty`/`source`), set
  `domain` = active domain, `box: 1`, `due_date: <today>`, `created: <today>`,
  `last_reviewed: null`, `last_result: null`, `consecutive_resets: 0`.
  - **Grouping field:** by default `area` = bank filename stem (one file per area, e.g.
    `flashcards/cpu.json` → `area: "cpu"`). If the domain's schedule rules specify other
    grouping fields instead (e.g. ccna banks are per-chapter and carry `chapter`/`week`/
    `topic`, not `area`), carry those per the domain's rules.

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

**⚠ Never reveal a card's back before the user answers.** Tool output (Bash/Read) is
visible to the user, so do **not** read full card backs up front — that leaks every
answer. Build the session queue from scheduling metadata only, then fetch each `back`
one at a time, **after** the user has committed an answer.

1. Build the queue without backs — e.g.:
   ```bash
   jq '[.deck[] | select(.due_date <= "YYYY-MM-DD") | {id, front, box, due_date, last_result, area, chapter, topic}]' data/flashcards.json
   ```
   Select cards with `due_date <= today`. **Interleave:** draw across all areas by default;
   restrict to one area only if `[area]` was given.
2. If >25 cards are due, ask how to scope: *"(a) wrongs first, (b) new cards, (c) oldest-due,
   (d) all?"* Cards not selected get `due_date` deferred by 1 day.
3. Present each card one at a time:
   - Show the **front** (already in memory). **Wait** for the user's attempt (retrieval).
   - **Only after they answer**, fetch that one card's back:
     `jq -r '.deck[] | select(.id=="ID") | .back' data/flashcards.json` — print it so they
     can compare (include `source` if present). Never batch-read backs.
   - Ask: `Rate: (a)gain | (h)ard | (g)ood | (e)asy`
   - Apply grading:
     - **again** → box 1, due tomorrow; `consecutive_resets += 1`.
     - **hard** → same box, due tomorrow; `consecutive_resets = 0`.
     - **good** → box +1 (max 5), due per interval; `consecutive_resets = 0`.
     - **easy** → box +2 (max 5), due per interval; `consecutive_resets = 0`.
   - Update `last_reviewed`, `last_result`. Reset `consecutive_resets` to 0 when a card reaches box 3+.
4. **Leech detection:** if `consecutive_resets >= 3`, flag: *"Leech — reset 3+ times.
   Consider rephrasing or splitting this card."* (offer to rewrite, or an `mm`/tutor session).
5. End: summary — reviewed N, again X, hard Y, good Z, easy W; next due count.

---

## `flash add`

Author a card into the deck. Accept a one-liner argument or prompt for the fact; generate
a `front`/`back` (for a command → "what does this do?" + explanation; for a concept →
name + explanation). Confirm with the user, then append to the deck with `box: 1`,
`due_date: today`, `created: today`, and a unique `id`.

---

## `flash box` / `flash stats`

Filter the deck (by `[area]` if given, else whole domain) and display the box histogram,
due counts, mastered (box 5), retention rate (good+easy / reviews), and any leeches:

```
<DOMAIN> flashcards — N total

Box 1 (daily):     ████████████████ 42
Box 2 (3 days):    ████████░░░░░░░░ 18
Box 3 (weekly):    ██████░░░░░░░░░░ 15
Box 4 (2 weeks):   ████░░░░░░░░░░░░ 12
Box 5 (monthly):   ██████░░░░░░░░░░ 13

Due today: 8  |  Due this week: 23  |  Mastered (box 5): 13
Retention rate: 72% (good+easy / total reviews)  |  Leeches: 2 cards
```
