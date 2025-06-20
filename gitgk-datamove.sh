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

echo "Stopping services..."
systemctl stop gitea || true
systemctl stop mariadb || true

echo "Creating destination directories..."
mkdir -p "$GITEA_DEST"
mkdir -p "$MYSQL_DEST"

echo "Moving Gitea data to $GITEA_DEST"
rsync -av "$GITEA_SRC/" "$GITEA_DEST/"
chown -R gitea:gitea "$GITEA_DEST"

echo "Moving MariaDB data to $MYSQL_DEST"
rsync -av "$MYSQL_SRC/" "$MYSQL_DEST/"
chown -R mysql:mysql "$MYSQL_DEST"

echo "Updating MariaDB config..."
cp "$MYSQL_CONFIG" "$MYSQL_CONFIG.bak"
sed -i "s|^datadir\s*=.*|datadir = $MYSQL_DEST|" "$MYSQL_CONFIG"

echo "Backing up original directories..."
mv "$GITEA_SRC" "${GITEA_SRC}.bak"
mv "$MYSQL_SRC" "${MYSQL_SRC}.bak"

echo "Creating symlinks..."
ln -s "$GITEA_DEST" "$GITEA_SRC"
ln -s "$MYSQL_DEST" "$MYSQL_SRC"

echo "Starting services..."
systemctl start mariadb
systemctl start gitea

echo ""
echo "✅ All gitGK data has been moved to $TARGET_BASE"
echo "Backups stored as:"
echo " - ${GITEA_SRC}.bak"
echo " - ${MYSQL_SRC}.bak"
echo ""
echo "IMPORTANT: To ensure the mounted disk is available after reboot,"
echo "           you must add an entry to /etc/fstab."
echo ""
echo "Example fstab line:"
echo "  /dev/sdX1  $TARGET_BASE  ext4  defaults  0  2"
echo ""
echo "Failure to do this before rebooting may prevent gitGK from starting."
