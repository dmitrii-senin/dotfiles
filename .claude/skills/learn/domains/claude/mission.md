# Mission: claude

## Why
I use Claude Code daily as a C++ infra engineer. The leverage is enormous but only if I
*drive* it well — precise prompts, well-authored skills, the right workflows (plan mode,
hooks, subagents, worktrees), and an accurate mental model of how the LLM actually behaves
(tokens, context, caching, cost). I want to stop fumbling and operate the tool
deliberately, grounded in my own real setup rather than generic tips.

## What success looks like
- Write prompts that eliminate guesses on the first try (specificity, constraints,
  output shape, context placement).
- Author skills that trigger reliably and stay maintainable (this `learn` engine is the
  proving ground).
- Use the power workflows fluently: plan mode, hooks, MCP, worktrees, subagents.
- Have a correct LLM mental model — reason about context windows, caching, model/effort
  trade-offs, and cost without hand-waving.
- Retain it: my config keeps improving and I stop re-learning the same techniques.

## Deadline
Continuous — this compounds every working day. Pace by consistency.

## Constraints / style
Short sessions (5–10 min). Anchor everything to my real `~/x/dotfiles/.claude/` setup;
cite specific lines. Always explain the WHY and the failure mode a technique prevents.
Don't re-recommend things I already have configured.
