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

# Function to confirm deletion
confirm_deletion() {
    while true; do
        read -p "Are you sure you want to delete previous data? (y/n): " choice
        case "$choice" in
            [Yy]* ) return 0;;  # If user presses y/Y, return success
            [Nn]* ) return 1;;  # If user presses n/N, return failure
            * ) echo "Please answer y or n.";;
        esac
    done
}


# Function to restore priv_validator_state.json
restore_priv_validator_state() {
    print_info "Checking for private key backup to restore..."
    if [ -f "$backup_path" ]; then
        print_info "Backup found. Restoring priv_validator_state.json..."
        if sudo cp "$backup_path" "$private_key_path"; then
            print_info "Restore completed successfully. priv_validator_state.json restored."
        else
            print_info "Failed to restore priv_validator_state.json."
        fi
    else
        print_info "No backup found. Skipping restoration."
    fi

    print_info "Snapshot Sync completed!"
}




# Function to ask the user which snapshot to install
choose_snapshot() {
    print_info "Which snapshot would you like to install?"
    print_info "1: Geth Snapshot"
    print_info "2: Story Snapshot"
    print_info "3: Exit"

    read -p "Please enter your choice: " snapshot_choice

    # Check user input and exit if invalid
    if [ "$snapshot_choice" != "1" ] && [ "$snapshot_choice" != "2" ] && [ "$snapshot_choice" != "3" ]; then
        print_error "Invalid choice. Please run the script again and select 1, 2, or 3."
        exit 1
    fi

    case $snapshot_choice in
        1)
            print_info "You selected Geth Snapshot."
            ;;
        2)
            print_info "You selected Story Snapshot."
            ;;
        3)
            print_info "Exiting the script."
            exit 0   # Exits the script
            ;;
        *)
            print_info "Invalid option, please select a number between 1 and 3."
            ;;
    esac
}



# Define the Archive function
archive() {
    print_info "You selected Archive snapshot."

    # Function to ask the user which snapshot to install
    choose_snapshot
    
    if [ "$snapshot_choice" == "1" ]; then
        # Geth Snapshot Installation Process
        if [ -d "$HOME/.story/geth/iliad/geth" ]; then
            print_info "Old Geth snapshot found. Do you want to delete it and download the new one? (y/n)"
            read -r choice
            case "$choice" in
                [Yy]* )
                    print_info "Deleting old Geth snapshot..."
                    sudo cp "$private_key_path" "$backup_path"
                    print_info "Private key backed up successfully!"
                    rm -rf "$HOME/.story/geth/iliad/geth"
                    print_info "Old Geth snapshot deleted."

                    # Download the new Geth snapshot
                    print_info "Downloading the Geth snapshot..."
                    if ! curl -L https://snapshots.mandragora.io/geth_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/geth/iliad/geth"; then
                        print_error "Failed to download Geth snapshot"
                        exit 1
                    fi
                    print_info "Download completed successfully."
                    ;;
                [Nn]* )
                    print_info "Exiting without deleting the old Geth snapshot."
                    exit 0
                    ;;
                * )
                    print_error "Invalid choice. Please enter y or n."
                    exit 1
                    ;;
            esac
        else
            # If no old Geth snapshot found, download the new one directly
            print_info "No old Geth snapshot found. Downloading the new one..."
            if ! curl -L https://snapshots.mandragora.io/geth_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/geth/iliad/geth"; then
                print_error "Failed to download Geth snapshot"
                exit 1
            fi
            print_info "Download completed successfully."
        fi

    elif [ "$snapshot_choice" == "2" ]; then
        # Story Snapshot Installation Process
        if [ -d "$HOME/.story/story/data" ]; then
            print_info "Old Story snapshot found. Do you want to delete it and download the new one? (y/n)"
            read -r choice
            case "$choice" in
                [Yy]* )
                    print_info "Deleting old Story snapshot..."
                    sudo cp "$private_key_path" "$backup_path"
                    print_info "Private key backed up successfully!"
                    rm -rf "$HOME/.story/story/data"
                    print_info "Old Story snapshot deleted."

                    # Download the new Story snapshot
                    print_info "Downloading the Story snapshot..."
                    if ! curl -L https://snapshots.mandragora.io/story_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/story"; then
                        print_error "Failed to download Story snapshot"
                        exit 1
                    fi
                    print_info "Download completed successfully."
                    ;;
                [Nn]* )
                    print_info "Exiting without deleting the old Story snapshot."
                    exit 0
                    ;;
                * )
                    print_error "Invalid choice. Please enter y or n."
                    exit 1
                    ;;
            esac
        else
            # If no old Story snapshot found, download the new one directly
            print_info "No old Story snapshot found. Downloading the new one..."
            if ! curl -L https://snapshots.mandragora.io/story_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/story"; then
                print_error "Failed to download Story snapshot"
                exit 1
            fi
            print_info "Download completed successfully."
        fi
    fi

    # Private key Backup Function 
    restore_priv_validator_state
}




# Define the Archive function
archive() {
    print_info "You selected Archive snapshot."

    # Function to ask the user which snapshot to install
    choose_snapshot
    
    if [ "$snapshot_choice" == "1" ]; then
        # Geth Snapshot Installation Process
        if [ -d "$HOME/.story/geth/iliad/geth" ]; then
            print_info "Old Geth snapshot found. Do you want to delete it and download the new one? (y/n)"
            read -r choice
            case "$choice" in
                [Yy]* )
                    print_info "Deleting old Geth snapshot..."
                    sudo cp "$private_key_path" "$backup_path"
                    print_info "Private key backed up successfully!"
                    rm -rf "$HOME/.story/geth/iliad/geth"
                    print_info "Old Geth snapshot deleted."

                    # Download the new Geth snapshot
                    print_info "Downloading the Geth snapshot..."
                    if ! curl -L https://snapshots.mandragora.io/geth_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/geth/iliad/geth"; then
                        print_error "Failed to download Geth snapshot"
                        exit 1
                    fi
                    print_info "Download completed successfully."
                    ;;
                [Nn]* )
                    print_info "Exiting without deleting the old Geth snapshot."
                    exit 0
                    ;;
                * )
                    print_error "Invalid choice. Please enter y or n."
                    exit 1
                    ;;
            esac
        else
            # If no old Geth snapshot found, download the new one directly
            print_info "No old Geth snapshot found. Downloading the new one..."
            if ! curl -L https://snapshots.mandragora.io/geth_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/geth/iliad/geth"; then
                print_error "Failed to download Geth snapshot"
                exit 1
            fi
            print_info "Download completed successfully."
        fi

    elif [ "$snapshot_choice" == "2" ]; then
        # Story Snapshot Installation Process
        if [ -d "$HOME/.story/story/data" ]; then
            print_info "Old Story snapshot found. Do you want to delete it and download the new one? (y/n)"
            read -r choice
            case "$choice" in
                [Yy]* )
                    print_info "Deleting old Story snapshot..."
                    sudo cp "$private_key_path" "$backup_path"
                    print_info "Private key backed up successfully!"
                    rm -rf "$HOME/.story/story/data"
                    print_info "Old Story snapshot deleted."

                    # Download the new Story snapshot
                    print_info "Downloading the Story snapshot..."
                    if ! curl -L https://snapshots.mandragora.io/story_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/story"; then
                        print_error "Failed to download Story snapshot"
                        exit 1
                    fi
                    print_info "Download completed successfully."
                    ;;
                [Nn]* )
                    print_info "Exiting without deleting the old Story snapshot."
                    exit 0
                    ;;
                * )
                    print_error "Invalid choice. Please enter y or n."
                    exit 1
                    ;;
            esac
        else
            # If no old Story snapshot found, download the new one directly
            print_info "No old Story snapshot found. Downloading the new one..."
            if ! curl -L https://snapshots.mandragora.io/story_snapshot.lz4 | lz4 -d | tar -xvf - -C "$HOME/.story/story"; then
                print_error "Failed to download Story snapshot"
                exit 1
            fi
            print_info "Download completed successfully."
        fi
    fi

    # Private key Backup Function 
    restore_priv_validator_state
}



# Function to check node sync status
check_sync_status() {
    # Fetch sync status from the node
    SYNC_STATUS=$(curl -s localhost:26657/status)

    # Check if the node is catching up or fully synced
    CATCHING_UP=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.catching_up')

    if [[ $CATCHING_UP == "false" ]]; then
        echo "Node is not syncing."
        print_info "Node is not syncing."
    else
        # Get the starting, current, highest, and latest block heights
        STARTING_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.earliest_block_height')
        CURRENT_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.latest_block_height')
        HIGHEST_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.highest_block_height')

        echo "Node is syncing:"
        print_info "Starting Block: $STARTING_BLOCK"
        print_info "Current Block: $CURRENT_BLOCK"
        print_info "Highest Block: $HIGHEST_BLOCK"
    fi
}




# Main Menu Fanction 
main_menu() {
    while true; do
        print_info "Select an option:"
        print_info "1: Download Archive Snapshot"
        print_info "2: Download Pruned Snapshot"
        print_info "3: Check Node Sync Status"
        print_info "4: Exit"

        read -p "Please enter your choice: " choice

        case "$choice" in
            1)
                archive
                ;;
            2)
                pruned
                ;;
            3)
                check_sync_status
                ;;
            4)
                print_info "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
    done
}


# Call the main menu function
main_menu
