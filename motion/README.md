# motion_utilities
Utilities for managing the motion package on a Debian (or equivalent OS like Raspberry Pi)

# Prerequisites
## motion has been installed
1. Run an update on your system ```sudo apt update && sudo apt upgarde```
2. Install Motion ```sudo apt install motion```
3. Configure Motion file to store snapshots and timelapses ```sudo nano /etc/motion/motion.conf```

# Installation of motion_delete.py
## This script checks a folder and deletes all files in that folder if they match a specific 
## file type. Additionally, an age check is implemented to only delete desired files.

1. Clone this Repo into your home folder
2. Make the motion_delete.py file executable ```chmod +x motion_delete.py```
3. Update the cron with an entry to run the script ```crontab -e```
4. This is an example cron schedule: ```* * * * * python3 /home/pi/{path to motion_delete.py}```
