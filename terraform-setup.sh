#!/bin/bash
set -e

GREEN='\033[0;32m'
NC='\033[0m'

log() {
  echo -e "${GREEN} $1${NC}"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_amazon_linux() {
  grep -qi "amazon" /etc/os-release
}

get_fedora_version() {
  grep -oP '(?<=VERSION_ID=)[0-9]+' /etc/os-release
}

if command_exists terraform; then
  echo "Terraform is already installed"
else
  if is_amazon_linux; then
    log "Amazon Linux detected. Installing Terraform..."
    sudo yum install -y yum-utils shadow-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
    sudo yum install terraform

  elif command_exists apt; then
    log "Debian/Ubuntu detected. Installing Terraform..."
    wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    sudo apt update && sudo apt install terraform

  elif command_exists dnf; then
    FEDORA_VERSION=$(get_fedora_version)
    if [ "$FEDORA_VERSION" -eq 41 ]; then
      log "Fedora 41 detected. Installing Terraform..."
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
      sudo dnf -y install terraform
    elif [ "$FEDORA_VERSION" -ge 42 ]; then
      log "Fedora 42+ detected. Installing Terraform..."
      wget -O- https://rpm.releases.hashicorp.com/fedora/hashicorp.repo | sudo tee /etc/yum.repos.d/hashicorp.repo
      sudo yum list available | grep hashicorp
      sudo dnf -y install terraform
    else
      log "RHEL/Fedora detected but version not explicitly handled. Attempting generic install..."
      sudo dnf install -y dnf-plugins-core
      sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
      sudo dnf -y install terraform
    fi

  elif command_exists yum; then
    log "RHEL/CentOS 7 detected. Installing Terraform..."
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
    sudo yum -y install terraform

  else
    log "No supported package manager found. Aborting."
    exit 1
  fi
fi

log "Terraform installation complete. Checking version..."
terraform version
