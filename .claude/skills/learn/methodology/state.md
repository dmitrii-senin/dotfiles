# State — files, schemas, and rules

All paths are relative to the active domain directory: `domains/<domain>/`.
**Volatile machine state** lives in `data/` (gitignored). **Durable artifacts**
(`notes/`, `records/`) are tracked in git. Create any file with its default if missing.

---

## `data/progress.json` (gitignored)

Tracks completed topics per area, sessions, and streak.

```json
{
  "version": 1,
  "last_session": "",
  "total_sessions": 0,
  "completed_topics": {
    "<area>": [
      {"title": "...", "area": "<area>", "difficulty": "beginner|intermediate|advanced",
       "date": "YYYY-MM-DD", "score": 0.0, "source": "bank|freeform"}
    ]
  },
  "challenges_completed": [],
  "streaks": { "current": 0, "longest": 0, "last_date": "" }
}
```

The `completed_topics` keys are the domain's `areas` (from `domain.md`). A domain with
no areas uses a single key `"default"`.

**Streak rules:** if `last_date` is today → no change; if yesterday → `current += 1`;
if 2+ days ago → `current = 1`. Always `longest = max(longest, current)`,
`last_date = today`, `total_sessions += 1`.

**Score:** combined drill + review result as a decimal 0.0–1.0.

---

## `data/flashcards.json` (gitignored) — the active Leitner deck

Flat array of cards. Created on first `flash` run by injecting from `flashcards/`
(see `srs.md`). Each card:

```json
{
  "id": "cpu-001",
  "domain": "<domain>",
  "area": "<area>",
  "front": "...",
  "back": "...",
  "tags": ["..."],
  "difficulty": "beginner",
  "source": "<short citation if known>",
  "box": 1,
  "due_date": "YYYY-MM-DD",
  "created": "YYYY-MM-DD",
  "last_reviewed": null,
  "last_result": null,
  "consecutive_resets": 0
}
```

`area` is derived from the bank **filename stem** on injection (`flashcards/cpu.json`
→ `area: "cpu"`). `domain` is the active domain. Legacy `last_result` values `"y"/"n"`
are treated as `"g"/"a"`.

---

## `data/weak-areas.json` (gitignored)

Per-area map of weak subtopics, now including the **misconception** (the *why*), not
just a miss count.

```json
{
  "<area>": {
    "<subtopic-key>": {
      "misses": 1, "attempts": 1, "last_seen": "YYYY-MM-DD", "last_score": 0.0,
      "misconception": "one line: what the learner got wrong / the wrong mental model"
    }
  }
}
```

Drills weight scenarios toward subtopics with high `misses/attempts`.

---

## `records/NNNN-<dash-case>.md` (tracked) — learning records

ADR-style insight log. Numbered, zero-padded, incrementing. Write one when a session
surfaces a misconception, a hard-won insight, or a "revisit later" decision — and
whenever the **mission changes** (capture the change + reason).

```markdown
# 0001 — DSB is indexed by 32-byte code regions
date: 2026-06-04
area: cpu
type: misconception | insight | mission-change
trigger: <which session/topic/drill surfaced this>

## What happened
<the wrong mental model or the key realization, 2-4 lines>

## Correct model / resolution
<the right understanding, citing a source where possible>

## Revisit
<what to re-test later, or "n/a">
```

These records — not raw transcripts — feed future ZPD decisions. The engine reads
recent records when choosing what to teach next.

---

## `notes/NNNN-<dash-case>.md` (tracked) — durable session notes

The learner's personal knowledge base. After an `mm` session, persist the Concept
content as a re-readable note. Numbered like records.

```markdown
# 0001 — Pipeline stages: fetch to retire
date: 2026-05-29
area: cpu
topic: Pipeline stages and instruction flow
sources: <primary source(s) cited in the session>

<the distilled concept: diagrams, numbers, tool anchors — terse but complete,
the same content taught in the session, written so it stands alone on re-read>

## Takeaway
<the one-line takeaway from the session>
```

Notes are reference, not state — keep them clean and self-contained. Link related
notes/records by filename where useful.

---

## `data/session-log.md` (gitignored, optional/legacy)

A flat chronological log may exist from a migrated domain. Prefer `records/` for new
insights; `progress.json` already carries session count/streak. Don't depend on it.

---

## Numbering helper

Next number = (highest existing `NNNN` in the target dir) + 1, zero-padded to 4.
If the dir is empty, start at `0001`.
