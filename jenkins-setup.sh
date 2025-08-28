#!/bin/bash
set -e

JAVA_VERSION="17"
CUSTOM_PORT="9090"  # Change this to your desired Jenkins port
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

install_java() {
  if command_exists java && java -version 2>&1 | grep -q "$JAVA_VERSION"; then
    log "Java $JAVA_VERSION already installed. Skipping installation."
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
      log "Fedora/RHEL (dnf) detected. Installing OpenJDK..."
      sudo dnf update -y
      sudo dnf install java-${JAVA_VERSION}-openjdk -y
    elif command_exists yum; then
      log "RHEL/CentOS (yum) detected. Installing OpenJDK..."
      sudo yum update -y
      sudo yum install java-${JAVA_VERSION}-openjdk -y
    else
      log "No supported package manager found. Aborting Java installation."
      exit 1
    fi
  fi
  log "Java installation complete. Checking version..."
  java -version
}

install_jenkins() {
  if command_exists apt; then
    log "Installing Jenkins on Debian/Ubuntu..."
    sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
      https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
    echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
      sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt-get update
    sudo apt-get install jenkins -y

  elif command_exists dnf; then
    log "Installing Jenkins on Fedora/RHEL (dnf)..."
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/redhat/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat/jenkins.io-2023.key
    sudo dnf upgrade -y
    sudo dnf install jenkins -y
    sudo systemctl daemon-reload

  elif command_exists yum || is_amazon_linux; then
    log "Installing Jenkins on RHEL/CentOS/Amazon Linux (yum)..."
    sudo wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/redhat-stable/jenkins.repo
    sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
    sudo yum upgrade -y
    sudo yum install jenkins -y
    sudo systemctl daemon-reload

  else
    log "No supported package manager found. Aborting Jenkins installation."
    exit 1
  fi

  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  sudo systemctl status jenkins
  log "Admin Password:"
  sudo cat /var/lib/jenkins/secrets/initialAdminPassword
}

# Execute installations
install_java
install_jenkins