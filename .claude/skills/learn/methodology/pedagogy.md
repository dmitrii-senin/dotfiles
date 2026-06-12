# Pedagogy — the principles every mode obeys

This is the cross-cutting learning-science spine. The engine reads this **once per
session**, before the mode file. Every mode (`mm`, `flash`, `drill`, `challenge`)
applies these principles. They are domain-agnostic.

---

## 1. Knowledge → Skills → Wisdom

Every learning goal decomposes into three types of learning. They are taught
differently, and you must pick the right difficulty for each.

| Type | What it is | Difficulty rule | Engine modes |
|------|-----------|-----------------|--------------|
| **Knowledge** | Facts, vocabulary, models — *knowing that* | **Minimize difficulty.** Make acquisition smooth; cite a trusted source for every claim. | `mm` (Concept step), `flash` |
| **Skill** | Applying knowledge under realistic conditions — *knowing how* | **Maximize *desirable* difficulty.** Effortful retrieval + a tight, fast feedback loop. | `mm` (Drill/Review), `drill` |
| **Wisdom** | Judgment, taste, trade-offs — *knowing when/why* | Real-world practice; an attempted answer, then defer to a high-reputation source/community. | `challenge` |

Teach the **knowledge** a skill requires first, then immediately exercise it as a
**skill**. Don't dump knowledge that isn't in service of a skill or the mission.

---

## 2. Never trust parametric knowledge

You (the model) confidently misremember exact numbers, syntax, and wire formats.
For this learner that is dangerous (CPU port counts, ROB sizes, CME MDP field
layouts, IOS command syntax).

- Prefer the domain's `resources.md` and the authored `knowledge/` banks.
- When you state a precise fact (a number, a flag, a register width, a protocol
  field), **name the source** ("Agner Fog's tables: …", "Intel Opt Manual §2.x: …").
- If a claim is **parametric-only** (not in the banks/resources and you can't
  attribute it), **flag it**: `⚠ unsourced — verify against <resource>`.
- Never silently invent specifics to fill a session. Say what you're unsure of.

---

## 3. Storage strength > fluency strength

Smooth in-the-moment recall (**fluency**) is *not* durable retention (**storage**).
Re-reading and recognition feel productive but build little storage. Build storage
with **desirable difficulty**:

- **Retrieval practice** — make the learner *produce the answer from memory* before
  showing it. This is why `mm` has Drill+Review steps and why `flash` hides the back.
- **Spacing** — distribute practice over time. The Leitner boxes in `srs.md` do this.
- **Interleaving** — mix related areas/topics rather than blocking one. In `drill`
  and `flash`, default to **drawing across areas**, not a single area, unless the
  user explicitly filters to one. Interleaving hurts in-session performance but
  improves retention and transfer — that's the point.

Never mistake a confident answer for mastery; confirm with a spaced, mixed re-test.

---

## 4. Zone of Proximal Development (ZPD)

Teach the thing that challenges the learner **just enough** — not what they already
know, not three prerequisites ahead.

ZPD is a **single ranking over all candidate topics — new *and* completed**, not a
new-vs-revisit split. New and decayed topics compete on one priority signal:

1. **Prerequisites (gate)** — `domain.md` may declare area/topic prereqs; never propose
   a topic whose prereqs are unmet.
2. **Mastery gap** — `data/progress.json` score + `data/weak-areas.json` misses. New
   topics are max-gap; a low-scored or frequently-missed completed topic also has a real
   gap and belongs in the ZPD.
3. **Retention decay** — time since a completed topic was last seen. A topic scored high
   weeks ago looks "mastered" but has decayed; without this term it would never resurface.
   Well-learned material (high score) decays more slowly.
4. **Mission proximity** — `mission.md`: prefer topics that move the learner toward their
   stated goal and success criteria.

A "revisit" is simply a completed topic whose gap + decay out-rank the new topics — it
falls out of the ranking, it is not a reserved quota. **Division of labor:** `flash`
(Leitner) carries the bulk of retention at the atom level, so an `mm` revisit is reserved
for topics that need a *full re-session* (significant gap or deep decay), not mild
forgetting. `mm.md` defines the concrete scoring.

---

## 5. Mission-grounded

Every session serves `mission.md` (why they're learning + what success looks like +
any deadline). Open ambiguous sessions by connecting the topic to the mission in one
line. When the mission and the bank disagree on what's next, the **mission wins**.

If a domain has **no `mission.md`**, do not teach yet — run the onboarding interview
(see `SKILL.md`) to write one first.

---

## 6. Capture what's non-obvious

When a session surfaces a **misconception**, a hard-won insight, or a "revisit this
later" decision, write a short **learning record** to `records/NNNN-<dash-case>.md`
(see `state.md`). These records — not raw transcripts — drive future ZPD choices.
`weak-areas.json` stores the *count*; the record stores the *why*.
