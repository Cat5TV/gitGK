#!/bin/bash
# install-gitgk.sh - Installer for gitGK Git Appliance
#
# Copyright 2025 Robbie Ferguson
# Category5 TV Network
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# === Configuration ===
DOMAIN=${1:-}  # Optional: pass domain as first argument
if [ -z "$DOMAIN" ]; then
  DOMAIN=$(hostname -I | awk '{print $1}')
  echo "No domain provided, using IP: $DOMAIN"
fi

GITEA_USER="gitea"
GITEA_DB="gitea"
GITEA_DB_USER="gitea"
GITEA_DB_PASS="$(openssl rand -base64 32)"
GITEA_VERSION="1.24.1"

# === Confirm root privileges ===
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run this script as root or with sudo."
  exit 1
fi

echo "Updating system and installing required packages..."
apt update
DEBIAN_FRONTEND=noninteractive apt install -y \
  git \
  wget \
  curl \
  mariadb-server \
  nginx \
  certbot \
  python3-certbot-nginx \
  openssl \
  unattended-upgrades \
  apt-listchanges

echo "Enabling automatic security updates..."
dpkg-reconfigure -f noninteractive unattended-upgrades

# === Setup Gitea Users and Directories ===
echo "Creating system users..."
id git >/dev/null 2>&1 || adduser --system --group --home /home/git --shell /bin/bash git
id "$GITEA_USER" >/dev/null 2>&1 || adduser --system --group --home /home/gitea --shell /bin/bash "$GITEA_USER"

echo "Setting up gitGK directories..."
mkdir -p /var/lib/gitea/{custom,data,log}
mkdir -p /etc/gitea
chown -R $GITEA_USER:$GITEA_USER /var/lib/gitea
chown root:$GITEA_USER /etc/gitea
chmod -R 750 /var/lib/gitea
chmod 770 /etc/gitea

echo "Installing Gitea binary..."
echo "Downloading Gitea binary..."
GITEA_BINARY_URL="https://dl.gitea.com/gitea/1.24.1/gitea-${GITEA_VERSION}-linux-amd64"
wget -q --show-progress -O /usr/local/bin/gitea "$GITEA_BINARY_URL"

if [[ ! -x /usr/local/bin/gitea ]]; then
  chmod +x /usr/local/bin/gitea
fi

if ! /usr/local/bin/gitea --version &>/dev/null; then
  echo "Failed to install Gitea. Check your network connection or the URL."
  exit 1
else
  echo "Gitea installed: version $(/usr/local/bin/gitea --version)"
fi

echo "Creating Gitea systemd service..."
cat > /etc/systemd/system/gitea.service <<EOF
[Unit]
Description=Gitea (Git with a cup of tea)
After=network.target

[Service]
RestartSec=2s
Type=simple
User=$GITEA_USER
Group=$GITEA_USER
WorkingDirectory=/var/lib/gitea/
ExecStart=/usr/local/bin/gitea web --config /etc/gitea/app.ini
Restart=always
Environment=USER=$GITEA_USER HOME=/home/$GITEA_USER GITEA_WORK_DIR=/var/lib/gitea

[Install]
WantedBy=multi-user.target
EOF

echo "Starting Gitea service..."
systemctl daemon-reexec
systemctl enable --now gitea

# === MariaDB Setup ===
echo "Setting up MariaDB database..."
mysql -e "
CREATE DATABASE IF NOT EXISTS \`$GITEA_DB\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '$GITEA_DB_USER'@'localhost' IDENTIFIED BY '$GITEA_DB_PASS';
GRANT ALL PRIVILEGES ON \`$GITEA_DB\`.* TO '$GITEA_DB_USER'@'localhost';
FLUSH PRIVILEGES;"

echo "$GITEA_DB_PASS" > /root/gitea-db-password.txt
chmod 600 /root/gitea-db-password.txt
echo "MariaDB credentials saved to /root/gitea-db-password.txt"

# === NGINX Reverse Proxy Setup ===
echo "Configuring NGINX reverse proxy..."
cat > /etc/nginx/sites-available/gitea <<EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/gitea /etc/nginx/sites-enabled/gitea
nginx -t && systemctl reload nginx

# === Let's Encrypt Setup (optional, only for FQDN) ===
if [[ "$DOMAIN" != *[0-9]* ]]; then
  echo "Attempting HTTPS setup with Let's Encrypt for domain: $DOMAIN"
  certbot --non-interactive --nginx --agree-tos -d "$DOMAIN" -m admin@"$DOMAIN" || echo "Certbot failed; skipping SSL"
else
  echo "Domain appears to be an IP address. Skipping SSL certificate setup."
fi

# === Final Notes ===
echo ""
echo "======================================================="
echo "gitGK Git Appliance Installed Successfully"
echo ""
echo "Web UI:     http://$DOMAIN"
echo "Repo Path:  /var/lib/gitea"
echo "MariaDB:    User '$GITEA_DB_USER', database '$GITEA_DB'"
echo "Credentials saved to: /root/gitea-db-password.txt"
echo "Auto Security Updates: ENABLED"
echo ""
echo "Next Steps:"
echo "- Visit the web interface to complete the admin setup."
echo "- Consider configuring HTTPS if you used an IP."
echo "- Schedule backups of /etc/gitea, /var/lib/gitea, and the DB."
echo "======================================================="
