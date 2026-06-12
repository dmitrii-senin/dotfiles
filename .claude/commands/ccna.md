---
description: CCNA 200-301 exam prep — runs the learn engine for the ccna domain
argument-hint: "subnet [N] [--mixed] | flash review | quiz [mock|weak-areas|N] | schedule | tutor <t> | explain <c>"
---
Run the **learn** skill for the `ccna` domain.

Treat this exactly as `/learn ccna $ARGUMENTS`: read `~/.claude/skills/learn/SKILL.md`
and follow its dispatcher with domain = `ccna` and the remaining arguments
`$ARGUMENTS` (mode / area / topic), then execute the requested mode. With no arguments,
run the domain's default mode (`schedule`).
