# Domain 3: IP Connectivity (25%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 3.1 Interpret the components of routing table

**Topics:**
- Routing protocol code
- Prefix
- Network mask
- Next hop
- Administrative distance
- Metric
- Gateway of last resort

**Exam focus:**
- `show ip route` codes: C (connected, AD 0), L (local /32), S (static, AD 1), O (OSPF, AD 110), R (RIP, AD 120), D (EIGRP, AD 90), B (BGP — internal AD 200, external 20).
- Format: `O 10.0.0.0/24 [110/2] via 192.168.1.2, 00:01:30, GigabitEthernet0/0` → `[AD/metric]`.
- Gateway of last resort = candidate default route (`S* 0.0.0.0/0`).

**Administrative Distance defaults (memorize):**
| Source | AD |
|---|---|
| Connected | 0 |
| Static | 1 |
| EIGRP summary | 5 |
| eBGP | 20 |
| EIGRP internal | 90 |
| OSPF | 110 |
| IS-IS | 115 |
| RIP | 120 |
| EIGRP external | 170 |
| iBGP | 200 |
| Unknown / unreachable | 255 |

---

## 3.2 Determine how a router makes a forwarding decision by default

**Topics:**
- Longest match
- Administrative distance
- Routing protocol metric

**Exam focus:**
- **Longest prefix match wins first** (most specific route).
- If multiple routes to the same prefix from different protocols → lowest AD wins.
- If multiple routes to same prefix from same protocol → lowest metric wins.
- Equal-cost multipath load balancing if metrics tie (e.g., OSPF up to 4 paths by default).

---

## 3.3 Configure and verify IPv4 and IPv6 static routing

**Topics:**
- Default route
- Network route
- Host route
- Floating static

**Exam focus:**

**IPv4 static:**
```
ip route 10.0.0.0 255.255.255.0 192.168.1.2          # next-hop IP
ip route 10.0.0.0 255.255.255.0 GigabitEthernet0/0   # exit interface
ip route 10.0.0.0 255.255.255.0 GigabitEthernet0/0 192.168.1.2  # both (best practice on multipoint)
ip route 0.0.0.0 0.0.0.0 192.168.1.254               # default route
ip route 10.0.0.5 255.255.255.255 192.168.1.2        # host route /32
ip route 10.0.0.0 255.255.255.0 192.168.1.2 200      # floating static (AD 200 — backup to OSPF)
```

**IPv6 static:**
```
ipv6 route 2001:db8::/64 2001:db8:1::2
ipv6 route ::/0 2001:db8:1::1                        # default
```

Floating static AD must be > the routing protocol's AD so it stays inactive until the protocol drops the route.

---

## 3.4 Configure and verify single area OSPFv2

**Topics:**
- Neighbor adjacencies
- Point-to-point
- Broadcast (DR/BDR selection)
- Router ID

**Exam focus:**

**Basic OSPF config:**
```
router ospf 1
 router-id 1.1.1.1
 network 192.168.1.0 0.0.0.255 area 0
 passive-interface GigabitEthernet0/2
```

**Router ID selection (in order):**
1. Manually configured `router-id`
2. Highest IPv4 address on a `loopback` interface (UP)
3. Highest IPv4 address on any active interface

To change: configure `router-id`, then `clear ip ospf process` (asks for confirmation).

**Network types:**
- Broadcast (default on Ethernet) — DR/BDR election, hello 10s, dead 40s
- Point-to-point (e.g., serial, or `ip ospf network point-to-point` on Ethernet) — no DR/BDR, hello 10s, dead 40s
- Non-broadcast (frame-relay legacy) — hello 30s, dead 120s
- Point-to-multipoint

**Neighbor states:** DOWN → ATTEMPT → INIT → 2WAY → EXSTART → EXCHANGE → LOADING → FULL.

**DR/BDR:**
- Election based on highest OSPF priority (default 1, 0 = never DR), then highest router ID.
- Non-DR/BDR routers form FULL only with DR and BDR (2WAY with each other on broadcast segments).
- `ip ospf priority 0` on an interface keeps that router out of DR/BDR election.

**Verify:**
```
show ip ospf neighbor
show ip ospf interface
show ip ospf interface brief
show ip protocols
show ip route ospf
```

**Tune timers (must match between neighbors):**
```
interface gi0/0
 ip ospf hello-interval 5
 ip ospf dead-interval 20
```

**Authentication (MD5):**
```
interface gi0/0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 cisco123
```

---

## 3.5 Describe the purpose, functions, and concepts of first hop redundancy protocol

**Topics:**
- HSRP, VRRP, GLBP

**Exam focus:**
- Provide a single virtual gateway IP for hosts; routers fail over.
- **HSRP** (Cisco): active/standby, virtual MAC `0000.0c07.acXX`, hello 3s, hold 10s, priority default 100.
  - Configure: `standby 1 ip 192.168.1.254`, `standby 1 priority 110`, `standby 1 preempt`.
- **VRRP** (RFC 5798): master/backup, virtual MAC `0000.5e00.01XX`, hello 1s, master-down 3s, priority default 100.
- **GLBP** (Cisco): load balances across multiple AVFs (Active Virtual Forwarders), one AVG (Active Virtual Gateway).

---

## Common exam traps

- **MTU mismatch** keeps OSPF stuck in EXSTART/EXCHANGE — fix with matching MTU or `ip ospf mtu-ignore`.
- **Hello/Dead timer mismatch** prevents adjacency at all (stays in INIT or DOWN). `show ip ospf interface` reveals timers.
- **Area mismatch** (one router area 0, other area 1 on same link) → no adjacency.
- **Network type mismatch** (broadcast vs point-to-point on same link) → adjacency may form but with weird DR behavior, or fail.
- **Authentication mismatch** → `%OSPF-4-ERRRCV: Received invalid packet: mismatch authentication type` log.
- **Wildcard mask on `network` statement is the OPPOSITE of subnet mask**: /24 = `0.0.0.255`. Beware: `network 192.168.1.0 0.0.0.255 area 0` matches all interfaces in 192.168.1.0/24.
- **Passive interface** stops sending hellos but the network is still advertised in OSPF. Use on interfaces facing only end-hosts.
- **DR/BDR elections are NOT preemptive by default** — first router up wins. Even if a higher-priority router comes online later, no re-election unless `clear ip ospf process` or DR fails.
- **Router ID changes require `clear ip ospf process`** to take effect.
- **Floating static** must have AD > the dynamic protocol's AD it's backing up. Backing up OSPF (AD 110) → use 111 or higher.
- **On a multi-access broadcast network**, only DR↔non-DR and BDR↔non-DR form FULL adjacencies; non-DR↔non-DR stays in 2WAY (this is correct, not broken).
