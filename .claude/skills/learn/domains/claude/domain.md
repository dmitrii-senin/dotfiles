# Domain: claude — Claude Code & LLM mastery

title: Claude Code Mastery Coach
level: intermediate — a C++ infra engineer learning to use Claude Code and LLMs effectively

## Areas

`prompt`, `skill`, `workflow`, `llm`

- **prompt** — prompting techniques: specificity, constraints, roles, chain-of-thought, output format, context
- **skill** — skill authoring: frontmatter, arguments, dynamic injection, state, references, triggering
- **workflow** — power workflows: plan mode, hooks, MCP, worktrees, subagents/workflows, permissions
- **llm** — LLM mental models: tokens, context windows, models, prompt caching, cost, effort  *(was `mm` in the old skill; renamed to avoid clashing with the `mm` mode)*

### Area prerequisites
- `prompt` is foundational — prefer before `skill`/`workflow`.
- `llm` pairs with everything (ground cost/token discussions early).

## Modes

enabled: `mm`, `challenge`, `audit`, `update`, `status`
not used: `flash` (no flashcards), `drill` (sessions embed their own drill step), `cheatsheet` (no cheatsheets)

- `audit` is a **domain-specific** mode → `modes/audit.md` (audits the Claude Code setup).
- `challenge` reads `challenges.md` (hands-on mini-projects producing a real artifact).

## Session style (mm override)
Keep `mm` sessions **short (5–10 min): Tip + drill + review**, not a 30-min deep dive.
Step 2 is a **single technique** ("Tip") with a concrete **before/after anchored to the
user's real config** — read the grounding files below and cite specific lines. Always
explain WHY (the failure mode it prevents). Don't re-recommend what the user already has.

## Grounding (anchor each area to real files)

| Area | Read to ground examples |
|---|---|
| prompt | `CLAUDE.md` files; skill frontmatters in `~/.claude/skills/*/SKILL.md` |
| skill | `~/.claude/skills/*/SKILL.md` — the `learn` engine, ccna as exemplars |
| workflow | `~/.claude/settings.json`, `settings.local.json`, hooks config |
| llm | `~/.claude/settings.json` (model, effort) to ground token/cost discussion |

## Resources / knowledge sources
See `resources.md`. Prefer official Claude Code + Anthropic docs over parametric memory;
cite the page. Flag unsourced specifics (limits, pricing, flag names).
