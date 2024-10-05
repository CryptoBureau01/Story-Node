#!/bin/bash

# Stop the Existing Story Client
echo "Stopping the existing Story node..."
sudo systemctl stop story

# Download and extract the Story v0.11.0 binary
echo "Downloading Story v0.11.0..."
cd $HOME
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.11.0-aac4bfe.tar.gz

# Unzip Story v0.11.0 binary
echo "Extracting Story v0.11.0..."
tar -xzf story-linux-amd64-0.11.0-aac4bfe.tar.gz

# Replace the Old Binary with the New One in go/bin
echo "Replacing the old binary with the new one in $HOME/go/bin..."
sudo cp story-linux-amd64-0.11.0-aac4bfe/story $HOME/go/bin

# Replace the Old Binary with the New One in /usr/local/bin
echo "Replacing the old binary with the new one in /usr/local/bin..."
sudo cp story-linux-amd64-0.11.0-aac4bfe/story /usr/local/bin

# Restart the Story Node
echo "Restarting the Story node..."
sudo systemctl start story

# Check the Story Version to Confirm Update
echo "Checking the Story node version..."
story version
