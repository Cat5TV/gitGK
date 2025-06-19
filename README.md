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

### Step 1: Download the script

```bash
wget https://raw.githubusercontent.com/Cat5TV/gitGeek/refs/heads/main/install-gitgk.sh
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

---

## 📂 Post-Install Info

- Web UI: Visit `http://yourdomain` or `http://your-server-ip`
- Admin account setup is completed via the browser
- MariaDB password saved to: `/root/gitea-db-password.txt`
- Repo data stored in: `/var/lib/gitea`
- Configuration in: `/etc/gitea/`

---

## 🛡️ Security & Backups

- Unattended security updates are **enabled**
- All ports other than 22 and 80/443 can be firewalled off
- Recommended backups:
  - `/var/lib/gitea/`
  - `/etc/gitea/`
  - MariaDB `gitea` DB (daily `mysqldump`)

---

## 📜 License

Licensed under the **Apache License 2.0**  
(c) 2025 Robbie Ferguson  
**Category5 TV Network**
