# Topic 212: System Security

Official reference: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## 212.1 Configuring a router (weight: 3)

**Description:** Candidates should be able to configure a system to forward IP packets and perform network address translation (NAT, IP masquerading) and state its significance in protecting a network. This objective includes configuring port redirection, managing filter rules and averting attacks.

**Key Knowledge Areas:**
- iptables and ip6tables configuration files, tools and utilities
- Tools, commands and utilities to manage routing tables
- Private address ranges (IPv4) and Unique Local Addresses as well as Link Local Addresses (IPv6)
- Port redirection and IP forwarding
- List and write filtering and rules that accept or block IP packets based on source or destination protocol, port and address
- Save and reload filtering configurations

**Files, terms and utilities:**
- `/proc/sys/net/ipv4/`
- `/proc/sys/net/ipv6/`
- `/etc/services`
- `iptables`, `ip6tables`

### Exam focus areas

- **IP forwarding** — enable: `echo 1 > /proc/sys/net/ipv4/ip_forward` (temporary) or `sysctl -w net.ipv4.ip_forward=1`. Permanent: `net.ipv4.ip_forward = 1` in `/etc/sysctl.conf` or `/etc/sysctl.d/*.conf`, apply with `sysctl -p`. IPv6: `net.ipv6.conf.all.forwarding = 1`.
- **iptables tables** — `filter` (default: INPUT, FORWARD, OUTPUT), `nat` (PREROUTING, OUTPUT, POSTROUTING), `mangle` (all chains, modify packets), `raw` (PREROUTING, OUTPUT, connection tracking exceptions).
- **iptables chains** — `INPUT` (packets destined for this host), `OUTPUT` (locally generated packets), `FORWARD` (packets passing through/routed), `PREROUTING` (before routing decision), `POSTROUTING` (after routing decision).
- **iptables commands** — `-A` (append rule), `-I` (insert at position), `-D` (delete rule), `-L` (list rules), `-F` (flush/delete all rules in chain), `-P` (set default policy), `-N` (create custom chain), `-X` (delete custom chain), `-Z` (zero counters). `-v` (verbose), `-n` (numeric output), `--line-numbers`.
- **iptables match options** — `-p tcp/udp/icmp` (protocol), `-s`/`-d` (source/dest IP), `--sport`/`--dport` (source/dest port), `-i`/`-o` (in/out interface), `-m state --state NEW,ESTABLISHED,RELATED` (connection tracking), `-m multiport --dports 80,443`, `-m limit --limit 5/min` (rate limiting).
- **iptables targets** — `-j ACCEPT` (allow), `-j DROP` (silently discard), `-j REJECT` (discard with ICMP error), `-j LOG` (log to syslog), `-j MASQUERADE` (SNAT for dynamic IP), `-j SNAT --to-source IP` (static NAT), `-j DNAT --to-destination IP:port` (port forwarding), `-j REDIRECT --to-port PORT`.
- **NAT/masquerading** — outbound: `iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE` (dynamic IP) or `-j SNAT --to-source 1.2.3.4` (static IP). Port forwarding: `iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.10:80` + `iptables -A FORWARD -p tcp -d 192.168.1.10 --dport 80 -j ACCEPT`.
- **Save/restore** — `iptables-save > /etc/iptables.rules`, `iptables-restore < /etc/iptables.rules`. Red Hat: `service iptables save` saves to `/etc/sysconfig/iptables`. Debian: use `iptables-persistent` package or `/etc/network/if-pre-up.d/` script.
- **Private address ranges** — IPv4: 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16. IPv6: ULA fc00::/7 (fd00::/8 in practice), Link-Local fe80::/10 (auto-configured on every interface).
- **Routing** — `ip route show` (show routing table), `ip route add 10.0.0.0/8 via 192.168.1.1`, `ip route add default via 192.168.1.1`. Legacy: `route -n`, `route add`. `/etc/services` maps port numbers to service names.

---

## 212.2 Managing FTP servers (weight: 2)

**Description:** Candidates should be able to configure an FTP server for anonymous downloads and uploads. This objective includes precautions to be taken if anonymous uploads are permitted and configuring user access.

**Key Knowledge Areas:**
- Configuration files, tools and utilities for Pure-FTPd and vsftpd
- Awareness of ProFTPd
- Understanding of passive vs. active FTP connections

**Files, terms and utilities:**
- `vsftpd.conf`
- Important Pure-FTPd command line options

### Exam focus areas

- **vsftpd config** — `/etc/vsftpd/vsftpd.conf` or `/etc/vsftpd.conf`. Key directives:
  - `anonymous_enable=YES/NO` (allow anonymous FTP)
  - `local_enable=YES` (allow local users to log in)
  - `write_enable=YES` (allow write commands)
  - `anon_upload_enable=YES` (anonymous uploads)
  - `anon_mkdir_write_enable=YES` (anonymous directory creation)
  - `chroot_local_user=YES` (confine users to home directory)
  - `chroot_list_enable=YES` + `chroot_list_file=/etc/vsftpd.chroot_list` (list of users NOT chrooted)
  - `allow_writeable_chroot=YES` (allow chroot to writeable directory)
  - `userlist_enable=YES` + `userlist_deny=YES` (deny users in `/etc/vsftpd.user_list`)
  - `listen=YES` (standalone mode) vs `listen=NO` (xinetd mode)
  - `ssl_enable=YES` (enable FTPS)
  - `pasv_enable=YES`, `pasv_min_port`, `pasv_max_port` (passive mode port range)
- **Anonymous FTP security** — anonymous users map to `ftp` system user. Home: `/srv/ftp` or `/var/ftp`. Uploads should go to directory owned by root with write permission for ftp group, files should NOT be downloadable until reviewed (use `chown_uploads=YES`, `chown_username=daemon`). `anon_umask=077`.
- **Active vs passive FTP** — Active: client opens port, tells server via PORT command, server connects back from port 20. Passive: client sends PASV, server opens port and tells client, client connects. Passive is firewall-friendly (no inbound connection to client). Passive port range should be configured and opened in firewall.
- **Pure-FTPd** — command-line options instead of config file (or `/etc/pure-ftpd.conf` on some distros). Key options: `-A` (chroot all users), `-B` (background/daemon), `-c N` (max clients), `-C N` (max connections per IP), `-e` (anonymous only), `-E` (no anonymous), `-p low:high` (passive port range), `-S port` (listen port). Can use wrapper scripts in `/etc/pure-ftpd/conf/` (Debian).
- **ProFTPd awareness** — Apache-like config syntax. Config: `/etc/proftpd/proftpd.conf`. Uses `<Directory>`, `<VirtualHost>`, `<Anonymous>` blocks. `ServerType standalone/inetd`. More configurable than vsftpd but larger attack surface.

---

## 212.3 Secure shell (SSH) (weight: 4)

**Description:** Candidates should be able to configure and secure an SSH daemon. This objective includes managing keys and configuring SSH for users. Candidates should also be able to forward an application protocol over SSH and manage the SSH login.

**Key Knowledge Areas:**
- OpenSSH configuration files, tools and utilities
- Login restrictions for the superuser and the normal users
- Managing and using server and client keys to login with and without password
- Usage of multiple connections from multiple hosts to guard against loss of connection to remote host following configuration changes

**Files, terms and utilities:**
- `ssh`, `sshd`
- `/etc/ssh/sshd_config`
- `/etc/ssh/`
- Private and public key files
- `PermitRootLogin`, `PubKeyAuthentication`, `AllowUsers`, `PasswordAuthentication`, `Protocol`

### Exam focus areas

- **`sshd_config`** — `/etc/ssh/sshd_config`. Key directives:
  - `Port 22` (change to non-standard for obscurity)
  - `ListenAddress 0.0.0.0` (bind to specific interface)
  - `PermitRootLogin no` (options: `yes`, `no`, `prohibit-password`/`without-password`, `forced-commands-only`)
  - `PubkeyAuthentication yes`
  - `PasswordAuthentication no` (disable after setting up keys)
  - `ChallengeResponseAuthentication no`
  - `AllowUsers user1 user2` (whitelist users, most restrictive)
  - `AllowGroups sshusers` (whitelist groups)
  - `DenyUsers baduser` / `DenyGroups noremote`
  - `MaxAuthTries 3` (max auth attempts per connection)
  - `MaxSessions 10` (max sessions per connection)
  - `LoginGraceTime 60` (seconds to authenticate)
  - `ClientAliveInterval 300` / `ClientAliveCountMax 3` (detect dead clients)
  - `X11Forwarding yes/no`
  - `AllowTcpForwarding yes/no`
  - `GatewayPorts no` (allow remote port forwarding to bind to all interfaces)
  - `Banner /etc/ssh/banner.txt` (pre-login banner)
  - `UsePAM yes` (use PAM for authentication)
- **Key management** — `ssh-keygen -t ed25519` (or `-t rsa -b 4096`). Files: `~/.ssh/id_ed25519` (private), `~/.ssh/id_ed25519.pub` (public). `ssh-copy-id user@host` (copy public key to remote `~/.ssh/authorized_keys`). Permissions: `~/.ssh/` = 700, `authorized_keys` = 600, private key = 600. `ssh-keygen -p` (change passphrase). `ssh-keygen -R hostname` (remove host from known_hosts).
- **Server host keys** — stored in `/etc/ssh/`: `ssh_host_rsa_key`, `ssh_host_ecdsa_key`, `ssh_host_ed25519_key` (+ `.pub`). Clients verify against `~/.ssh/known_hosts`. `ssh-keyscan host` to retrieve host keys.
- **SSH agent** — `eval $(ssh-agent)` then `ssh-add` (or `ssh-add ~/.ssh/id_rsa`). Caches decrypted private keys in memory. `ssh-add -l` (list loaded keys), `ssh-add -D` (remove all). Agent forwarding: `ssh -A user@host` (or `ForwardAgent yes` in config) — allows using local keys on remote host. Security risk: remote root can access forwarded agent.
- **Port forwarding / tunneling** — Local: `ssh -L 8080:remote-db:3306 user@jumphost` (access remote-db:3306 via localhost:8080). Remote: `ssh -R 9090:localhost:80 user@remote` (expose local:80 on remote:9090). Dynamic/SOCKS: `ssh -D 1080 user@host` (SOCKS proxy). `-N` (no command), `-f` (background).
- **SSH client config** — `~/.ssh/config`:
  ```
  Host jumpbox
      HostName 203.0.113.10
      User admin
      Port 2222
      IdentityFile ~/.ssh/jump_key
  Host internal
      HostName 10.0.0.5
      ProxyJump jumpbox
  ```
  `ProxyJump` (or `-J`) for jump hosts. `StrictHostKeyChecking ask/yes/no`.
- **Safe remote config changes** — when modifying sshd_config remotely: keep existing session open, start a second connection to test after `systemctl reload sshd`. If locked out, the first session is still active. Or use `at` to revert: `at now + 5 minutes <<< 'cp /etc/ssh/sshd_config.bak /etc/ssh/sshd_config && systemctl reload sshd'`.

---

## 212.4 Security tasks (weight: 3)

**Description:** Candidates should be able to receive security alerts from various sources, install, configure and run intrusion detection systems and apply security patches and bugfixes.

**Key Knowledge Areas:**
- Tools and utilities to scan and test ports on a server
- Locations and organisations that report security alerts as Bugtraq, CERT or other sources
- Tools and utilities to implement an intrusion detection system (IDS)
- Awareness of OpenVAS and Snort

**Files, terms and utilities:**
- `telnet`
- `nmap`
- `fail2ban`
- `nc`
- `iptables`

### Exam focus areas

- **`nmap`** — network scanner. `nmap host` (default: top 1000 TCP ports). Scan types: `-sS` (SYN/stealth scan, default with root), `-sT` (full TCP connect), `-sU` (UDP scan), `-sP`/`-sn` (ping sweep, host discovery), `-sV` (service version detection), `-O` (OS detection), `-A` (aggressive: OS + version + scripts + traceroute). Port specification: `-p 22,80,443`, `-p-` (all 65535), `-p 1-1024`. Output: `-oN file` (normal), `-oX file` (XML), `-oG file` (grepable). Port states: open, closed, filtered.
- **`nc` (netcat)** — network Swiss army knife. Listen: `nc -l -p 8080` (listen on port 8080). Connect: `nc host 80`. Port test: `nc -zv host 22` (quick port check). Banner grab: `echo "" | nc host 25`. File transfer: receiver `nc -l -p 9999 > file`, sender `nc host 9999 < file`. Chat/simple server: `nc -l -p 1234`.
- **`telnet`** — `telnet host port` for basic port/service testing. `telnet mail.example.com 25` to test SMTP manually (type HELO, MAIL FROM, RCPT TO). Not for secure remote access (use SSH).
- **`fail2ban`** — intrusion prevention. Config: `/etc/fail2ban/jail.conf` (defaults) → `/etc/fail2ban/jail.local` (overrides, never edit .conf). Key settings: `bantime` (ban duration), `findtime` (window), `maxretry` (attempts before ban). Jails: `[sshd]` (enabled by default), `[apache-auth]`, `[postfix]`, `[dovecot]`. Actions: ban IP via iptables/firewalld/nftables. Commands: `fail2ban-client status` (list active jails), `fail2ban-client status sshd` (show banned IPs), `fail2ban-client set sshd unbanip IP` (unban), `fail2ban-client reload`. Custom filters in `/etc/fail2ban/filter.d/`. Regex-based log parsing.
- **Security alert sources** — CERT/CC (cert.org), Bugtraq (mailing list), CVE (cve.mitre.org), NVD (nvd.nist.gov), US-CERT, distribution security lists (debian-security-announce, RHSA). RSS feeds, mailing lists for notifications.
- **IDS tools** — Snort: network-based IDS/IPS, uses rule-based detection. Rules in `/etc/snort/rules/`. Modes: sniffer, packet logger, NIDS. OpenVAS: vulnerability scanner (successor to Nessus free version), performs network vulnerability assessment. AIDE/Tripwire: file integrity checkers (host-based IDS), detect unauthorized file changes.
- **Security scanning with iptables** — log suspicious traffic: `iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --set`, `iptables -A INPUT -p tcp --dport 22 -m recent --name ssh --rcheck --seconds 60 --hitcount 4 -j DROP` (rate limit SSH connections).

---

## 212.5 OpenVPN (weight: 2)

**Description:** Candidates should be able to configure a VPN (Virtual Private Network) and create secure point-to-point or site-to-site connections.

**Key Knowledge Areas:**
- OpenVPN

**Files, terms and utilities:**
- `/etc/openvpn/`
- `openvpn`

### Exam focus areas

- **OpenVPN basics** — SSL/TLS-based VPN. Operates in user space (not kernel like IPsec). Uses `tun` (layer 3, routed) or `tap` (layer 2, bridged) virtual interfaces. Default port: UDP 1194.
- **PKI setup** — uses easy-rsa scripts (or manual openssl). Generate: CA cert/key, server cert/key, client cert/key, DH parameters (`openssl dhparam -out dh2048.pem 2048`). Optional: `ta.key` for TLS-auth (HMAC, prevents DoS).
- **Server config** — `/etc/openvpn/server.conf`:
  ```
  port 1194
  proto udp
  dev tun
  ca ca.crt
  cert server.crt
  key server.key
  dh dh2048.pem
  tls-auth ta.key 0
  server 10.8.0.0 255.255.255.0
  push "redirect-gateway def1"
  push "dhcp-option DNS 8.8.8.8"
  keepalive 10 120
  cipher AES-256-GCM
  user nobody
  group nogroup
  persist-key
  persist-tun
  status /var/log/openvpn-status.log
  verb 3
  ```
  `server` directive sets VPN subnet. `push` sends options to clients. `client-to-client` allows VPN clients to reach each other.
- **Client config** — `.ovpn` or `.conf` file:
  ```
  client
  dev tun
  proto udp
  remote vpn.example.com 1194
  resolv-retry infinite
  nobind
  ca ca.crt
  cert client.crt
  key client.key
  tls-auth ta.key 1
  cipher AES-256-GCM
  verb 3
  ```
  Note `tls-auth` direction: 0 on server, 1 on client.
- **Routing** — site-to-site: add `route` directives and client-specific configs in `ccd/` directory. `iroute 192.168.2.0 255.255.255.0` in client config file (tells OpenVPN server about client's subnet). Server needs corresponding `route` directive. Enable IP forwarding on server.
- **Management** — `systemctl start openvpn@server` (uses `/etc/openvpn/server.conf`). Status file shows connected clients. `openvpn --config file.conf` (manual start). Revoke client: generate CRL, set `crl-verify crl.pem` in server config.
- **Bridging vs routing** — `tun` (routed, layer 3): separate subnet for VPN, most common, more efficient. `tap` (bridged, layer 2): same subnet as LAN, needed for broadcasts/non-IP protocols, more overhead. Bridge setup requires `brctl` and bridge helper scripts.
