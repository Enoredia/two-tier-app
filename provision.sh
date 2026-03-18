#!/bin/bash

set -e

echo "===== Starting EC2 Provisioning ====="

# -----------------------------------------
# 1. Update system packages
# -----------------------------------------
echo "Updating system packages..."
sudo apt update -y
sudo apt upgrade -y

# -----------------------------------------
# 2. Install Docker (if not installed)
# -----------------------------------------
echo "Checking Docker installation..."

if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed."
else
    echo "Installing Docker..."

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common gnupg lsb-release

    # Add Docker GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Add Docker repo
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    sudo systemctl start docker
    sudo systemctl enable docker

    # Add current user to docker group safely
    ACTUAL_USER=${SUDO_USER:-$USER}
    sudo usermod -aG docker "$ACTUAL_USER"

    echo "Docker installed successfully."
fi

# -----------------------------------------
# 3. Install Docker Compose (if needed)
# -----------------------------------------
echo "Checking Docker Compose..."

if docker compose version >/dev/null 2>&1; then
    echo "Docker Compose already installed."
else
    echo "Installing Docker Compose plugin..."
    sudo apt install -y docker-compose-plugin
fi

# Verify installation
aws --version

# -----------------------------------------
# 7. Set permissions
# -----------------------------------------
echo "Setting permissions..."

ACTUAL_USER=${SUDO_USER:-$USER}
sudo chown -R "$ACTUAL_USER":"$ACTUAL_USER" /mnt/mysql-data
sudo chmod -R 755 /mnt/mysql-data

# -----------------------------------------
# 8. Ensure Docker is running
# -----------------------------------------
echo "Checking Docker service..."

if systemctl is-active --quiet docker; then
    echo "Docker is running."
else
    echo "Starting Docker..."
    sudo systemctl start docker
fi

# -----------------------------------------
# 9. Final message
# -----------------------------------------
echo "===== Provisioning Complete ====="
echo "IMPORTANT: Log out and log back in before running Docker commands."
echo "Then run: docker compose up -d"
echo "Also run: aws configure (for S3 backups)"
