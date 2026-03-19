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
if ! command -v docker &> /dev/null
then
    echo "Installing Docker..."
    sudo apt install -y docker.io
    sudo systemctl start docker
    sudo systemctl enable docker
    # Add current user to docker group safely
    sudo usermod -aG docker ubuntu
else
    echo "Docker is already installed"
fi

# -----------------------------------------
# 3. Install Docker Compose (if not installed)
# -----------------------------------------
echo "Checking Docker Compose..."
if ! command -v docker-compose &> /dev/null
then
    echo "Installing Docker Compose..."
    sudo apt install -y docker-compose
else
    echo "Docker Compose already installed"
fi

# -----------------------------------------
# 4. Install AWS CLI(if not installed)
# -----------------------------------------
echo "============================================"
echo "Installing aws cli"
echo "============================================"

if command -v aws &>/dev/null; then
  echo "aws CLI $(aws --version) is installed"
else

  # Download the official AWS CLI v2 installer. I am using Ubuntu
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"

  # Unzip it
  sudo apt install unzip -y
  unzip /tmp/awscliv2.zip -d /tmp

  # Run the installer
  sudo /tmp/aws/install

  # Verify installation
  aws --version

  # Cleanup
  rm -rf /tmp/awscliv2.zip /tmp/aws
fi

# -----------------------------------------
# 5. Create MySQL directory
# -----------------------------------------
echo "Creating MySQL data directory..."
sudo mkdir -p /mnt/mysql-data

# -----------------------------------------
# 6. Set permissions
# -----------------------------------------
echo "Setting permissions..."

sudo chown -R ubuntu:ubuntu /mnt/mysql-data
sudo chmod -R 755 /mnt/mysql-data

# -----------------------------------------
# 7. Check EBS volume mount
# -----------------------------------------
echo "==========================================="
echo "Mounting EBS Volume"
echo "==========================================="

if mountpoint -q /mnt/ebs; then
  echo "EBS Volume is mounted"
else
  echo "EBS Volume is not mounted.... Mounting EBS Volume"

  #Format the EBS volume
  sudo mkfs -t ext4 /dev/nvme1n1

  #Create a mount point where the EBS Volume will appear
  sudo mkdir -p /mnt/ebs

  #Mount the volume to the mount point (Folder), add the fstan to make the mount permanent (survives reboots)
  sudo mount /dev/nvme1n1 /mnt/ebs
  echo '/dev/nvme1n1 /mnt/ebs ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
fi

# Create a folder on the mounted EBS volume for mysql to write to
sudo mkdir -p /mnt/ebs/mysql-data

# mysql runs as a user with UID:999,  grant it ownership to the volume directory so that it can write into it
sudo chown -R 999:999 /mnt/ebs/mysql-data


echo "===== Provisioning Complete ====="
