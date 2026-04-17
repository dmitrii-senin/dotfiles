# LPIC-202-450 Exam Objectives

Source of truth: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## Topic 207: Domain Name Server

### 207.1 Basic DNS server configuration (weight: 3)

**Key Knowledge Areas:**
- BIND 9.x configuration files, terms and utilities
- Defining the location of the BIND zone files in BIND configuration files
- Reloading modified configuration and zone files
- Awareness of dnsmasq, djbdns and PowerDNS as alternate name servers

**Files, terms and utilities:**
- `/etc/named.conf`
- `/var/named/`
- `rndc`
- `named-checkconf`
- `kill`
- `host`
- `dig`

### 207.2 Create and maintain DNS zones (weight: 3)

**Key Knowledge Areas:**
- BIND 9 configuration files, terms and utilities
- Utilities to request information from the DNS server
- Layout, content and file location of the BIND zone files
- Various methods to add a new host in the zone files, including reverse zones

**Files, terms and utilities:**
- `/var/named/`
- Zone file syntax
- Resource record formats (A, AAAA, MX, NS, SOA, PTR, CNAME, TXT)
- `named-checkzone`
- `named-compilezone`
- `masterfile-format`
- `dig`
- `nslookup`
- `host`

### 207.3 Securing a DNS server (weight: 2)

**Key Knowledge Areas:**
- BIND 9 configuration files
- Configuring BIND to run in a chroot jail
- Split configuration of BIND using the forwarders statement
- Configuring and using transaction signatures (TSIG)
- Awareness of DNSSEC and basic tools
- Awareness of DANE and related records

**Files, terms and utilities:**
- `/etc/named.conf`
- `/etc/passwd`
- DNSSEC
- `dnssec-keygen`
- `dnssec-signzone`

---

## Topic 208: HTTP Services

### 208.1 Basic Apache configuration (weight: 4)

**Key Knowledge Areas:**
- Apache 2.4 configuration files, terms and utilities
- Apache log files configuration and content
- Access restriction methods and files
- mod_perl and PHP configuration
- Client user authentication files and utilities
- Configuration of maximum requests, minimum and maximum servers and clients
- Apache 2.4 virtual host implementation (with and without dedicated IP addresses)
- Using redirect statements to customize file access

**Files, terms and utilities:**
- Access logs and error logs
- `.htaccess`
- `httpd.conf`
- `mod_auth_basic`, `mod_authz_host`, `mod_access_compat`
- `htpasswd`
- `AuthUserFile`, `AuthGroupFile`
- `apachectl`, `apache2ctl`
- `httpd`, `apache2`

### 208.2 Apache configuration for HTTPS (weight: 3)

**Key Knowledge Areas:**
- SSL configuration files, tools and utilities
- Generate a server private key and CSR for a commercial CA
- Generate a self-signed certificate
- Install the key and certificate, including intermediate CAs
- Configure Virtual Hosting using SNI
- Awareness of the issues with Virtual Hosting and use of SSL
- Security issues in SSL use, disable insecure protocols and ciphers

**Files, terms and utilities:**
- Apache2 configuration files
- `/etc/ssl/`, `/etc/pki/`
- `openssl`, `CA.pl`
- `SSLEngine`, `SSLCertificateKeyFile`, `SSLCertificateFile`
- `SSLCACertificateFile`, `SSLCACertificatePath`
- `SSLProtocol`, `SSLCipherSuite`
- `ServerTokens`, `ServerSignature`, `TraceEnable`

### 208.3 Implementing Squid as a caching proxy (weight: 2)

**Key Knowledge Areas:**
- Squid 3.x configuration files, terms and utilities
- Access restriction methods
- Client user authentication methods
- Layout and content of ACL in the Squid configuration files

**Files, terms and utilities:**
- `squid.conf`
- `acl`
- `http_access`

### 208.4 Implementing Nginx as a web server and reverse proxy (weight: 2)

**Key Knowledge Areas:**
- Nginx
- Reverse Proxy
- Basic Web Server

**Files, terms and utilities:**
- `/etc/nginx/`
- `nginx`

---

## Topic 209: File Sharing

### 209.1 Samba Server Configuration (weight: 5)

**Key Knowledge Areas:**
- Samba 4 documentation
- Samba 4 configuration files
- Samba 4 tools and utilities and daemons
- Mounting CIFS shares on Linux
- Mapping Windows user names to Linux user names
- User-Level, Share-Level and AD security

**Files, terms and utilities:**
- `smbd`, `nmbd`, `winbindd`
- `smbcontrol`, `smbstatus`, `testparm`
- `smbpasswd`, `nmblookup`
- `samba-tool`, `net`
- `smbclient`
- `mount.cifs`
- `/etc/samba/`
- `/var/log/samba/`

### 209.2 NFS Server Configuration (weight: 3)

**Key Knowledge Areas:**
- NFS version 3 configuration files
- NFS tools and utilities
- Access restrictions to certain hosts and/or subnets
- Mount options on server and client
- TCP Wrappers
- Awareness of NFSv4

**Files, terms and utilities:**
- `/etc/exports`
- `exportfs`
- `showmount`
- `nfsstat`
- `/proc/mounts`
- `/etc/fstab`
- `rpcinfo`
- `mountd`, `portmapper`

---

## Topic 210: Network Client Management

### 210.1 DHCP configuration (weight: 2)

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

### 210.2 PAM authentication (weight: 3)

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

### 210.3 LDAP client usage (weight: 2)

**Key Knowledge Areas:**
- LDAP utilities for data management and queries
- Change user passwords
- Querying the LDAP directory

**Files, terms and utilities:**
- `ldapsearch`
- `ldappasswd`
- `ldapadd`
- `ldapdelete`

### 210.4 Configuring an OpenLDAP server (weight: 4)

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

---

## Topic 211: E-Mail Services

### 211.1 Using e-mail servers (weight: 4)

**Key Knowledge Areas:**
- Configuration files for postfix
- Basic TLS configuration for postfix
- Basic knowledge of the SMTP protocol
- Awareness of sendmail and exim

**Files, terms and utilities:**
- Configuration files and commands for postfix
- `/etc/postfix/`
- `/var/spool/postfix/`
- sendmail emulation layer commands
- `/etc/aliases`
- mail-related logs in `/var/log/`

### 211.2 Managing E-Mail Delivery (weight: 2)

**Key Knowledge Areas:**
- Understanding of Sieve functionality, syntax and operators
- Use Sieve to filter and sort mail with respect to sender, recipient(s), headers and size
- Awareness of procmail

**Files, terms and utilities:**
- Conditions and comparison operators
- `keep`, `fileinto`, `redirect`, `reject`, `discard`, `stop`
- Dovecot vacation extension

### 211.3 Managing Mailbox Access (weight: 2)

**Key Knowledge Areas:**
- Dovecot IMAP and POP3 configuration and administration
- Basic TLS configuration for Dovecot
- Awareness of Courier

**Files, terms and utilities:**
- `/etc/dovecot/`
- `dovecot.conf`
- `doveconf`
- `doveadm`

---

## Topic 212: System Security

### 212.1 Configuring a router (weight: 3)

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

### 212.2 Managing FTP servers (weight: 2)

**Key Knowledge Areas:**
- Configuration files, tools and utilities for Pure-FTPd and vsftpd
- Awareness of ProFTPd
- Understanding of passive vs. active FTP connections

**Files, terms and utilities:**
- `vsftpd.conf`
- Important Pure-FTPd command line options

### 212.3 Secure shell (SSH) (weight: 4)

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

### 212.4 Security tasks (weight: 3)

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

### 212.5 OpenVPN (weight: 2)

**Key Knowledge Areas:**
- OpenVPN

**Files, terms and utilities:**
- `/etc/openvpn/`
- `openvpn`
