#!/bin/bash
# gitgk-host.sh - Fixes hardcoded IPs in gitGK configs after IP change or domain assignment
#
# Copyright 2025 Robbie Ferguson
# Category5 TV Network
#
# Licensed under the Apache License, Version 2.0

set -e

GITEA_CONFIG="/etc/gitea/app.ini"
NGINX_CONFIG="/etc/nginx/sites-available/gitea"

# Ask user if they want to use a domain
read -p "Would you like to use a domain name instead of your IP? [y/N]: " USE_DOMAIN

if [[ "$USE_DOMAIN" =~ ^[Yy]$ ]]; then
  read -p "Enter your domain name (e.g., git.example.com): " NEW_HOST
else
  # Get the current IP address (first non-loopback)
  NEW_HOST=$(hostname -I | awk '{print $1}')
  if [[ -z "$NEW_HOST" ]]; then
    echo "Unable to determine the current IP address."
    exit 1
  fi
fi

echo "New hostname to configure: $NEW_HOST"

# Check if the new host is already in use
if grep -q "$NEW_HOST" "$GITEA_CONFIG" && grep -q "$NEW_HOST" "$NGINX_CONFIG"; then
  echo "Config files already use this host. No changes needed."
  exit 0
fi

# Detect old IP or host in the config files (excluding loopback and localhost)
OLD_HOST=$(grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$GITEA_CONFIG" | grep -v '127.0.0.1' | head -n 1)
if [[ -z "$OLD_HOST" ]]; then
  OLD_HOST=$(grep -Eo '([a-zA-Z0-9.-]+\.[a-zA-Z]{2,6})' "$GITEA_CONFIG" | grep -v 'localhost' | head -n 1)
fi

if [[ -z "$OLD_HOST" ]]; then
  echo "Could not detect the current configured host."
  read -p "Please enter the host (IP or domain) to replace: " OLD_HOST
fi

echo "Replacing $OLD_HOST with $NEW_HOST in config files..."

# Replace in Gitea app.ini
sed -i "s/$OLD_HOST/$NEW_HOST/g" "$GITEA_CONFIG"

# Replace in NGINX config
sed -i "s/$OLD_HOST/$NEW_HOST/g" "$NGINX_CONFIG"

# Restart services
echo "Restarting Gitea and NGINX..."
systemctl restart gitea
systemctl reload nginx

echo "Hostname/IP successfully updated to: $NEW_HOST"
