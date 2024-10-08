
#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Step to download private-key-path.sh and set permissions
print_info "Downloading and setting up private-key-path.sh..."
cd $HOME && wget -O ./setup/wallet/private-key-path.sh https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup/wallet/private-key-path.sh && chmod +x ./setup/wallet/private-key-path.sh

# Load the private key from the private-key-path.sh file
source ./setup/wallet/private-key-path.sh

# Print the private key for debugging
print_info "Private key from private-key-path.sh: $PRIVATE_KEY"

# Check if the private key is loaded
if [[ -z "$PRIVATE_KEY" ]]; then
    print_error "Private key not found. Please check the private-key-path.sh file."
    exit 1
fi

# Derive the address from the private key using web3 or a similar tool
address=$(curl -s -X POST "https://testnet.storyrpc.io/" -H "Content-Type: application/json" -d '{
    "jsonrpc": "2.0",
    "method": "personal_importRawKey",
    "params": ["'$PRIVATE_KEY'", ""],
    "id": 1
}' | jq -r '.result')

# Check if the address was retrieved successfully
if [[ -z "$address" || "$address" == "null" ]]; then
    print_error "Unable to retrieve address from the private key."
    exit 1
fi

# Fetch the balance using the derived address
balance=$(curl -s -X POST "https://testnet.storyrpc.io/" -H "Content-Type: application/json" -d '{
    "jsonrpc": "2.0",
    "method": "eth_getBalance",
    "params": ["'$address'", "latest"],
    "id": 1
}' | jq -r '.result')

# Check if the balance was retrieved successfully
if [[ "$balance" == "null" || -z "$balance" ]]; then
    print_error "Unable to retrieve balance. Please check the address."
    exit 1
fi

# Convert balance from Wei to IP tokens (assuming 1 IP = 1e18 Wei)
balance_in_ip=$(bc <<< "scale=18; $balance / 1000000000000000000")

# Print the private key, address, and balance
print_info "Address: $address"
print_info "Balance: $balance_in_ip IP"
