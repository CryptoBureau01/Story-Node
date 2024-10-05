#!/bin/bash

# Function to print messages in color
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

# Install lz4 and wget if not already installed
print_info "Installing lz4 and wget..."
if ! sudo apt-get install wget lz4 -y; then
    print_error "Failed to install lz4 and wget"
    exit 1
fi

# Stop Story and Story-Geth services
print_info "Stopping the Story and Story-Geth services..."
sudo systemctl stop story
sudo systemctl stop story-geth

# Backup priv_validator_state.json
print_info "Backing up priv_validator_state.json..."
if ! sudo cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup; then
    print_error "Failed to backup priv_validator_state.json"
    exit 1
fi

# Check and delete the old Geth snapshot if it exists
if [ -f "$HOME/Geth_snapshot.lz4" ]; then
    print_info "Old Geth snapshot found. Deleting..."
    rm "$HOME/Geth_snapshot.lz4"
fi

# Download the new Geth snapshot
print_info "Downloading the Geth snapshot..."
cd $HOME
if ! wget -O Geth_snapshot.lz4 https://snapshots.mandragora.io/geth_snapshot.lz4; then
    print_error "Failed to download Geth snapshot"
    exit 1
fi

# Check and delete the old Story snapshot if it exists
if [ -f "$HOME/Story_snapshot.lz4" ]; then
    print_info "Old Story snapshot found. Deleting..."
    rm "$HOME/Story_snapshot.lz4"
fi

# Download the new Story snapshot
print_info "Downloading the Story snapshot..."
if ! wget -O story_snapshot.lz4 https://snapshots.mandragora.io/story_snapshot.lz4; then
    print_error "Failed to download Story snapshot"
    exit 1
fi

# Unzip Geth snapshot
print_info "Extracting Geth snapshot..."
if ! lz4 -c -d Geth_snapshot.lz4 | tar -xv -C $HOME/.story/geth/iliad/geth; then
    print_error "Failed to extract Geth snapshot"
    exit 1
fi

# Unzip Story snapshot
print_info "Extracting Story snapshot..."
if ! lz4 -c -d story_snapshot.lz4 | tar -xv -C $HOME/.story/story; then
    print_error "Failed to extract Story snapshot"
    exit 1
fi

# Restore priv_validator_state.json
print_info "Restoring priv_validator_state.json..."
if ! sudo cp $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json; then
    print_error "Failed to restore priv_validator_state.json"
    exit 1
fi

# Restart Story and Story-Geth services
print_info "Restarting the Story and Story-Geth services..."
sudo systemctl start story
sudo systemctl start story-geth

# Check if the services have started successfully
print_info "Checking Story and Story-Geth status..."
sudo systemctl status story
sudo systemctl status story-geth

# Final success message
print_info "Congratulations, Sync Snapshot completed!"
