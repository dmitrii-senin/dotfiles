# Topic 208: HTTP Services

Official reference: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## 208.1 Basic Apache configuration (weight: 4)

**Description:** Candidates should be able to install and configure a web server. This objective includes monitoring the server's load and performance, restricting client user access, configuring support for scripting languages as modules and setting up client user authentication. Also included is configuring server options to restrict usage of resources. Candidates should be able to configure a web server to use virtual hosts and customize file access.

**Key Knowledge Areas:**
- Apache 2.4 configuration files, terms and utilities
- Apache log files configuration and content
- Access restriction methods and files
- mod_perl and PHP configuration
- Client user authentication files and utilities
- Configuration of maximum requests, minimum and maximum servers and clients
- Apache 2.4 virtual host implementation (with and without dedicated IP addresses)
- Using redirect statements in Apache's configuration files to customize file access

**Files, terms and utilities:**
- Access logs and error logs
- `.htaccess`
- `httpd.conf`
- `mod_auth_basic`, `mod_authz_host`, `mod_access_compat`
- `htpasswd`
- `AuthUserFile`, `AuthGroupFile`
- `apachectl`, `apache2ctl`
- `httpd`, `apache2`

### Exam focus areas

- **Configuration files** — Red Hat: `/etc/httpd/conf/httpd.conf`, modules in `/etc/httpd/conf.modules.d/`, sites in `/etc/httpd/conf.d/`. Debian: `/etc/apache2/apache2.conf`, sites in `sites-available/`+`sites-enabled/`, mods in `mods-available/`+`mods-enabled/`. Key directives: `ServerRoot`, `Listen`, `ServerName`, `DocumentRoot`, `DirectoryIndex`.
- **Log files** — `ErrorLog` directive (default: `/var/log/httpd/error_log` or `/var/log/apache2/error.log`). `LogLevel` (emerg, alert, crit, error, warn, notice, info, debug). Access log via `CustomLog` + `LogFormat`. Combined log format: `LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined`. `%h`=remote host, `%u`=user, `%t`=time, `%r`=request line, `%>s`=final status, `%b`=bytes. Log rotation: `rotatelogs` or external logrotate.
- **`.htaccess`** — per-directory config, read on every request (slower than main config). Enabled by `AllowOverride` (None, All, AuthConfig, FileInfo, Indexes, Limit, Options). `AllowOverride None` disables .htaccess entirely (recommended for performance). Common uses: authentication, URL rewriting, custom error pages.
- **Access control (Apache 2.4)** — uses `mod_authz_host` with `Require` directive. `Require all granted` (allow all), `Require all denied` (deny all), `Require ip 192.168.1.0/24`, `Require host example.com`, `Require not ip 10.0.0.1`. Wrap in `<RequireAll>`, `<RequireAny>`, `<RequireNone>` for complex logic. **Apache 2.2 (legacy)**: `Order Allow,Deny` / `Allow from` / `Deny from` via `mod_access_compat` — know the difference for exam.
- **Authentication (mod_auth_basic)** — HTTP Basic Auth setup in `<Directory>` or `.htaccess`:
  ```
  AuthType Basic
  AuthName "Restricted Area"
  AuthUserFile /etc/httpd/conf/.htpasswd
  AuthGroupFile /etc/httpd/conf/.htgroups
  Require user admin
  Require group developers
  Require valid-user
  ```
- **`htpasswd`** — manages password files. Flags: `-c` (create new file — CAUTION: overwrites existing!), `-m` (MD5 hash), `-B` (bcrypt, most secure), `-D` (delete user), `-b` (password on command line, less secure). Usage: `htpasswd -c /etc/httpd/.htpasswd user1` (first user, creates file), `htpasswd /etc/httpd/.htpasswd user2` (add user). File format: `username:password_hash`.
- **`AuthUserFile` / `AuthGroupFile`** — `AuthUserFile` points to htpasswd-created file. `AuthGroupFile` points to group file with format: `groupname: user1 user2 user3`. Used with `Require group groupname`.
- **mod_perl** — embeds Perl interpreter in Apache for performance. Config: `LoadModule perl_module modules/mod_perl.so`. Handler: `<Location /perl> SetHandler perl-script PerlResponseHandler MyApp </Location>`. `PerlRequire` to load startup scripts. Alternative to CGI for Perl apps.
- **PHP configuration** — as module: `LoadModule php_module modules/libphp.so` + `AddHandler php-script .php`. As FPM (FastCGI): `ProxyPassMatch ^/(.*\.php)$ fcgi://127.0.0.1:9000/var/www/html/$1`. PHP config: `php.ini`, `php_value`/`php_flag` directives in Apache config or `.htaccess`.
- **Performance tuning (MPM)** — Multi-Processing Modules: `prefork` (one process per connection, required for mod_php), `worker` (threads), `event` (async, best performance). Key directives: `StartServers`, `MinSpareServers`/`MaxSpareServers` (prefork), `MinSpareThreads`/`MaxSpareThreads` (worker/event), `MaxRequestWorkers` (max simultaneous connections), `MaxConnectionsPerChild` (requests before worker recycles, 0=unlimited), `ServerLimit`. `KeepAlive On/Off`, `MaxKeepAliveRequests`, `KeepAliveTimeout`.
- **Virtual hosts** — name-based (multiple domains on one IP, default in 2.4): `<VirtualHost *:80> ServerName www.example.com DocumentRoot /var/www/example </VirtualHost>`. IP-based (dedicated IP per site): `<VirtualHost 192.168.1.10:80>`. First VirtualHost is default for unmatched requests. `ServerAlias` for additional domain names. `a2ensite`/`a2dissite` on Debian.
- **Redirects** — `Redirect` (simple): `Redirect permanent /old /new` or `Redirect 301 /old http://new.example.com/`. `RedirectMatch` (regex). `mod_rewrite`: `RewriteEngine On`, `RewriteRule ^old(.*)$ /new$1 [R=301,L]`, `RewriteCond %{HTTP_HOST}`. Flags: `[R=301]` redirect, `[L]` last rule, `[P]` proxy, `[F]` forbidden.
- **`apachectl` / `apache2ctl`** — `start`, `stop`, `restart`, `graceful` (restart without dropping connections), `configtest` (syntax check), `status` (requires mod_status), `-t` (test config), `-S` (show virtual host settings), `-M` (list loaded modules).

---

## 208.2 Apache configuration for HTTPS (weight: 3)

**Description:** Candidates should be able to configure a web server to provide HTTPS.

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

### Exam focus areas

- **SSL/TLS setup** — requires `mod_ssl`. VirtualHost on port 443:
  ```
  <VirtualHost *:443>
      ServerName www.example.com
      SSLEngine on
      SSLCertificateFile /etc/ssl/certs/server.crt
      SSLCertificateKeyFile /etc/ssl/private/server.key
      SSLCACertificateFile /etc/ssl/certs/ca-bundle.crt
  </VirtualHost>
  ```
- **Key/CSR generation** — Private key: `openssl genrsa -out server.key 2048` (or `-aes256` for passphrase-protected). CSR: `openssl req -new -key server.key -out server.csr`. Self-signed: `openssl req -new -x509 -key server.key -out server.crt -days 365`. View cert: `openssl x509 -in server.crt -text -noout`. `CA.pl` is a wrapper script for openssl CA operations.
- **Certificate paths** — Debian: `/etc/ssl/certs/`, `/etc/ssl/private/`. Red Hat: `/etc/pki/tls/certs/`, `/etc/pki/tls/private/`. `SSLCACertificatePath` points to directory of hashed CA certs (use `c_rehash` to create hash symlinks).
- **SNI (Server Name Indication)** — allows multiple HTTPS virtual hosts on one IP. Client sends hostname in TLS handshake. Supported by all modern browsers/servers. Without SNI, only one SSL cert per IP was possible — this was the historical limitation.
- **Protocol/cipher hardening** — `SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1` (allow only TLSv1.2+). `SSLCipherSuite HIGH:!aNULL:!MD5:!RC4`. `SSLHonorCipherOrder on` (server preference). Know which protocols are insecure: SSLv2, SSLv3 (POODLE), TLSv1.0/1.1 (deprecated).
- **Security headers** — `ServerTokens Prod` (minimal server version in headers, options: Full/OS/Minimal/Minor/Major/Prod). `ServerSignature Off` (remove server info from error pages). `TraceEnable Off` (disable HTTP TRACE method, prevents XST attacks). `Header set X-Frame-Options SAMEORIGIN`, `Header set X-Content-Type-Options nosniff`.
- **HSTS** — `Header always set Strict-Transport-Security "max-age=31536000"` (force HTTPS for returning visitors).

---

## 208.3 Implementing Squid as a caching proxy (weight: 2)

**Description:** Candidates should be able to install and configure a proxy server, including access policies, authentication and resource usage.

**Key Knowledge Areas:**
- Squid 3.x configuration files, terms and utilities
- Access restriction methods
- Client user authentication methods
- Layout and content of ACL in the Squid configuration files

**Files, terms and utilities:**
- `squid.conf`
- `acl`
- `http_access`

### Exam focus areas

- **`squid.conf`** — main config file, typically `/etc/squid/squid.conf`. Key directives: `http_port 3128` (listening port), `cache_dir ufs /var/spool/squid 100 16 256` (type, path, size_MB, L1_dirs, L2_dirs), `cache_mem 256 MB`, `maximum_object_size`, `visible_hostname`.
- **ACL system** — two-step: define ACL, then apply with `http_access`. ACL types: `acl name src 192.168.1.0/24` (source IP), `acl name dst` (destination IP), `acl name dstdomain .example.com` (destination domain), `acl name port 443 8080` (port), `acl name proto HTTP HTTPS`, `acl name time MTWHF 08:00-17:00` (time-based), `acl name url_regex -i pattern`, `acl name srcdom_regex`. Built-in: `all` (all sources), `localhost`, `manager` (cache manager).
- **`http_access`** — processed top-to-bottom, first match wins. `http_access allow localnet`, `http_access deny all` (always put deny all at end). Order matters critically. `http_access allow manager localhost` + `http_access deny manager` = allow cache manager only from localhost.
- **Authentication** — `auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords`. `auth_param basic realm Squid Proxy`. `acl authenticated proxy_auth REQUIRED`. `http_access allow authenticated`. Supports basic, digest, NTLM, negotiate schemes.
- **Transparent proxy** — `http_port 3128 transparent` (or `intercept` in newer versions). Requires iptables redirect rule: `iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 3128`. Clients don't need proxy configuration.
- **Cache management** — `squidclient mgr:info` (cache statistics), `squid -k reconfigure` (reload config), `squid -k rotate` (rotate logs), `squid -z` (initialize cache directories).

---

## 208.4 Implementing Nginx as a web server and a reverse proxy (weight: 2)

**Description:** Candidates should be able to install and configure a reverse proxy server, Nginx. Basic configuration of Nginx as a HTTP server is included.

**Key Knowledge Areas:**
- Nginx
- Reverse Proxy
- Basic Web Server

**Files, terms and utilities:**
- `/etc/nginx/`
- `nginx`

### Exam focus areas

- **Config structure** — `/etc/nginx/nginx.conf` main file. Structure: `events { }` (connection processing), `http { }` (web server). Inside http: `server { }` blocks (virtual hosts), inside server: `location { }` blocks (URL matching). `include /etc/nginx/conf.d/*.conf;` for modular configs.
- **Basic web server** —
  ```
  server {
      listen 80;
      server_name www.example.com;
      root /var/www/html;
      index index.html;
      location / { try_files $uri $uri/ =404; }
  }
  ```
- **Reverse proxy** —
  ```
  location /app/ {
      proxy_pass http://backend:8080/;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Forwarded-Proto $scheme;
  }
  ```
  Trailing slash in `proxy_pass` matters — with slash, `/app/foo` → `/foo` on backend; without, `/app/foo` → `/app/foo`.
- **Location matching** — prefix match (default), `=` (exact), `~` (regex case-sensitive), `~*` (regex case-insensitive), `^~` (prefix, don't check regex). Priority: exact > `^~` prefix > regex > prefix.
- **Upstream / load balancing** — `upstream backend { server 10.0.0.1; server 10.0.0.2; }` then `proxy_pass http://backend;`. Methods: round-robin (default), `least_conn;`, `ip_hash;` (sticky sessions).
- **SSL in Nginx** —
  ```
  server {
      listen 443 ssl;
      ssl_certificate /etc/ssl/certs/server.crt;
      ssl_certificate_key /etc/ssl/private/server.key;
      ssl_protocols TLSv1.2 TLSv1.3;
  }
  ```
- **Control** — `nginx -t` (test config), `nginx -s reload` (reload), `nginx -s stop`, `nginx -s quit` (graceful).
- **Key differences from Apache** — event-driven (not process/thread per connection), no `.htaccess` equivalent, uses `location` blocks instead of `<Directory>`, config changes require reload.
