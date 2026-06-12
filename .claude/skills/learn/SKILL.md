---
name: learn
description: "Personal learning engine — one methodology, many domains. Spaced-repetition flashcards (Leitner), mental-model sessions, scenario drills, real-world challenges, and cheatsheets, grounded in a per-domain mission with progress tracking. Invoke as /learn <domain> <mode>. Domains live in domains/ (perf, ccna, neovim, …)."
argument-hint: "<domain> <mode> [area|topic] | list | help"
disable-model-invocation: true
allowed-tools: Bash(ls *) Bash(cat *) Bash(find *) Bash(grep *) Bash(date *) Bash(wc *) Bash(jq *) Read Write Edit
---

# Learn — personal learning engine

One engine defines *how* learning works; each subject is a folder under `domains/`
holding its materials and state. This file is the **dispatcher**. The pedagogy and
the per-mode mechanics live in `methodology/` and are read on demand — do not inline
their content here.

## Learner profile (global)

The user is a **C++ core infrastructure engineer on a market-data team (SBE + CME MDP
3.0) at a hedge fund**. Default level: **intermediate** — skip absolute basics, start
from real depth. A `domain.md` may override level/persona for its subject. Be terse,
concrete, and honest about uncertainty (see `methodology/pedagogy.md` §2).

---

## Dispatch

Parse `$ARGUMENTS` as: `<domain> <mode> [rest…]`.

1. **Resolve domain** = first token. List `domains/` to validate. If missing/unknown →
   run `list` (below) and stop.
2. **Read `domains/<domain>/domain.md`** — it declares: `level`, `areas`, enabled
   `modes`, optional `schedule`, `cheatsheets` map, area `prereqs`, and `drill flavor`.
3. **Mission gate:** if `domains/<domain>/mission.md` is **absent**, run the
   **onboarding interview** (below) instead of any mode — a domain isn't ready to teach
   without a mission.
4. **Resolve mode + area** from the remaining tokens. Match each token against the
   union of the domain's enabled `{modes}` and its `{areas}` (fuzzy/prefix) so **order
   is forgiving**: `/learn perf flash cpu` and `/learn perf cpu flash` are equivalent. A
   bare number / `random` / `stats` / `box` / quoted topic is the mode's argument.
   - If an **area** is given but **no mode** → default to **`mm`** on that area
     (`/learn perf cpu` ⇒ mm session on cpu; `/claude prompt` ⇒ mm session on prompt).
   - If **neither** mode nor area is given → run `status`.
   - If the mode isn't in the domain's enabled `modes` → say so and list what's enabled.
5. **Run the mode.** Read `methodology/pedagogy.md`, then the mode file — resolved as:
   `methodology/<mode>.md` if it exists (**universal** modes: `mm`, `flash`, `drill`,
   `challenge`, `cheatsheet`, `update`), otherwise `domains/<domain>/modes/<mode>.md`
   (**domain-specific** modes declared in `domain.md`, e.g. `audit`, `subnet`). Then
   operate on the domain's content + `data/`. State schemas: `methodology/state.md`.

If a token is ambiguous, say so and offer 2–3 specific options. Do not guess.

---

## Onboarding a new domain (no `mission.md`)

Before teaching a subject for the first time, interview the user, then scaffold it.
Ask (concisely, all at once is fine):

1. **Why** are you learning this? (the goal behind the goal)
2. **Current level** in this subject?
3. **What does success look like** — and is there a **deadline**?
4. **Preferred style / constraints** (e.g. avoid communities, prefer hands-on, time/session).

Then:
- Write `domains/<domain>/mission.md` (why + success criteria + deadline).
- Gather and write `domains/<domain>/resources.md` — vetted, trustworthy sources
  (see `methodology/pedagogy.md` §2). Prefer primary/authoritative references.
- Write a starter `domains/<domain>/domain.md` (level, areas, enabled modes, etc.).
- Create empty `knowledge/`, `flashcards/`, `cheatsheets/`, `notes/`, `records/`, `data/`.
- Confirm the plan with the user before authoring bulk content.

---

## `status` mode

Read `domain.md`, `data/progress.json`, `data/flashcards.json`, `data/weak-areas.json`,
recent `records/`, and `mission.md`. Show a compact dashboard:

```
/learn <domain> — <N> sessions · streak <c> (best <b>) · mission: <one-line goal>

Mental models:   ▓▓▓▓░░░░ <done>/<total>   (by difficulty/area)
Flashcards:      <total> · <mastered> mastered · <due> due today · retention <r>%
Drills:          avg <x>/3 · weak: <subtopics>

Suggested: <ZPD-based next step>
```

Empty input (`/learn <domain>`) ⇒ `status` + a suggested next mode.

---

## `list` mode  (`/learn` or `/learn list`)

Enumerate `domains/`. For each, read its `mission.md` (one-line goal) and
`data/` to show what's due / current streak:

```
Domains:
  perf    — <mission one-liner>          · <due> cards due · streak <c>
  ccna    — <mission one-liner>          · …
Use: /learn <domain> <mode>   (modes: mm, flash, drill, challenge, cheatsheet, status)
```

---

## `help` mode

```
/learn <domain> <mode> [area|topic]

MODES (universal):
  mm [area] [topic|random]   — mental-model session (knowledge + retrieval)
  flash [area] [box|stats]   — Leitner spaced repetition
  drill [area] [N]           — scenario-based practice (default 5, 1–10)
  challenge [topic]          — real-world application task
  cheatsheet [name]          — quick reference
  update <area|challenge|all> [--source <path>]  — extend a domain's banks from sources
  status                     — progress dashboard
  help                       — this message

A domain may add its own modes (declared in its domain.md), e.g. neovim/claude `audit`.
An area with no mode defaults to `mm` (`/learn perf cpu` ⇒ mm on cpu).

list                         — all domains + what's due
Token order is forgiving: `/learn perf flash cpu` == `/learn perf cpu flash`.
Short aliases exist for frequent domains (e.g. /perf, /claude, /nvim).
```

---

## Edit policy

Default: read-only except the active domain's state + durable artifacts — `data/*`
(progress, deck, weak-areas), `notes/*`, `records/*`. Two scoped exceptions, both
**diff-first + confirm + never auto-commit**:
- **`update`** may append to the domain's content banks (`knowledge/*`, `flashcards/*`,
  `challenges.md`) with an `Added: YYYY-MM-DD` marker.
- **Domain-specific modes** may edit their declared external targets (e.g. `audit` edits
  the user's real config under `~/x/dotfiles/...`) — per-change confirmation, and never
  `~/.config` or `~/.claude` directly (always the dotfiles path).

Reading `methodology/` is always allowed.
