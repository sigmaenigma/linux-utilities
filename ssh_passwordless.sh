#!/usr/bash

# Copies the contents of your local public file
# and copies it over and stores it on the machine's
# local authorized_keys for that user you're trying to log in as

# One Liner
cat ~/.ssh/id_rsa.pub | ssh remote_username@linux_box_ip_address "mkdir -p ~/.ssh && chmod 700 ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"

# Broken Out
cat ~/.ssh/id_rsa.pub | ssh remote_username@linux_box_ip_address "mkdir -p ~/.ssh
chmod 700 ~/.ssh
cat >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys"
