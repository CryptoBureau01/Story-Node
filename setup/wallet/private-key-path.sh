#!/bin/bash

# Read the private key without adding any spaces or formatting
PRIVATE_KEY=$(cat /root/.story/story/config/private_key.txt | sed 's/PRIVATE_KEY=//')

# Save the plain private key to private-key-path.sh for use in other scripts
echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" > private-key-path.sh
echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" > ./setup/wallet/private-key-path.sh

# Specify the path to the private key file
echo 'PRIVATE_KEY_PATH="/root/.story/story/config/private_key.txt"' >> private-key-path.sh


