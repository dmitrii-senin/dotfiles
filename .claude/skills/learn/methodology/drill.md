# `drill` mode — Scenario-Based Practice (Skill)

Effortful, interleaved retrieval against realistic scenarios with a tight feedback
loop. Read `pedagogy.md` first: this is the **Skill** type — difficulty is the tool.

Invoked as `/learn <domain> drill [area] [N]` (N default 5, range 1–10).

---

## Flow

1. Read `data/weak-areas.json` and recent `records/`. **Weight scenarios toward weak
   subtopics** and recently-surfaced misconceptions.
2. Generate **N** scenarios. **Interleave** across areas by default (mix the domain's
   areas); restrict to one area only if `[area]` was given. Use the **drill flavor**
   declared in `domain.md` (the kinds of scenarios + the realistic artifacts to show).
3. Present each scenario one at a time. **Wait for the user's answer before the next.**
4. Score each on 3 criteria (1 pt each):
   - **Correct identification** — did they name the right cause/answer?
   - **Correct next step** — did they propose the right action?
   - **Reasoning quality** — did they explain *why*, not just *what*?
5. After all scenarios: summary score (X/3N). For each miss, update
   `data/weak-areas.json` (increment `misses`/`attempts`, set `last_seen`/`last_score`,
   and record the **misconception** line). If a notable wrong mental model surfaced,
   write `records/NNNN-<insight>.md`.

---

## Scenario quality

A good scenario presents a concrete, realistic artifact (per the domain's drill
flavor) and asks for a diagnosis + next step — not a definition. Calibrate difficulty
to ZPD: hard enough to require real retrieval, not so hard it's guessing.

Cite the source for any precise facts in the *explanation* (not the prompt), and flag
parametric-only specifics (`⚠ unsourced`). Keep answer options, when used, matched in
length so formatting gives no tells.
