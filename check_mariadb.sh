#!/bin/bash

# Log file path
LOG_FILE="/var/log/check_mariadb.log"

# Function to log timestamp and message
log_message() {
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp $1" >> "$LOG_FILE"
}

# Check if MariaDB service is running
if systemctl is-active --quiet mariadb.service; then
    echo "MariaDB is running."
else
    log_message "MariaDB is not running. Restarting..."
    systemctl restart mariadb.service
fi

