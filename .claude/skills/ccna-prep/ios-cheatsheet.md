# IOS Behavior Cheatsheet (for `cli-roleplay` mode)

Reference for impersonating a Cisco IOS router/switch realistically. Read before any `cli-roleplay` session and during one whenever output format is uncertain.

---

## Prompt strings (track current mode)

| Mode | Prompt |
|---|---|
| User EXEC | `Router>` / `Switch>` |
| Privileged EXEC | `Router#` / `Switch#` |
| Global config | `Router(config)#` |
| Interface config | `Router(config-if)#` |
| Sub-interface | `Router(config-subif)#` |
| Routing protocol | `Router(config-router)#` |
| Line config | `Router(config-line)#` |
| VLAN config | `Switch(config-vlan)#` |
| Standard ACL | `Router(config-std-nacl)#` |
| Extended ACL | `Router(config-ext-nacl)#` |
| Class-map | `Router(config-cmap)#` |
| Policy-map | `Router(config-pmap)#` |
| ROMmon | `rommon 1 >` |

Update prompt after every mode-changing command. The hostname before the prompt char reflects the configured hostname (default `Router` / `Switch`).

---

## Mode transition commands

- `enable` (or `en`) — User EXEC → Privileged EXEC. Prompts for enable password if set.
- `disable` — Privileged → User.
- `configure terminal` (or `conf t`) — Privileged → Global config. Prints `Enter configuration commands, one per line. End with CNTL/Z.`
- `interface gi0/1` — Global → Interface config.
- `router ospf 1` — Global → Router config.
- `line vty 0 15` — Global → Line config.
- `exit` — back one level.
- `end` (or `^Z`) — back to Privileged EXEC from any config sub-mode.

---

## Common error messages

```
% Invalid input detected at '^' marker.
```
Mark the `^` under the first invalid character of the input.

```
% Incomplete command.
```

```
% Ambiguous command:  "sh"
```

```
% Unknown command or computer name, or unable to find computer address
```
(in User EXEC when input doesn't match a command and isn't a hostname for telnet)

```
% Permission denied.
```

```
Password:
```
(prompts on `enable`, `telnet`, `ssh`, console login, vty login)

```
% Login invalid
```
(after wrong password)

---

## `show ip interface brief` — typical output

```
Interface              IP-Address      OK? Method Status                Protocol
GigabitEthernet0/0     192.168.1.1     YES manual up                    up
GigabitEthernet0/1     unassigned      YES NVRAM  administratively down down
GigabitEthernet0/2     10.0.0.1        YES manual up                    down
Vlan1                  unassigned      YES NVRAM  administratively down down
```

Status column values: `up`, `down`, `administratively down`. Protocol: `up`, `down`. Method: `manual`, `NVRAM`, `DHCP`, `unset`.

---

## `show ip route` — typical output

```
Codes: L - local, C - connected, S - static, R - RIP, M - mobile, B - BGP
       D - EIGRP, EX - EIGRP external, O - OSPF, IA - OSPF inter area
       N1 - OSPF NSSA external type 1, N2 - OSPF NSSA external type 2
       E1 - OSPF external type 1, E2 - OSPF external type 2
       i - IS-IS, su - IS-IS summary, L1 - IS-IS level-1, L2 - IS-IS level-2
       ia - IS-IS inter area, * - candidate default, U - per-user static route
       o - ODR, P - periodic downloaded static route

Gateway of last resort is not set

     192.168.1.0/24 is variably subnetted, 2 subnets, 2 masks
C       192.168.1.0/24 is directly connected, GigabitEthernet0/0
L       192.168.1.1/32 is directly connected, GigabitEthernet0/0
O    10.0.0.0/24 [110/2] via 192.168.1.2, 00:01:30, GigabitEthernet0/0
S*   0.0.0.0/0 [1/0] via 192.168.1.254
```

`[AD/metric]` format. AD: connected=0, static=1, EIGRP=90, OSPF=110, RIP=120.

---

## `show ip ospf neighbor` — typical output

```
Neighbor ID     Pri   State           Dead Time   Address         Interface
2.2.2.2           1   FULL/DR         00:00:35    192.168.1.2     GigabitEthernet0/0
3.3.3.3           1   FULL/BDR        00:00:38    192.168.1.3     GigabitEthernet0/0
```

Neighbor states (in order): DOWN → ATTEMPT → INIT → 2WAY → EXSTART → EXCHANGE → LOADING → FULL.

If stuck in:
- INIT — hellos one-way (check ACL, mismatched subnet)
- 2WAY — normal if neither is DR/BDR on multi-access; only build FULL with DR/BDR
- EXSTART/EXCHANGE — MTU mismatch is the classic cause
- LOADING — LSU/LSAck issues, rare

---

## `show vlan brief` — typical output

```
VLAN Name                             Status    Ports
---- -------------------------------- --------- -------------------------------
1    default                          active    Gi0/1, Gi0/2, Gi0/3, Gi0/4
10   SALES                            active    Gi0/5, Gi0/6
20   ENG                              active    Gi0/7, Gi0/8
99   MGMT                             active
1002 fddi-default                     act/unsup
1003 token-ring-default               act/unsup
1004 fddinet-default                  act/unsup
1005 trnet-default                    act/unsup
```

Trunk ports do NOT appear in this output. Use `show interfaces trunk` for those.

---

## `show interfaces trunk` — typical output

```
Port        Mode             Encapsulation  Status        Native vlan
Gi0/24      on               802.1q         trunking      1

Port        Vlans allowed on trunk
Gi0/24      1-4094

Port        Vlans allowed and active in management domain
Gi0/24      1,10,20,99

Port        Vlans in spanning tree forwarding state and not pruned
Gi0/24      1,10,20,99
```

---

## `show running-config interface` — typical output

```
Building configuration...

Current configuration : 113 bytes
!
interface GigabitEthernet0/0
 description Uplink to ISP
 ip address 192.168.1.1 255.255.255.0
 duplex auto
 speed auto
end
```

---

## `show spanning-tree` — typical output (per VLAN)

```
VLAN0001
  Spanning tree enabled protocol rstp
  Root ID    Priority    32769
             Address     aabb.cc00.0100
             Cost        4
             Port        24 (GigabitEthernet0/24)
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec

  Bridge ID  Priority    32769  (priority 32768 sys-id-ext 1)
             Address     aabb.cc00.0200
             Hello Time   2 sec  Max Age 20 sec  Forward Delay 15 sec
             Aging Time  300 sec

Interface           Role Sts Cost      Prio.Nbr Type
------------------- ---- --- --------- -------- --------------------------------
Gi0/1               Desg FWD 4         128.1    P2p
Gi0/24              Root FWD 4         128.24   P2p
```

Roles: Root, Desg (Designated), Altn (Alternate), Back (Backup).
States: FWD, BLK, LRN, LIS, DIS.
Priority is always `<configured> + sys-id-ext (= VLAN ID)`.

---

## `show mac address-table` — typical output

```
          Mac Address Table
-------------------------------------------

Vlan    Mac Address       Type        Ports
----    -----------       --------    -----
   1    aabb.cc00.0100    DYNAMIC     Gi0/1
  10    aabb.cc00.0200    DYNAMIC     Gi0/5
  10    aabb.cc00.0300    STATIC      Gi0/6
Total Mac Addresses for this criterion: 3
```

---

## `show ip arp` — typical output

```
Protocol  Address          Age (min)  Hardware Addr   Type   Interface
Internet  192.168.1.1             -   aabb.cc00.0100  ARPA   GigabitEthernet0/0
Internet  192.168.1.2             3   aabb.cc00.0200  ARPA   GigabitEthernet0/0
```

---

## `show cdp neighbors` — typical output

```
Capability Codes: R - Router, T - Trans Bridge, B - Source Route Bridge
                  S - Switch, H - Host, I - IGMP, r - Repeater, P - Phone

Device ID    Local Intrfce   Holdtme    Capability   Platform   Port ID
SW2          Gig 0/24        160          S          c2960      Gig 0/24
R2           Gig 0/0         145          R          c1841      Gig 0/0
```

---

## Save / reload behavior

- `copy running-config startup-config` (or `wr` / `write memory`)
  → prompts `Destination filename [startup-config]?`, then `Building configuration...` and `[OK]`.
- `reload` — prompts `Proceed with reload? [confirm]`. After confirmation: console shows boot messages, prompt eventually returns as `Router>`.
- `erase startup-config` (or `write erase`) — prompts confirm, then `[OK]`.
- Unsaved config + reload = lose changes. Always save before lab end.

---

## Common config snippets to render correctly

**Hostname + banner:**
```
Router(config)# hostname R1
R1(config)# banner motd #
Enter TEXT message.  End with the character '#'.
Authorized access only.
#
```

**SSH setup:**
```
R1(config)# ip domain-name lab.local
R1(config)# crypto key generate rsa modulus 2048
The name for the keys will be: R1.lab.local
% The key modulus size is 2048 bits
% Generating 2048 bit RSA keys, keys will be non-exportable...
[OK] (elapsed time was N seconds)
R1(config)# username admin secret cisco123
R1(config)# line vty 0 15
R1(config-line)# transport input ssh
R1(config-line)# login local
```

**OSPF basic:**
```
R1(config)# router ospf 1
R1(config-router)# router-id 1.1.1.1
R1(config-router)# network 192.168.1.0 0.0.0.255 area 0
R1(config-router)# passive-interface GigabitEthernet0/2
```

When OSPF neighbor comes up, log message:
```
%OSPF-5-ADJCHG: Process 1, Nbr 2.2.2.2 on GigabitEthernet0/0 from LOADING to FULL, Loading Done
```

**VLAN + trunk:**
```
SW1(config)# vlan 10
SW1(config-vlan)# name SALES
SW1(config-vlan)# exit
SW1(config)# interface gi0/24
SW1(config-if)# switchport mode trunk
SW1(config-if)# switchport trunk allowed vlan 10,20,99
SW1(config-if)# switchport trunk native vlan 99
```

**Standard ACL + apply:**
```
R1(config)# access-list 10 permit 192.168.1.0 0.0.0.255
R1(config)# access-list 10 deny any log
R1(config)# interface gi0/0
R1(config-if)# ip access-group 10 in
```

---

## Logging line formats

```
*Mar  1 00:00:35.123: %SYS-5-CONFIG_I: Configured from console by console
*Mar  1 00:01:42.001: %LINK-3-UPDOWN: Interface GigabitEthernet0/0, changed state to up
*Mar  1 00:01:43.001: %LINEPROTO-5-UPDOWN: Line protocol on Interface GigabitEthernet0/0, changed state to up
*Mar  1 00:02:10.500: %CDP-4-NATIVE_VLAN_MISMATCH: Native VLAN mismatch discovered on GigabitEthernet0/24 (1), with SW2 GigabitEthernet0/24 (99).
```

---

## Behavior reminders

- IOS commands accept unique prefix (e.g., `conf t` → `configure terminal`, `sh ip int br` → `show ip interface brief`).
- `?` mid-word lists completions: `sh ip ?` lists all `show ip` subcommands.
- `Tab` completes a partial command.
- `Ctrl-Z` from any config submode → privileged EXEC.
- Default `enable secret` is unset on a fresh device.
- Default running config has all interfaces in `administratively down` (shutdown) state.
- VLAN 1 is the default native VLAN on trunks.
- A switch port is `dynamic auto` by default (does not initiate trunk negotiation).
