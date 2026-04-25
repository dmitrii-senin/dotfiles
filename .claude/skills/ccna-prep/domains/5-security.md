# Domain 5: Security Fundamentals (15%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 5.1 Define key security concepts (threats, vulnerabilities, exploits, mitigation techniques)

**Exam focus:**
- **Threat** — potential danger
- **Vulnerability** — weakness that could be exploited
- **Exploit** — actual use of a vulnerability
- **Mitigation** — defense
- **Risk** = likelihood × impact

Common attacks:
- DoS / DDoS (volume-based, protocol-based, application-based)
- Spoofing (IP, MAC, ARP)
- Reconnaissance (port scans, OS fingerprinting)
- Man-in-the-middle (ARP poisoning, rogue DHCP)
- Brute force (passwords, keys)
- Phishing / social engineering
- Reflection / amplification (DNS, NTP)

---

## 5.2 Describe security program elements (user awareness, training, physical access control)

**Exam focus:**
- **User awareness** — annual training, simulated phishing
- **Training** — role-specific
- **Physical security** — locks, cameras, badges, biometrics; protect server rooms, console access

---

## 5.3 Configure and verify device access control using local passwords

**Console + enable + VTY passwords:**
```
enable secret cisco123                 # privileged EXEC password (hashed)
service password-encryption            # encrypt all type-7 passwords (weak, but obscures)

line console 0
 password consolepass
 login

line vty 0 15
 password vtypass
 login
 transport input ssh                   # SSH only

username admin secret cisco123         # local user (use with `login local`)
line vty 0 15
 login local
```

**Password types:**
- Type 0 — cleartext (DON'T)
- Type 5 — MD5 (legacy, weak)
- Type 7 — Cisco's reversible encryption (very weak)
- Type 8 — PBKDF2 with SHA-256 (good)
- Type 9 — Scrypt (best for IOS)

`enable secret` defaults to MD5 (Type 5). Use `enable algorithm-type scrypt secret cisco123` for Type 9.

---

## 5.4 Describe security password policies elements

**Exam focus:**
- **Complexity**: length (≥8-12), uppercase, lowercase, digits, symbols
- **Management**: regular rotation, no reuse, secure storage (vault)
- **Alternatives**: SSH keys, MFA, certificates

---

## 5.5 Describe IPsec remote access and site-to-site VPNs

**Exam focus (concept-level only — no configuration on CCNA):**
- IPsec provides confidentiality (encryption), integrity (HMAC), authentication, anti-replay.
- **Two modes**: Transport (encrypts payload, used host-to-host) vs Tunnel (encrypts entire packet, used network-to-network).
- **Two protocols**: AH (authentication only, no encryption) vs ESP (auth + encryption — almost always used).
- **IKE** (Internet Key Exchange): IKEv1 (legacy) and IKEv2 (modern). Negotiates SAs (Security Associations) using DH key exchange.
- **Site-to-site**: GRE-over-IPsec (Cisco common pattern), DMVPN, FlexVPN.
- **Remote access**: AnyConnect (SSL VPN over TCP 443).

---

## 5.6 Configure and verify access control lists

**Standard ACL** (filters by source IP only, range 1-99 or 1300-1999):
```
access-list 10 permit 192.168.1.0 0.0.0.255
access-list 10 deny any log
interface gi0/1
 ip access-group 10 out
```

**Extended ACL** (filters by source, dest, protocol, ports — range 100-199 or 2000-2699):
```
access-list 100 deny tcp 10.1.1.0 0.0.0.255 host 192.168.1.10 eq 80
access-list 100 deny icmp any any echo
access-list 100 permit ip any any
interface gi0/0
 ip access-group 100 in
```

**Named ACLs** (modern, can edit by sequence number):
```
ip access-list extended BLOCK-WEB
 10 deny tcp 10.1.1.0 0.0.0.255 any eq 80
 20 deny tcp 10.1.1.0 0.0.0.255 any eq 443
 30 permit ip any any
interface gi0/0
 ip access-group BLOCK-WEB in
```

**Placement rules:**
- **Standard ACL → close to destination** (matches only source, applied early would block too much).
- **Extended ACL → close to source** (saves bandwidth — drop unwanted traffic at the edge).

**Implicit deny**: every ACL ends with implicit `deny any`. Always permit something or you'll block all traffic.

**Wildcard masks**: inverse of subnet mask. /24 = `0.0.0.255`. /30 = `0.0.0.3`. /32 (single host) = `0.0.0.0` (or use `host x.x.x.x`).

**Verify:**
- `show access-lists`
- `show ip interface gi0/0` — shows applied ACLs
- `show ip access-lists BLOCK-WEB` — shows hit counters

---

## 5.7 Configure Layer 2 security features

**Topics:**
- DHCP snooping
- Dynamic ARP Inspection (DAI)
- Port security

### Port security

```
interface gi0/5
 switchport mode access
 switchport access vlan 10
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security violation shutdown
```

**Violation modes:**
- **Protect**: silently drop unauthorized frames; no log; no counter increment
- **Restrict**: drop + log (`%PORT_SECURITY-2-PSECURE_VIOLATION`) + counter increment + SNMP trap
- **Shutdown** (default): err-disable port; requires `shutdown` then `no shutdown` (or errdisable recovery) to restore

**Sticky MAC**: dynamically learned MACs are saved to running-config (must `wr` to persist).

**Verify:** `show port-security`, `show port-security interface gi0/5`, `show port-security address`.

### DHCP snooping

```
ip dhcp snooping
ip dhcp snooping vlan 10,20

interface gi0/24
 ip dhcp snooping trust              # uplink to legitimate DHCP server
```

Untrusted ports drop DHCP server responses (Offer, Ack) — prevents rogue DHCP servers. Trusted ports allow them.

`ip dhcp snooping limit rate 10` — rate-limit DHCP messages per port.

### Dynamic ARP Inspection (DAI)

```
ip arp inspection vlan 10
interface gi0/24
 ip arp inspection trust
```

Validates ARP packets against DHCP snooping binding table. Untrusted ports must have ARP source-MAC + IP matching the binding table. Prevents ARP poisoning.

---

## 5.8 Describe wireless security protocols (WPA, WPA2, WPA3)

**Exam focus:**
- **WEP** — broken since 2001, never use
- **WPA** — TKIP, transitional, weak
- **WPA2** — AES/CCMP, currently most widespread
  - WPA2-Personal (PSK)
  - WPA2-Enterprise (802.1X with RADIUS)
- **WPA3** — SAE (Simultaneous Authentication of Equals), forward secrecy, harder to brute-force
  - WPA3-Personal (replaces PSK with SAE)
  - WPA3-Enterprise (192-bit suite)

**802.1X**: per-user authentication via EAP (PEAP, EAP-TLS, EAP-FAST). Requires RADIUS server.

---

## 5.9 Configure WLAN using WPA2 PSK using the GUI

**Exam focus:**
- WLC GUI: Security tab → Layer 2 = WPA + WPA2 → enable WPA2 + AES → set PSK
- Map WLAN to VLAN/interface
- Enable WLAN status

---

## 5.10 Configure and verify AAA (server-based, RADIUS/TACACS+)

**Exam focus:**

**RADIUS** (UDP 1812 auth, 1813 acct):
- Combines auth + authz
- Encrypts password only
- Open standard
- Used for **network access** (802.1X, VPN)

**TACACS+** (TCP 49):
- Separates auth, authz, acct
- Encrypts entire payload
- Cisco proprietary
- Used for **device admin** (SSH/console login authorization per command)

**Configure:**
```
aaa new-model
radius server MY-RADIUS
 address ipv4 192.168.1.10 auth-port 1812 acct-port 1813
 key cisco123
aaa authentication login default group radius local      # try RADIUS, fall back to local
aaa authorization exec default group radius local
aaa accounting exec default start-stop group radius
```

Always include `local` fallback in case RADIUS server is unreachable.

---

## 5.11 Compare security program characteristics

(Covered in 5.1-5.4 above)

---

## Common exam traps

- **Standard ACL near destination, extended ACL near source** — backward = inefficient or breaks legitimate traffic.
- **Implicit deny at end** — every ACL ends with deny. Without explicit permit, all traffic is blocked.
- **Wildcard mask, not subnet mask** — `0.0.0.255` for /24. Confusing because it's inverted.
- **Port-security default = `shutdown`** mode — port goes err-disabled, needs admin recovery.
- **Sticky MACs must be saved with `wr`** to persist across reboot.
- **DHCP snooping trust** must be set on uplink to real DHCP server, otherwise legitimate DHCP responses get dropped.
- **DAI requires DHCP snooping enabled first** (it uses the binding table).
- **`enable secret` overrides `enable password`** — both can exist but secret wins.
- **`service password-encryption` only encrypts type-0 to type-7** — weak, easily reversed; use type-8/9 for new passwords.
- **VTY without `transport input`** allows both telnet and SSH by default → security risk.
- **RADIUS encrypts password only**, TACACS+ encrypts everything.
- **TACACS+ separates AAA**, RADIUS combines auth+authz.
- **WPA2-Personal uses PSK**, Enterprise uses 802.1X RADIUS.
- **AAA `login default` applies to all lines** unless overridden by a specific named list.
