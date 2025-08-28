#!/bin/bash
set -e

JAVA_VERSION="17"
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

if command_exists java && java -version 2>&1 | grep -q "17"; then
  log "Java 17 already installed. Skipping installation."
else
  if is_amazon_linux; then
    log "Amazon Linux detected. Installing Amazon Corretto..."
    sudo yum update -y
    sudo yum install java-${JAVA_VERSION}-amazon-corretto-devel -y
  elif command_exists apt; then
    log "Debian/Ubuntu detected. Installing OpenJDK..."
    sudo apt update -y
    sudo apt install openjdk-${JAVA_VERSION}-jdk -y
  elif command_exists dnf; then
    log "RHEL/Fedora detected. Installing OpenJDK..."
    sudo dnf update -y
    sudo dnf install java-${JAVA_VERSION}-openjdk -y
  elif command_exists yum; then
    log "RHEL/CentOS 7 detected. Installing OpenJDK..."
    sudo yum update -y
    sudo yum install java-${JAVA_VERSION}-openjdk -y
  else
    log "No supported package manager found. Aborting."
    exit 1
  fi
fi

log "Java installation complete. Checking version..."
java -version