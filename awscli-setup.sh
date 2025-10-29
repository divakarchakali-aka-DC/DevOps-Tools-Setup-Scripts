#!/bin/bash
# AWS CLI v2 Minimal Installer - Supports all major Linux distributions

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

error() { echo -e "${RED}ERROR: $1${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}INFO: $1${NC}"; }

[ "$(id -u)" -ne 0 ] && error "Run as root: sudo ./$(basename "$0")"

[ -f /etc/os-release ] || error "Cannot detect OS"
. /etc/os-release
OS_ID=$ID

info "Detected: $PRETTY_NAME"

install_via_zip() {
    info "Installing AWS CLI v2 via official ZIP"
    if command -v apt &>/dev/null; then
        apt update -y && apt install -y curl unzip
    elif command -v dnf &>/dev/null; then
        dnf install -y curl unzip
    elif command -v yum &>/dev/null; then
        yum install -y curl unzip
    fi
    
    curl -fL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    ./aws/install
    rm -rf awscliv2.zip aws
}

case "$OS_ID" in
    rhel|centos|ol|fedora|amzn|ubuntu|debian)
        install_via_zip
        ;;
    *)
        error "Unsupported OS: $OS_ID"
        ;;
esac

# Fix PATH if needed
[ -f "/usr/local/bin/aws" ] && [ ! -f "/usr/bin/aws" ] && ln -sf /usr/local/bin/aws /usr/bin/aws

info "Verifying installation..."
aws --version && info "AWS CLI installed successfully"
