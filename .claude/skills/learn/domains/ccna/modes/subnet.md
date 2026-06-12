# `subnet` mode (ccna) — subnetting drills

Generate subnetting problems. Default is IPv4-only, count 10.

Invoked as `/learn ccna subnet [N] [--ipv4|--ipv6|--mixed] [--timed]` (alias: `/ccna subnet …`).

- `--ipv4` (default / no flag) — IPv4-only
- `--ipv6` — IPv6-only
- `--mixed` — ~60% IPv4 / 40% IPv6, **interleaved** (not grouped); cycle each list independently
- `--timed` — per-problem limit (default 60s); reduce score for over-time answers

## IPv4 problem types (cycle through)

**Variety principle:** never reuse the same canonical example twice in a session. Rotate the
source prefix, the octet where the math lands, the starting offset (don't always start at
`.0`), and the block (mix 10.x, 172.16–31.x, 192.168.x, occasional 100.64.x / 203.0.113.x).
Favor problems where the math straddles an octet boundary or starts at a non-zero offset.

1. **Network/broadcast/usable range** — e.g. `192.168.42.135/27` → network, broadcast, first/last usable, host count.
2. **Mask for N hosts** — "need 50 hosts" → smallest mask.
3. **Mask for N subnets** — given a /24 + "8 equal subnets" → new mask + network IDs.
4. **VLSM allocation** — /24 + LANs needing 100/50/20 → non-overlapping subnets.
5. **Summarization** — find the summary route. **Vary aggressively** — do NOT default to
   "4 contiguous /24s → /22". Rotate: source prefixes /30–/23; counts 2/4/8/16 (+ odd 3/5/6/7);
   2nd/3rd/4th-octet boundaries; non-`.0` starting offsets; boundary-straddling lists that
   *can't* cleanly summarize; "smallest covering summary" with gaps (e.g. `10.1.4/24,5/24,7/24`
   → `10.1.4.0/22` over-including .6); reverse direction (given a summary, list members).
6. **Wildcard mask conversion** — e.g. `255.255.255.224` → wildcard (for ACL/OSPF).

## IPv6 problem types

1. Compress/expand (`2001:0db8:0000:…:0001` ↔ `2001:db8::1`).
2. Identify prefix type (link-local `fe80::/10`, ULA `fc00::/7`, multicast `ff00::/8`, GUA `2000::/3`).
3. SLAAC EUI-64 from MAC.
4. Subnet a `/48` into `/64` LANs.

## Flow

1. Print `problem N/total` and timestamp the start.
2. **Wait for the user's answer.**
3. Verify; show the correct answer with brief working (e.g. "block size 32 → nets at .128/.160;
   .135 ∈ .128/27").
4. Tag missed types into `data/weak-areas.json` under `subnetting:<type>` (increment
   `misses`/`attempts`, set `last_seen`/`last_score`). If the same conceptual error recurs
   (e.g. block-size direction, octet-boundary straddling), write a `records/` entry
   (`methodology/state.md`) capturing the misconception.
5. After all: score, average time-per-problem, and any subtopic the user struggled with.

Daily-driver: keep it fast and low-friction — this is run every day. Don't over-explain
correct answers; expand only on misses.
