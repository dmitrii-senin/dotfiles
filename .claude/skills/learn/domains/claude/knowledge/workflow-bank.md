# Workflow Topic Bank
Updated: 2026-05-26

## beginner

### Plan mode basics
Use plan mode to explore and design before editing — when to plan vs just do.
**Tip:** Plan mode for multi-file changes and architecture. Direct prompt for single-file fixes.
**Drill:** Decide plan-or-direct for 5 tasks and explain your reasoning
**Tags:** plan-mode, planning, strategy, when-to-use

### Reading and navigating code with Claude
Use Claude Code to explore unfamiliar codebases — the right questions to ask.
**Tip:** "What does this function do?" < "Trace the call path from handleRequest to the database query"
**Drill:** Write 3 exploration prompts for a codebase you've never seen
**Tags:** exploration, navigation, codebase, reading

### CLAUDE.md essentials
What belongs in CLAUDE.md, what doesn't, and how to structure it.
**Tip:** Rules that always apply: coding standards, forbidden patterns, project structure. Don't put one-off tasks.
**Drill:** Write a CLAUDE.md for a hypothetical TypeScript API project (under 20 lines)
**Tags:** CLAUDE.md, structure, rules, conventions

### Effective use of the slash menu
Know what's available: built-in commands, skills, plugins — and when each is the right tool.
**Tip:** `/help`, `/status`, `/config`, `/cost` are built-in. Your custom skills show up alongside them.
**Drill:** Match 5 tasks to the right slash command or skill
**Tags:** slash-menu, commands, discovery, navigation

### Working with git through Claude
Let Claude handle git operations: committing, branching, diffing, conflict resolution.
**Tip:** Claude writes better commit messages than you do — let it read the diff and compose one
**Drill:** Write prompts for: create a commit, create a branch, resolve a merge conflict
**Tags:** git, commit, branch, merge, conflict

### Session management
Know when to start fresh vs continue — context window implications.
**Tip:** After ~30 turns or a topic shift, start a new session. Stale context degrades quality.
**Drill:** Identify 3 signals that it's time to start a new session
**Tags:** session, context, fresh-start, continuation

### Settings.json basics
Understand the key settings: model, effort level, theme, permissions.
**Tip:** `model: opus` for complex tasks, `sonnet` for speed. `effort: xhigh` for thoroughness.
**Drill:** Configure settings.json for a "thorough code review" profile vs a "quick fix" profile
**Tags:** settings, model, effort, configuration

### Permission management
Configure permissions to reduce prompts without sacrificing safety.
**Tip:** Allow read-only commands freely. Be selective with write operations.
**Drill:** Design a permission allowlist for a typical web project
**Tags:** permissions, allow, security, prompts

## intermediate

### Hooks: automating recurring actions
Configure hooks in settings.json to run commands on specific events.
**Tip:** Pre-commit hook to lint, post-edit hook to format — automate what you'd do manually every time
**Drill:** Write a hook spec that runs `prettier` after every file edit
**Tags:** hooks, automation, events, settings

### Agent delegation patterns
Use subagents for parallel work — when to delegate vs do inline.
**Tip:** Research (reading many files) → delegate to Explore agent. Implementation → do inline.
**Drill:** Decide delegate-or-inline for 5 tasks and explain the tradeoff
**Tags:** agents, delegation, parallel, subagents

### Worktrees for parallel work
Use git worktrees with Claude Code for isolated feature development.
**Tip:** Worktrees let an agent work on a separate branch without touching your working directory
**Drill:** Plan a workflow using worktrees for 2 parallel features
**Tags:** worktrees, parallel, isolation, branches

### Context window management
Monitor and manage context usage — techniques for long sessions.
**Tip:** Claude auto-compacts when context fills. Structure sessions so compaction preserves important info.
**Drill:** Identify 3 techniques to reduce context usage in a long session
**Tags:** context-window, compaction, management, efficiency

### MCP servers: connecting external tools
Understand MCP architecture and when to add a server vs use Bash tool calls.
**Tip:** MCP for structured tool APIs (database, API, file system). Bash for ad-hoc commands.
**Drill:** Decide MCP-or-Bash for 4 different external tool integrations
**Tags:** mcp, servers, external-tools, architecture

### Multi-file operations
Coordinate changes across many files efficiently — patterns and pitfalls.
**Tip:** List all files and changes upfront. Claude handles them sequentially but needs the full picture first.
**Drill:** Structure a prompt for renaming a function across 8 files
**Tags:** multi-file, coordination, refactoring, rename

### Using Claude for documentation
Generate and maintain docs, READMEs, API references — what Claude does well vs poorly.
**Tip:** Claude writes good API docs from code. It writes bad architecture docs without context.
**Drill:** Write a prompt for generating API docs vs a prompt for architecture docs and compare
**Tags:** documentation, docs, README, API

### Effective code review with Claude
Use Claude for PR review — setup, prompting, and interpreting results.
**Tip:** "Review this diff for correctness bugs only" > "review this PR." Scope the review criteria.
**Drill:** Write a code review prompt with specific criteria for a security-sensitive PR
**Tags:** code-review, PR, diff, criteria

## advanced

### Building custom agents
Define custom agent types in `.claude/agents/` for specialized workflows.
**Tip:** Agents are like skills but run in isolated subagent contexts with their own tool sets
**Drill:** Design an agent definition for a "database migration reviewer"
**Tags:** agents, custom, definition, isolation

### Task orchestration
Break complex work into tasks with dependencies — TaskCreate, TaskUpdate patterns.
**Tip:** Independent tasks can run in parallel. Dependent tasks must be sequenced. Use blockedBy.
**Drill:** Design a task graph for implementing a feature with frontend, backend, and test work
**Tags:** tasks, orchestration, dependencies, parallel

### Hooks: advanced patterns
Complex hook configurations: conditional hooks, chain hooks, error handling.
**Tip:** Hooks can validate, transform, and gate tool calls. But complex hooks are hard to debug.
**Drill:** Design a hook chain that: validates → transforms → logs for every file write
**Tags:** hooks, advanced, chains, conditional

### CI/CD integration with Claude Code
Use Claude Code in CI pipelines — automated review, test generation, migration.
**Tip:** Headless mode for CI. Scope permissions tightly. Use `--print` for non-interactive output.
**Drill:** Design a CI step that uses Claude Code to review PRs automatically
**Tags:** ci-cd, automation, headless, pipeline

### Performance optimization
Optimize Claude Code for speed — model selection, effort levels, caching, parallelism.
**Tip:** Haiku for simple tasks, Sonnet for moderate, Opus for complex. Don't use Opus for formatting.
**Drill:** Design a model-selection strategy for 5 different workflow stages
**Tags:** performance, speed, model-selection, optimization

### Plugin development
Build and publish Claude Code plugins — the full lifecycle.
**Tip:** Plugins package skills + agents + hooks for distribution. They live in their own repo.
**Drill:** Design the plugin manifest for a "code quality" plugin with 3 skills
**Tags:** plugins, development, publishing, distribution

### Session recovery and debugging
Diagnose and recover from bad Claude Code sessions — context corruption, tool failures, infinite loops.
**Tip:** `/status` shows tool call counts. If Claude is stuck in a loop, interrupt and restate the goal.
**Drill:** Write recovery prompts for 3 failure scenarios: loop, wrong file, context exhaustion
**Tags:** debugging, recovery, failures, diagnosis

### Combining skills with hooks and MCP
Design integrated workflows that chain skills, hooks, and MCP servers.
**Tip:** Hook triggers skill → skill calls MCP tool → result feeds back. Powerful but complex.
**Drill:** Design an integrated workflow for automated code review + formatting + deployment
**Tags:** integration, combined, workflow, architecture
