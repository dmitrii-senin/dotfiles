# Domain: ccna — CCNA 200-301 exam prep

title: CCNA 200-301 Exam Practice
level: exam candidate — goal is to pass, not gold-plate. Blueprint-bounded (don't teach off-blueprint).

## Areas (the 6 exam domains)

Quiz/tutor/explain read the matching `knowledge/` file before generating content. Map user
input by semantic context — exact keywords aren't required.

| Area key | Exam domain (weight) | Keywords | Knowledge file |
|---|---|---|---|
| `fundamentals` | 1 Network Fundamentals (20%) | osi, tcpip, cabling, topology, interfaces, virtualization | `knowledge/1-network-fundamentals.md` |
| `access` | 2 Network Access (20%) | switching, vlan, trunk, stp, rstp, etherchannel, wireless, wlc | `knowledge/2-network-access.md` |
| `connectivity` | 3 IP Connectivity (25%) | routing, static, ospf, route, ipv6 | `knowledge/3-ip-connectivity.md` |
| `services` | 4 IP Services (10%) | dhcp, dns, nat, ntp, qos, snmp, syslog, tftp | `knowledge/4-ip-services.md` |
| `security` | 5 Security Fundamentals (15%) | acl, port-security, aaa, vpn, dhcp-snooping, dai | `knowledge/5-security.md` |
| `automation` | 6 Automation & Programmability (10%) | json, yaml, rest, api, netconf, restconf, sdn, dna, ansible | `knowledge/6-automation.md` |

For `quiz mock` / `quiz weak-areas`, read all six (or the subset matching weak areas).

## Modes

enabled: `flash`, `cheatsheet` (universal) · `subnet`, `schedule`, `quiz`, `tutor`, `explain`, `progress` (domain — `modes/`)
default: `schedule`   (bare `/ccna` shows this week's targets)
removed (decommissioned): ~~cli-roleplay~~, ~~config-review~~, ~~journal~~
not used: `mm`, `drill`, `challenge` (ccna uses `quiz`/`tutor`/`explain` instead)

A bare integer first token (e.g. `/ccna 15`) → `quiz 15`.

## Schedule (source of truth for `schedule` mode + flash injection)

- **Start:** Monday **2026-05-04**. **Exam target:** ~**2026-11-23** (Week 30).
- `current_week = floor((today − start) / 7) + 1`. The detailed plan lives in `ccna.md`
  (5 phases: W1-5 Foundations, W6-9 Switching, W10-15 Routing, W16-21 Services+Security,
  W22-26 Automation+Review; W27-28 consolidation, W29 light review, W30 exam). `schedule`
  mode reads `ccna.md` for the authoritative weekly content.

## Flash (week-gated injection — overrides the generic rule)

The deck `data/flashcards.json` is **version 2**, cards keyed by **`chapter`/`week`/`topic`**
(not `area`). Banks in `flashcards/` are **per-chapter** (`vol1-ch08.json`), each with a
`weeks` array + `cards`.

- **Injection (Step 1 of `flash review`):** a chapter is eligible iff `current_week > max(weeks)`
  — the whole span of weeks for that chapter is in the past (don't inject material not yet
  studied). For each eligible chapter, inject each card not already in the deck with
  `chapter` + `week` (first of `weeks`) + `topic` from the bank, `box: 1`, `due_date: today`,
  `created: today`. Then review per the generic `flash` mechanics (`methodology/srs.md`).
- Pre-prep / week 1: nothing eligible yet (correct). Then review due cards normally.

## Cheatsheets
default: `ios`  ·  available: `ios` (IOS prompt strings, show-output formats, error messages)

## Daily habits (surface in `schedule`/`status`)
Daily subnetting drill (`/ccna subnet 10`) + daily flashcards (`/ccna flash review`);
weekly weak-area quiz (`/ccna quiz weak-areas`). Resources in `resources.md`.
