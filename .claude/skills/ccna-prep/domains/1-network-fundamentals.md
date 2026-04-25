# Domain 1: Network Fundamentals (20%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 1.1 Explain the role and function of network components

**Topics:**
- Routers (L3, route between subnets, RIB/FIB, AD)
- L2 and L3 switches (L2 = MAC table, L3 = SVIs + routing)
- Next-generation firewalls and IPS
- Access points (autonomous vs lightweight)
- Controllers (Cisco DNA Center, WLC)
- Endpoints
- Servers
- PoE

**Exam focus:**
- Differences between hub, switch, router (collision domain, broadcast domain)
- Access point modes; lightweight APs depend on a WLC for control plane
- Cisco DNA Center vs traditional management
- PoE standards: 802.3af (15.4W), 802.3at (30W), 802.3bt (60-90W)

---

## 1.2 Describe characteristics of network topology architectures

**Topics:**
- 2-tier (collapsed core)
- 3-tier (access, distribution, core)
- Spine-leaf
- WAN
- SOHO
- On-prem and cloud

**Exam focus:**
- When to collapse core into distribution (small networks)
- Spine-leaf used in modern data centers; non-blocking East-West
- Cloud connectivity options (direct connect, IPsec VPN over internet)

---

## 1.3 Compare physical interface and cabling types

**Topics:**
- Single-mode fiber, multi-mode fiber, copper
- Connections (Ethernet shared media and point-to-point)
- Concepts of PoE

**Exam focus:**
- SMF for long distance (>2km), MMF for short (~550m)
- Cat5e/Cat6/Cat6a max distance = 100m
- Auto-MDIX (no need for crossover cables on modern gear)
- Straight-through vs crossover use cases (legacy)

---

## 1.4 Identify interface and cable issues

**Topics:**
- Collisions
- Errors
- Mismatch duplex
- Speed

**Exam focus:**
- Duplex mismatch symptom: late collisions on full-duplex side, FCS errors, runts
- `show interfaces` counters: input errors, runts, giants, CRC, frame, overrun, ignored
- Always set both ends to same speed/duplex (or both to auto)

---

## 1.5 Compare TCP to UDP

**Exam focus:**
- TCP: connection-oriented, three-way handshake (SYN, SYN-ACK, ACK), reliable, ordered, flow control (windows), congestion control
- UDP: connectionless, no handshake, no reliability, low overhead
- Common ports — TCP: 20/21 FTP, 22 SSH, 23 Telnet, 25 SMTP, 53 DNS, 80 HTTP, 110 POP3, 143 IMAP, 443 HTTPS. UDP: 53 DNS, 67/68 DHCP, 69 TFTP, 123 NTP, 161/162 SNMP, 514 Syslog

---

## 1.6 Configure and verify IPv4 addressing and subnetting

**Exam focus:**
- Classful: A (0-127, /8), B (128-191, /16), C (192-223, /24), D multicast (224-239), E reserved (240-255)
- Private RFC1918: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
- Subnetting: block size = 256 - mask octet; network at multiples of block size; broadcast = network + block - 1
- VLSM
- CIDR summarization

---

## 1.7 Describe the need for private IPv4 addressing

**Exam focus:**
- IPv4 exhaustion drove RFC1918
- NAT translates private to public for internet access
- APIPA (169.254.0.0/16) when DHCP fails

---

## 1.8 Configure and verify IPv6 addressing and prefix

**Exam focus:**
- Address types: Global Unicast (2000::/3), Link-Local (FE80::/10), Unique-Local (FC00::/7), Multicast (FF00::/8), Anycast
- Loopback: ::1/128
- Unspecified: ::/128
- All-routers multicast: FF02::2
- All-nodes multicast: FF02::1
- Solicited-node: FF02::1:FFXX:XXXX (last 24 bits of unicast)
- EUI-64: insert FFFE in middle of MAC, flip 7th bit
- SLAAC vs DHCPv6 (stateless, stateful)
- ICMPv6 Neighbor Discovery (NS, NA, RS, RA) replaces ARP

---

## 1.9 Compare IPv6 address types

| Type | Prefix |
|---|---|
| Global Unicast | 2000::/3 |
| Unique Local | FC00::/7 |
| Link-Local | FE80::/10 |
| Multicast | FF00::/8 |
| Loopback | ::1/128 |
| Unspecified | ::/128 |

---

## 1.10 Verify IP parameters for Client OS

**Exam focus:**
- Windows: `ipconfig /all`, `ipconfig /release`, `ipconfig /renew`, `ipconfig /flushdns`
- Linux/macOS: `ip addr`, `ip route`, `ifconfig` (legacy)
- DNS resolution: `nslookup`, `dig`
- Default gateway, subnet mask, DNS servers

---

## 1.11 Describe wireless principles

**Exam focus:**
- 2.4 GHz: channels 1, 6, 11 (non-overlapping in NA); 11 channels total
- 5 GHz: many non-overlapping 20MHz channels; better throughput, shorter range
- 6 GHz: Wi-Fi 6E
- SSID, BSSID (AP MAC), ESS (multiple APs same SSID)
- Security: WEP (insecure), WPA (TKIP), WPA2 (AES/CCMP), WPA3 (SAE)
- 802.11 standards: a/b/g/n/ac/ax (Wi-Fi 6) — speeds and bands

---

## 1.12 Explain virtualization fundamentals

**Exam focus:**
- Hypervisors: Type 1 (bare-metal: ESXi, Hyper-V, KVM) vs Type 2 (hosted: VirtualBox, VMware Workstation)
- VMs vs containers (Docker shares OS kernel, lighter)
- vSwitch concept

---

## 1.13 Describe switching concepts

**Exam focus:**
- MAC learning: source MAC + ingress port → MAC table entry
- Frame forwarding: known unicast → out the matching port; unknown unicast / broadcast / multicast → flood out all ports in same VLAN
- Frame switching methods: store-and-forward (default, checks FCS), cut-through (faster, no FCS check)
- MAC aging timer (default 300s)
- Collision domain: per-port on a switch (each switch port = 1 collision domain)
- Broadcast domain: per-VLAN

---

## Common exam traps

- **APIPA address** indicates DHCP failure — check DHCP server reachability
- **Duplex mismatch** is silent at link level (link comes up) but kills throughput; look for late collisions on the full-duplex side
- **Auto-MDIX** means crossover cables are usually optional now, but historically required between same-type devices (router-router, switch-switch, host-host)
- **Solicited-node multicast** is computed from unicast, not configured
- **Wi-Fi 2.4 GHz channel overlap** — only 1, 6, 11 are non-overlapping in 20 MHz spacing
- **TCP/UDP port numbers** — DHCP uses both 67 (server) and 68 (client) on UDP. DNS is 53 on both TCP and UDP (TCP for zone transfers and large responses)
