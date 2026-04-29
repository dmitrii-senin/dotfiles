# CCNA 200-301 — 7-Month Preparation Plan

## Context

You're preparing for the **Cisco CCNA 200-301** exam with a **7-month** timeline at a sustainable **~7-8 h/week** pace. You hold **LPIC-202**, so you already have solid foundations in Linux networking, DNS, DHCP, mail, web services, and routing concepts at the OS level. The CCNA shifts the perspective from *host-side* to *network-device-side* (Cisco IOS CLI, switching, routing protocols, ACLs, wireless, automation).

The longer runway lets you go deeper, repeat labs from memory, and consolidate — instead of cramming. The risk of a long timeline is **forgetting early material**, so this plan bakes in cumulative review every 4 weeks. Two video tracks (Jeremy's IT Lab + Neil Anderson's Udemy CCNA Complete) run in parallel and reinforce each topic from two angles.

**Plan start date:** Monday **2026-04-27** (this is the source of truth for the `/ccna-prep schedule` mode — change it here if the start shifts).

**Goal:** Pass CCNA 200-301 in **November 2026**. Week 26 ends ~2026-10-25; **target exam date ~2026-11-23** (week 30). Weeks 27-28 are confidence-consolidation (no new material), week 29 is light review, exam in week 30.

## Resources (locked in)

- **Primary video course (spine):** Jeremy's IT Lab — free CCNA 200-301 playlist on YouTube. Sets weekly topic order.
- **Secondary video course:** [Udemy — Cisco CCNA 200-301: The Complete Guide to Getting Certified by Neil Anderson](https://www.udemy.com/course/ccna-complete/). 40 sections, 326 lectures, ~42.5h total. Includes 31 articles, 235 downloadable resources, **lab exercises**, and a **bundled Anki flashcard deck** (downloaded from Sec 2 of the course — see Cross-cutting habits). Used as a second pass on each topic — different teaching angle, often clearer on Cisco-specific syntax. Sections 1-2 (Welcome + How to Use the Lab Exercises and Anki Flashcards, ~50 min) are pure orientation — knock out in week 1.
- **Primary book:** Wendell Odom — *CCNA 200-301 Official Cert Guide, Volumes 1 & 2* (Cisco Press)
- **Lab environment:** Cisco Packet Tracer (free via Cisco NetAcad — sign up for the free "Packet Tracer 101" course to get the download)
- **Practice exams (final stretch only):** [Udemy — CCNA 200-301 Pre-Exam Testing](https://www.udemy.com/course/ccna-200-301-pre-exam-testing/) (already purchased) — used as full-length mock exams in weeks 24 + 26, **not** split by domain (filtering by topic isn't practical there)
- **Claude-assisted drills (built in week 1):** custom skill for daily quizzing, flashcards, subnetting, IOS CLI roleplay, and config review — see "Claude-assisted prep" section below
- **Optional supplement (week 24):** Boson ExSim-Max for CCNA — closest difficulty to the real exam if budget allows

## Weekly time budget (7-8 h)

- **Theory (Jeremy + Udemy video + OCG reading):** 4-5 h — split across 3 weekday evenings (~90 min each). Udemy sections each week are listed below as a second pass on the same topic.
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

## 7-Month Schedule (26 weeks)

### Phase 1 — Foundations (Weeks 1-5)

**Week 1 — Networking refresh + IOS CLI orientation**
- Jeremy's IT Lab Day 1-3 (intro, OSI/TCP-IP, network devices)
- OCG Vol 1: Ch 1 *Introduction to TCP/IP Networking*, Ch 2 *Fundamentals of Ethernet LANs*, Ch 3 *Fundamentals of WANs and IP Routing*
- **Udemy**: Sec 1 Welcome (20m), Sec 2 How to Use the Lab Exercises and Anki Flashcards (29m) — pure orientation, knock out first; Sec 3 Host to Host Communications (30m), Sec 5 OSI Layer 4 - The Transport Layer (13m), Sec 6 OSI Layer 3 - The Network Layer (54m)
- Lab: install Packet Tracer, interface tour, basic device drag-and-drop topology
- **Start daily 10-problem subnetting drill on subnettingpractice.com** (or `/ccna-prep subnet 10`). Begin from week 1 — your LPIC-202 IPv4 background means there's no warm-up needed; longer runway = more reps before exam.
- **Confirm Cisco CCNA 200-301 v1.1 is still current** (check cisco.com training-events page) — don't study for an outdated blueprint.
- *LPIC-202 leverage:* skim OSI fast — focus on Cisco-specific layer terminology

**Week 2 — IOS CLI fundamentals**
- Jeremy Day 4-7
- OCG Vol 1: Ch 4 *Using the Command-Line Interface*, Ch 6 *Configuring Basic Switch Management*, Ch 7 *Configuring and Verifying Switch Interfaces*
- **Udemy**: Sec 4 The Cisco IOS Operating System (59m), Sec 14 Cisco Router and Switch Basics (55m)
- Lab: hostname, banners, console + enable + VTY passwords, SSH, save running-config to startup-config

**Week 3 — Ethernet LAN basics**
- Jeremy Day 8-10
- OCG Vol 1: Ch 5 *Analyzing Ethernet LAN Switching*
- **Udemy**: Sec 9 OSI Layer 2 - The Data-Link Layer (11m), Sec 10 OSI Layer 1 - The Physical Layer (13m), Sec 11 Cisco Device Functions (24m)
- Lab: 2-switch + 4-PC topology, observe MAC address table learning, examine frame paths

**Week 4 — IPv4 addressing + subnetting (deep dive)**
- Jeremy Day 11-13
- OCG Vol 1: Ch 11 *Perspectives on IPv4 Subnetting*, Ch 12 *Analyzing Classful IPv4 Networks*, Ch 13 *Analyzing Subnet Masks*, Ch 14 *Analyzing Existing Subnets*, Ch 15 *Subnet Design*
- **Udemy**: Sec 7 IP Address Classes (25m), Sec 8 Subnetting (16 lectures, 1h37m) — heavy week, this is the cornerstone
- Subnetting drill is now daily habit (started week 1) — this week, push to **20/day** while the topic is fresh
- Lab: assign IPs to a multi-subnet topology, verify connectivity

**Week 5 — Consolidation + Phase 1 review**
- Re-watch any Jeremy day where flashcards scored < 80%
- **Udemy**: Sec 12 The Life of a Packet (57m), Sec 13 The Cisco Troubleshooting Methodology (19m), Sec 15 Cisco Device Management (47m)
- Re-build week 3 lab from memory (no notes)
- OCG Vol 1 "Do I Know This Already?" quizzes for Ch 1-15
- **Milestone:** `/ccna-prep quiz domain 1 25` — target ≥ 70%

### Phase 2 — Switching (Weeks 6-9)

**Week 6 — VLANs**
- Jeremy Day 14-16
- OCG Vol 1: Ch 8 *Implementing Ethernet Virtual LANs* — VLAN access-port sections
- **Udemy**: Sec 21 VLANs - Virtual Local Area Networks (12 lectures, 1h33m) — first half (intro, access ports)
- Lab: 3 VLANs across two switches with access ports

**Week 7 — Trunking + VTP/DTP**
- Jeremy Day 17-19
- OCG Vol 1: Ch 8 (continued) — trunking, VTP, DTP sections
- **Udemy**: Sec 21 VLANs (continued) — trunk port, DTP, VTP lectures (second half of the section)
- Lab: 802.1Q trunk between switches, manually prune VLANs, disable DTP for security

**Week 8 — STP + RSTP (start)**
- Jeremy Day 20-22
- OCG Vol 1: Ch 9 *Spanning Tree Protocol Concepts*
- **Udemy**: Sec 25 STP - Spanning Tree Protocol (19 lectures, 3h20m) — first half (intro, terminology, how it works, versions, verification, root manipulation)
- Lab: observe root election, manipulate priority to force a chosen root
- *Common confusion area:* memorize STP port states + RSTP port roles cold

**Week 9 — STP advanced + EtherChannel + Phase 2 review**
- Jeremy Day 23
- OCG Vol 1: Ch 10 *RSTP and EtherChannel Configuration*
- **Udemy**: Sec 25 STP — second half (Portfast, BPDU Guard, Root Guard, Loop Guard, RPVST+ convergence) + Sec 26 EtherChannel (8 lectures, 53m)
- Lab: configure LACP EtherChannel, BPDU Guard, Root Guard
- Re-build the full Phase 2 topology (VLANs + trunks + STP + EtherChannel) from memory in < 30 min
- **Milestone:** `/ccna-prep quiz domain 1,2 30` — target ≥ 72%

### Phase 3 — Routing (Weeks 10-15)

**Week 10 — Routing fundamentals + static routes**
- Jeremy Day 24-26
- OCG Vol 1: Ch 16 *Operating Cisco Routers*, Ch 17 *Configuring IPv4 Addresses and Static Routes*, Ch 19 *IP Addressing on Hosts*
- **Udemy**: Sec 16 Routing Fundamentals (9 lectures, 1h4m), Sec 18 Connectivity Troubleshooting (3 lectures, 14m)
- Lab: static routes between 3 routers, default route, floating static for backup

**Week 11 — Inter-VLAN routing (RoaS + L3 switch SVI)**
- Jeremy Day 27-28
- OCG Vol 1: Ch 18 *IP Routing in the LAN*
- **Udemy**: Sec 22 Inter-VLAN Routing (6 lectures, 43m)
- Lab: router-on-a-stick first, then convert to L3 switch with SVIs — compare both

**Week 12 — Dynamic routing intro + OSPF part 1 (single area)**
- Jeremy Day 29-31
- OCG Vol 1: Ch 20 *Troubleshooting IPv4 Routing*, Ch 21 *Understanding OSPF Concepts*, Ch 22 *Implementing Basic OSPF Features*
- **Udemy**: Sec 17 Dynamic Routing Protocols (16 lectures, 2h22m) — first half (network redundancy, protocol types, metrics, ECMP, administrative distance) + Sec 19 IGP Interior Gateway Protocol Fundamentals (6 lectures, 49m) + Sec 20 OSPF (16 lectures, 2h28m) — first half (characteristics, basic config)
- Lab: OSPFv2 on 3 routers, single area, verify `show ip ospf neighbor`, `show ip route ospf`

**Week 13 — OSPF part 2 (DR/BDR, timers, areas, authentication)**
- Jeremy Day 32-34
- OCG Vol 1: Ch 23 *Implementing Optional OSPF Features*, Ch 24 *OSPF Neighbors and Route Selection*
- **Udemy**: Sec 17 Dynamic Routing Protocols — second half (loopbacks, adjacencies, passive interfaces, route precedence) + Sec 20 OSPF — second half (advanced topics, areas, cost metric, adjacencies, DR/BDR)
- Lab: manipulate router-id, force DR election, tune hello/dead timers, set passive interfaces
- *Heavily tested:* practice troubleshooting broken OSPF adjacencies (timer mismatch, area mismatch, network type mismatch)

**Week 14 — IPv6 fundamentals + IPv6 routing**
- Jeremy Day 35-37
- OCG Vol 1: Ch 25 *Fundamentals of IP Version 6*, Ch 26 *IPv6 Addressing and Subnetting*, Ch 27 *Implementing IPv6 Addressing on Routers*, Ch 28 *Implementing IPv6 Addressing on Hosts*, Ch 29 *Implementing IPv6 Routing*
- **Udemy**: Sec 30 IPv6 Addressing and Routing (12 lectures, 1h45m)
- Lab: dual-stack topology, SLAAC, OSPFv3
- *LPIC-202 leverage:* IPv6 addressing rules transfer directly — focus on Cisco config syntax

**Week 15 — Consolidation + Phase 3 review (mid-plan checkpoint)**
- Re-build a full Phase 3 lab from memory: 3 routers + 2 switches + VLANs + OSPF + dual-stack
- **Major milestone:** `/ccna-prep quiz mock 50` — target ≥ 70%
- Use `/ccna-prep cli-roleplay ospf-troubleshoot` (Claude pretends to be a broken router; you fix it via CLI)
- Identify weakest topic; spend 1 extra hour on it before continuing

### Phase 4 — Services + Security + Wireless (Weeks 16-21)

**Week 16 — DHCP, DNS, NTP**
- Jeremy Day 38-40
- OCG Vol 2: Ch 13 *Device Management Protocols* (covers NTP, syslog, CDP/LLDP). Note: OCG has no dedicated DHCP/DNS chapter — DHCP server config lives in Vol 1 Ch 19; lean on Jeremy / Udemy Sec 23 for DHCP basics this week.
- **Udemy**: Sec 23 DHCP - Dynamic Host Configuration Protocol (7 lectures, 32m) + Sec 34 Network Device Management (10 lectures, 1h4m) — NTP / syslog / CDP / LLDP lectures (defer SNMP/FTP/TFTP lectures to week 20)
- Lab: IOS DHCP server + `ip helper-address` relay, NTP client/server hierarchy
- *LPIC-202 leverage:* DHCP/DNS concepts identical — focus on IOS syntax

**Week 17 — NAT (static, dynamic, PAT) + QoS**
- Jeremy Day 41-43
- OCG Vol 2: Ch 14 *Network Address Translation*, Ch 15 *Quality of Service (QoS)*
- **Udemy**: Sec 29 NAT - Network Address Translation (10 lectures, 1h14m) + Sec 35 QoS Quality of Service (5 lectures, 59m)
- Lab: PAT for an internal LAN to a single public IP, static NAT for an inside server

**Week 18 — Security threat landscape + ACLs**
- Jeremy Day 44-46
- OCG Vol 2: Ch 5 *Introduction to TCP/IP Transport and Applications* (port-number context for ACLs), Ch 6 *Basic IPv4 Access Control Lists*, Ch 7 *Named and Extended IP ACLs*, Ch 8 *Applied IP ACLs*
- **Udemy**: Sec 28 ACLs - Access Control Lists (8 lectures, 1h9m) + Sec 32 The Security Threat Landscape (10 lectures, 2h1m) — first half (threats, common attacks, firewalls vs IDS/IPS, packet filters)
- Lab: standard ACL, extended ACL, named ACL — practice placement (extended close to source, standard close to destination)
- **Buy Cisco exam voucher this week** and schedule for ~2026-11-23 (week 30). Re-confirm CCNA 200-301 v1.1 is still the current blueprint before purchase.

**Week 19 — Cisco device security + AAA + WAN/VPN concepts**
- Jeremy Day 47-49
- OCG Vol 2: Ch 9 *Security Architectures*, Ch 10 *Securing Network Devices*, Ch 19 *WAN Architecture*
- **Udemy**: Sec 32 Security Threat Landscape — second half (cryptography, TLS, site-to-site + remote-access VPNs, threat defense) + Sec 31 WAN - Wide Area Networks (8 lectures, 1h) + Sec 33 Cisco Device Security (12 lectures, 1h27m)
- Lab: line-level security, SSH, AAA local-user setup
- VPN/IPsec is concept-only on CCNA — read, don't lab

**Week 20 — Layer 2 security + FHRP + Network Device Management**
- Jeremy Day 50
- OCG Vol 2: Ch 11 *Implementing Switch Port Security*, Ch 12 *DHCP Snooping and ARP Inspection*, Ch 16 *First Hop Redundancy Protocols*, Ch 17 *SNMP, FTP, and TFTP*
- **Udemy**: Sec 24 HSRP - Hot Standby Router Protocol (6 lectures, 38m) + Sec 27 Switch Security (9 lectures, 54m) + Sec 34 Network Device Management — SNMP / FTP / TFTP lectures (carry-over from week 16)
- Lab: port security with all 3 violation modes, DHCP snooping, DAI, HSRP between two routers

**Week 21 — Wireless + WLC**
- Jeremy Day 51-56
- OCG Vol 2: Ch 1 *Fundamentals of Wireless Networks*, Ch 2 *Analyzing Cisco Wireless Architectures*, Ch 3 *Securing Wireless Networks*, Ch 4 *Building a Wireless LAN*
- **Udemy**: Sec 37 Wireless Networking Fundamentals (10 lectures, 1h35m)
- Lab: Packet Tracer WLC GUI walkthrough, configure a WLAN with WPA2-PSK
- **Milestone:** `/ccna-prep quiz domain 4,5 30` — target ≥ 72%
- **Mid-plan mock exam:** take **Udemy practice test #3** (different from the two reserved for weeks 24 + 26) under timed conditions. Catches weak areas with 9 weeks left to remediate. Target ≥ 70%.

### Phase 5 — Automation + Heavy Review (Weeks 22-26)

**Week 22 — Cloud + Automation foundations**
- Jeremy Day 57-58
- OCG Vol 2: Ch 18 *LAN Architecture*, Ch 20 *Cloud Architecture*, Ch 23 *Understanding REST and JSON*
- **Udemy**: Sec 36 Cloud Computing (9 lectures, 1h28m) + Sec 38 Network Automation and Programmability (15 lectures, 2h50m) — first half (Python/Git/CI-CD, JSON/XML/YAML, REST/SOAP APIs, Postman lab)
- Lab: hit a REST API with curl or Postman, parse a JSON response
- *LPIC-202 leverage:* you've used YAML and JSON — focus on Cisco's specific automation tools

**Week 23 — Automation deep dive + AI/ML + SDN**
- Jeremy Day 59-60
- OCG Vol 2: Ch 21 *Introduction to Controller-Based Networking*, Ch 22 *Cisco Software-Defined Access (SD-Access)*, Ch 24 *Understanding Ansible and Terraform*
- **Udemy**: Sec 38 Network Automation and Programmability — second half (NETCONF/RESTCONF/gRPC, Ansible, SDN, Catalyst Center, SD-Access, SD-WAN, Meraki) + Sec 39 AI Artificial Intelligence and Machine Learning (5 lectures, 1h21m)
- Lab: small Ansible playbook against a Packet Tracer device (or read-along if too fiddly)
- Topics consolidated: controller-based vs traditional, SDN architecture, AIOps

**Week 24 — Full blueprint review + weak-area remediation**
- **Major milestone:** Udemy full-length practice test #1 (full blueprint, timed) — target ≥ 75%. (Mid-plan mock #3 was in week 21.)
- **Udemy**: Sec 40 BONUS! Recommended Practice Tests (7m) — short pointer lecture; the actual practice questions live in your separately-purchased Udemy "Pre-Exam Testing" course
- Re-watch Jeremy / Udemy videos for any topic < 80% on the practice test
- Re-do labs from memory: OSPF, VLAN+trunking+STP, ACLs, NAT
- Run `/ccna-prep quiz weak-areas` (Claude pulls from memory ledger of low-scoring topics — see Claude-assisted prep section)
- *(Optional)* Buy Boson ExSim-Max here if budget allows — take exam A

**Week 25 — Lab marathon + scenario practice**
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

**Week 26 — Final mock + exam-condition rehearsal**
- Udemy full practice test #2 under exam conditions (120 min, no pause, no notes) — target ≥ 80%
- *(Optional)* Boson ExSim exam B
- Review every wrong answer — write a one-line "why" for each (feed into `/ccna-prep flash add` so the missed concepts get spaced-repeated)

**Weeks 27-28 — Confidence consolidation (no new material)**
- Daily flashcards (`/ccna-prep flash review`)
- Re-do weakest-area quizzes from `/ccna-prep quiz weak-areas`
- Re-build capstone topology from memory once per week

**Week 29 — Light review**
- 30 min/day max: flashcards + 10 subnetting problems
- Skim OCG chapters tagged "review" in your notes
- No new labs

**Week 30 — Exam week (~2026-11-23)**
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
3. **Daily flashcards (10-15 min)** — `/ccna-prep flash review`. Imports the **Neil Anderson Udemy Anki deck** (downloaded from Sec 2 of the course) into your local ledger; appended with cards you add as you study, plus Jeremy's free Anki deck as supplement. Critical against a 6-month forgetting curve.
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
- Score ≥ 80% on the Udemy full-length practice test in week 24, ≥ 85% in week 26
- Can subnet any /prefix in < 30 seconds without paper (verified by `/ccna-prep subnet 20 --timed`)
- Can build, from scratch in Packet Tracer with no notes: a 3-router OSPF topology with VLANs, inter-VLAN routing, DHCP, NAT, and an ACL — in under 60 minutes
- Can complete `/ccna-prep cli-roleplay ospf-troubleshoot` and `/ccna-prep cli-roleplay vlan-build` end-to-end without referring to notes
- Can explain (out loud, to a rubber duck — or via `/ccna-prep tutor`) the difference between: trunk vs access port, RSTP port roles/states, OSPF neighbor states, standard vs extended ACL placement rules, controller-based vs traditional networking
- Weak-areas ledger is empty or shows only topics with current score ≥ 80%

## Notes / decisions

- **7-month pace** chosen to keep weekly load at ~7-8 h while running two video tracks (Jeremy + Udemy) in parallel. Tradeoff: higher forgetting risk, mitigated by monthly consolidation weeks + daily Claude flashcards + weekly weak-area quiz.
- **Two video tracks, Jeremy as spine.** Jeremy's IT Lab determines week-by-week topic order (matches blueprint flow). Neil Anderson's Udemy sections are mapped to each week as a second-pass reinforcement — different teacher, often clearer on Cisco-specific syntax. Udemy sections are self-contained, so watching them out of Udemy's native order is fine. Total Udemy content = ~42.5h (40 sections, 326 lectures). Sections 1-2 (Welcome + How to Use the Lab Exercises and Anki Flashcards, ~50m combined) are pure orientation — knock out in week 1. **Why Udemy over Coursera (decided 2026-04-29):** the Packt Coursera specialization doesn't bundle the per-topic lab exercises and Anki deck the Udemy course includes. Same blueprint coverage, more usable artifacts.
- **Udemy practice tests reserved for weeks 21 + 24 + 26** — used as full-length, exam-condition mock exams. Earlier-phase domain quizzes are generated by Claude (`/ccna-prep quiz domain N`), since the Udemy course doesn't filter cleanly by topic.
- **Boson ExSim** kept optional — your Udemy course covers practice testing; Boson is a polish-and-confidence add-on for week 24+ if you want extra signal before exam day.
- **Packet Tracer over GNS3/EVE-NG** — covers 100% of CCNA blueprint with zero IOS image licensing hassle. If you want to go further post-cert, switch to EVE-NG for CCNP prep.
- This plan assumes the current **CCNA 200-301 v1.1** blueprint. Confirm Cisco hasn't released a v1.2 before purchasing the exam voucher (week 18). Re-check at week 1 too.
- **Buy the exam voucher in week 18** and schedule the exam for ~2026-11-23 (week 30). Earlier purchase = ~12 weeks of "exam scheduled" pressure. Concrete date > vague target.
- **Plan source of truth:** this file is now the canonical copy at `~/x/dotfiles/.claude/skills/ccna-prep/ccna-prep.md` (the original at `~/ccna-prep.md` can be deleted or symlinked: `ln -sf ~/x/dotfiles/.claude/skills/ccna-prep/ccna-prep.md ~/ccna-prep.md`).
