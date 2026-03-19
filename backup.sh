#!/bin/bash

# Exit immediately if any command fails
set -e

# Load variables
source .env

# -----------------------------------------
# 1. Define variables
# -----------------------------------------

# MySQL container name (must match docker-compose)
CONTAINER_NAME="wordpress-db"

# Database credentials (should match your .env)
MYSQL_USER=${MYSQL_USER}                # mysql DB user
MYSQL_DATABASE=${MYSQL_DATABASE}        # mysql DB
MYSQL_PASSWORD=${MYSQL_PASSWORD}        # mysql Password
#S3
S3_BUCKET="wordpress-backup-blessingg-2026"


# Backup directory (local)
BACKUP_DIR="/tmp"

# Generate timestamp (e.g., 2026-03-15-1430)
TIMESTAMP=$(date +"%Y-%m-%d-%H%M")

# Backup filename
BACKUP_FILE="backup-$TIMESTAMP.sql"

# Full path to backup file
FULL_PATH="$BACKUP_DIR/$BACKUP_FILE"

echo "===== Starting MySQL backup ====="

# -----------------------------------------
# 2. Run mysqldump inside the container
# -----------------------------------------
# This executes mysqldump inside the running MySQL container
# and redirects the output to a file on the host machine

docker exec $CONTAINER_NAME \
    mysqldump -u$MYSQL_USER -p$MYSQL_PASSWORD $MYSQL_DATABASE > "$FULL_PATH"

echo "Backup created at $FULL_PATH"

# -----------------------------------------
# 3. Upload backup to S3
# -----------------------------------------
# Uses AWS CLI (must be configured with aws configure)

S3_PATH="s3://$S3_BUCKET/$BACKUP_FILE"

aws s3 cp $BACKUP_FILE s3://wordpress-backup-blessingg-2026/

echo "Backup uploaded to S3: $S3_PATH"


echo "===== Backup process completed successfully ====="
