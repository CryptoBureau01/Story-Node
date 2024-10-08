#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Load the private key path from the private-key-path.sh file
source ./private-key-path.sh

# Debugging: Print the path being checked
print_info "Checking private key file at: $PRIVATE_KEY_PATH"

print_info "Private Key : $$PRIVATE_KEY" 
