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





# Define the Archive function
archive() {
    print_info "You selected Archive snapshot."
    # Ask the user which snapshot to install
    print_info "Which snapshot would you like to install?"
    
    read -p "Please enter your choice (
    print_info "1: Geth Snapshot" 
    print_info "2: Story Snapshot" 
    print_info "3: Exit" ): " snapshot_choice




    
}

# Define the Pruned function
pruned() {
    print_info "You selected Pruned snapshot."
    # Add your Pruned snapshot logic here

    print_info "Which snapshot would you like to install?"
    
    read -p "Please enter your choice (
    print_info "1: Geth Snapshot" 
    print_info "2: Story Snapshot" 
    print_info "3: Exit" ): " snapshot_choice


}

# Prompt user to choose between Archive, Pruned, or Exit
print_info "Choose an option:"
print_info "1. Archive"
print_info "2. Pruned"
print_info "3. Exit"

# Read user input
read -n 1 -p "Enter your choice: " choice
echo ""  # New line after user input

# Call the respective function based on user input
case $choice in
    1)
        archive
        ;;
    2)
        pruned
        ;;
    3)
        print_info "Exiting."
        exit 0
        ;;
    *)
        print_info "Invalid choice. Please type 1, 2, or 3."
        ;;
esac
