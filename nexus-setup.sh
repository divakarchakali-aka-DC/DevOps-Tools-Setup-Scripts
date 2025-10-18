#!/bin/bash
set -e

# --- Variables ---
# Define variables for easier maintenance. You can change these values as needed.
NEXUS_VERSION="3.79.1-04"
NEXUS_ARCHIVE="nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
NEXUS_DOWNLOAD_URL="https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-linux-x86_64.tar.gz"
NEXUS_DIR="nexus-${NEXUS_VERSION}"
NEXUS_USER="nexus"
INSTALL_DIR="/app"
DATA_DIR="/app/sonatype-work"

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

# Step 1: Install Java, the prerequisite for Nexus.
install_java

# Step 2: Create a dedicated user for Nexus (for security).
log "Checking for '$NEXUS_USER' user..."
if id "$NEXUS_USER" >/dev/null 2>&1; then
    warn "User '$NEXUS_USER' already exists. Skipping creation."
else
    log "Creating '$NEXUS_USER' user..."
    sudo useradd "$NEXUS_USER"
fi

# Step 3: Download and extract the Nexus archive.
log "Downloading Nexus Repository Manager version ${NEXUS_VERSION}..."
sudo wget "${NEXUS_DOWNLOAD_URL}" -O /tmp/"${NEXUS_ARCHIVE}"

log "Creating installation and data directories..."
sudo mkdir -p "${INSTALL_DIR}"
sudo mkdir -p "${DATA_DIR}"

log "Extracting the archive to ${INSTALL_DIR}..."
sudo tar -xvf /tmp/"${NEXUS_ARCHIVE}" -C "${INSTALL_DIR}"

log "Renaming Nexus directory to 'nexus' for simplicity..."
sudo mv "${INSTALL_DIR}/${NEXUS_DIR}" "${INSTALL_DIR}/nexus"

# Step 4: Set correct permissions and ownership.
log "Setting ownership of Nexus directories to '$NEXUS_USER'..."
sudo chown -R "${NEXUS_USER}":"${NEXUS_USER}" "${INSTALL_DIR}/nexus"
sudo chown -R "${NEXUS_USER}":"${NEXUS_USER}" "${DATA_DIR}"

# Step 5: Configure the Nexus start script to run as the correct user.
log "Configuring Nexus to run as the '$NEXUS_USER'..."
sudo sed -i 's/#run_as_user=""/run_as_user="'${NEXUS_USER}'"/g' "${INSTALL_DIR}/nexus/bin/nexus"

# Step 6: Create a systemd service file.
log "Creating systemd service file for Nexus..."
cat <<EOF | sudo tee /etc/systemd/system/nexus.service > /dev/null
[Unit]
Description=Sonatype Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
User=${NEXUS_USER}
Group=${NEXUS_USER}
ExecStart=${INSTALL_DIR}/nexus/bin/nexus start
ExecStop=${INSTALL_DIR}/nexus/bin/nexus stop
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF

# Step 7: Reload systemd and start the Nexus service.
log "Reloading systemd daemon and starting Nexus service..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus || error "Nexus failed to start. Check logs with 'journalctl -u nexus'."

log "Setup complete. Nexus is now managed by systemd."
log "You can check its status with: sudo systemctl status nexus"
log "Initial admin password is in: ${DATA_DIR}/nexus3/admin.password"
log "Access the Nexus UI at http://<ipaddress>:8081"
systemctl status nexus
