# `audit` mode (claude domain) — Claude Code config audit

A tool, not a lesson: read the user's actual Claude Code setup, compare against best
practices, and produce a ranked, actionable improvement list. Apply only with
confirmation. Paths are the dotfiles source, never `~/.claude` directly.

Invoked as `/learn claude audit [focus]` (or `/claude audit [focus]`).
Focus: `settings`, `skills`, `permissions`, `plugins`, `claude-md`. Empty → everything.

---

## Protocol

1. **Read the relevant files** (subset matching focus):
   - `~/.claude/settings.json` and `~/x/dotfiles/.claude/settings.json`
   - `~/x/dotfiles/.claude/settings.local.json`
   - All `SKILL.md` under `~/.claude/skills/` (incl. the `learn` engine + domains)
   - `~/.claude/statusline.sh` (if present)
   - Any `CLAUDE.md` in the user's projects
   - Plugins: `~/.claude/plugins/installed_plugins.json`, local marketplace
2. **Cross-reference** `references/best-practices.md`.
3. **Produce a ranked table** — `HIGH` / `MED` / `LOW`, each with: what to change, why it
   matters, and the proposed edit (diff or config snippet).
   - HIGH = bug, anti-pattern, or missing feature affecting daily workflow
   - MED = cleaner / faster / more maintainable
   - LOW = nice-to-have / taste
4. **Wait for selection.** Never auto-apply. End with: *"Select items by number to see
   the diff, or 'all'."*
5. **Show diffs and apply** one at a time, each with "Apply this change? (y/n)". Use the
   **dotfiles path** (`~/x/dotfiles/.claude/...`), never `~/.claude/...` directly. After
   applying, remind the user to `git diff` and commit when ready. Never auto-commit.
6. **Log** to `data/audit-log.md` (create with `# Audit Log\n\n` if missing): date,
   focus, findings count (H/M/L), items applied/deferred.

## Notes
- Respect what exists — don't recommend things already configured (check first).
- No cargo-cult: every recommendation needs a rationale + concrete before/after.
- Cross-reference learning: a finding about a technique may point to a session, e.g.
  *"See `/claude workflow mm 'hooks'`"*.
