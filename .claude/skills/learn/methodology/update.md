# `update` mode — Extend a domain's content banks

Grow a domain's authored content (knowledge topics, flashcards, or challenges) from
trusted sources, without duplicating what's already there. This is maintenance, not a
learning session. Obey source discipline (`pedagogy.md` §2).

Invoked as `/learn <domain> update <target> [--source <path>]` where `<target>` is an
**area** (extend that area's knowledge bank), `flashcards [area]`, `challenge`, or `all`.

---

## Flow

1. **Read the current bank(s)** for the target:
   - area → `knowledge/<area>-bank.md`
   - `flashcards [area]` → `flashcards/<area>.json`
   - `challenge` → `challenges.md`
   - `all` → every knowledge bank (+ challenges if present).
2. **Read sources.** Prefer the domain's `resources.md` (trusted/primary). If
   `--source <path>` is given, also read that file as additional material. Fetch primary
   web sources only if the domain's resources list them and they're reachable.
3. **Generate new entries** that **don't duplicate** existing ones (match on title/tags).
   Keep the domain's existing entry format exactly (same fields, same schema). Tag each
   precise claim with its source; flag anything parametric-only.
4. **Show what would be added** — title + 1-line description per new entry — and the
   target file(s). Do **not** write yet.
5. **Ask for confirmation.** On approval, append with an `Added: YYYY-MM-DD` marker
   (a comment line for markdown banks; a sibling field or grouping note for JSON).
   Never rewrite or reorder existing entries; append only.

Keep additions in the learner's scope and aligned to `mission.md` — extend toward the
goal, not encyclopedically.
