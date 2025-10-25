#!/bin/bash

# --- Supported Distributions ---
# This script supports: RHEL, Fedora, Ubuntu, Debian, and Amazon Linux.
# If a kernel update is installed (common on RHEL/Fedora), a manual reboot is necessary.

# Function to display error and exit
die() {
    echo "ERROR: $1" >&2
    exit 1
}

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   die "This script must be run as root (use sudo -i or sudo ./scriptname.sh)"
fi

# Get distribution ID
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID=$ID
    OS_VERSION_ID=$VERSION_ID
else
    die "Cannot determine OS distribution. /etc/os-release not found."
fi

echo "=================================================="
echo " Detected OS: ${OS_ID} ${OS_VERSION_ID}"
echo "=================================================="

# --- RHEL / Fedora / CentOS Installation ---
if [[ "$OS_ID" == "rhel" || "$OS_ID" == "fedora" || "$OS_ID" == "centos" ]]; then
    
    echo "Starting standard Docker installation for RHEL/Fedora/CentOS family..."
    
    # 1. Remove old versions and conflicting packages (including podman on RHEL)
    echo "Removing conflicting packages..."
    dnf remove -y docker \
        docker-client \
        docker-client-latest \
        docker-common \
        docker-latest \
        docker-latest-logrotate \
        docker-logrotate \
        docker-engine \
        podman \
        runc 2>/dev/null || echo "No conflicting packages found or removal skipped, proceeding..."
    
    # 2. Set up the repository
    echo "Setting up Docker CE repository..."
    dnf -y install dnf-plugins-core
    
    REPO_URL="https://download.docker.com/linux/${OS_ID}/docker-ce.repo"
    
    # Use dnf-3 for Fedora if it exists (for compatibility), otherwise use dnf
    if [[ "$OS_ID" == "fedora" && -x "$(command -v dnf-3)" ]]; then
         dnf-3 config-manager --add-repo "$REPO_URL"
    else
         dnf config-manager --add-repo "$REPO_URL"
    fi
    
    # 3. Install Docker packages
    echo "Installing Docker CE components. This may include a kernel update..."
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 4. Enable and start Docker
    echo "Attempting to enable and start Docker service..."
    # Execute the start command and capture the exit code
    systemctl enable --now docker
    START_STATUS=$?

    # 5. Check for required reboot
    # If the systemctl command failed (exit code != 0) OR the service is now in a 'failed' state
    if [ $START_STATUS -ne 0 ] || systemctl is-failed docker >/dev/null; then
        echo "--------------------------------------------------------------------------------"
        echo "🚨 **DOCKER SERVICE START FAILED! (Exit Code: $START_STATUS)** 🚨"
        echo "This failure is expected on RHEL/Fedora systems if a **KERNEL UPDATE** was installed."
        echo "To resolve this and activate the new kernel modules:"
        echo "1. Run the command: **reboot**"
        echo "2. After reconnecting, verify with: 'sudo systemctl status docker'"
        echo "--------------------------------------------------------------------------------"
        exit 0
    fi

# --- Amazon Linux Installation ---
elif [[ "$OS_ID" == "amzn" ]]; then
    
    echo "Starting standard Docker installation for Amazon Linux..."
    yum update -y
    yum install docker -y
    systemctl enable --now docker
    
# --- Ubuntu / Debian Installation ---
elif [[ "$OS_ID" == "ubuntu" || "$OS_ID" == "debian" ]]; then
    
    echo "Starting standard Docker installation for Ubuntu/Debian..."
    apt update -y
    # Install the simpler 'docker.io' package found in default repos
    apt install docker.io -y
    
    systemctl enable --now docker

# --- Unsupported OS ---
else
    die "Unsupported OS distribution: ${OS_ID}. Script terminating."
fi

# --- Final Verification ---
echo "=================================================="
echo " ✅ Installation Attempt Complete. Verifying Docker."
echo "=================================================="

# Check if docker command is available and running
if command -v docker >/dev/null 2>&1 && systemctl is-active docker >/dev/null; then
    docker --version
    echo "Docker is installed and running."
    echo "Running hello-world to confirm functionality..."
    sudo docker run hello-world
    
    # Add user to the docker group for running commands without 'sudo'
    CURRENT_USER=$(logname 2>/dev/null || whoami)
    if ! id -nG "$CURRENT_USER" | grep -qw "docker"; then
        echo "--------------------------------------------------------------------------------"
        echo "💡 To run Docker commands without 'sudo':"
        echo "Run: sudo usermod -aG docker ${CURRENT_USER}"
        echo "Then: **Log out and log back in** (or run 'newgrp docker') to activate the change."
        echo "--------------------------------------------------------------------------------"
    fi
else
    echo "Docker service is not active. Please check 'sudo systemctl status docker'."
fi
