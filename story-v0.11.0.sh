#!/bin/bash

# Function to print messages
print_info() {
    echo -e "\033[1;32m$1\033[0m"
}

print_error() {
    echo -e "\033[1;31m$1\033[0m"
}

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Stop the Existing Story Client
print_info "Stopping the existing Story node..."
if ! sudo systemctl stop story; then
    print_error "Failed to stop Story node"
    exit 1
fi

# Check if the tar file exists and delete if present
if [ -f "$HOME/story-linux-amd64-0.11.0-aac4bfe.tar.gz" ]; then
    print_info "Existing tar file found. Deleting..."
    rm "$HOME/story-linux-amd64-0.11.0-aac4bfe.tar.gz"
fi

# Download and extract the Story v0.11.0 binary
print_info "Downloading Story v0.11.0..."
cd $HOME
if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.11.0-aac4bfe.tar.gz; then
    print_error "Failed to download Story binary"
    exit 1
fi

# Unzip Story v0.11.0 binary
print_info "Extracting Story v0.11.0..."
if ! tar -xzf story-linux-amd64-0.11.0-aac4bfe.tar.gz; then
    print_error "Failed to extract Story binary"
    exit 1
fi

# Replace the Old Binary with the New One in go/bin
print_info "Replacing the old binary with the new one in $HOME/go/bin..."
if ! sudo cp story-linux-amd64-0.11.0-aac4bfe/story $HOME/go/bin; then
    print_error "Failed to replace the binary in $HOME/go/bin"
    exit 1
fi

# Replace the Old Binary with the New One in /usr/local/bin
print_info "Replacing the old binary with the new one in /usr/local/bin..."
if ! sudo cp story-linux-amd64-0.11.0-aac4bfe/story /usr/local/bin; then
    print_error "Failed to replace the binary in /usr/local/bin"
    exit 1
fi

# Make the binary executable
print_info "Making the binary executable..."
if ! sudo chmod +x /usr/local/bin/story; then
    print_error "Failed to make the binary executable"
    exit 1
fi

# Restart the Story Node
print_info "Restarting the Story node..."
if ! sudo systemctl start story; then
    print_error "Failed to start Story node"
    exit 1
fi

# Check the Story Version to Confirm Update
print_info "Checking the Story node version..."
if ! story version; then
    print_error "Failed to check Story version"
    exit 1
fi

# Cleanup
print_info "Cleaning up downloaded files..."
rm -f story-linux-amd64-0.11.0-aac4bfe.tar.gz

print_info "Story node has been successfully updated to version 0.11.0!"

