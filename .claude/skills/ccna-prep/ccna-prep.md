# CCNA 200-301 — 6-Month Preparation Plan

## Context

You're preparing for the **Cisco CCNA 200-301** exam with a **6-month** timeline at a sustainable **~5-6 h/week** pace. You hold **LPIC-202**, so you already have solid foundations in Linux networking, DNS, DHCP, mail, web services, and routing concepts at the OS level. The CCNA shifts the perspective from *host-side* to *network-device-side* (Cisco IOS CLI, switching, routing protocols, ACLs, wireless, automation).

The longer runway lets you go deeper, repeat labs from memory, and consolidate — instead of cramming. The risk of a long timeline is **forgetting early material**, so this plan bakes in cumulative review every 4 weeks.

**Plan start date:** Monday **2026-04-27** (this is the source of truth for the `/ccna-prep schedule` mode — change it here if the start shifts).

**Goal:** Pass CCNA 200-301 in **November 2026**. Week 24 ends ~2026-10-11; **target exam date ~2026-11-09** (week 28). Weeks 25-26 are confidence-consolidation (no new material), week 27 is light review, exam in week 28.

## Resources (locked in)

- **Primary video course:** Jeremy's IT Lab — free CCNA 200-301 playlist on YouTube
- **Primary book:** Wendell Odom — *CCNA 200-301 Official Cert Guide, Volumes 1 & 2* (Cisco Press)
- **Lab environment:** Cisco Packet Tracer (free via Cisco NetAcad — sign up for the free "Packet Tracer 101" course to get the download)
- **Practice exams (final stretch only):** [Udemy — CCNA 200-301 Pre-Exam Testing](https://www.udemy.com/course/ccna-200-301-pre-exam-testing/) (already purchased) — used as full-length mock exams in weeks 22 + 24, **not** split by domain (filtering by topic isn't practical there)
- **Claude-assisted drills (built in week 1):** custom skill for daily quizzing, flashcards, subnetting, IOS CLI roleplay, and config review — see "Claude-assisted prep" section below
- **Optional supplement (week 22):** Boson ExSim-Max for CCNA — closest difficulty to the real exam if budget allows

## Weekly time budget (5-6 h)

- **Theory (video + reading):** 2.5-3 h — split across 2 weekday evenings (~75 min each)
- **Hands-on labs (Packet Tracer):** 1.5-2 h — one weekend session
- **Review + flashcards + practice Qs:** ~1 h — short daily 10-15 min sessions

## Exam blueprint weighting

| Domain | Weight |
|---|---|
| 1.0 Network Fundamentals | 20% |
| 2.0 Network Access (switching, VLANs, wireless) | 20% |
| 3.0 IP Connectivity (routing, OSPF) | 25% |
| 4.0 IP Services (NAT, NTP, DHCP, QoS, SNMP, Syslog) | 10% |
| 5.0 Security Fundamentals (ACLs, port security, AAA, VPN) | 15% |
| 6.0 Automation & Programmability | 10% |

## 6-Month Schedule (24 weeks)

### Phase 1 — Foundations (Weeks 1-5)

**Week 1 — Networking refresh + IOS CLI orientation**
- Jeremy's IT Lab Day 1-3 (intro, OSI/TCP-IP, network devices)
- OCG Vol 1 Ch 1-2
- Lab: install Packet Tracer, interface tour, basic device drag-and-drop topology
- **Start daily 10-problem subnetting drill on subnettingpractice.com** (or `/ccna-prep subnet 10`). Begin from week 1 — your LPIC-202 IPv4 background means there's no warm-up needed; longer runway = more reps before exam.
- **Confirm Cisco CCNA 200-301 v1.1 is still current** (check cisco.com training-events page) — don't study for an outdated blueprint.
- *LPIC-202 leverage:* skim OSI fast — focus on Cisco-specific layer terminology

**Week 2 — IOS CLI fundamentals**
- Jeremy Day 4-7
- OCG Vol 1 Ch 3-4
- Lab: hostname, banners, console + enable + VTY passwords, SSH, save running-config to startup-config

**Week 3 — Ethernet LAN basics**
- Jeremy Day 8-10
- OCG Vol 1 Ch 5-7
- Lab: 2-switch + 4-PC topology, observe MAC address table learning, examine frame paths

**Week 4 — IPv4 addressing + subnetting (deep dive)**
- Jeremy Day 11-13
- OCG Vol 1 Ch 11-12
- Subnetting drill is now daily habit (started week 1) — this week, push to **20/day** while the topic is fresh
- Lab: assign IPs to a multi-subnet topology, verify connectivity

**Week 5 — Consolidation + Phase 1 review**
- Re-watch any Jeremy day where flashcards scored < 80%
- Re-build week 3 lab from memory (no notes)
- OCG "Do I Know This Already?" quizzes for Ch 1-12
- **Milestone:** `/ccna-prep quiz domain 1 25` — target ≥ 70%

### Phase 2 — Switching (Weeks 6-9)

**Week 6 — VLANs**
- Jeremy Day 14-16
- OCG Vol 1 Ch 13-14
- Lab: 3 VLANs across two switches with access ports

**Week 7 — Trunking + VTP/DTP**
- Jeremy Day 17-19
- OCG Vol 1 Ch 15
- Lab: 802.1Q trunk between switches, manually prune VLANs, disable DTP for security

**Week 8 — STP + RSTP + EtherChannel**
- Jeremy Day 20-23
- OCG Vol 1 Ch 16-18
- Lab: observe root election, manipulate priority to force a chosen root, configure LACP EtherChannel
- *Common confusion area:* memorize STP port states + RSTP port roles cold

**Week 9 — Consolidation + Phase 2 review**
- Re-build the full Phase 2 topology (VLANs + trunks + STP + EtherChannel) from memory in < 30 min
- **Milestone:** `/ccna-prep quiz domain 1,2 30` — target ≥ 72%

### Phase 3 — Routing (Weeks 10-15)

**Week 10 — Routing fundamentals + static routes**
- Jeremy Day 24-26
- OCG Vol 1 Ch 19-20
- Lab: static routes between 3 routers, default route, floating static for backup

**Week 11 — Inter-VLAN routing (RoaS + L3 switch SVI)**
- Jeremy Day 27-28
- OCG Vol 1 Ch 21
- Lab: router-on-a-stick first, then convert to L3 switch with SVIs — compare both

**Week 12 — OSPF part 1 (single area, fundamentals)**
- Jeremy Day 29-31
- OCG Vol 1 Ch 22-23
- Lab: OSPFv2 on 3 routers, single area, verify `show ip ospf neighbor`, `show ip route ospf`

**Week 13 — OSPF part 2 (DR/BDR, timers, passive, authentication)**
- Jeremy Day 32-34
- OCG Vol 1 Ch 24-25
- Lab: manipulate router-id, force DR election, tune hello/dead timers, set passive interfaces
- *Heavily tested:* practice troubleshooting broken OSPF adjacencies (timer mismatch, area mismatch, network type mismatch)

**Week 14 — IPv6 fundamentals + IPv6 routing**
- Jeremy Day 35-37
- OCG Vol 1 Ch 26-29
- Lab: dual-stack topology, SLAAC, OSPFv3
- *LPIC-202 leverage:* IPv6 addressing rules transfer directly — focus on Cisco config syntax

**Week 15 — Consolidation + Phase 3 review (mid-plan checkpoint)**
- Re-build a full Phase 3 lab from memory: 3 routers + 2 switches + VLANs + OSPF + dual-stack
- **Major milestone:** `/ccna-prep quiz mock 50` — target ≥ 70%
- Use `/ccna-prep cli-roleplay ospf-troubleshoot` (Claude pretends to be a broken router; you fix it via CLI)
- Identify weakest topic; spend 1 extra hour on it before continuing

### Phase 4 — Services + Security + Wireless (Weeks 16-20)

**Week 16 — DHCP, DNS, NTP**
- Jeremy Day 38-40
- OCG Vol 2 Ch 1-3
- Lab: IOS DHCP server + `ip helper-address` relay, NTP client/server hierarchy
- *LPIC-202 leverage:* DHCP/DNS concepts identical — focus on IOS syntax

**Week 17 — NAT (static, dynamic, PAT) + QoS concepts**
- Jeremy Day 41-43
- OCG Vol 2 Ch 4-5
- Lab: PAT for an internal LAN to a single public IP, static NAT for an inside server

**Week 18 — Security fundamentals + ACLs**
- Jeremy Day 44-46
- OCG Vol 2 Ch 6-8
- Lab: standard ACL, extended ACL, named ACL — practice placement (extended close to source, standard close to destination)
- **Buy Cisco exam voucher this week** and schedule for ~2026-11-09 (week 28). Re-confirm CCNA 200-301 v1.1 is still the current blueprint before purchase.

**Week 19 — Layer 2 security + AAA + VPN concepts**
- Jeremy Day 47-50
- OCG Vol 2 Ch 9-10
- Lab: port security with all 3 violation modes, DHCP snooping, DAI
- VPN/IPsec is concept-only on CCNA — read, don't lab

**Week 20 — Wireless + WLC**
- Jeremy Day 51-56
- OCG Vol 2 Ch 11-14
- Lab: Packet Tracer WLC GUI walkthrough, configure a WLAN with WPA2-PSK
- **Milestone:** `/ccna-prep quiz domain 4,5 30` — target ≥ 72%
- **Mid-plan mock exam:** take **Udemy practice test #3** (different from the two reserved for weeks 22 + 24) under timed conditions. Catches weak areas with 7 weeks left to remediate. Target ≥ 70%.

### Phase 5 — Automation + Heavy Review (Weeks 21-24)

**Week 21 — Automation & programmability**
- Jeremy Day 57-60
- OCG Vol 2 Ch 16-18
- Topics: REST APIs, JSON/XML/YAML, Ansible/Puppet/Chef *concepts only*, SDN, Cisco DNA Center, controller-based vs traditional
- Lab: hit a REST API with curl or Postman, parse a JSON response
- *LPIC-202 leverage:* you've used YAML and JSON — focus on Cisco's specific automation tools

**Week 22 — Full blueprint review + weak-area remediation**
- **Major milestone:** Udemy full-length practice test #1 (full blueprint, timed) — target ≥ 75%. (Mid-plan mock #3 was in week 20.)
- Re-watch Jeremy videos for any topic < 80% on the practice test
- Re-do labs from memory: OSPF, VLAN+trunking+STP, ACLs, NAT
- Run `/ccna-prep quiz weak-areas` (Claude pulls from memory ledger of low-scoring topics — see Claude-assisted prep section)
- *(Optional)* Buy Boson ExSim-Max here if budget allows — take exam A

**Week 23 — Lab marathon + scenario practice**
- Build, from scratch in one sitting, a "capstone" topology:
  - 3 routers running OSPF
  - 2 L3 switches with 3 VLANs each
  - Inter-VLAN routing via SVI
  - DHCP server on a router with relay
  - PAT to simulate internet
  - Extended ACL blocking specific traffic
  - Dual-stack IPv4/IPv6
- Target build time: < 60 minutes with no notes
- Daily 30 subnetting problems

**Week 24 — Final mock + exam-condition rehearsal**
- Udemy full practice test #2 under exam conditions (120 min, no pause, no notes) — target ≥ 80%
- *(Optional)* Boson ExSim exam B
- Review every wrong answer — write a one-line "why" for each (feed into `/ccna-prep flash add` so the missed concepts get spaced-repeated)

**Weeks 25-26 — Confidence consolidation (no new material)**
- Daily flashcards (`/ccna-prep flash review`)
- Re-do weakest-area quizzes from `/ccna-prep quiz weak-areas`
- Re-build capstone topology from memory once per week

**Week 27 — Light review**
- 30 min/day max: flashcards + 10 subnetting problems
- Skim OCG chapters tagged "review" in your notes
- No new labs

**Week 28 — Exam week (~2026-11-09)**
- 2 days before: only flashcards, sleep, hydrate
- Exam day

## Claude-assisted prep (built in week 1)

The 6-month timeline + your absence of a question-bank-on-demand makes Claude an ideal study partner. Build **one custom skill** at `~/.claude/skills/ccna-prep/` (source in `~/x/dotfiles/.claude/skills/ccna-prep/`) that exposes several modes, plus a small persistent ledger for tracking weak topics across sessions.

### Skill: `ccna-prep` (single skill, multiple modes)

| Invocation | What it does |
|---|---|
| `/ccna-prep quiz <domain\|topic\|weak-areas\|mock> [N]` | Generates N exam-style questions (multiple choice + multi-select), grades, explains every answer with the *exam-relevant* reasoning, logs missed topics to the weak-areas ledger |
| `/ccna-prep flash <add\|review>` | Lightweight spaced-repetition flashcard system stored as JSON. `add` ingests a fact you missed; `review` surfaces due cards (Leitner box scheduling — simpler than full SM-2) |
| `/ccna-prep subnet [N] [--ipv6]` | Generates N subnetting problems (default 10), times you, grades. IPv6 mode for week 14+ |
| `/ccna-prep cli-roleplay <scenario>` | Claude pretends to be an IOS device. You type commands, it returns realistic `show` output and accepts config changes. Scenarios: `ospf-troubleshoot`, `vlan-build`, `acl-design`, `bare-router`. **Huge value** because real exam includes simlets — and this trains muscle memory without booting Packet Tracer. |
| `/ccna-prep config-review` | Paste an IOS config; Claude critiques it as if it were an exam scenario: missing best practices, security gaps, would this pass the lab task |
| `/ccna-prep tutor <topic>` | Socratic mode. Claude asks questions to draw out your understanding of e.g. OSPF neighbor states, doesn't give answers until you commit |
| `/ccna-prep explain <concept>` | Direct explanation, but framed against your LPIC-202 background (e.g., "OSPF LSA flooding is like…") |
| `/ccna-prep journal <append\|search>` | Persistent IOS command journal. `append` adds a `{date, topic, command, note}` entry; `search` greps for command/topic. Replaces the plain text "command journal" habit. |
| `/ccna-prep schedule [week\|next\|overview]` | Reads this plan file, computes current week from the start date, prints what's due this week (theory targets, lab task, milestones, habit reminders) and weeks-until-exam. `schedule next` previews next week; `schedule overview` shows all phases at a glance. |

### Persistent state

Three small files maintained by the skill (under `~/.claude/skills/ccna-prep/data/`, gitignored):

- `data/weak-areas.json` — `{topic: {misses, last_seen, last_score}}`. Drives `/ccna-prep quiz weak-areas`.
- `data/flashcards.json` — Leitner deck: each card has `{front, back, box (1-5), due_date}`. Cards in box 1 review daily, box 2 every 3 days, box 3 weekly, box 4 every 2 weeks, box 5 monthly.
- `data/command-journal.md` — plain-text IOS command journal for `/ccna-prep journal`.

### Why a skill, not a hook or memory

- **Skill** = on-demand, parameterized, has its own instructions and data files → perfect fit for quiz/flash/CLI roleplay
- **Memory** = facts about you (already used for "user holds LPIC-202", "studying for CCNA")
- **Hook** = automatic on event. *Optional add:* a `SessionStart` hook that runs `/ccna-prep flash review` to surface 5 due cards at the start of every session — turns idle session-opens into review opportunities. Decide in week 4 whether you want this nudge or find it noisy.

### Build sequence (week 1, ~2 hours total)

1. Scaffold the skill directory + `SKILL.md` with the instructions above
2. Implement `quiz` mode first (most-used, simplest — pure prompt engineering, no state needed)
3. Implement `subnet` mode next (deterministic generation, easy to verify)
4. Implement `flash` mode (introduces the JSON ledger pattern)
5. Implement `cli-roleplay` last (most complex prompt design — keep a small "IOS behavior cheatsheet" inside the skill so Claude's outputs stay realistic)
6. Save a memory note: "use `/ccna-prep` skill before answering CCNA questions; cross-reference weak-areas.json"

### What Claude is *not* good for (be honest)

- **Real packet capture / timing-sensitive behavior** — Packet Tracer remains essential
- **Authoritative exam-question phrasing** — Cisco's wording quirks are unique; Boson/Udemy practice tests still own the "feel" of the exam
- **Visual sims/drag-drop** — exam UI elements that Claude can only describe, not render

Use Claude for **drilling concepts, fast feedback loops, weak-area discovery, and CLI muscle memory**. Use Packet Tracer for **topology behavior**. Use Udemy/Boson for **exam-realism calibration**.

## Cross-cutting habits (start week 1, never stop)

1. **Daily subnetting drill (10 min)** — `/ccna-prep subnet 10`. Non-negotiable from week 1 onward.
2. **Lab-from-memory rule** — after every guided Packet Tracer lab, wipe the topology and rebuild it without notes. Produces real recall under exam pressure.
3. **Daily flashcards (10-15 min)** — `/ccna-prep flash review`. Combines Jeremy's free Anki deck (imported into your local ledger) with cards you add as you study. Critical against a 6-month forgetting curve.
4. **Weekly mini-quiz (Sunday, 15 min)** — `/ccna-prep quiz weak-areas 15`. Targets exactly the topics you've been missing.
5. **Command journal** — use `/ccna-prep journal append` after every lab. Becomes your personal cheat sheet for weeks 22-24 and feeds `/ccna-prep cli-roleplay` scenario design.
6. **Monthly cumulative review** — every 4 weeks (built into the consolidation weeks above), re-do labs from earlier phases to fight decay.

## Leveraging your LPIC-202 background

| You already know (LPIC-202) | CCNA angle to focus on |
|---|---|
| DNS server config (BIND) | DNS as a *client service* on IOS, `ip name-server`, `ip domain-lookup` |
| DHCP server (isc-dhcp) | IOS DHCP server + `ip helper-address` relay |
| Routing concepts (Linux `ip route`) | Cisco RIB/FIB, administrative distance, OSPF LSA types and neighbor states |
| Firewall (iptables/nftables) | Cisco ACLs (stateless, top-down match, implicit deny — placement rules) |
| TCP/IP, OSI, ports | Skim fast; reinvest the saved time in switching/STP/wireless |
| YAML, scripting basics | Focus on Cisco automation tooling specifics (DNA Center, NETCONF/RESTCONF) |

**Where the real new learning happens:** switching internals, STP/RSTP, wireless architecture, OSPF Cisco-specific behavior (DR/BDR, LSA types, neighbor state machine), and the IOS CLI itself. Budget mental energy there.

## Verification — how you'll know you're ready

You're exam-ready when **all** of these are true:
- Score ≥ 80% on the Udemy full-length practice test in week 22, ≥ 85% in week 24
- Can subnet any /prefix in < 30 seconds without paper (verified by `/ccna-prep subnet 20 --timed`)
- Can build, from scratch in Packet Tracer with no notes: a 3-router OSPF topology with VLANs, inter-VLAN routing, DHCP, NAT, and an ACL — in under 60 minutes
- Can complete `/ccna-prep cli-roleplay ospf-troubleshoot` and `/ccna-prep cli-roleplay vlan-build` end-to-end without referring to notes
- Can explain (out loud, to a rubber duck — or via `/ccna-prep tutor`) the difference between: trunk vs access port, RSTP port roles/states, OSPF neighbor states, standard vs extended ACL placement rules, controller-based vs traditional networking
- Weak-areas ledger is empty or shows only topics with current score ≥ 80%

## Notes / decisions

- **6-month pace** chosen to keep weekly load at ~5-6 h. Tradeoff: higher forgetting risk, mitigated by monthly consolidation weeks + daily Claude flashcards + weekly weak-area quiz.
- **Udemy practice tests reserved for weeks 20 + 22 + 24** — used as full-length, exam-condition mock exams. Earlier-phase domain quizzes are generated by Claude (`/ccna-prep quiz domain N`), since the Udemy course doesn't filter cleanly by topic.
- **Boson ExSim** kept optional — your Udemy course covers practice testing; Boson is a polish-and-confidence add-on for week 22+ if you want extra signal before exam day.
- **Packet Tracer over GNS3/EVE-NG** — covers 100% of CCNA blueprint with zero IOS image licensing hassle. If you want to go further post-cert, switch to EVE-NG for CCNP prep.
- This plan assumes the current **CCNA 200-301 v1.1** blueprint. Confirm Cisco hasn't released a v1.2 before purchasing the exam voucher (week 18). Re-check at week 1 too.
- **Buy the exam voucher in week 18** and schedule the exam for ~2026-11-09 (week 28). Earlier purchase = ~10 weeks of "exam scheduled" pressure. Concrete date > vague target.
- **Plan source of truth:** this file is now the canonical copy at `~/x/dotfiles/.claude/skills/ccna-prep/ccna-prep.md` (the original at `~/ccna-prep.md` can be deleted or symlinked: `ln -sf ~/x/dotfiles/.claude/skills/ccna-prep/ccna-prep.md ~/ccna-prep.md`).
