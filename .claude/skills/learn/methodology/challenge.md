# `challenge` mode — Real-World Application (Wisdom)

Apply the domain to a realistic, open-ended task that builds judgment. Read
`pedagogy.md` first: this is the **Wisdom** type — attempt an answer, then defer to a
high-reputation source/community for what only real-world practice teaches.

Invoked as `/learn <domain> challenge [topic]`.

Only available if `domain.md` lists `challenge` in its enabled modes and the domain
has a `challenges.md` bank.

---

## Flow

1. Read `challenges.md` (the domain's challenge bank) and
   `data/progress.json → challenges_completed`. Read `mission.md` for relevance.
2. Select a challenge in the learner's ZPD that advances the mission — or use the
   `[topic]` if given (fuzzy-match, else generate one grounded in `resources.md`).
3. Present the challenge as a concrete, real-world task with clear "done" criteria.
   Make it tangible and bounded (a single meaningful win).
4. Coach as the learner works: ask before telling, give hints before answers, keep the
   feedback loop tight. **Wait for the learner's attempts.**
5. Evaluate against the done criteria. Give an honest critique grounded in trusted
   sources; cite them and flag parametric-only claims.
6. **Defer to the field** where judgment is contested: point to the canonical
   reference, spec, or a high-reputation community (forum/subreddit/docs) for the
   parts that real-world practice settles better than any single answer. Respect any
   per-domain or user preference against communities (`domain.md` / `NOTES`).
7. **Log:** append to `challenges_completed` in `progress.json`; if a durable insight
   or judgment lesson emerged, write `records/NNNN-<insight>.md`.
