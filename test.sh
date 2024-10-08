#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Step 1: Download the private-key-path.sh file from GitHub and make it executable
print_info "Downloading private-key-path.sh..."
wget -O ./setup/wallet/private-key-path.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/private-key-path.sh
chmod +x ./setup/wallet/private-key-path.sh

# Step 2: Import the private key
source ./setup/wallet/private-key-path.sh

# Step 3: Print the private key (optional for debugging)
print_info "Full private key: $PRIVATE_KEY"

# Step 4: Download the balance-checker.sh file from GitHub and make it executable
print_info "Downloading balance-checker.sh..."
wget -O ./setup/wallet/balance-checker.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/balance-checker.sh
chmod +x ./setup/wallet/balance-checker.sh

# Step 5: Source the balance checker script and run the check_balance function
source ./setup/wallet/balance-checker.sh

# The check_balance function should be called here to check the balance
check_balance

# Step 6: Delete the downloaded files
print_info "Cleaning up by deleting downloaded files..."
rm -f ./setup/wallet/private-key-path.sh
rm -f ./setup/wallet/balance-checker.sh

print_info "Cleanup complete."


