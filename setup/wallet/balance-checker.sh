
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

# Print the private key path for debugging
print_info "Checking private key file at: $PRIVATE_KEY_PATH"

# Check if the private key file exists
if [[ -f "$PRIVATE_KEY_PATH" ]]; then
    # Read the private key
    private_key=$(cat "$PRIVATE_KEY_PATH")
    
    # Print the full private key for debugging
    print_info "Full private key: $private_key"
    
    # Derive the address from the private key using web3 or a similar tool
    address=$(curl -s -X POST "https://testnet.storyrpc.io/" -H "Content-Type: application/json" -d '{
        "jsonrpc": "2.0",
        "method": "personal_importRawKey",
        "params": ["'$private_key'", ""],
        "id": 1
    }' | jq -r '.result')
    
    # Check if the address was retrieved successfully
    if [[ -z "$address" || "$address" == "null" ]]; then
        print_error "Unable to retrieve address from the private key."
        return
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
        return
    fi
    
    # Convert balance from Wei to IP tokens (assuming 1 IP = 1e18 Wei)
    balance_in_ip=$(bc <<< "scale=18; $balance / 1000000000000000000")
    
    # Print the balance information
    print_info "Address: $address"
    print_info "Balance: $balance_in_ip IP"
else
    print_error "Private key file does not exist. Please check the path: $PRIVATE_KEY_PATH"
fi
