import os
import subprocess

# Directory to scan
DIR = "/path/to/folder"

# Log file
LOGFILE = "corruption_log.txt"

# Supported movie formats
FORMATS = ["mp4", "mkv", "avi", "mov", "flv"]

# Clear the log file
with open(LOGFILE, "w") as log_file:
    log_file.write("")

# Function to check for corruption using Docker
def check_corruption(file):
    result = subprocess.run(
        [
            "docker", "run", "--rm", "-v",
            f"{os.path.abspath(DIR)}:/videos",
            "linuxserver/ffmpeg:latest",
            "-v", "error", "-i", f"/videos/{os.path.relpath(file, DIR)}", "-f", "null", "-"
        ],
        stderr=subprocess.PIPE,
        stdout=subprocess.PIPE
    )
    with open(LOGFILE, "a") as log_file:
        if result.returncode != 0:
            log_file.write(f"Corruption detected in: {file}\n")
        else:
            log_file.write(f"No corruption detected in: {file}\n")

# Iterate through the directory
for root, _, files in os.walk(DIR):
    for file in files:
        if any(file.endswith(f".{format}") for format in FORMATS):
            print(f'Filename: {file}')
            check_corruption(os.path.join(root, file))

print(f"Corruption check completed. Results are logged in {LOGFILE}.")
