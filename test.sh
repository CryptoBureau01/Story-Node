#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Import private key from ./setup/wallet/private-key-path.sh
source ./setup/wallet/private-key-path.sh

# Print the private key
print_info "Full private key: $PRIVATE_KEY"

# Import balance checker from ./setup/wallet/balance-checker.sh and check balance
source ./setup/wallet/balance-checker.sh

# Function from balance-checker.sh will run and check balance
check_balance

