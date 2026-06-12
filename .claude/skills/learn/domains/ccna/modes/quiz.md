# `quiz` mode (ccna) — exam-style questions

Generate CCNA 200-301 questions. Read the matching `knowledge/` file(s) (per `domain.md`'s
area map) before generating — it's the authoritative, blueprint-bounded source. Don't invent
off-blueprint topics.

Invoked as `/learn ccna quiz [domain|topic|weak-areas|mock] [N]` (alias `/ccna quiz …`).
Default = 10 questions, mixed across all 6 domains. `quiz N` / `quiz <area> N` / `quiz <topic>`.

## Question formats (mix all 6)
Multi-select MC and config-debugging are **guaranteed in every quiz** (they dominate the exam).
1. **MC single** — 4 options, 1 correct, plausible distractors.
2. **MC multi-select** — 4–6 options, 2–3 correct; always state "Choose 2/3".
3. **Short answer** — a specific IOS command, prefix length, OSPF state, etc.
4. **Fill-in-the-blank** — IOS snippet with a blank.
5. **Scenario** — describe a problem, ask diagnosis/fix.
6. **Config debug / output reading** — `show …` snippet with a bug; what's wrong.

**Difficulty:** mixed by default = 25% easy / 50% medium / 25% hard.

## Quiz flow (one question at a time)
1. Show `Question N/total · [Format] · Domain X.Y`.
2. **Wait for the answer.**
3. Feedback: verdict · correct answer · why it's right · why each wrong option is wrong (MC) ·
   **deep dive** (~25-35 lines scoped to the exact concept: syntax, flags, config snippet,
   gotchas — don't branch) · `References: knowledge/N-<name>.md · cisco doc`.
4. Action prompt: `[n] Next · [h] Hint (pre-answer) · [s] Skip (review at end) · or a follow-up`.
   - `h` → one-sentence nudge, no spoilers; `s` → defer, replay before scoring; other → discuss then re-show prompt.
   - **Never advance without `n`/`s`.** Never reveal upcoming answers.
5. After all (+ skipped re-pass): score `X/N · NN%`, breakdown by domain/subtopic, focus areas,
   and **update `data/weak-areas.json`** (missed subtopics: `misses`/`attempts`++, `last_seen`,
   recalc `last_score`). For a notable wrong mental model, also write a
   `records/NNNN-<insight>.md` (see `methodology/state.md`) so it feeds future ZPD selection.

## `quiz mock [N]` — full mock exam
- **60 questions** default; **weighted** D1:12 D2:12 D3:15 D4:6 D5:9 D6:6 (→60). All formats, mixed difficulty.
- **No per-question feedback** — accept and move on; prompt is just `[n] Next · [s] Skip`.
- Pre-quiz: *"60 questions, ~120 min. Skip hard ones with `s`."*
- After: full breakdown + top-3 weakest subtopics, then ask *"Walk through every wrong/skipped with full feedback? [y/n]"*. Update `weak-areas.json`.

## `quiz weak-areas [N]`
1. Read `data/weak-areas.json`; if empty → *"No weak-area data yet — run a few quizzes first."*
2. Pick topics with `misses/attempts > 0.4` AND `attempts >= 3`, lowest score first.
3. Generate N (default 15) across them, weighted by struggle; run as a standard quiz.
4. After: *"Improved: X. Still weak: Y."*; update the ledger.

Match the depth/style of the example questions in `knowledge/` and the OCG.
