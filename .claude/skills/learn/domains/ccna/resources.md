# Resources: ccna — vetted, citeable sources

Stay on the CCNA 200-301 blueprint. Cite these over parametric memory for exact IOS syntax,
default values, and AD/timer numbers. The `knowledge/` files are the authoritative
blueprint-bounded source; the card bank is derived from the OCG.

## Primary / authoritative
- **Wendell Odom, *CCNA 200-301 Official Cert Guide*, Vol 1 + Vol 2** (OCG) — the card bank
  (`flashcards/`) is derived from its chapters; the canonical reference for facts/syntax.
- **`knowledge/1..6-*.md`** — the blueprint domain reference files (topics, terminology,
  exam traps). Authoritative for what's in/out of scope. Don't invent off-blueprint topics.
- **`cheatsheets/ios.md`** — IOS prompt strings, `show` output formats, error messages.
- **Cisco IOS command references / Cisco documentation** — for exact command syntax/defaults.

## Practice / video (second-pass teaching angles)
- **Jeremy's IT Lab (CCNA, free)** — primary video course; lab exercises.
- **Udemy — Neil Anderson, *CCNA 200-301 Complete Guide*** — second-pass angle; bundled
  Anki deck; lab exercises.
- **Cisco Packet Tracer** — hands-on labs.
- **subnettingpractice.com** — extra subnetting reps beyond `/ccna subnet`.

> When a precise figure matters (admin distances, timers, default VLAN/native, AD of OSPF,
> port ranges) and it isn't in `knowledge/`, attribute it to the OCG or Cisco docs. Flag
> anything you can't source as `⚠ unsourced — verify`.
