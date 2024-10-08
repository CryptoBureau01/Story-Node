#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Step to download and set up private-key-path.sh
print_info "Downloading and setting up private-key-path.sh..."
cd $HOME && wget -O ./setup/wallet/private-key-path.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/private-key-path.sh && chmod +x ./setup/wallet/private-key-path.sh

# Import the private key from private-key-path.sh
source ./private-key-path.sh

# Print the private key
print_info "Your Private Key: $PRIVATE_KEY"

# Step to download and set up balance-checker.sh
print_info "Downloading and setting up balance-checker.sh..."
cd $HOME && wget -O ./setup/wallet/balance-checker.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/balance-checker.sh && chmod +x ./setup/wallet/balance-checker.sh

# Import balance checker and display the balance
source ./balance-checker.sh

# Print the balance
print_info "Address: $address"
print_info "Balance: $balance_in_ip IP"

