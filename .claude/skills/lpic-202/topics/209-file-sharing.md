# Topic 209: File Sharing

Official reference: https://www.lpi.org/our-certifications/exam-201-202-objectives/

---

## 209.1 Samba Server Configuration (weight: 5)

**Description:** Candidates should be able to set up a Samba server for various clients. This objective includes setting up Samba as a standalone server as well as integrating Samba as a member in an Active Directory. Furthermore, the configuration of simple CIFS and printer shares is covered. Also covered is configuring a Linux client to use a Samba server. Troubleshooting installations is also tested.

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

### Exam focus areas

- **Daemons** — `smbd` (file/print sharing, authentication, port 445/139), `nmbd` (NetBIOS name service, browsing, port 137/138), `winbindd` (maps Windows SIDs to Unix UIDs/GIDs, needed for AD integration).
- **`/etc/samba/smb.conf`** — sections: `[global]` (server-wide settings), `[homes]` (auto-create home shares), `[printers]` (auto-create printer shares), `[sharename]` (custom shares). Key global directives: `workgroup`, `server string`, `security` (user/ads/domain), `map to guest` (Bad User), `log file`, `log level`, `interfaces`, `bind interfaces only`.
- **Share configuration** —
  ```
  [data]
      path = /srv/samba/data
      browseable = yes
      read only = no
      valid users = @staff
      write list = admin
      create mask = 0660
      directory mask = 0770
      guest ok = no
  ```
  `valid users` (who can connect), `write list` (who can write even if read only=yes), `read list`, `force user`/`force group`, `hosts allow`/`hosts deny`.
- **`testparm`** — validates smb.conf syntax and shows effective config. `testparm -s` (suppress prompt). Always run after editing smb.conf.
- **`smbpasswd`** — manages Samba password database. `-a user` (add user, must exist in /etc/passwd first), `-x user` (delete), `-d user` (disable), `-e user` (enable). `pdbedit` is the newer alternative: `pdbedit -L` (list users), `pdbedit -a user`.
- **`smbclient`** — FTP-like client for SMB shares. `smbclient //server/share -U user`. Commands: `ls`, `get`, `put`, `mkdir`, `cd`. `smbclient -L server` (list shares). `-N` for no password (anonymous).
- **`mount.cifs`** — `mount -t cifs //server/share /mnt/point -o username=user,password=pass,domain=WORKGROUP`. In fstab: `//server/share /mnt/point cifs credentials=/etc/samba/creds,uid=1000,gid=1000 0 0`. Credentials file: `username=user\npassword=pass` (chmod 600).
- **`smbstatus`** — shows current connections, locked files, share access. `-b` (brief), `-S` (shares only).
- **`nmblookup`** — NetBIOS name queries. `nmblookup -A IP` (adapter status), `nmblookup hostname`.
- **`samba-tool`** — Samba AD DC management. `samba-tool domain provision`, `samba-tool user create`, `samba-tool dns`, `samba-tool group`.
- **`net`** — `net ads join -U admin` (join AD domain), `net ads info`, `net ads testjoin`. `net rpc` for older NT domains.
- **AD integration** — `security = ads`, `realm = EXAMPLE.COM`, `idmap config * : backend = tdb`, `idmap config EXAMPLE : backend = rid`, `idmap config EXAMPLE : range = 10000-999999`. Requires `winbindd` running, Kerberos configured (`/etc/krb5.conf`), join with `net ads join`.
- **User mapping** — `username map = /etc/samba/smbusers`. File format: `unixuser = WindowsUser`. `idmap` for automatic mapping in AD environments.
- **Printer sharing** — `[printers]` section auto-shares CUPS printers. `load printers = yes`, `printing = cups`, `printcap name = cups`. `cupsaddsmb` for driver distribution.

---

## 209.2 NFS Server Configuration (weight: 3)

**Description:** Candidates should be able to export filesystems using NFS. This objective includes access restrictions, mounting an NFS filesystem on a client and securing NFS.

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

### Exam focus areas

- **`/etc/exports`** — defines NFS shares. Format: `/path client(options) client2(options)`. Example: `/data 192.168.1.0/24(rw,sync,no_subtree_check) 10.0.0.5(ro)`. Key options: `rw`/`ro` (read-write/read-only), `sync`/`async` (sync is safer), `no_root_squash` (allow remote root to be root — security risk), `root_squash` (default: map root to nobody), `all_squash` (map all users to nobody), `anonuid`/`anongid` (UID/GID for squashed users), `no_subtree_check` (recommended, avoids issues with renamed files).
  **CAUTION:** space between client and options means different things: `host(rw)` = rw for host; `host (rw)` = rw for everyone, nothing special for host.
- **`exportfs`** — manages exported filesystems. `-a` (export all from /etc/exports), `-r` (re-export/refresh), `-u` (unexport), `-v` (verbose, show current exports). `exportfs -ra` after editing /etc/exports.
- **`showmount`** — queries NFS server. `-e server` (show exports), `-a server` (show all mount points), `-d server` (show only directories being mounted).
- **NFS daemons** — `rpcbind`/`portmapper` (maps RPC services to ports, must start first), `nfsd` (handles NFS requests), `mountd` (handles mount requests, checks /etc/exports), `lockd`/`statd` (file locking). Start with `systemctl start nfs-server`.
- **Client mounting** — `mount -t nfs server:/path /mnt/point`. Options: `mount -t nfs -o rw,hard,intr,timeo=600 server:/data /mnt/data`. In fstab: `server:/data /mnt/data nfs rw,hard,intr 0 0`. `hard` (retry indefinitely) vs `soft` (return error after timeout). `intr` (allow interrupts during hard mount). `bg` (background mount if server unavailable).
- **`nfsstat`** — NFS statistics. `-s` (server stats), `-c` (client stats), `-m` (mounted NFS info). Useful for troubleshooting performance.
- **`rpcinfo`** — shows registered RPC services. `rpcinfo -p [host]` (list all), `rpcinfo -u host nfs` (check UDP NFS), `rpcinfo -t host nfs` (check TCP NFS).
- **TCP Wrappers** — `/etc/hosts.allow` and `/etc/hosts.deny` for access control. `portmap: 192.168.1.0/255.255.255.0` in hosts.allow. Checked by rpcbind/portmapper. Format: `daemon: client_list`. Processed hosts.allow first, then hosts.deny. If not in either, access allowed.
- **NFSv4** — single port (2049), no rpcbind needed. Uses pseudo-filesystem (fsid=0 for root export). Kerberos support for authentication. ID mapping via `idmapd`. Export syntax slightly different: `fsid=root` or `fsid=0` for root.
