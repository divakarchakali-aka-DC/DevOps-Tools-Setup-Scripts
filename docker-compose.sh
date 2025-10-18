#!/bin/bash

set -e

echo "Fetching latest stable Docker Compose version..."

# Get all releases and filter out pre-releases
STABLE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases \
  | grep -E '"tag_name": "v[0-9]+\.[0-9]+\.[0-9]+"' \
  | grep -vE 'rc|alpha|beta' \
  | head -1 \
  | cut -d '"' -f4)

if [ -z "$STABLE_VERSION" ]; then
  echo "Failed to fetch stable version. Exiting."
  exit 1
fi

echo "Latest stable version is $STABLE_VERSION"

DOWNLOAD_URL="https://github.com/docker/compose/releases/download/$STABLE_VERSION/docker-compose-$(uname -s)-$(uname -m)"

echo "Downloading Docker Compose from $DOWNLOAD_URL"
sudo curl -L "$DOWNLOAD_URL" -o /usr/local/bin/docker-compose

echo "Verifying binary format..."
if ! file /usr/local/bin/docker-compose | grep -q 'ELF'; then
  echo "Download failed or incorrect file format. Aborting."
  sudo rm /usr/local/bin/docker-compose
  exit 1
fi

echo "Setting executable permissions..."
sudo chmod +x /usr/local/bin/docker-compose

echo "Installation complete. Version installed:"
docker-compose --version
