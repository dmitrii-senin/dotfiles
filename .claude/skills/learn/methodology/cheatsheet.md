# `cheatsheet` mode — Quick Reference

Fast lookup of the domain's reference material. No retrieval practice here — this is
the "remind me" path. Terse, not a tutorial.

Invoked as `/learn <domain> cheatsheet [name]`.

---

## Flow

1. Look at the domain's `cheatsheets/` directory and the `cheatsheets` map in
   `domain.md` (which names the available sheets and any default).
2. Resolve the argument:
   - No argument → show the domain's default cheatsheet (per `domain.md`), or list the
     available sheets if no default is set.
   - A name → fuzzy-match against the files in `cheatsheets/`.
   - No match → list what's available: "available: <names>".
3. Display the cheatsheet content verbatim. Keep it terse; do not expand into a lesson.

If the learner asks to *learn* (not just look up) the material, suggest the matching
`mm` topic instead.
