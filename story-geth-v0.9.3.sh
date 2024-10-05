#!/bin/bash

# Stop the existing Story-Geth client
echo "Stopping the Story-Geth service..."
sudo systemctl stop story-geth

# Download and extract the Story-Geth v0.9.3 binary
echo "Downloading Story-Geth v0.9.3..."
cd $HOME
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz

echo "Extracting Story-Geth v0.9.3..."
tar -xvzf geth-linux-amd64-0.9.3-b224fdf.tar.gz

# Replace the old Story-Geth binary with the new one
echo "Replacing the old Story-Geth binary..."
sudo cp $HOME/geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth

# Restart the Story-Geth service
echo "Restarting the Story-Geth service..."
sudo systemctl start story-geth

# Check the Story-Geth version to confirm the update
echo "Checking the Story-Geth version..."
story-geth version
