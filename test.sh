#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Import the private key from private-key-path.sh
source ./setup/wallet/private-key-path.sh # Use relative path to source the file

# Print the private key
print_info "Your Private Key: $PRIVATE_KEY"
print_info "Checking private key file at: $PRIVATE_KEY_PATH"

