# Topic 210: Network Client Management

Official reference: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## 210.1 DHCP configuration (weight: 2)

**Description:** Candidates should be able to configure a DHCP server. This objective includes setting default and per client options, adding static hosts and BOOTP hosts. Also included is configuring a DHCP relay agent and maintaining the DHCP server.

**Key Knowledge Areas:**
- DHCP configuration files, terms and utilities
- Subnet and dynamically-allocated range setup
- Awareness of DHCPv6 and IPv6 Router Advertisements

**Files, terms and utilities:**
- `dhcpd.conf`
- `dhcpd.leases`
- DHCP log messages in syslog or systemd journal
- `arp`
- `dhcpd`
- `radvd`, `radvd.conf`

### Exam focus areas

- **`dhcpd.conf`** — typically `/etc/dhcp/dhcpd.conf`. Global options apply to all subnets unless overridden. Structure:
  ```
  option domain-name "example.com";
  option domain-name-servers 192.168.1.1, 8.8.8.8;
  default-lease-time 600;
  max-lease-time 7200;
  authoritative;

  subnet 192.168.1.0 netmask 255.255.255.0 {
      range 192.168.1.100 192.168.1.200;
      option routers 192.168.1.1;
      option subnet-mask 255.255.255.0;
  }
  ```
- **Static hosts (reservations)** — assign fixed IP based on MAC address:
  ```
  host printer {
      hardware ethernet 00:11:22:33:44:55;
      fixed-address 192.168.1.50;
  }
  ```
  Can be inside or outside subnet declaration.
- **BOOTP** — `host diskless { hardware ethernet ...; fixed-address ...; filename "pxelinux.0"; next-server 192.168.1.1; }`. `allow bootp;` in subnet. Used for PXE/network booting.
- **`dhcpd.leases`** — `/var/lib/dhcpd/dhcpd.leases`. Records active leases with MAC, IP, start/end times. Read by dhcpd on startup to know current state. Automatically cleaned up.
- **DHCP relay** — `dhcrelay -i eth0 192.168.1.1` (forward DHCP requests across subnets to server at 192.168.1.1). Needed when DHCP server is on different subnet than clients. Alternative: `ip helper-address` on router.
- **Logging** — DHCP logs to syslog facility `daemon` or `local7`. Check with `journalctl -u dhcpd` or `/var/log/messages`. Shows DHCPDISCOVER, DHCPOFFER, DHCPREQUEST, DHCPACK sequence.
- **`radvd`** — Router Advertisement Daemon for IPv6. Config: `/etc/radvd.conf`. Announces IPv6 prefixes and flags for SLAAC (Stateless Address Autoconfiguration). `interface eth0 { AdvSendAdvert on; prefix 2001:db8::/64 { }; };`. DHCPv6 is the stateful alternative.
- **`arp`** — `arp -a` (show ARP cache), `arp -d IP` (delete entry). Useful for troubleshooting DHCP — verify client got correct IP-to-MAC mapping.

---

## 210.2 PAM authentication (weight: 3)

**Description:** The candidate should be able to configure PAM to support authentication using various available methods. This includes basic SSSD functionality.

**Key Knowledge Areas:**
- PAM configuration files, terms and utilities
- passwd and shadow passwords
- Use sssd for LDAP authentication

**Files, terms and utilities:**
- `/etc/pam.d/`
- `pam.conf`
- `nsswitch.conf`
- `pam_unix`, `pam_cracklib`, `pam_limits`, `pam_listfile`, `pam_sss`
- `sssd.conf`

### Exam focus areas

- **PAM config files** — `/etc/pam.d/` directory (one file per service: `login`, `sshd`, `su`, `sudo`, `passwd`, `common-auth`, `system-auth`). Older systems: single `/etc/pam.conf` file. Format: `type control module [arguments]`.
- **PAM types (stacks)** — `auth` (verify identity — password, biometric), `account` (authorization — is account valid, not expired, allowed access), `password` (update credentials — password change), `session` (setup/teardown — mount homedir, set limits, log).
- **Control flags** — `required` (must pass, but continue checking stack), `requisite` (must pass, fail immediately if not), `sufficient` (if passes and no prior required failed, return success immediately), `optional` (result ignored unless it's the only module), `include` (include another file's stack).
- **Key modules:**
  - `pam_unix` — traditional /etc/passwd + /etc/shadow auth. `nullok` (allow empty passwords), `try_first_pass`, `use_first_pass`.
  - `pam_cracklib` / `pam_pwquality` — password strength checking. `minlen=8`, `dcredit=-1` (require digit), `ucredit=-1` (require uppercase), `lcredit=-1` (lowercase), `ocredit=-1` (other/special).
  - `pam_limits` — enforces `/etc/security/limits.conf` resource limits. Format: `user/group type resource value`. Types: `soft` (user can increase to hard), `hard` (absolute max). Resources: `nofile` (open files), `nproc` (processes), `maxlogins`, `core`, `memlock`.
  - `pam_listfile` — allow/deny based on list file. `item=user sense=allow file=/etc/allowed_users onerr=fail`.
  - `pam_sss` — SSSD authentication module. Replaces pam_ldap for LDAP/AD auth.
  - `pam_nologin` — prevents non-root login when `/etc/nologin` exists.
  - `pam_securetty` — restricts root login to terminals listed in `/etc/securetty`.
- **`nsswitch.conf`** — `/etc/nsswitch.conf` determines order of name resolution sources. `passwd: files sss`, `group: files sss`, `shadow: files sss`, `hosts: files dns`. Sources: `files` (/etc/passwd etc.), `sss` (SSSD), `ldap`, `nis`, `dns`, `compat`.
- **SSSD** — System Security Services Daemon. Config: `/etc/sssd/sssd.conf` (mode 0600). Caches credentials for offline login. Sections: `[sssd]` (services, domains), `[domain/EXAMPLE]` (id_provider=ldap/ad, auth_provider, ldap_uri, ldap_search_base). `id_provider = ad` for Active Directory. Replaces older nss_ldap + pam_ldap approach.

---

## 210.3 LDAP client usage (weight: 2)

**Description:** Candidates should be able to perform queries and updates to an LDAP server. Also included is importing and adding items, as well as adding and managing users.

**Key Knowledge Areas:**
- LDAP utilities for data management and queries
- Change user passwords
- Querying the LDAP directory

**Files, terms and utilities:**
- `ldapsearch`
- `ldappasswd`
- `ldapadd`
- `ldapdelete`

### Exam focus areas

- **`ldapsearch`** — query LDAP directory. `ldapsearch -x -H ldap://server -b "dc=example,dc=com" -D "cn=admin,dc=example,dc=com" -W "(uid=john)"`. Key flags: `-x` (simple auth), `-H` (URI), `-b` (search base), `-D` (bind DN), `-W` (prompt password), `-w` (password on cmdline), `-s` (scope: base/one/sub), `-LLL` (clean LDIF output). Filter syntax: `(objectClass=posixAccount)`, `(&(uid=john)(objectClass=person))`, `(|(cn=John*)(cn=Jane*))`.
- **`ldapadd`** — add entries from LDIF file. `ldapadd -x -H ldap://server -D "cn=admin,dc=example,dc=com" -W -f newuser.ldif`. LDIF format:
  ```
  dn: uid=john,ou=People,dc=example,dc=com
  objectClass: inetOrgPerson
  objectClass: posixAccount
  cn: John Doe
  sn: Doe
  uid: john
  uidNumber: 10001
  gidNumber: 10001
  homeDirectory: /home/john
  ```
- **`ldapdelete`** — `ldapdelete -x -D "cn=admin,dc=example,dc=com" -W "uid=john,ou=People,dc=example,dc=com"`. Can delete multiple DNs from file with `-f`.
- **`ldapmodify`** — modify existing entries. Uses LDIF with changetype:
  ```
  dn: uid=john,ou=People,dc=example,dc=com
  changetype: modify
  replace: loginShell
  loginShell: /bin/zsh
  ```
  Operations: `add` (add attribute), `replace` (change value), `delete` (remove attribute).
- **`ldappasswd`** — change LDAP user password. `ldappasswd -x -D "cn=admin,dc=example,dc=com" -W -S "uid=john,ou=People,dc=example,dc=com"`. `-S` prompts for new password. `-s newpass` sets directly.
- **LDAP client config** — `/etc/ldap/ldap.conf` or `/etc/openldap/ldap.conf`. Sets defaults: `BASE dc=example,dc=com`, `URI ldap://server`, `TLS_CACERT /etc/ssl/certs/ca.crt`.

---

## 210.4 Configuring an OpenLDAP server (weight: 4)

**Description:** Candidates should be able to configure a basic OpenLDAP server including knowledge of LDIF format and essential access controls.

**Key Knowledge Areas:**
- OpenLDAP
- Directory based configuration
- Access Control
- Distinguished Names
- Changetype Operations
- Schemas and Whitepages
- Directories
- Object IDs, Attributes and Classes

**Files, terms and utilities:**
- `slapd`
- `slapd-config`
- LDIF
- `slapadd`, `slapcat`, `slapindex`
- `/var/lib/ldap/`
- `loglevel`

### Exam focus areas

- **`slapd`** — OpenLDAP server daemon. Old config: `/etc/ldap/slapd.conf` (deprecated). New config: `cn=config` (OLC — On-Line Configuration), stored in `/etc/ldap/slapd.d/` as LDIF. Changes via `ldapmodify` against `cn=config` — no restart needed.
- **Distinguished Names (DN)** — hierarchical naming. Components: `dc` (domain), `ou` (organizational unit), `cn` (common name), `uid` (user id). Example: `uid=john,ou=People,dc=example,dc=com`. Base DN is the root of the tree.
- **LDIF format** — text representation of LDAP entries. Each entry starts with `dn:`, followed by attributes. Entries separated by blank lines. Continuation lines start with single space. `changetype: add|modify|delete|modrdn`. Binary data encoded in base64 with `:: `.
- **Schemas** — define object classes and attributes. Core schemas: `core.schema`, `cosine.schema`, `inetorgperson.schema`, `nis.schema` (for posixAccount). Object classes: `structural` (main class, one per entry), `auxiliary` (additional attributes), `abstract` (base, like `top`). OID (Object Identifier) uniquely identifies each schema element.
- **`slapadd`** — bulk load LDIF into database offline (slapd must be stopped). `slapadd -l data.ldif`. Faster than ldapadd for initial population. Fix ownership after: `chown -R ldap:ldap /var/lib/ldap/`.
- **`slapcat`** — dump database to LDIF (can run while slapd is running for backup). `slapcat -l backup.ldif`. `-b "dc=example,dc=com"` for specific database.
- **`slapindex`** — rebuild database indices (slapd must be stopped). Run after modifying index configuration. `slapindex -b "dc=example,dc=com"`.
- **Access control** — in `slapd.conf`: `access to <what> by <who> <access>`. Access levels: `none`, `disclose`, `auth`, `compare`, `search`, `read`, `write`, `manage`. Example: `access to attrs=userPassword by self write by anonymous auth by * none`. In OLC: `olcAccess` attribute. Rules processed top-to-bottom, first match wins. Default: read access to all.
- **`loglevel`** — controls slapd logging verbosity. Values: `none` (0), `trace` (1), `packets` (2), `args` (4), `conns` (8), `BER` (16), `filter` (32), `config` (64), `ACL` (128), `stats` (256), `stats2` (512), `shell` (1024), `parse` (2048), `any` (-1). Can combine: `loglevel stats ACL`. Logs to syslog facility `local4`.
- **Database backends** — `mdb` (recommended, LMDB-based, replaces bdb/hdb), `bdb`/`hdb` (deprecated Berkeley DB). Config: `database mdb`, `suffix "dc=example,dc=com"`, `rootdn "cn=admin,dc=example,dc=com"`, `rootpw {SSHA}hashedpassword`, `directory /var/lib/ldap`.
