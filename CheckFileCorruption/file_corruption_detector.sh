#!/bin/bash

# Directory to scan
DIR="/path/to/folder"

# Log file
LOGFILE="corruption_log.txt"

# Supported movie formats
FORMATS=("mp4" "mkv" "avi" "mov" "flv")

# Clear the log file
> "$LOGFILE"

# Function to check for corruption using Docker
check_corruption() {
    local file="$1"
    local result
    result=$(docker run --rm -v "${DIR}:/videos" linuxserver/ffmpeg:latest -v info -i "/videos/${file}" -f null - 2>&1)
    if [[ $? -ne 0 ]]; then
        echo "Corruption detected in: ${file}" >> "$LOGFILE"
        echo "Error message: ${result}" >> "$LOGFILE"
    else
        echo "No corruption detected in: ${file}" >> "$LOGFILE"
    fi
}

# Iterate through the directory
find "$DIR" -type f \( -iname "*.mp4" -o -iname "*.mkv" -o -iname "*.avi" -o -iname "*.mov" -o -iname "*.flv" \) | while read -r file; do
    echo "Filename: ${file}"
    check_corruption "$(basename "$file")"
done

echo "Corruption check completed. Results are logged in ${LOGFILE}."
