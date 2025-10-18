#!/bin/bash
set -e

# --- Variables ---
# Define variables for easier maintenance. You can change these values as needed.
TOMCAT_VERSION="9.0.111"
TOMCAT_ARCHIVE="apache-tomcat-${TOMCAT_VERSION}.tar.gz"
TOMCAT_DOWNLOAD_URL="https://dlcdn.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/${TOMCAT_ARCHIVE}"
TOMCAT_DIR="apache-tomcat-${TOMCAT_VERSION}"
TOMCAT_USER="tomcat"
TOMCAT_PASS="admin@123"
TOMCAT_PORT="8080" #Change Port here
INSTALL_DIR="/opt"

# Set the specific Java JDK version to install.
JAVA_VERSION="17"

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

# --- Function to install Java ---
install_java() {
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
      error "No supported package manager found. Aborting."
    fi
  fi
  log "Java installation complete. Checking version..."
  java -version
}

# --- Main Script Execution ---

# Step 1: Install Java, the prerequisite for Tomcat.
install_java

# Step 2: Create a dedicated user for Tomcat (for security).
log "Checking for '$TOMCAT_USER' user..."
if id "$TOMCAT_USER" >/dev/null 2>&1; then
    warn "User '$TOMCAT_USER' already exists. Skipping creation."
else
    log "Creating '$TOMCAT_USER' user and group..."
    sudo useradd -r -s /bin/false "$TOMCAT_USER"
fi

# Step 3: Download and extract the Apache Tomcat archive.
log "Downloading Apache Tomcat version ${TOMCAT_VERSION}..."
sudo wget "${TOMCAT_DOWNLOAD_URL}" -O /tmp/"${TOMCAT_ARCHIVE}"

log "Extracting the archive to ${INSTALL_DIR}..."
sudo tar -zxvf /tmp/"${TOMCAT_ARCHIVE}" -C "${INSTALL_DIR}"

# Step 4: Set correct permissions and ownership.
log "Setting ownership of Tomcat directory to '$TOMCAT_USER'..."
sudo chown -R "${TOMCAT_USER}":"${TOMCAT_USER}" "${INSTALL_DIR}/${TOMCAT_DIR}"

# Step 5: Configure the Tomcat Manager user and roles.
log "Configuring Tomcat user roles..."
sudo sed -i '/<\/tomcat-users>/i\  <role rolename="manager-gui"/>' "${INSTALL_DIR}/${TOMCAT_DIR}/conf/tomcat-users.xml"
sudo sed -i '/<\/tomcat-users>/i\  <role rolename="manager-script"/>' "${INSTALL_DIR}/${TOMCAT_DIR}/conf/tomcat-users.xml"
sudo sed -i '/<\/tomcat-users>/i\  <user username="'${TOMCAT_USER}'" password="'${TOMCAT_PASS}'" roles="manager-gui, manager-script"/>' "${INSTALL_DIR}/${TOMCAT_DIR}/conf/tomcat-users.xml"

# Step 6: Enable remote access to the Tomcat Manager GUI.
log "Enabling remote access to Tomcat Manager GUI..."
sudo sed -i '/RemoteAddrValve/d' "${INSTALL_DIR}/${TOMCAT_DIR}/webapps/manager/META-INF/context.xml"

# Step 7: Configure the Tomcat port.
log "Configuring Tomcat port to ${TOMCAT_PORT}..."
sudo sed -i "s/port=\"8080\"/port=\"${TOMCAT_PORT}\"/g" "${INSTALL_DIR}/${TOMCAT_DIR}/conf/server.xml"

# Step 8: Create a systemd service file.
log "Creating systemd service file for Tomcat..."
cat <<EOF | sudo tee /etc/systemd/system/tomcat.service > /dev/null
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking
User=${TOMCAT_USER}
Group=${TOMCAT_USER}
ExecStart=${INSTALL_DIR}/${TOMCAT_DIR}/bin/startup.sh
ExecStop=${INSTALL_DIR}/${TOMCAT_DIR}/bin/shutdown.sh
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Step 9: Reload systemd and start the Tomcat service.
log "Reloading systemd daemon and starting Tomcat service..."
sudo systemctl daemon-reload
sudo systemctl enable tomcat
sudo systemctl start tomcat || error "Tomcat failed to start. Check logs with 'journalctl -u tomcat'."

log "Setup complete. Tomcat is now managed by systemd."
log "You can check its status with: sudo systemctl status tomcat"
log "Access the Tomcat Manager GUI at http://<ipaddress>:${TOMCAT_PORT}/manager/html"
log "Username: ${TOMCAT_USER}"
log "Password: ${TOMCAT_PASS}"
