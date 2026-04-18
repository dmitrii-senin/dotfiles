# LPIC-202-450 Exam Objectives — Overview

Source of truth: https://www.lpi.org/our-certifications/exam-201-202-objectives/

Detailed per-topic references with exam focus areas are in the `topics/` directory.

---

## Topic 207: Domain Name Server

- **207.1 Basic DNS server configuration** (weight: 3) — Configure BIND as authoritative and recursive/caching-only DNS server. Manage a running server and configure logging.
- **207.2 Create and maintain DNS zones** (weight: 3) — Create forward/reverse zone files and root hints. Set record values, add hosts, delegate zones.
- **207.3 Securing a DNS server** (weight: 2) — Run DNS as non-root in chroot jail. Secure data exchange between servers (TSIG, DNSSEC, DANE).

## Topic 208: HTTP Services

- **208.1 Basic Apache configuration** (weight: 4) — Install and configure Apache: monitoring, access restriction, scripting modules (mod_perl, PHP), authentication (htpasswd, AuthUserFile/AuthGroupFile), resource limits, virtual hosts, redirects.
- **208.2 Apache configuration for HTTPS** (weight: 3) — Configure HTTPS: generate keys/CSRs/self-signed certs, install certs with intermediate CAs, SNI, disable insecure protocols/ciphers.
- **208.3 Implementing Squid as a caching proxy** (weight: 2) — Install and configure Squid proxy: ACLs, access policies, authentication, resource usage.
- **208.4 Implementing Nginx as a web server and reverse proxy** (weight: 2) — Configure Nginx as HTTP server and reverse proxy.

## Topic 209: File Sharing

- **209.1 Samba Server Configuration** (weight: 5) — Set up Samba as standalone server and AD member. Configure CIFS/printer shares, Linux client access, troubleshooting.
- **209.2 NFS Server Configuration** (weight: 3) — Export filesystems via NFS. Access restrictions, mount options, TCP Wrappers, NFSv4 awareness.

## Topic 210: Network Client Management

- **210.1 DHCP configuration** (weight: 2) — Configure DHCP server: default/per-client options, static hosts, BOOTP, relay agent, server maintenance.
- **210.2 PAM authentication** (weight: 3) — Configure PAM for various auth methods. Basic SSSD functionality.
- **210.3 LDAP client usage** (weight: 2) — Query and update LDAP server. Import/add items, manage users.
- **210.4 Configuring an OpenLDAP server** (weight: 4) — Configure basic OpenLDAP server: LDIF format, access controls, schemas, directory structure.

## Topic 211: E-Mail Services

- **211.1 Using e-mail servers** (weight: 4) — Manage e-mail server: aliases, quotas, virtual domains, internal relays, monitoring. Postfix focus, sendmail/exim awareness.
- **211.2 Managing E-Mail Delivery** (weight: 2) — Implement Sieve mail filtering: syntax, operators, actions. Dovecot vacation. Procmail awareness.
- **211.3 Managing Mailbox Access** (weight: 2) — Install and configure Dovecot for IMAP/POP3. TLS configuration. Courier awareness.

## Topic 212: System Security

- **212.1 Configuring a router** (weight: 3) — IP forwarding, NAT/masquerading, port redirection, iptables/ip6tables filter rules, save/reload configs.
- **212.2 Managing FTP servers** (weight: 2) — Configure vsftpd and Pure-FTPd for anonymous/user access. Active vs passive FTP.
- **212.3 Secure shell (SSH)** (weight: 4) — Configure and secure sshd. Key management, login restrictions, port forwarding, safe remote configuration changes.
- **212.4 Security tasks** (weight: 3) — Port scanning (nmap, nc), security alerts (CERT, Bugtraq), IDS (fail2ban, Snort, OpenVAS).
- **212.5 OpenVPN** (weight: 2) — Configure VPN for point-to-point and site-to-site connections.
