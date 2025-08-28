#!/bin/bash
set -e

# === Configurable Variables ===
JAVA_VERSION="17"
SONAR_VERSION="8.9.6.50800"
SONAR_ZIP="sonarqube-${SONAR_VERSION}.zip"
SONAR_URL="https://binaries.sonarsource.com/Distribution/sonarqube/${SONAR_ZIP}"
INSTALL_DIR="/opt"
SONAR_USER="sonar"

# === Colors ===
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

log()   { echo -e "${GREEN}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

is_amazon_linux() {
  grep -qi "amazon" /etc/os-release
}

# === Java Installation ===
install_java() {
  if command_exists java && java -version 2>&1 | grep -q "$JAVA_VERSION"; then
    log "Java $JAVA_VERSION already installed. Skipping installation."
  else
    if is_amazon_linux; then
      log "Amazon Linux detected. Installing Amazon Corretto..."
      yum update -y
      yum install java-${JAVA_VERSION}-amazon-corretto-devel -y
    elif command_exists apt; then
      log "Debian/Ubuntu detected. Installing OpenJDK..."
      apt update -y
      apt install openjdk-${JAVA_VERSION}-jdk -y
    elif command_exists dnf; then
      log "RHEL/Fedora detected. Installing OpenJDK..."
      dnf update -y
      dnf install java-${JAVA_VERSION}-openjdk -y
    elif command_exists yum; then
      log "RHEL/CentOS 7 detected. Installing OpenJDK..."
      yum update -y
      yum install java-${JAVA_VERSION}-openjdk -y
    else
      error "No supported package manager found. Aborting."
    fi
  fi

  log "Java installation complete. Checking version..."
  java -version
}

# === SonarQube Setup ===
install_sonarqube() {
  log "Installing dependencies..."
  if command_exists apt; then
    apt install -y unzip wget
  elif command_exists yum; then
    yum install -y unzip wget
  else
    dnf install -y unzip wget
  fi

  log "Downloading SonarQube..."
  cd "$INSTALL_DIR"
  wget "$SONAR_URL"
  unzip "$SONAR_ZIP"

  log "Creating sonar user..."
  useradd -m $SONAR_USER

  log "Setting permissions..."
  chown -R $SONAR_USER:$SONAR_USER "sonarqube-${SONAR_VERSION}"
  chmod -R 755 "sonarqube-${SONAR_VERSION}"

  log "Creating systemd service..."
  cat <<EOF > /etc/systemd/system/sonar.service
[Unit]
Description=SonarQube service
After=network.target

[Service]
Type=forking
User=$SONAR_USER
Group=$SONAR_USER
ExecStart=$INSTALL_DIR/sonarqube-${SONAR_VERSION}/bin/linux-x86-64/sonar.sh start
ExecStop=$INSTALL_DIR/sonarqube-${SONAR_VERSION}/bin/linux-x86-64/sonar.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

  log "Reloading systemd and starting SonarQube..."
  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable sonar
  systemctl start sonar || error "SonarQube failed to start"

  log "Installation complete. Access SonarQube at http://<your-server-ip>:9000"
  echo -e "${GREEN}Default credentials: username: admin / password: admin${NC}"
}

# === Main Execution ===
install_java
install_sonarqube