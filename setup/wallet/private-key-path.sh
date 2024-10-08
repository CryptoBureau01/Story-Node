#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Read the private key without adding any spaces or formatting
PRIVATE_KEY=$(cat /root/.story/story/config/private_key.txt | sed 's/PRIVATE_KEY=//')

# Specify the path to the private key file
PRIVATE_KEY_PATH="/root/.story/story/config/private_key.txt"

# Print the private key and the private key path
print_info "Your Private Key: $PRIVATE_KEY"
print_info "Your Private Key Path: $PRIVATE_KEY_PATH"

