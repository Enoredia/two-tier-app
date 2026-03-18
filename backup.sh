#!/bin/bash

# Exit immediately if any command fails
set -e

# -----------------------------------------
# 1. Define variables
# -----------------------------------------

# MySQL container name (must match docker-compose)
CONTAINER_NAME="wordpress-db"

# Database credentials (should match your .env)
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASSWORD="strongpassword"

# S3 bucket name
S3_BUCKET="wordpress-backup-blessing-2026"

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
    mysqldump -u$DB_USER -p$DB_PASSWORD $DB_NAME > "$FULL_PATH"

echo "Backup created at $FULL_PATH"

# -----------------------------------------
# 3. Upload backup to S3
# -----------------------------------------
# Uses AWS CLI (must be configured with aws configure)

S3_PATH="s3://$S3_BUCKET/$BACKUP_FILE"

aws s3 cp "$FULL_PATH" "$S3_PATH"

echo "Backup uploaded to S3: $S3_PATH"

# -----------------------------------------
# 4. Optional: Clean up local backup
# -----------------------------------------
# Uncomment if you want to remove local copy after upload

# rm -f "$FULL_PATH"

echo "===== Backup process completed successfully ====="
