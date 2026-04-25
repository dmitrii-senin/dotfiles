# Domain 2: Network Access (20%)

Official blueprint: https://learningnetwork.cisco.com/s/ccna-exam-topics

---

## 2.1 Configure and verify VLANs (normal range) spanning multiple switches

**Topics:**
- Access ports (data and voice)
- Default VLAN
- InterVLAN connectivity

**Exam focus:**
- Normal range: VLAN 1-1005. Extended: 1006-4094 (requires VTP transparent or v3).
- Default VLAN: 1 (cannot be deleted; should not be used for production traffic).
- Reserved: 1002-1005 (FDDI/token-ring legacy).
- Configure: `vlan 10`, `name SALES`, `interface gi0/1`, `switchport mode access`, `switchport access vlan 10`.
- Voice VLAN: `switchport voice vlan 100` (one access + one voice per port).
- Verify: `show vlan brief`, `show interfaces switchport`.

---

## 2.2 Configure and verify interswitch connectivity

**Topics:**
- Trunk ports
- 802.1Q
- Native VLAN

**Exam focus:**
- 802.1Q tagging: 4-byte tag inserted in Ethernet header (TPID 0x8100, PCP 3 bits, DEI 1 bit, VLAN ID 12 bits).
- Native VLAN traffic = untagged; both ends must agree.
- ISL is legacy, no longer in CCNA.
- Configure trunk: `switchport trunk encapsulation dot1q` (only on switches that support ISL too), `switchport mode trunk`, `switchport trunk allowed vlan 10,20,30`, `switchport trunk native vlan 99`.
- DTP (Dynamic Trunking Protocol) — `switchport mode dynamic auto` (passive) vs `dynamic desirable` (active). Best practice: hardcode `mode trunk` or `mode access` and disable DTP with `switchport nonegotiate`.
- Verify: `show interfaces trunk`, `show interfaces switchport`.

**Trunk-mode matrix:**
| Side A \ Side B | Access | Trunk | Dyn Auto | Dyn Desirable |
|---|---|---|---|---|
| Access | Access | Mismatch | Access | Access |
| Trunk | Mismatch | Trunk | Trunk | Trunk |
| Dyn Auto | Access | Trunk | **Access** | Trunk |
| Dyn Desirable | Access | Trunk | Trunk | Trunk |

**Two `dynamic auto` ports = no trunk.**

---

## 2.3 Configure and verify Layer 2 discovery protocols (CDP and LLDP)

**Exam focus:**
- CDP: Cisco proprietary, on by default, 60-second hello, 180-second holdtime.
- `show cdp neighbors`, `show cdp neighbors detail` (shows IP, IOS version, platform).
- Disable globally: `no cdp run`. Per-interface: `no cdp enable`.
- LLDP: IEEE 802.1AB, vendor-neutral, off by default. Enable: `lldp run`. Same outputs: `show lldp neighbors`.

---

## 2.4 Configure and verify (Layer 2/Layer 3) EtherChannel

**Topics:**
- LACP
- PAgP

**Exam focus:**
- EtherChannel = bundle 2-8 physical links into one logical link for bandwidth + redundancy.
- All links in a bundle must have **identical config**: speed, duplex, mode (access/trunk), allowed VLANs, native VLAN.
- Negotiation:
  - **LACP** (802.3ad, standard): `active` (initiates) or `passive` (responds). Two passive = no EC.
  - **PAgP** (Cisco): `desirable` (initiates) or `auto` (responds). Two auto = no EC.
  - **`on` mode** = static, no negotiation. Both ends must be `on`.
- Layer 2 EC: `interface range gi0/1-2`, `channel-group 1 mode active`. Creates `Port-channel 1`.
- Layer 3 EC: configure on a routed interface (`no switchport`) and assign IP to the Port-channel interface, not member ports.
- Verify: `show etherchannel summary`, `show etherchannel port-channel`.

---

## 2.5 Interpret basic operations of Rapid PVST+ Spanning Tree Protocol

**Topics:**
- Root port, root bridge, BID
- Port states (forwarding, blocking)
- PortFast benefits

**Exam focus:**
- BPDU: Root Bridge ID, Root Path Cost, Sender Bridge ID, Port ID. Sent every 2 sec by default.
- **Bridge ID = Priority (4 bits, default 32768) + sys-id-ext (12 bits = VLAN ID) + MAC.**
- Root election: lowest BID wins. Manipulate with `spanning-tree vlan 10 priority 4096`.
- Port roles: **Root** (best path to root, on non-root switches), **Designated** (best port on each segment toward root), **Alternate/Backup** (RSTP only, replaces Blocking).
- Port states (RSTP): **Discarding** (= legacy Blocking + Listening), **Learning**, **Forwarding**.
- Path cost (revised IEEE): 10 Mb=100, 100 Mb=19, 1 Gb=4, 10 Gb=2.
- **PortFast**: skip Listening/Learning, go straight to Forwarding. Use only on edge ports (PCs). Pair with BPDU Guard (`spanning-tree bpduguard enable`) to err-disable port if BPDU received.
- **Rapid PVST+**: Cisco's per-VLAN RSTP. One STP instance per VLAN.
- Verify: `show spanning-tree`, `show spanning-tree vlan 10`, `show spanning-tree summary`.

**RSTP convergence: <1s typical; 802.1D legacy: ~50s.**

---

## 2.6 Describe Cisco Wireless Architectures and AP modes

**Topics:**
- Autonomous APs
- Cloud-based APs
- Split MAC architecture (lightweight APs + WLC, CAPWAP tunnel)
- Embedded controller / Mobility Express

**Exam focus:**
- **Autonomous AP**: standalone, runs full 802.11. Configured per-AP. Doesn't scale.
- **Lightweight AP (LAP) + WLC**:
  - LAP joins WLC via **CAPWAP** (Control And Provisioning of Wireless Access Points). Two tunnels: control (UDP 5246), data (UDP 5247).
  - Split MAC: real-time 802.11 (ACKs, beacons) at AP; management (auth, association, radio mgmt) at WLC.
  - LAP boots, gets IP via DHCP, discovers WLC (DHCP option 43, DNS, broadcast), joins.
- **Cloud-managed**: Meraki — controller in cloud.
- **Embedded WLC**: small deployment, WLC in switch hardware.

---

## 2.7 Describe physical infrastructure connections of WLAN components

**Exam focus:**
- AP → switch via Ethernet (PoE typically)
- WLC → switch via trunk port (carries multiple VLANs for SSIDs)
- Wireless clients → AP wirelessly → tunneled via CAPWAP to WLC → out WLC to wired network

---

## 2.8 Describe AP and WLC management access connections

**Exam focus:**
- WLC management interfaces: console, SSH, HTTPS GUI, SNMP, RADIUS, TACACS+
- AP management: via WLC (no direct config on LAPs)

---

## 2.9 Configure components of a wireless LAN access for client connectivity (GUI only)

**Topics:**
- WLAN creation
- Security settings (WPA2-PSK, 802.1X)
- QoS profiles
- Advanced WLAN settings

**Exam focus:**
- WLAN config (on WLC GUI):
  - SSID name, profile name
  - Map to interface/VLAN
  - Security: WPA2 Personal (PSK) or Enterprise (802.1X RADIUS)
  - QoS: Platinum (voice), Gold (video), Silver (best-effort), Bronze (background)
  - Enable/disable broadcast SSID
- WPA2-PSK: shared password, suitable for SOHO
- WPA2-Enterprise: 802.1X EAP authentication via RADIUS server, per-user creds

---

## Common exam traps

- **Two `dynamic auto` ports never form a trunk** — both are passive
- **Native VLAN mismatch** doesn't break the link but generates `%CDP-4-NATIVE_VLAN_MISMATCH` and untagged traffic ends up in wrong VLAN
- **EtherChannel mismatch**: any inconsistent setting (speed, duplex, allowed VLAN list) prevents bundle. `show etherchannel summary` shows individual port flags (P=bundled, I=independent, s=suspended)
- **STP root election tie**: equal priority → lowest MAC wins
- **Default native VLAN = 1** — security best practice is to change it to an unused VLAN AND tag it (`vlan dot1q tag native`)
- **PortFast on a trunk** = bad. PortFast = edge ports (single-host) only; if a switch is plugged in, you can cause loops
- **BPDU Guard vs BPDU Filter**: Guard err-disables the port if BPDU received; Filter just drops BPDUs (dangerous, can mask loops)
- **CAPWAP control = UDP 5246, data = UDP 5247** — common port memorization question
- **WPA2 = AES/CCMP** (TKIP is WPA1 era; deprecated)
- **VLAN 1 cannot be deleted** but should not be used for management or user traffic
