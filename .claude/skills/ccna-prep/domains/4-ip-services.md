# Domain 4: IP Services (10%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 4.1 Configure and verify inside source NAT using static and pools

**Exam focus:**

**Static NAT (1:1 mapping):**
```
ip nat inside source static 10.1.1.5 200.1.1.5
interface gi0/0
 ip nat inside
interface gi0/1
 ip nat outside
```

**Dynamic NAT (pool, 1:1 from pool):**
```
access-list 1 permit 10.1.1.0 0.0.0.255
ip nat pool MY-POOL 200.1.1.10 200.1.1.20 netmask 255.255.255.0
ip nat inside source list 1 pool MY-POOL
```

**PAT (overload, many:1 with port mapping — most common):**
```
access-list 1 permit 10.1.1.0 0.0.0.255
ip nat inside source list 1 interface gi0/1 overload
```

**Verify:**
- `show ip nat translations`
- `show ip nat statistics`
- `clear ip nat translation *` (force re-translate)

**Inside vs outside:**
- Inside Local = private IP of host (10.1.1.5)
- Inside Global = translated public IP (200.1.1.5)
- Outside Global = public IP of internet host
- Outside Local = how outside is seen from inside (rarely used)

---

## 4.2 Configure and verify NTP operating in client/server mode

**Exam focus:**
- NTP uses UDP port 123.
- Stratum 0 = atomic clock; stratum 1 = directly attached; stratum 2 = synced from stratum 1; … up to 15. 16 = unsynchronized.

**Configure as client:**
```
ntp server 192.168.1.10
ntp server 192.168.1.11 prefer
```

**Configure as server (also acts as client):**
```
ntp master 3              # sets stratum to 3 if no upstream
clock timezone CET 1
clock summer-time CEST recurring
```

**Verify:**
- `show ntp status` — synced or not, stratum, ref ID
- `show ntp associations` — all configured peers, * = sys.peer, + = candidate, - = outlyer

**Authentication:**
```
ntp authenticate
ntp authentication-key 1 md5 cisco123
ntp trusted-key 1
ntp server 192.168.1.10 key 1
```

---

## 4.3 Explain the role of DHCP and DNS within the network

**DHCP exam focus:**
- DORA: Discover (broadcast, dst FF:FF:FF:FF:FF:FF, src 0.0.0.0), Offer (server unicast or broadcast), Request (client broadcasts the chosen offer), Ack.
- UDP 67 (server), 68 (client).
- DHCP relay agent: `ip helper-address 10.1.1.5` on the interface receiving client broadcasts.
- DHCP options: 1 subnet mask, 3 default gateway, 6 DNS, 15 domain name, 51 lease time, 66 TFTP server (used for IP phones), 150 (TFTP server list).

**Configure IOS DHCP server:**
```
ip dhcp excluded-address 10.1.1.1 10.1.1.10
ip dhcp pool LAN
 network 10.1.1.0 255.255.255.0
 default-router 10.1.1.1
 dns-server 8.8.8.8
 lease 7
```

**DNS exam focus:**
- IOS as client: `ip name-server 8.8.8.8`, `ip domain-lookup`, `ip domain-name lab.local`.
- Without `ip domain-lookup` (off by default on some), unknown commands like typos cause the router to attempt DNS resolution and hang. Best practice: `no ip domain-lookup` + `transport preferred none` on console.

---

## 4.4 Explain the function of SNMP in network operations

**Exam focus:**
- SNMP = Simple Network Management Protocol. Polling + trap.
- UDP 161 (manager → agent polls), UDP 162 (agent → manager traps/informs).
- Versions: v1 (cleartext community), v2c (cleartext community, supports informs), v3 (auth + encryption — recommended).
- Community strings: read-only (RO) and read-write (RW).
- MIB = OID hierarchy.

**Configure SNMPv2c:**
```
snmp-server community PUBLIC RO
snmp-server community PRIVATE RW
snmp-server host 192.168.1.10 version 2c PUBLIC
snmp-server enable traps
```

**Configure SNMPv3 (recommended):**
```
snmp-server group MYGROUP v3 priv
snmp-server user MYUSER MYGROUP v3 auth sha cisco123 priv aes 128 cisco123
```

---

## 4.5 Describe the use of syslog features including facilities and severities

**Exam focus:**

Severity levels (memorize — order matters):
| # | Name | Mnemonic |
|---|---|---|
| 0 | Emergency | Every |
| 1 | Alert | Awesome |
| 2 | Critical | Cisco |
| 3 | Error | Engineer |
| 4 | Warning | Will |
| 5 | Notification | Need |
| 6 | Informational | Icecream |
| 7 | Debugging | Daily |

Lower number = more severe. Setting severity N logs that level AND ALL ABOVE (lower numbers).

**Configure:**
```
logging host 192.168.1.10
logging trap 4               # send severity 0-4 to syslog server
logging buffered 8192 6      # local buffer, severity 6
logging console 5            # console messages, severity 0-5
logging monitor 6            # SSH/telnet sessions, severity 0-6
service timestamps log datetime msec
```

**Format:**
```
*Mar  1 00:00:35.123: %SYS-5-CONFIG_I: Configured from console by console
                                  ^      ^                                
                                  facility-severity-mnemonic
```

---

## 4.6 Configure and verify DHCP client and relay

**Configure interface as DHCP client:**
```
interface gi0/0
 ip address dhcp
```

**Configure relay (separate router from server):**
```
interface gi0/0
 ip helper-address 192.168.10.5
```

`ip helper-address` forwards broadcast UDP 67 (DHCP) AND seven other UDP services (DNS, TFTP, NTP, NetBIOS NS/DS, TACACS, time). Use `no ip forward-protocol udp <port>` to disable forwarding for unwanted services.

---

## 4.7 Explain the forwarding per-hop behavior (PHB) for QoS

**Topics:**
- Classification
- Marking
- Queuing
- Congestion management
- Policing
- Shaping

**Exam focus:**
- **Classification**: identify traffic (NBAR, ACL, DSCP marking).
- **Marking**: tag packets with DSCP (Layer 3, 6 bits in IP ToS) or CoS (Layer 2, 3 bits in 802.1Q).
- DSCP values: EF (46) for voice, AF31/AF41 (signaling/video), CS6 (network control). Default = 0.
- **Queuing**: PQ, WFQ, CBWFQ, LLQ (low-latency queuing — strict priority for voice).
- **Policing**: drops or re-marks excess traffic (immediate).
- **Shaping**: buffers excess traffic and sends later (smooths bursts).
- **Congestion management** (during congestion): tail drop (default), WRED (weighted random early detect, drops lower-priority first).
- **Trust boundary**: trust QoS markings only from trusted devices (IP phones), strip from end-hosts.

---

## 4.8 Configure network devices for remote access using SSH

**Exam focus:**

**SSH setup (5 commands):**
```
hostname R1                               # required for crypto key
ip domain-name lab.local                  # required for crypto key
crypto key generate rsa modulus 2048      # generates host key
username admin secret cisco123            # local user (or use AAA)
line vty 0 15
 transport input ssh                      # disable telnet
 login local                              # use local username/password
```

Optional: `ip ssh version 2`, `ip ssh time-out 60`, `ip ssh authentication-retries 3`.

**Verify:** `show ip ssh`, `show ssh`.

---

## 4.9 Describe the capabilities and function of TFTP/FTP in the network

**Exam focus:**
- **TFTP**: UDP 69, no authentication, used for IOS image and config transfer.
  - `copy running-config tftp:` — prompts for TFTP server IP and filename.
  - `copy tftp: flash:` — download IOS image.
- **FTP**: TCP 20 (data, active mode), TCP 21 (control). Authenticated.
- **SCP** (over SSH): authenticated, encrypted. Best practice for file transfer.

---

## Common exam traps

- **`ip helper-address` forwards 8 UDP services by default**, not just DHCP.
- **DHCP DORA — Discover and Request are broadcast**; Offer and Ack can be unicast or broadcast (depends on `broadcast` flag in client request).
- **NAT exhausts when too many flows hit PAT** — use multiple outside IPs in pool with overload.
- **NTP stratum 16 = not synchronized**.
- **Syslog severity is "AND BELOW" by number** — `logging trap 4` sends 0-4, not just 4.
- **SNMPv3 priv = encryption + auth**; `auth` alone = auth only; `noauth` = neither (weakest).
- **TFTP is UDP, FTP is TCP** — common confusion.
- **`ip domain-lookup` enabled by default** — typing a misspelled command in EXEC tries to resolve it as hostname (annoying delay). Disable with `no ip domain-lookup`.
- **SSH requires an RSA key** — won't work without `crypto key generate rsa`. Hostname + domain-name must be set first.
- **Login local vs login**: `login` (no `local`) uses the line password (`password cisco`); `login local` uses `username … secret …`.
- **SNMP RO/RW community** sent in cleartext on v1/v2c — never use over untrusted networks.
