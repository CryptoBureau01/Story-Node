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

# Check if private key exists and backup priv_validator_state.json
private_key_path="$HOME/.story/story/data/priv_validator_state.json"
backup_path="$HOME/.story/priv_validator_state.json.backup"



# Stop Story and Story-Geth services
print_info "Stopping the Story and Story-Geth services..."
sudo systemctl stop story
sudo systemctl stop story-geth



# Check if private key file exists
if [ -f "$private_key_path" ]; then
    print_info "Private key found. Backing up priv_validator_state.json..."
    
    # Attempt to backup the private key file
    if sudo cp "$private_key_path" "$backup_path"; then
        print_info "Backup completed successfully. File saved as priv_validator_state.json.backup."
    else
        print_info "You are new and do not have a private key yet. Next time, I will back up your private key."
    fi
else
    print_info "Private key does not exist. Moving to the next step..."
fi



# Delete previous chaindata and story data folders
print_info "Deleting previous data..."
sudo rm -rf $HOME/.story/geth/iliad/geth/chaindata
sudo rm -rf $HOME/.story/story/data


# Check and delete the old Geth snapshot if it exists
if [ -f "$HOME/geth_snapshot.lz4" ]; then
    print_info "Old geth snapshot found. Deleting..."
    rm "$HOME/geth_snapshot.lz4"
fi

# Download the new Geth snapshot
print_info "Downloading the Geth snapshot..."
cd $HOME
if ! wget -O geth_snapshot.lz4 https://snapshots.mandragora.io/geth_snapshot.lz4; then
    print_error "Failed to download geth snapshot"
    exit 1
fi


# Check and delete the old Story snapshot if it exists
if [ -f "$HOME/story_snapshot.lz4" ]; then
    print_info "Old Story snapshot found. Deleting..."
    rm "$HOME/story_snapshot.lz4"
fi

# Download the new Story snapshot
print_info "Downloading the Story snapshot..."
if ! wget -O story_snapshot.lz4 https://snapshots.mandragora.io/story_snapshot.lz4; then
    print_error "Failed to download Story snapshot"
    exit 1
fi

# Unzip Geth snapshot
print_info "Extracting Geth snapshot..."
if ! lz4 -c -d geth_snapshot.lz4 | tar -xv -C $HOME/.story/geth/iliad/geth; then
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
print_info "Checking for private key backup to restore..."
if [ -f "$backup_path" ]; then
    print_info "Backup found. Restoring priv_validator_state.json..."
    
    # Attempt to restore the private key file
    if sudo cp "$backup_path" "$private_key_path"; then
        print_info "Restore completed successfully. priv_validator_state.json restored."
    else
        print_info "Failed to restore priv_validator_state.json."
    fi
else
    print_info "No backup found. Looks like you don't have a previous private key. Skipping restoration."
fi


# Check if the services have started successfully
print_info "Checking Story and Story-Geth status..."
sudo systemctl status story
sudo systemctl status story-geth


# Delete the snapshot file after extraction
if ! rm -f geth_snapshot.lz4; then
    print_error "Failed to delete the Story snapshot file"
    exit 1
fi

# Delete the snapshot file after extraction
if ! rm -f story_snapshot.lz4; then
    print_error "Failed to delete the Story snapshot file"
    exit 1
fi


# Final success message
print_info "Congratulations, Sync Snapshot completed!"
