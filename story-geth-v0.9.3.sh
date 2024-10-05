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

# Stop the existing Story-Geth client
print_info "Stopping the Story-Geth service..."
if ! sudo systemctl stop story-geth; then
    print_error "Failed to stop Story-Geth service"
    exit 1
fi

# Check if the tar file exists and delete it if present
if [ -f "$HOME/geth-linux-amd64-0.9.3-b224fdf.tar.gz" ]; then
    print_info "Existing tar file found. Deleting..."
    rm "$HOME/geth-linux-amd64-0.9.3-b224fdf.tar.gz"
fi

# Download the Story-Geth v0.9.3 binary
print_info "Downloading Story-Geth v0.9.3..."
cd $HOME
if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
    print_error "Failed to download Story-Geth binary"
    exit 1
fi

# Extract Story-Geth v0.9.3 binary
print_info "Extracting Story-Geth v0.9.3..."
if ! tar -xvzf geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
    print_error "Failed to extract Story-Geth binary"
    exit 1
fi

# Replace the old Story-Geth binary with the new one
print_info "Replacing the old Story-Geth binary..."
if ! sudo cp $HOME/geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth; then
    print_error "Failed to replace Story-Geth binary"
    exit 1
fi

# Make the binary executable
print_info "Making the binary executable..."
if ! sudo chmod +x $HOME/go/bin/story-geth; then
    print_error "Failed to make the binary executable"
    exit 1
fi

# Restart the Story-Geth service
print_info "Restarting the Story-Geth service..."
if ! sudo systemctl start story-geth; then
    print_error "Failed to start Story-Geth service"
    exit 1
fi

# Check the Story-Geth version to confirm the update
print_info "Checking the Story-Geth version..."
if ! story-geth version; then
    print_error "Failed to check Story-Geth version"
    exit 1
fi

# Cleanup
print_info "Cleaning up downloaded files..."
rm -f geth-linux-amd64-0.9.3-b224fdf.tar.gz

print_info "Story-Geth has been successfully updated to version 0.9.3!"
