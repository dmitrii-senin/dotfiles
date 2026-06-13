# 0002 — Flashcards should hold knowledge, not skills practiced elsewhere
date: 2026-06-13
area: meta (learning system)
type: insight
trigger: `/ccna flash review 20` session — multiple cards triggered "we train this daily in /ccna subnet" reactions

## What happened
Reviewing 20 due cards revealed that ~20% of the active deck (20 of 129 cards,
mostly in vol1-ch11–15) was **procedural subnetting** the user already drills
every day via `/ccna subnet` (recipe steps, specific `192.168.42.135/27`
instances, host-count tables, VLSM allocation walkthroughs). These cards added
friction without adding storage — the procedure is already at fluency from
the daily drill, so the flashcard pass was redundant.

Two other duplication patterns also surfaced:
- IPv4 classes A/B/C/D/E spread across **3 cards** in 3 chapters (v1c11-j01,
  v1c12-01, v1c13-j01), each asking a slightly different facet (ranges /
  default mask / network count) — wasteful overlap.
- Loopback `127/8` defined in **2 cards** (v1c11-j02, v1c12-04), nearly
  identical content.

After cleanup: 129 → 109 cards (20 net: 17 removed + 3 merged → 1).

## Correct model / resolution
**Division of labor between flash and skill modes (pedagogy §1 Knowledge vs Skill):**

- `flash` (Leitner) is for **knowledge atoms** — facts that need long-term
  durable retention but don't benefit from in-context practice. Vocabulary,
  field values (`EtherType 0x0806 = ARP`), ranges (`RFC 1918`), special
  addresses (loopback, APIPA), bit patterns (class leading bits), concepts
  (what is VLSM and what does it solve).
- **Skill modes** (`subnet`, `drill`, `quiz`, `tutor`) carry the procedural
  skill. The repetition + immediate scoring builds fluency that flashcards
  can't.

When a flashcard is just the procedure for something that has its own daily
drill mode, **remove the flashcard**. Keep cards for: *why* the procedure
works, *when* to apply it, the *concept* it implements. Not the procedure
itself.

**Rule of thumb to apply at `flash add` and during quarterly audits:**
1. Could the user pass this card by running another mode for 60 seconds?
   → Remove. The mode is the better teacher.
2. Is the card a specific *instance* (a particular IP/prefix)? → Remove.
   Instances rotate; the variety principle of the mode covers them better.
3. Is the card a near-duplicate of another card? → Merge into one
   comprehensive card, keep the earliest-chapter ID for stability.
4. Is the card a pure formula the user can re-derive in seconds? → Remove
   if the formula is exercised in a daily mode; keep if it's standalone
   knowledge (e.g., wildcard formula stays *as a concept*, not as a drill).

## Revisit
- Audit each new domain's deck during its first quarterly review for this
  same pattern. The risk is highest in domains with both a high-frequency
  practice mode and a large bank from a textbook (which tends to repeat
  the same concept across chapters as part of the textbook's spiral).
- For `ccna` specifically: re-audit after Phase 3 (W10–15 routing) when
  vol1-ch16–22 banks become eligible — OSPF and routing tables have similar
  knowledge-vs-skill overlap risk.
- Consider adding a `flash audit` mode that lists card pairs with similar
  fronts (Jaccard on tokenized front text, threshold ≥ 0.5) for periodic
  review.
