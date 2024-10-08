#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Step 1: Download the private-key-path.sh file if it doesn't exist
if [ ! -f "./setup/wallet/private-key-path.sh" ]; then
    print_info "Downloading private-key-path.sh..."
    wget -O ./setup/wallet/private-key-path.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/private-key-path.sh
    chmod +x ./setup/wallet/private-key-path.sh
fi

# Step 2: Source the private-key-path.sh file
if [ -f "./setup/wallet/private-key-path.sh" ]; then
    source ./setup/wallet/private-key-path.sh
    if [[ -z "$PRIVATE_KEY" ]]; then
        print_error "Private key not found in private-key-path.sh."
    else
        print_info "Your Private Key: $PRIVATE_KEY"
        print_info "Private key path: $PRIVATE_KEY_PATH"
    fi
else
    print_error "Failed to find or download private-key-path.sh."
fi
