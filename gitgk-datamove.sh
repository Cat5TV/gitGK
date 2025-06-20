#!/bin/bash
# gitgk-datamove.sh - Moves Gitea and MariaDB data to mounted external storage (e.g., VHD)
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

# === Configurable Variables ===
TARGET_BASE="${1}"

if [[ -z "$TARGET_BASE" ]] || [[ ! -d "$TARGET_BASE" ]]; then
  echo "Usage: sudo ./gitgk-datamove.sh /mnt/your-mounted-disk"
  echo ""
  echo "This script will move all gitGK data to the given target directory."
  echo "Make sure the disk is mounted first. Example:"
  echo ""
  echo "  sudo mount /dev/sdb1 /mnt/gitgk-data"
  echo ""
  echo "Then run:"
  echo "  sudo ./gitgk-datamove.sh /mnt/gitgk-data"
  echo ""
  echo "IMPORTANT: If you reboot your system without mounting this path again,"
  echo "           gitGK will FAIL TO START. You must add an fstab entry first."
  echo ""
  echo "Example fstab entry:"
  echo "  /dev/sdX1  /mnt/gitgk-data  ext4  defaults  0  2"
  echo ""
  exit 1
fi

GITEA_SRC="/var/lib/gitea/data"
MYSQL_SRC="/var/lib/mysql"
GITEA_DEST="$TARGET_BASE/data"
MYSQL_DEST="$TARGET_BASE/mysql"
MYSQL_CONFIG="/etc/mysql/mariadb.conf.d/50-server.cnf"

# Ensure root
if [[ $EUID -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi


# === Determine what to move ===
echo ""
read -p "Would you like to move Gitea repository data to $TARGET_BASE? [y/N]: " MOVE_GITEA
read -p "Would you like to move MariaDB database data to $TARGET_BASE? [y/N]: " MOVE_MYSQL

echo "Stopping services..."
systemctl stop gitea || true
systemctl stop mariadb || true

# === Gitea Data ===
if [[ "$MOVE_GITEA" =~ ^[Yy]$ ]]; then
  if mountpoint -q "$GITEA_SRC" || df "$GITEA_SRC" | grep -q "$TARGET_BASE"; then
    echo "Gitea data already resides on the target mount. Skipping Gitea move."
  else
    echo "Moving Gitea data to $GITEA_DEST"
    mkdir -p "$GITEA_DEST"
    rsync -av "$GITEA_SRC/" "$GITEA_DEST/"
    chown -R gitea:gitea "$GITEA_DEST"
    mv "$GITEA_SRC" "${GITEA_SRC}.bak"
    ln -s "$GITEA_DEST" "$GITEA_SRC"
  fi
else
  echo "Skipping Gitea data move."
fi

# === MariaDB Data ===
if [[ "$MOVE_MYSQL" =~ ^[Yy]$ ]]; then
  echo "Moving MariaDB data to $MYSQL_DEST"
  mkdir -p "$MYSQL_DEST"
  rsync -av "$MYSQL_SRC/" "$MYSQL_DEST/"
  chown -R mysql:mysql "$MYSQL_DEST"
  cp "$MYSQL_CONFIG" "$MYSQL_CONFIG.bak"
  sed -i "s|^datadir\s*=.*|datadir = $MYSQL_DEST|" "$MYSQL_CONFIG"
  mv "$MYSQL_SRC" "${MYSQL_SRC}.bak"
  ln -s "$MYSQL_DEST" "$MYSQL_SRC"
else
  echo "Skipping MariaDB data move."
fi

# === Restart services ===
echo "Starting services..."
systemctl start mariadb
systemctl start gitea

echo ""
echo "Selected gitGK data has been moved to $TARGET_BASE (if requested)"
echo "IMPORTANT: Ensure this mount is present before reboot or services may fail."
echo "Example fstab line:"
echo "  /dev/sdX1  $TARGET_BASE  ext4  defaults  0  2"

