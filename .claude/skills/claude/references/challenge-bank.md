# Challenge Bank
Updated: 2026-05-26

Each challenge is a guided mini-project (5-10 min) that produces a real, keepable artifact.

---

### ch-01: Build a /morning skill
- **Difficulty:** beginner
- **Time:** 8 min
- **Brief:** Create a skill that shows your git status, pending tasks, and a random Claude Code tip when you start your day.
- **Exercises:** SKILL.md anatomy, frontmatter, dynamic injection (`!`command``)
- **Artifact:** `~/.claude/skills/morning/SKILL.md`

### ch-02: Write your first CLAUDE.md
- **Difficulty:** beginner
- **Time:** 5 min
- **Brief:** Create a CLAUDE.md for your dotfiles project with coding standards, structure overview, and key conventions.
- **Exercises:** CLAUDE.md best practices, concise rule writing
- **Artifact:** `~/x/dotfiles/CLAUDE.md`

### ch-03: Add a mode to an existing skill
- **Difficulty:** beginner
- **Time:** 10 min
- **Brief:** Add a `stats` mode to the `/claude` skill that shows session frequency over the last 30 days.
- **Exercises:** Multi-mode dispatch, argument parsing, state file reading
- **Artifact:** Modified `/claude` SKILL.md

### ch-04: Design a permission allowlist
- **Difficulty:** beginner
- **Time:** 5 min
- **Brief:** Audit your current permissions and create a clean, categorized allowlist in settings.json.
- **Exercises:** Permission patterns, security model, settings.json structure
- **Artifact:** Updated `settings.json` or `settings.local.json`

### ch-05: Build a /til skill (Today I Learned)
- **Difficulty:** intermediate
- **Time:** 10 min
- **Brief:** Create a skill that logs daily learnings to a markdown file with date headers and tags. Support `add` and `search` modes.
- **Exercises:** State files, multi-mode dispatch, append-only logs, argument parsing
- **Artifact:** `~/.claude/skills/til/SKILL.md` + `data/til.md`

### ch-06: Create a pre-commit hook
- **Difficulty:** intermediate
- **Time:** 8 min
- **Brief:** Configure a settings.json hook that runs a linter/formatter before every commit Claude makes.
- **Exercises:** Hook configuration, settings.json, tool event matching
- **Artifact:** Hook entry in `settings.json`

### ch-07: Build a skill with Leitner flashcards
- **Difficulty:** intermediate
- **Time:** 15 min
- **Brief:** Create a `/vocab` skill for learning technical terms with spaced-repetition flashcards. Support `add` and `review` modes.
- **Exercises:** Leitner box scheduling, JSON state files, review intervals, due-date computation
- **Artifact:** `~/.claude/skills/vocab/SKILL.md` + state schema

### ch-08: Build a /review skill for PRs
- **Difficulty:** intermediate
- **Time:** 10 min
- **Brief:** Create a skill that reads a git diff and reviews it against a configurable checklist (security, performance, correctness).
- **Exercises:** Dynamic injection, argument parsing, allowed-tools, checklist-driven review
- **Artifact:** `~/.claude/skills/review/SKILL.md`

### ch-09: Build a forked research skill
- **Difficulty:** advanced
- **Time:** 10 min
- **Brief:** Create a skill using `context: fork` and `agent: Explore` that researches a topic across the codebase and returns a summary.
- **Exercises:** Subagent skills, context isolation, agent types, result summarization
- **Artifact:** `~/.claude/skills/research/SKILL.md`

### ch-10: Design an integrated workflow
- **Difficulty:** advanced
- **Time:** 15 min
- **Brief:** Design and partially implement a workflow combining a skill + hook + MCP server for automated code quality.
- **Exercises:** Integration patterns, hook-skill chaining, MCP architecture
- **Artifact:** Design doc + partial implementation

### ch-11: Build an updateable topic bank
- **Difficulty:** advanced
- **Time:** 12 min
- **Brief:** Create a skill with a topic bank that can be extended via an `update` subcommand using external documentation.
- **Exercises:** Update protocol, bank format, deduplication, source fetching
- **Artifact:** Skill with working `update` command

### ch-12: Optimize your context budget
- **Difficulty:** advanced
- **Time:** 10 min
- **Brief:** Audit your total context footprint (CLAUDE.md + skills + plugins + settings) and reduce it by 30% without losing functionality.
- **Exercises:** Token estimation, context efficiency, CLAUDE.md trimming, skill refactoring
- **Artifact:** Leaner config files with before/after token estimates
