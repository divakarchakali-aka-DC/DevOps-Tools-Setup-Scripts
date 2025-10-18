#!/bin/bash
set -e

# --- Colors ---
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
warn()  { echo -e "${RED}[WARNING]${NC} $1"; }

# --- Function to check if a command exists ---
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_amazon_linux() {
  grep -qi "amazon" /etc/os-release
}

# --- Function to install Trivy ---
install_trivy() {
  if is_amazon_linux; then
    log "Amazon Linux detected. Installing Trivy"
    cat << EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
    sudo yum -y update
    sudo yum -y install trivy

  elif command_exists apt; then
    log "Debian/Ubuntu detected. Installing Trivy"
    sudo apt-get update
    sudo apt-get install -y wget gnupg
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" | sudo tee /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install -y trivy

  elif command_exists dnf; then
    log "RHEL/Fedora detected. Installing Trivy"
    cat << EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
    sudo dnf -y update
    sudo dnf -y install trivy

  elif command_exists yum; then
    log "RHEL/CentOS 7 detected. Installing Trivy"
    cat << EOF | sudo tee /etc/yum.repos.d/trivy.repo
[trivy]
name=Trivy repository
baseurl=https://aquasecurity.github.io/trivy-repo/rpm/releases/\$basearch/
gpgcheck=1
enabled=1
gpgkey=https://aquasecurity.github.io/trivy-repo/rpm/public.key
EOF
    sudo yum -y update
    sudo yum -y install trivy

  else
    error "No supported package manager found. Aborting."
  fi

  log "Trivy installation complete. Checking version..."
  trivy -v
}

# --- Main Execution ---
install_trivy
log "Setup complete."
