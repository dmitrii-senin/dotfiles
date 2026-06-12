# `mm` mode — Mental-Model Session (Knowledge + Skill)

A focused session (~30 min, or shorter for a single win) that teaches one topic to
**Knowledge** depth, then exercises it as a **Skill** via retrieval. Read
`pedagogy.md` first; obey ZPD, source discipline, and retrieval practice.

Invoked as `/learn <domain> mm [area] [topic|random]`.

---

## Topic selection (unified ZPD ranking)

When no explicit topic is given, build **one ranked list over all candidate topics**
— new *and* completed — and propose the top ~10. There is **no fixed new/revisit
quota**; a completed topic earns a slot only when it out-ranks the new ones.

1. **Scope candidates.** Read the relevant knowledge bank(s): `knowledge/<area>-bank.md`
   if `[area]` was given, otherwise span areas (interleaving). Each topic is **new**
   (absent from `progress.json → completed_topics`) or **completed** (present, with a
   `date` + `score`).
2. **Read signals.** `data/progress.json` (completed, score, date), `data/weak-areas.json`
   (misses/attempts/last_seen/misconception), recent `records/` (any "Revisit" lines),
   `domain.md` (area prereqs + mission link), `mission.md` (goal + success criteria), and
   today's date (for decay).
3. **Gate on prerequisites.** Drop — or mark `🔒 locked` — any topic whose prerequisites
   aren't yet met. Never propose a topic the learner isn't ready for.
4. **Score each remaining candidate.** `priority` = sum of:

   | Signal | New topic | Completed topic |
   |---|---|---|
   | **Mission proximity** (0–3) | how directly it advances `mission.md` success criteria | same |
   | **Mastery gap** (0–3) | 3 — never learned | `round((1 − last_score)·3)`; **+1** if it appears in `weak-areas` (misses>0) or a record's "Revisit" line |
   | **Retention pressure** (0–3) | 0 | by days since `last_seen`/`date`: `<7→0`, `7–21→1`, `22–45→2`, `>45→3`; **−1** if `last_score ≥ 0.9` (well-learned fades slower) |
   | **ZPD fit** (0–2) | 2 if difficulty sits just past current mastery; 0–1 if too easy or too far ahead | same |
   | **Foundational** (0–1) | +1 if it's a prerequisite for many downstream topics | same |

5. **Rank** by `priority`; take the top ~10. Break ties for **diversity**: interleave
   areas and blend new with decayed rather than clustering one kind.
6. **Annotate** each item with the dominant reason it surfaced — `[new]`,
   `[foundational]`, `[decayed 24d]`, `[weak: accumulator-sizing]`, `[mission]`, or
   `[revisit ▸ record 0002]`. "Revisit" is now just one possible label, not a bucket.
7. **Leave light decay to `flash`.** A completed topic should reach this menu only when
   it needs a *full re-session* (real mastery gap or deep decay) — atomic retention is
   the Leitner deck's job (`srs.md`). Don't surface a 30-min `mm` session for mild forgetting.

Present as a numbered list: number, title, `[difficulty]`, annotation, 1-line
description. The user picks by number or name, or says "more" for the next 10. Then run
the session protocol on the chosen topic.

**Explicit topic** (`mm "<topic>"`): fuzzy-match title/tags/description in the bank.
If found → use it as the seed. If not → generate on the fly from `resources.md` +
knowledge sources, same protocol, log with `"source": "freeform"`.

**`random`:** pick one uncompleted, prereq-met topic at random; skip the menu.

---

## Session protocol (6 steps)

1. **Objective** — one sentence: what the learner will understand/do after this, tied
   to the mission in a few words.

2. **Concept** — the core (Knowledge; minimize difficulty). Include where useful:
   - text diagrams; **real tool output** with line-by-line annotation; **concrete
     numbers** (depths, sizes, counts, latencies, field widths);
   - a **tool anchor** — a concrete command that connects the concept to practice;
   - connection to the learner's real workload where natural;
   - **cross-references** to related topics/areas ("See also: `/learn <domain> mm
     <area> '<topic>'`").
   - **Cite sources** for every precise claim; flag any parametric-only fact
     (`⚠ unsourced — verify against <resource>`). See `pedagogy.md` §2.
   - Build 3–5 sub-concepts, simple → complex. (For a "single win" session, fewer.)

3. **Drill** — interactive retrieval (Skill; desirable difficulty). Present a
   realistic scenario; ask the learner to diagnose/produce the answer.
   - **Wait for the user's response. Never advance without it.**
   - Then score (0–3), give the ideal path, name what was good and what was missed.

4. **Review** — 3–4 quick retrieval questions (true/false, which-is-better, short
   answer, pick-the-metric). **Wait for each response.** Score each with brief rationale.

5. **Takeaway** — one actionable sentence to internalize.

6. **Log** — update `data/progress.json` (append the completed topic with score;
   apply streak rules) and **persist a note** to `notes/NNNN-<topic>.md` (the Concept,
   self-contained, with sources). If a misconception/insight surfaced in Drill/Review,
   also write `records/NNNN-<insight>.md` and update `data/weak-areas.json` with the
   misconception line. Show the current streak and suggest a next step.

**Critical:** never reveal the answer to a Drill/Review item before the user has
attempted it. Retrieval is the point.
