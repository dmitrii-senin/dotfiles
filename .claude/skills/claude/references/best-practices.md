# Claude Code Best Practices Checklist

Used by the `audit` mode to evaluate the user's setup. Each item has a severity (HIGH/MED/LOW) and a brief rationale.

---

## Settings (settings.json / settings.local.json)

### HIGH
- [ ] **Model is set explicitly** — not relying on defaults. Opus for complex work, Sonnet for everyday.
- [ ] **No overly broad Bash permissions** — `Bash(*)` allows everything. Scope to specific commands.
- [ ] **Sensitive files excluded** — `.env`, credentials, secrets not in any allow pattern.

### MED
- [ ] **Effort level set appropriately** — `high` or `xhigh` for code changes, `medium` for quick lookups.
- [ ] **Status line configured** — custom statusline shows useful info (model, cost, tokens).
- [ ] **Editor mode matches preference** — vim/emacs mode if the user prefers modal editing.
- [ ] **Permissions use specific patterns** — `Bash(git status)` better than `Bash(git *)`.

### LOW
- [ ] **Theme set** — personal preference but affects readability.
- [ ] **No duplicate permissions** — same pattern in both global and project settings.

---

## CLAUDE.md

### HIGH
- [ ] **Exists for active projects** — projects without CLAUDE.md miss persistent context.
- [ ] **Contains coding standards** — language, style, naming conventions.
- [ ] **No ephemeral content** — task lists, current bugs, "TODO: fix later" don't belong.

### MED
- [ ] **Under 100 lines** — longer CLAUDE.md wastes context every session. Move details to skills.
- [ ] **No duplicate of defaults** — don't restate Claude's built-in behavior.
- [ ] **Includes project structure** — key directories, entry points, build commands.
- [ ] **Includes test commands** — how to run tests, lint, build.

### LOW
- [ ] **Formatted for scanning** — bullets and headers, not paragraphs.
- [ ] **No commented-out rules** — if a rule doesn't apply, remove it.

---

## Skills

### HIGH
- [ ] **Each skill has a description** — skills without descriptions can't auto-invoke.
- [ ] **Destructive skills use disable-model-invocation** — deploy, delete, send should be manual-only.
- [ ] **State files are gitignored** — progress, session logs, etc. should not be committed.

### MED
- [ ] **Skills are under 500 lines** — detailed content belongs in reference files.
- [ ] **Skills use dynamic injection where appropriate** — `!`command`` beats "please run this command."
- [ ] **Skills have argument-hint** — helps the user know what arguments are valid.
- [ ] **Edit policy is explicit** — skills that modify files should say how and ask first.

### LOW
- [ ] **Supporting files are organized** — references/, topics/, data/ subdirectories.
- [ ] **Skills are symlinked from dotfiles** — version-controlled and portable.

---

## Permissions

### HIGH
- [ ] **No blanket Bash allow** — `Bash(*)` is a security risk. Scope permissions.
- [ ] **Read-only commands are allowed** — `Bash(git status)`, `Bash(ls *)` reduce permission fatigue.
- [ ] **Write commands require confirmation** — `Bash(git push *)`, `Bash(rm *)` should prompt.

### MED
- [ ] **Permissions organized by category** — group git, npm, test commands together.
- [ ] **No stale permissions** — remove allows for tools/commands you no longer use.
- [ ] **Project-specific permissions in project settings** — don't pollute global with project-specific allows.

### LOW
- [ ] **Permission list is documented** — comments or grouping help future-you understand why each exists.

---

## Plugins

### MED
- [ ] **No conflicting plugins** — two plugins providing the same functionality cause confusion.
- [ ] **Plugins are up to date** — outdated plugins may miss new features or have bugs.
- [ ] **Unused plugins disabled** — every loaded plugin adds context overhead.

### LOW
- [ ] **Plugin configuration is intentional** — default configs may not match your workflow.

---

## Hooks

### HIGH
- [ ] **Hooks don't block normal workflow** — a broken hook that rejects tool calls will freeze your session.
- [ ] **Hooks are tested** — run the hook command manually before configuring it.

### MED
- [ ] **Formatting hooks exist** — auto-format on file write saves manual steps.
- [ ] **Hooks are scoped** — hook on `Edit` is better than hook on all tool calls.

### LOW
- [ ] **Hook commands are fast** — slow hooks degrade the interactive experience.
