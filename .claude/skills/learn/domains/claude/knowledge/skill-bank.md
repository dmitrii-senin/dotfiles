# Skill Topic Bank
Updated: 2026-05-26

## beginner

### What is a skill and when to use one
Understand the difference between CLAUDE.md (always loaded) and skills (loaded on demand).
**Tip:** If you keep typing the same prompt, it should be a skill. If it's a rule that always applies, it's CLAUDE.md.
**Drill:** Classify 5 examples as "CLAUDE.md", "skill", or "hook"
**Tags:** skill-basics, CLAUDE.md, when-to-use

### SKILL.md anatomy
Understand the two parts: YAML frontmatter (metadata) + markdown body (instructions).
**Tip:** The body is what Claude sees. The frontmatter controls when/how the skill loads.
**Drill:** Identify the frontmatter fields and body sections in a real SKILL.md
**Tags:** anatomy, structure, frontmatter, body

### The description field
Write descriptions that help Claude decide when to auto-load your skill.
**Tip:** Keywords matter. "Review Python code for security vulnerabilities" beats "help with code."
**Drill:** Write descriptions for 3 hypothetical skills and evaluate their keyword coverage
**Tags:** description, auto-invocation, keywords

### Skill directory structure
Understand where skills live: `~/.claude/skills/` (personal) vs `.claude/skills/` (project).
**Tip:** Personal skills follow you everywhere. Project skills are shared with the team.
**Drill:** Decide personal vs project placement for 4 different skills
**Tags:** directory, personal, project, location

### Your first skill: a simple workflow
Create a minimal skill with just a description and 5 lines of instructions.
**Tip:** Start small. A skill that runs `git diff HEAD` and summarizes changes is useful from day one.
**Drill:** Write a complete SKILL.md for a "summarize my changes" skill (under 15 lines)
**Tags:** first-skill, minimal, workflow

### Invoking skills manually and automatically
Understand `/skill-name` (manual) vs auto-invocation (Claude matches your request to the description).
**Tip:** `disable-model-invocation: true` prevents auto-invocation — use for destructive skills like deploy.
**Drill:** Configure invocation settings for 3 skills with different risk profiles
**Tags:** invocation, manual, automatic, disable-model-invocation

### Supporting files and references
Keep SKILL.md focused; move detailed docs to reference.md, checklist.md, etc.
**Tip:** Keep SKILL.md under 500 lines. Reference files load on demand when Claude reads them.
**Drill:** Split a 600-line SKILL.md into a lean main file + 2 reference files
**Tags:** supporting-files, reference, organization

### The argument-hint field
Show users what arguments your skill accepts in the autocomplete menu.
**Tip:** `argument-hint: "[mode] [topic]"` tells the user the shape of valid input.
**Drill:** Write argument-hints for 3 skills with different argument patterns
**Tags:** argument-hint, autocomplete, ux

## intermediate

### Multi-mode dispatch
Design argument parsers that route to different modes — first-token dispatch pattern.
**Tip:** First token selects the mode; remaining tokens are mode-specific. Same pattern as ccna/neovim skills.
**Drill:** Design a mode dispatch table for a hypothetical `/journal` skill with add/search/list modes
**Tags:** multi-mode, dispatch, argument-parsing, first-token

### Named arguments and substitution
Use the `arguments` frontmatter field for `$name` substitutions in the body.
**Tip:** `arguments: [component, framework]` lets you write `$component` and `$framework` in the body
**Drill:** Add named arguments to a skill that currently uses positional `$0` / `$1`
**Tags:** arguments, named, substitution, variables

### Dynamic context injection
Run shell commands before the skill loads with `!`command`` syntax — inject live data.
**Tip:** `!`git diff HEAD`` injects the actual diff. Claude sees real data, not a placeholder.
**Drill:** Add dynamic injection to a skill that currently asks Claude to "read the git diff"
**Tags:** dynamic-injection, shell, live-data, bang-syntax

### The allowed-tools field
Pre-approve specific tools so Claude can use them without prompting during your skill.
**Tip:** `allowed-tools: Bash(git *) Read` — grants git commands and file reading without permission prompts
**Drill:** Design an allowed-tools list for a deploy skill (minimal privileges)
**Tags:** allowed-tools, permissions, security, tools

### State files and progress tracking
Design JSON/markdown state files that persist across sessions (gitignored).
**Tip:** Your ccna skill uses 3 state files: weak-areas.json, flashcards.json, command-journal.md
**Drill:** Design a progress.json schema for a hypothetical `/leetcode` skill
**Tags:** state-files, persistence, json, progress

### Anchoring to the user's real setup
Read actual config files from within a skill and cite them — the pattern that makes skills personal.
**Tip:** Your neovim skill reads `~/x/dotfiles/.config/nvim/lua/custom/` and cites specific lines
**Drill:** Add anchoring to a skill that currently teaches in the abstract
**Tags:** anchoring, real-config, personalization, cite

### Edit policy design
Control when and how a skill can modify files — diff first, ask before writing, never auto-commit.
**Tip:** Both your neovim and ccna skills require explicit user confirmation before any file write
**Drill:** Write an edit policy section for a skill that manages dotfiles
**Tags:** edit-policy, safety, diff, confirmation

### Path scoping with the paths field
Limit when a skill activates based on file patterns.
**Tip:** `paths: ["**/*.test.ts"]` only loads the skill when working with test files
**Drill:** Write path patterns for 3 skills: one for tests, one for configs, one for docs
**Tags:** paths, scoping, activation, patterns

## advanced

### Subagent skills with context: fork
Run a skill in an isolated subagent context to keep the main conversation clean.
**Tip:** `context: fork` + `agent: Explore` = read-only research that returns just a summary
**Drill:** Convert an inline research skill to a forked subagent skill
**Tags:** subagent, fork, isolation, context

### Leitner spaced repetition in skills
Implement box-based scheduling for flashcard/drill skills.
**Tip:** Box 1: daily, Box 2: 3 days, Box 3: weekly, Box 4: biweekly, Box 5: monthly. Your ccna skill does this.
**Drill:** Trace the box transitions for a card that goes: correct, correct, wrong, correct
**Tags:** leitner, spaced-repetition, flashcards, scheduling

### Curriculum and topic file design
Organize 10-25 topic files with phases, prerequisites, and keyword maps.
**Tip:** Your neovim skill has 16 sessions in 4 phases with a keyword-to-session resolver
**Drill:** Design a curriculum.md skeleton for a hypothetical 12-session DevOps skill
**Tags:** curriculum, topics, phases, organization

### Skill versioning and migration
Handle breaking changes in your skills — version fields, migration logic, backward compat.
**Tip:** Your ccna flashcards.json has `"version": 2` — the skill knows how to handle both formats
**Drill:** Design a migration strategy for a state file schema change
**Tags:** versioning, migration, schema, backward-compat

### Interactive drill engines
Build drill modes with auto-grading, retry, stuck/skip/done commands, and end-of-session summaries.
**Tip:** Your neovim text-drill engine simulates Vim buffers and auto-grades keystroke sequences
**Drill:** Design the grading logic for a regex drill engine
**Tags:** drill-engine, grading, interactive, simulation

### Hooks in skills
Attach lifecycle hooks to skills — run commands before/after the skill loads.
**Tip:** `hooks: { PreToolUse: [...] }` can validate state before every tool call in your skill
**Drill:** Design a hook that validates state file integrity before a skill runs
**Tags:** hooks, lifecycle, pre-tool, validation

### Plugin-style skills
Build skills that are reusable across projects — the plugin pattern.
**Tip:** Plugin skills live in their own repo and are installed via the Claude Code plugin system
**Drill:** Restructure a project skill into a shareable plugin with namespaced commands
**Tags:** plugins, reusable, shareable, namespacing

### Skill testing strategies
Verify your skills work: manual testing, edge cases, state file corruption recovery.
**Tip:** Test: empty state (first run), normal state, corrupted state, missing files
**Drill:** Write a test checklist for a skill with 3 modes and a state file
**Tags:** testing, verification, edge-cases, corruption
