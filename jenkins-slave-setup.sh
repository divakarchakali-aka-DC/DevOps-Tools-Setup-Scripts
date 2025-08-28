# --- Universal Jenkins slave setup Script ---
# This script is designed to automatically detect the package manager (apt, dnf, or yum)
# and set up a Jenkins slave, including its Java 17, Git, and other essential dependencies
# on both Debian-based and RHEL-based systems.

# Define color codes for a more verbose and readable output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Set the Java JDK version as a variable. Removed the space for proper syntax.
JAVA_JDK_VERSION="openjdk-17-jdk"

# Function to check if a command exists on the system
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo -e "${GREEN}Starting Jenkins slave setup process...${NC}"

# Detect the package manager and install dependencies
if command_exists apt; then
  echo -e "${GREEN}Detected 'apt' package manager. Proceeding with installation for Debian/Ubuntu.${NC}"
  echo -e "${GREEN}Installing OpenJDK 17, Git, and LSOF...${NC}"
  sudo apt update -y
  sudo apt install ${JAVA_JDK_VERSION} git lsof -y

elif command_exists dnf; then
  echo -e "${GREEN}Detected 'dnf' package manager. Proceeding with installation for RHEL/Fedora.${NC}"
  echo -e "${GREEN}Installing OpenJDK 17, Git, and LSOF...${NC}"
  sudo dnf update -y
  sudo dnf install ${JAVA_JDK_VERSION} git lsof -y

elif command_exists yum; then
  echo -e "${GREEN}Detected 'yum' package manager. Proceeding with installation for RHEL/CentOS.${NC}"
  echo -e "${GREEN}Installing OpenJDK 17, Git, and LSOF...${NC}"
  sudo yum update -y
  sudo yum install ${JAVA_JDK_VERSION} git lsof -y

echo -e "${GREEN}Script completed successfully.${NC}"NC}" modern RHEL and Debian derivatives.
