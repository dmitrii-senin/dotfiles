# Topic 211: E-Mail Services

Official reference: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## 211.1 Using e-mail servers (weight: 4)

**Description:** Candidates should be able to manage an e-mail server, including the configuration of e-mail aliases, e-mail quotas and virtual e-mail domains. This objective includes configuring internal e-mail relays and monitoring e-mail servers.

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

### Exam focus areas

- **Postfix config files** — `/etc/postfix/main.cf` (main configuration), `/etc/postfix/master.cf` (daemon/service definitions). Key `main.cf` directives:
  - `myhostname = mail.example.com`
  - `mydomain = example.com`
  - `myorigin = $mydomain` (domain appended to locally sent mail)
  - `inet_interfaces = all` (listen on all interfaces, or `localhost` for local only)
  - `mydestination = $myhostname, localhost.$mydomain, $mydomain` (domains this server accepts mail for)
  - `mynetworks = 192.168.1.0/24, 127.0.0.0/8` (trusted networks allowed to relay)
  - `relay_domains` (domains to relay mail for)
  - `relayhost = [smtp.isp.com]` (send all outbound mail via this host, brackets prevent MX lookup)
  - `mailbox_size_limit` (max mailbox size in bytes, 0=unlimited)
  - `message_size_limit` (max message size)
- **Postfix commands** — `postfix start/stop/reload/check`, `postconf` (show/set config: `postconf mydomain`, `postconf -e "mydomain=example.com"`), `postqueue -p` (show mail queue, same as `mailq`), `postqueue -f` (flush queue), `postsuper -d ALL` (delete all queued mail), `postsuper -d queue_id` (delete specific message), `postmap` (build lookup tables: `postmap /etc/postfix/virtual`).
- **`/etc/aliases`** — mail aliases. Format: `name: destination`. Examples: `postmaster: root`, `root: admin@example.com`, `dev-team: user1, user2, user3`, `archive: /var/mail/archive` (deliver to file), `filter: |/usr/local/bin/filter.sh` (pipe to command). Run `newaliases` or `postalias /etc/aliases` after editing to rebuild the database.
- **Virtual domains** — `virtual_alias_domains = example.org, example.net`. `virtual_alias_maps = hash:/etc/postfix/virtual`. Virtual file: `user@example.org localuser`, `@example.net catchall@example.com`. Run `postmap /etc/postfix/virtual` after editing.
- **TLS configuration** —
  ```
  smtpd_tls_cert_file = /etc/ssl/certs/mail.crt
  smtpd_tls_key_file = /etc/ssl/private/mail.key
  smtpd_tls_security_level = may    # opportunistic TLS for incoming
  smtp_tls_security_level = may     # opportunistic TLS for outgoing
  smtpd_tls_protocols = !SSLv2, !SSLv3
  ```
  `may` = use TLS if available, `encrypt` = require TLS. Submission port (587) typically enforces TLS.
- **SMTP protocol basics** — commands: `HELO`/`EHLO` (greeting), `MAIL FROM:` (sender), `RCPT TO:` (recipient), `DATA` (message body, end with `.` on its own line), `QUIT`. Response codes: 2xx (success), 3xx (intermediate), 4xx (temporary failure), 5xx (permanent failure). Port 25 (MTA-to-MTA), 587 (submission), 465 (SMTPS, deprecated/resurrected).
- **Mail queue** — `/var/spool/postfix/` subdirectories: `incoming/`, `active/`, `deferred/`, `bounce/`, `corrupt/`. `mailq` or `postqueue -p` to view. `postqueue -f` to retry deferred mail.
- **Sendmail emulation** — Postfix provides `/usr/sbin/sendmail` compatibility. `sendmail -bp` (show queue = mailq), `sendmail -bi` (rebuild aliases = newaliases), `sendmail -q` (process queue). Many scripts/apps use the sendmail command interface.
- **Logging** — `/var/log/mail.log` or `/var/log/maillog`. Shows connection attempts, authentication, delivery status, errors, relay information. Essential for troubleshooting delivery issues.
- **Sendmail/Exim awareness** — Sendmail: oldest MTA, complex config via m4 macros (`sendmail.mc` → `sendmail.cf`), `/etc/mail/` directory. Exim: default on Debian, single config file `/etc/exim4/exim4.conf` or split in `conf.d/`, `dpkg-reconfigure exim4-config` for Debian setup.

---

## 211.2 Managing E-Mail Delivery (weight: 2)

**Description:** Candidates should be able to implement client e-mail management software to filter, sort and monitor incoming user e-mail.

**Key Knowledge Areas:**
- Understanding of Sieve functionality, syntax and operators
- Use Sieve to filter and sort mail with respect to sender, recipient(s), headers and size
- Awareness of procmail

**Files, terms and utilities:**
- Conditions and comparison operators
- `keep`, `fileinto`, `redirect`, `reject`, `discard`, `stop`
- Dovecot vacation extension

### Exam focus areas

- **Sieve overview** — server-side mail filtering language (RFC 5228). Scripts processed by MDA (usually Dovecot's LDA or LMTP). Stored per-user, typically `~/.dovecot.sieve` or managed via ManageSieve protocol (port 4190). Dovecot plugin: `sieve` in `mail_plugins`.
- **Sieve syntax** — basic structure:
  ```sieve
  require ["fileinto", "reject", "vacation"];

  if header :contains "Subject" "URGENT" {
      fileinto "Important";
  } elsif address :is "from" "spam@example.com" {
      discard;
  } elsif size :over 10M {
      reject "Message too large";
  } else {
      keep;
  }
  ```
- **Test commands (conditions)** — `header` (check header field), `address` (check email address in header), `envelope` (check SMTP envelope), `size` (message size: `:over`, `:under`), `exists` (header exists), `allof` (AND), `anyof` (OR), `not` (negation), `true`/`false`.
- **Match types** — `:is` (exact match), `:contains` (substring), `:matches` (wildcard: `*` any string, `?` single char). `:comparator "i;ascii-casemap"` (case-insensitive, default).
- **Actions** — `keep` (deliver to inbox, implicit default), `fileinto "folder"` (deliver to named folder/mailbox), `redirect "user@example.com"` (forward, message leaves server), `reject "reason"` (bounce with message), `discard` (silently delete, no bounce), `stop` (stop processing rules). First action executed, implicit keep unless another action taken.
- **Dovecot vacation extension** — auto-reply:
  ```sieve
  require "vacation";
  vacation
      :days 7
      :subject "Out of Office"
      :addresses ["me@example.com", "alias@example.com"]
      "I am on vacation until Jan 15.";
  ```
  `:days` = minimum interval between auto-replies to same sender. `:addresses` = additional addresses to recognize as "me".
- **Procmail awareness** — older MDA filtering tool. Config: `~/.procmailrc`. Recipe format: `:0 [flags] [: lockfile]` + condition (`* ^From:.*spam`) + action (`/dev/null` or folder). Largely replaced by Sieve. `MAILDIR`, `DEFAULT`, `LOGFILE` variables.
- **Dovecot Sieve config** — in `90-sieve.conf` or `20-lmtp.conf`: `plugin { sieve = file:~/sieve;active=~/.dovecot.sieve }`. `sieve_before`/`sieve_after` for global scripts (admin-enforced). `sievec` to compile scripts. `sieve-test` to test without delivering.

---

## 211.3 Managing Mailbox Access (weight: 2)

**Description:** Candidates should be able to install and configure POP and IMAP daemons.

**Key Knowledge Areas:**
- Dovecot IMAP and POP3 configuration and administration
- Basic TLS configuration for Dovecot
- Awareness of Courier

**Files, terms and utilities:**
- `/etc/dovecot/`
- `dovecot.conf`
- `doveconf`
- `doveadm`

### Exam focus areas

- **Dovecot config** — main file: `/etc/dovecot/dovecot.conf`, includes from `conf.d/` directory. Key files: `10-auth.conf` (authentication), `10-mail.conf` (mail location), `10-ssl.conf` (TLS), `10-master.conf` (listeners), `20-imap.conf`, `20-pop3.conf`.
- **Protocols** — `protocols = imap pop3 lmtp` in dovecot.conf. IMAP (port 143, STARTTLS; 993 IMAPS). POP3 (port 110, STARTTLS; 995 POP3S). LMTP (local mail delivery).
- **Mail location** — `mail_location = maildir:~/Maildir` (Maildir format, one file per message) or `mail_location = mbox:~/mail:INBOX=/var/mail/%u` (mbox format, all messages in one file). Maildir structure: `cur/`, `new/`, `tmp/`. `%u` = full username, `%n` = user part, `%d` = domain part.
- **TLS configuration** — in `10-ssl.conf`:
  ```
  ssl = required    # yes/no/required
  ssl_cert = </etc/ssl/certs/dovecot.pem
  ssl_key = </etc/ssl/private/dovecot.key
  ssl_min_protocol = TLSv1.2
  ```
  Note the `<` prefix — it means read from file (Dovecot-specific syntax).
- **Authentication** — `auth_mechanisms = plain login` (PLAIN and LOGIN, require TLS). `10-auth.conf` includes auth sources: `auth-passwdfile.conf.ext`, `auth-system.conf.ext` (PAM/passwd), `auth-ldap.conf.ext`, `auth-sql.conf.ext`. `disable_plaintext_auth = yes` (default, require TLS for plain auth).
- **`doveconf`** — show effective configuration. `doveconf -n` (show only non-defaults, most useful). `doveconf -a` (show all). `doveconf mail_location` (specific setting).
- **`doveadm`** — administration tool. `doveadm mailbox list -u user` (list mailboxes), `doveadm search -u user mailbox INBOX` (search), `doveadm expunge -u user mailbox Trash savedbefore 30d` (delete old mail), `doveadm purge -u user` (purge deleted messages from mdbox), `doveadm force-resync -u user INBOX` (fix corruption), `doveadm pw -s SSHA256` (generate password hash), `doveadm reload` (reload config), `doveadm who` (show connected users).
- **Courier awareness** — alternative IMAP/POP3 server. Config in `/etc/courier/`. `imapd`, `pop3d` daemons. `authdaemonrc` for authentication. Uses Maildir format. Less common than Dovecot in modern deployments.
- **Namespaces** — Dovecot namespaces control mailbox hierarchy. `namespace inbox { inbox = yes; separator = / }`. Shared namespaces for shared folders, public namespaces for public folders.
