# gitGK Git Appliance

**gitGK** is a secure, self-hosted Git appliance based on Gitea, pre-configured to run on Debian Linux. It was created by Robbie Ferguson at **Category5 TV Network** to provide a fast, open-source alternative to GitHub and GitLab — with full control and zero vendor lock-in.

![gitGK Logo](./img/gitGK.svg)

---

## 🚀 Features

- Fully automated install in minutes
- Secure-by-default configuration
- Gitea web UI (GitHub-style)
- MariaDB database backend
- NGINX reverse proxy
- Optional HTTPS via Let's Encrypt
- Automatic security updates enabled

---

## 🛠️ Installation

### Step 1: Download the Installer

```bash
wget https://raw.githubusercontent.com/Cat5TV/gitGK/refs/heads/main/install-gitgk.sh
chmod +x install-gitgk.sh
```

### Step 2: Run it

With a domain name:

```bash
sudo ./install-gitgk.sh git.example.com
```

Or just use your server's IP:

```bash
sudo ./install-gitgk.sh
```

This will install:
- Git
- Gitea (latest release)
- MariaDB
- NGINX (preconfigured for secure web UI access)
- Automatic security updates

It will also:
- Create system users
- Set up services with `systemd`
- Launch the Gitea web UI (default port: 3000 or as configured)

---

## 📂 Post-Install Info

- Web UI: Visit `http://yourdomain` or `http://your-server-ip`
- Admin account setup is completed via the browser
- MariaDB password saved to: `/root/gitea-db-password.txt`
- Repo data stored in: `/var/lib/gitea`
- Configuration in: `/etc/gitea/`

---

## 🔀 Step 3 (Optional): Move gitGK Data to External Disk

You can move all persistent gitGK data (repos + database) to a mounted external volume, such as a second VHD.

This step is for advanced users only, and the following commands are only examples.

### Step-by-step:

1. Mount your external storage to a path like `/mnt/gitgk-data`:
```bash
sudo mount /dev/sdb1 /mnt/gitgk-data
```

2. Run the migration script:
```bash
wget https://raw.githubusercontent.com/Cat5TV/gitGK/refs/heads/main/gitgk-datamove.sh
chmod +x gitgk-datamove.sh
sudo ./gitgk-datamove.sh /mnt/gitgk-data
```

This will:
- Stop services
- Move Gitea data and MariaDB data to the mounted volume
- Update the MariaDB config
- Replace original data folders with symlinks
- Restart services

⚠️ **IMPORTANT**  
You must add the mount to `/etc/fstab` to ensure it is mounted again after reboot.  
Failing to do so will prevent gitGK from starting after a reboot.

Example `/etc/fstab` entry:
```
/dev/sdb1  /mnt/gitgk-data  ext4  defaults  0  2
```

---

## 🛡️ Security

- Unattended security updates are **enabled**
- MariaDB runs with a strong root password (generated during install)
- Gitea runs under a limited system user
- All services are managed with `systemd`
- A firewall is recommended (not configured by default)
- Automatic security updates are enabled

---

## 🔄 Backups

You can include this server in your existing `rdiff-backup` or snapshot routines.  

Make sure to include:
- `/var/lib/gitea` (or your mounted data location)
- `/var/lib/mysql` (or your mounted data location)
- `/etc/gitea/` and `/etc/mysql/`

---

## 📜 License

Licensed under the **Apache License 2.0**  
(c) 2025 Robbie Ferguson  
**Category5 TV Network**
