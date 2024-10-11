#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}


# Specify the path to the private key file
PRIVATE_KEY_PATH="/root/.story/story/config/private_key.txt"

# Read the private key without adding any spaces or formatting
PRIVATE_KEY=$(cat "$PRIVATE_KEY_PATH" | sed 's/PRIVATE_KEY=//')

# Command to get the EVM Public Key
ADDRESS_COMMAND="/root/go/bin/story validator export - export-evm-key"

# Extract the EVM Public Key from the command output
ADDRESS_KEY=$($ADDRESS_COMMAND | grep "EVM Public Key" | awk '{print $4}')

# Path to the JSON file
BASE64_PRIV_KEY="/root/.story/story/config/priv_validator_key.json"

# Use `jq` to extract the priv_key value
PRIV_KEY=$(jq -r '.priv_key.value' "$BASE64_PRIV_KEY")





# Function to ensure go/bin is in PATH
ensure_go_path() {
    [ ! -d "$HOME/go/bin" ] && mkdir -p "$HOME/go/bin"
    if ! grep -q "$HOME/go/bin" "$HOME/.bash_profile"; then
        echo "export PATH=\$PATH:\$HOME/go/bin" >> "$HOME/.bash_profile"
    fi
    source "$HOME/.bash_profile"
}

# Function to install Go
install_go() {
    local required_version="$1"
    print_info "Installing Go version $required_version..."

    # Download Go binary
    wget "https://golang.org/dl/go${required_version}.linux-amd64.tar.gz" -O /tmp/go.tar.gz

    # Remove any existing Go installation
    sudo rm -rf /usr/local/go

    # Extract and install Go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz

    # Cleanup
    rm /tmp/go.tar.gz

    print_info "Go version $required_version installed successfully."
}

# Function to compare versions
version_ge() { 
    dpkg --compare-versions "$1" ge "$2"
}

# Function to install dependencies
install_dependencies() {
    print_info "<================= Install dependencies ===============>"
    print_info "Starting Install Dependencies..."

    # Update package lists and install general dependencies
    echo "Updating package lists and installing dependencies..."
    if ! sudo apt update && sudo apt-get upgrade -y && sudo yum install bc && sudo apt install curl git make jq bc build-essential gcc unzip wget lz4 aria2 pv -y; then
        print_error "Failed to install dependencies. Please check the logs."
        exit 1
    fi

    # Check if curl is installed
    command -v curl >/dev/null 2>&1 || { 
        print_error "curl is not installed. Please install it first."; 
        exit 1; 
    }

    # Check Python version
    python_version=$(python3 --version 2>&1 | awk '{print $2}')
    version_check=$(python3 -c "import sys; print(sys.version_info >= (3, 12))")

    # Check if python3-apt is installed
    if ! python3 -c "import apt_pkg" &>/dev/null; then
        if [ "$version_check" = "False" ]; then
            print_info "Python version $python_version is below 3.12. Attempting to update Python..."
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip
        fi

        # Now try installing python3-apt
        print_info "Attempting to install python3-apt..."
        if sudo apt-get install -y python3-apt; then
            print_info "python3-apt installed successfully."
        else
            print_error "Failed to install python3-apt. Please check your system and try again."
            print_error "You may need to install it manually if the automated process fails."
            exit 1
        fi
    else
        print_info "python3-apt is already installed."
    fi

    # Required Go version
    required_version="1.22.0"

    # Check if Go is installed
    if command -v go &> /dev/null; then
        installed_version=$(go version | awk '{print $3}' | sed 's/go//')

        if version_ge "$installed_version" "$required_version"; then
            print_info "Go version $installed_version is installed and is >= $required_version."
        else
            print_info "Go version $installed_version is installed, but it's below $required_version. Updating..."
            install_go "$required_version"
        fi
    else
        print_info "Go is not installed. Installing Go version $required_version..."
        install_go "$required_version"
    fi

    # Ensure go/bin directory exists
    ensure_go_path

    # Display the Go version to confirm the installation
    go version

    # Check if Cosmovisor is already installed
    if command -v cosmovisor >/dev/null 2>&1; then
       print_info "Cosmovisor is already installed."
     else
        # Install Cosmovisor if not installed
           print_info "Cosmovisor not found. Installing..."
           go install github.com/cosmos/cosmos-sdk/cosmovisor/cmd/cosmovisor@v1.0.0
        export PATH=$PATH:$(go env GOPATH)/bin
       print_info "Cosmovisor installed successfully."
    fi

    
    # Return to node management menu
    node_management_menu
}


# Function to setup Story-Geth Binary
setup_story_geth() {
    print_info "<================= Story-Geth Binary Setup ===============>"

    # Ensure go/bin directory exists
    if [ ! -d "$HOME/go/bin" ]; then
           if ! mkdir -p "$HOME/go/bin"; then
              print_error "Failed to create directory $HOME/go/bin"
              exit 1
           fi
    fi


    # Add go/bin to PATH if not already added
    if ! grep -q "$HOME/go/bin" "$HOME/.bash_profile"; then
        echo 'export PATH=$PATH:$HOME/go/bin' >> "$HOME/.bash_profile"
        print_info "$HOME/go/bin has been added to PATH."
    fi

    # Source the .bash_profile to update the current session
    source "$HOME/.bash_profile"

    # Download the Story-Geth v0.9.3 binary
    print_info "Downloading Story-Geth v0.9.3..."
    cd "$HOME" || exit 1
    if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
        print_error "Failed to download Story-Geth binary"
        exit 1
    fi
    print_info "Successfully downloaded Story-Geth binary."

    # Extract Story-Geth v0.9.3 binary
    print_info "Extracting Story-Geth v0.9.3..."
    if ! tar -xvzf geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
        print_error "Failed to extract Story-Geth binary"
        exit 1
    fi
    print_info "Successfully extracted Story-Geth binary."

    # Move Story-Geth binary to go/bin and make it executable
    print_info "Moving Story-Geth binary to go/bin..."
    if ! mv geth-linux-amd64-0.9.3-b224fdf/geth "$HOME/go/bin/story-geth"; then
        print_error "Failed to move Story-Geth binary"
        exit 1
    fi

    # Make the binary executable
    print_info "Making the binary executable..."
    if ! chmod +x "$HOME/go/bin/story-geth"; then
        print_error "Failed to make the binary executable"
        exit 1
    fi

    # Check the Story-Geth version to confirm the update
    print_info "Checking the Story-Geth version..."
    if ! "$HOME/go/bin/story-geth" version; then
        print_error "Failed to check Story-Geth version"
        exit 1
    fi

    # Cleanup
    print_info "Cleaning up downloaded files..."
    rm -f /root/geth-linux-amd64-0.9.3-b224fdf.tar.gz
    rm -f /root/geth-linux-amd64-0.9.3-b224fdf

    print_info "Story-Geth has been successfully updated to version 0.9.3!"

    # Return to node management menu
    node_management_menu
}



# Function to setup Story Binary
setup_story_binary() {
    print_info "<================= Story Binary Setup ================>"

    # Ensure go/bin directory exists
    if [ ! -d "$HOME/go/bin" ]; then
        mkdir -p "$HOME/go/bin" || {
            print_error "Failed to create directory $HOME/go/bin"
            exit 1
        }
    fi

    # Add go/bin to PATH if not already added
    if ! grep -q "$HOME/go/bin" "$HOME/.bash_profile"; then
        echo "export PATH=\$PATH:\$HOME/go/bin" >> "$HOME/.bash_profile"
        print_info "$HOME/go/bin has been added to PATH."
    fi

    # Source the .bash_profile to update the current session
    source "$HOME/.bash_profile"

    # Download and extract the Story v0.11.0 binary
      print_info "Downloading Story v0.11.0..."
       cd $HOME
       if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.11.0-aac4bfe.tar.gz; then
          print_error "Failed to download Story binary"
          exit 1
       fi

    print_info "Successfully downloaded Story binary."

    # Unzip Story v0.11.0 binary
      print_info "Extracting Story v0.11.0..."
       if ! tar -xzf story-linux-amd64-0.11.0-aac4bfe.tar.gz; then
            print_error "Failed to extract Story binary"
            exit 1
      fi
    print_info "Successfully extracted Story binary."

    # Replace the Old Binary with the New One in go/bin
      print_info "Replacing the old binary with the new one in $HOME/go/bin..."
      if ! sudo cp story-linux-amd64-0.11.0-aac4bfe/story $HOME/go/bin; then
          print_error "Failed to replace the binary in $HOME/go/bin"
          exit 1
      fi

    # Replace the Old Binary with the New One in /usr/local/bin
      print_info "Replacing the old binary with the new one in /usr/local/bin..."
        if ! sudo cp story-linux-amd64-0.11.0-aac4bfe/story /usr/local/bin; then
           print_error "Failed to replace the binary in /usr/local/bin"
           exit 1
        fi


    # Make the binary executable
    print_info "Making the binary executable..."
    if ! chmod +x "$HOME/go/bin/story"; then
        print_error "Failed to make the binary executable"
        exit 1
    fi

    # Make the binary executable
    print_info "Making the binary executable..."
    if ! chmod +x "/usr/local/bin/story"; then
        print_error "Failed to make the binary executable"
        exit 1
    fi


    # Check the Story version to confirm the update
    print_info "Checking the Story version..."
    if ! "$HOME/go/bin/story" version; then
        print_error "Failed to check Story version"
        exit 1
    fi

    # Cleanup
    print_info "Cleaning up downloaded files..."
    rm -f /root/story-linux-amd64-0.11.0-aac4bfe.tar.gz
    rm -rf /root/story-linux-amd64-0.11.0-aac4bfe

    print_info "Story has been successfully updated to version 0.11.0!"

    # Return to node management menu
    node_management_menu
}




# Function to setup Moniker Name
setup_moniker_name() {
    print_info "<================= Setup Moniker Name ================>"

    # Please type your Moniker Name.....
    read -p "Enter your moniker: " moniker
    print_info "Moniker '$moniker' has been saved."

    # Initialize Story with the user's moniker
    print_info "Initializing Story with moniker '$moniker'..."
    if ! story init --network iliad --moniker "$moniker"; then
        print_error "Failed to initialize Story with moniker '$moniker'"
        exit 1
    fi


    # Return to node management menu
    node_management_menu
}



# Function to setup peers
update_peers() {
    print_info "<================= Setup Peers ================>"

    # Updating and define peers
    PEERS="10f4a5147c5ae2e4707e9077aad44dd1c3fc7cd3@116.202.217.20:37656,ccb6e8d1788bd46be4abec716e98236c2e21c067@116.202.51.143:26656,17d69e7e7f6b43ef414ee6a4b2585bd9ee0446ce@135.181.139.249:46656,51c6bda6a2632f2d105623026e1caf12743fb91c@204.137.14.33:36656,2027b0adffea21f09d28effa3c09403979b77572@198.178.224.25:26656,56e241d794ec8c12c7a28aa7863db1322589de0a@144.76.202.120:36656,5d7507dbb0e04150f800297eaba39c5161c034fe@135.125.188.77:26656,f8b29354fbe832c1cb011b2fbe4f930f89a0d430@188.245.60.19:26656,c1b1fb63cb1217e6c342c0fd7edf28902e33f189@100.42.179.9:26656,2a77804d55ec9e05b411759c70bc29b5e9d0cce0@165.232.184.59:26656,d6416eb44f9136fc3b03535ae588f63762a67f8e@211.219.19.141:31656,84d347aba1869b924a6d709f133f7b135202a787@84.247.136.201:26656"

    # Update peers in config.toml
    CONFIG_FILE="$HOME/.story/story/config/config.toml"

    # Check if the config file exists
      if [[ -f "$CONFIG_FILE" ]]; then
        # Update the persistent_peers line
          sed -i "s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" "$CONFIG_FILE"
           print_info "Updated persistent_peers in $CONFIG_FILE."
      else
           print_info "Config file not found: $CONFIG_FILE"
           exit 1
      fi

    # Create story-geth service file
    sudo tee /etc/systemd/system/story-geth.service > /dev/null <<EOF
[Unit]
Description=Story Geth Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story-geth --iliad --syncmode full
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    print_info "Successfully created story-geth service file!"

    # Create story service file
    sudo tee /etc/systemd/system/story.service > /dev/null <<EOF
[Unit]
Description=Story Consensus Client
After=network.target

[Service]
User=root
ExecStart=/root/go/bin/story run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

    print_info "Successfully created story service file!"

    sudo systemctl daemon-reload
    sudo systemctl start story-geth
    sudo systemctl enable story-geth
    sudo systemctl start story
    sudo systemctl enable story

    print_info "Successfully restarted peers!"

    # Return to node management menu
    node_management_menu
}

# Function to update snapshot
update_snapshot() {
    print_info "<================= Update Snapshot ================>"

    print_info "Deleting update-snapshots.sh file..."
    rm -f update-snapshots.sh
    rm -f update-snapshots.sh.1
    rm -f update-snapshots.sh.2
    rm -f update-snapshots.sh.3
    rm -f update-snapshots.sh.4
    rm -f update-snapshots.sh.5
    
    print_info "Applying Mandragora snapshots (story client + story-geth)..."

    print_info "Check the height of the snapshot (v0.10.1): Block Number -> 1016207"

    print_info "Download and setup sync-snapshots file..."
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/update-snapshots.sh && chmod +x update-snapshots.sh && ./update-snapshots.sh

    print_info "Snapshots applied successfully!"

    # Delete the update-snapshots.sh file after execution
    print_info "Deleting update-snapshots.sh file..."
    rm -f update-snapshots.sh
    
    # Return to node management menu
    node_management_menu
}



stake_ip() {
    print_info "<================= Stake IP ================>"

    # Inform the user about the requirement to have at least 1 IP in their wallet
    print_info "You need to have at least 1 IP in your wallet to proceed with staking."
    print_info "Get it from the faucet: https://faucet.story.foundation/"

    while true; do
        # Check sync status (ensure 'catching_up' is false)
        print_info "Checking the sync status..."
        SYNC_STATUS=$(curl -s localhost:26657/status | jq '.result.sync_info.catching_up')

        if [ "$SYNC_STATUS" == "false" ]; then
            print_info "Node is synced. Proceeding to validator registration."
            break  # Exit the loop if the node is synced
        else
            print_info "Node is still catching up. Please check the sync status:"
            print_info "Run the following command to check the sync info:"
            print_info "curl -s localhost:26657/status | jq '.result.sync_info'"
            print_info "The sync status is currently catching_up: true."

            # Ask user if they want to check again or return to the menu
            read -p "Do you want to check the sync status again? (y/n): " user_choice
            if [[ "$user_choice" =~ ^[Yy]$ ]]; then
                continue  # Continue the loop to check sync status again
            else
                print_info "Returning to the Node Management Menu..."
                node_management_menu  # Call the node_management_menu function directly
                return  # Exit the current function
            fi
        fi
    done

    # Ask the user how many IP they want to stake
    read -p "Enter the amount of IP you want to stake (minimum 1 IP): " STAKE_AMOUNT

    # Validate input (minimum stake must be 1)
    if [[ "$STAKE_AMOUNT" -lt 1 ]]; then
        print_info "The stake amount must be at least 1 IP. Exiting."
        exit 1
    fi

    # Convert stake amount to Wei (1 IP = 10^18 Wei)
    STAKE_WEI=$(python3 -c "print(int($STAKE_AMOUNT * 1000000000000000000))")  # Ensure integer output


    # Register the validator using the imported private key
    story validator create --stake "$STAKE_WEI" --private-key "$PRIVATE_KEY"

    # Wait for 2 minutes (120 seconds) before proceeding
    print_info "Waiting for 2 minutes for the changes to reflect..."
    sleep 120

    # Inform the user where they can check their validator
    print_info "You can check your validator's status and stake on the following explorer:"
    print_info "Explorer: https://testnet.story.explorers.guru/"

    # Return to node management menu
    node_management_menu
}





unstake_ip() {
    print_info "<================= Unstake IP ================>"
    print_info "You need to have staked IP to proceed with unstaking."
    
    # Check sync status
    while true; do
        print_info "Checking the sync status..."
        SYNC_STATUS=$(curl -s localhost:26657/status | jq '.result.sync_info.catching_up')

        if [ "$SYNC_STATUS" == "false" ]; then
            print_info "Node sync complete. Proceeding to unstake."
            break  # Exit the loop if the node is synced
        else
            print_info "Node is still catching up. Please check the sync status:"
            print_info "Run the following command to check the sync info:"
            print_info "curl -s localhost:26657/status | jq '.result.sync_info'"
            print_info "The sync status is currently catching_up: true."

            # Ask user if they want to check again or return to the menu
            read -p "Do you want to check the sync status again? (y/n): " user_input
            if [[ "$user_input" =~ ^[Yy]$ ]]; then
                continue  # Continue the loop to check sync status again
            elif [[ "$user_input" =~ ^[Nn]$ ]]; then
                print_info "Returning to the Node Management Menu..."
                node_management_menu  # Call the node_management_menu function directly
                return  # Exit the function
            else
                print_info "Invalid input. Please enter 'y' or 'n'."
            fi
        fi
    done

    # Ask the user how many IP they want to unstake
    read -p "Enter the amount of IP you want to unstake (minimum 1 IP): " UNSTAKE_AMOUNT

    # Validate input (minimum unstake must be 1)
    if [ "$UNSTAKE_AMOUNT" -lt 1 ]; then
        print_info "The unstake amount must be at least 1 IP. Exiting."
        exit 1
    fi

    # Convert stake amount to Wei (1 IP = 10^18 Wei)
    UNSTAKE_WEI=$(python3 -c "print(int($UNSTAKE_AMOUNT * 1000000000000000000))")  # Ensure integer output

    # Unregister the validator using the imported private key
    story validator unstake --validator-pubkey "$BASE64_PUB_KEY" --unstake "$UNSTAKE_WEI" --private-key "$PRIVATE_KEY"

    # Wait for 2 minutes (120 seconds) before proceeding
    print_info "Waiting for 2 minutes for the changes to reflect..."
    sleep 120

    # Inform the user where they can check their validator
    print_info "You can check your validator's status and unstaking on the following explorer:"
    print_info "Explorer: https://testnet.story.explorers.guru/"

    # Return to node management menu
    node_management_menu
}


# Function to update snapshot
logs_checker() {
    print_info "<================= Logs Checker ================>"

    print_info "Deleting old logs.sh file..."
    rm -f logs.sh
    rm -f logs.sh.1
    
    print_info "Check All Node Logs Like : Geth-Logs, Story-Logs, Sync-Status, Geth-Status, Story-Status"

    print_info "Live Logs File Install...."
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/logs.sh && chmod +x logs.sh && ./logs.sh

    print_info "Logs applied successfully!"

    # Delete the logs.sh file after execution
    print_info "Deleting logs.sh file..."
    rm -f logs.sh
    
    # Return to node management menu
    node_management_menu
}



# Function to start nodes
start_nodes() {
    print_info "<================= Start Nodes ================>"
    print_info "Starting Story and Story Geth services..."
    sudo systemctl daemon-reload
    sudo systemctl enable story-geth
    sudo systemctl enable story
    sudo systemctl start story-geth
    sudo systemctl start story
    print_info "Story and Story Geth services started."
    node_management_menu
}



# Function to stop nodes
stop_nodes() {
    print_info "<================= Stop Nodes ================>"
    print_info "Stopping Story and Story Geth services..."
    sudo systemctl stop story-geth.service
    sudo systemctl stop story.service
    print_info "Story and Story Geth services stopped."
    node_management_menu
}


# Function to stop nodes
refresh_nodes() {
    print_info "<================= Refresh Nodes ================>"
    print_info "Please Wait..."
    sudo systemctl stop story-geth.service
    sudo systemctl stop story.service

    sudo systemctl daemon-reload
    sudo systemctl enable story-geth
    sudo systemctl enable story
    sudo systemctl start story-geth
    sudo systemctl start story
    print_info "Now Successfully Refresh...."
    node_management_menu
}


# Function to check node sync status
check_node_status() {
    # Fetch sync status from the node
    SYNC_STATUS=$(curl -s localhost:26657/status)

    # Check if the node is catching up or fully synced
    CATCHING_UP=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.catching_up')

    if [[ $CATCHING_UP == "false" ]]; then
        print_info "Node is not syncing."
    else
        # Get the starting, current, highest, and latest block heights
        STARTING_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.earliest_block_height')
        CURRENT_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.latest_block_height')
        HIGHEST_BLOCK=$(echo "$SYNC_STATUS" | jq -r '.result.sync_info.highest_block_height')

        print_info "Node is syncing:"
        print_info "Starting Block: $STARTING_BLOCK"
        print_info "Current Block: $CURRENT_BLOCK"
        print_info "Highest Block: $HIGHEST_BLOCK"
    fi

    
    # Return to node management menu
    node_management_menu
}




# Function to display validator info
show_validator_info() {
print_info "<================= Show Validator Info ===============>"
    print_info "Fetching validator information from localhost:26657..."

    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        print_error "curl is not installed. Please install it first."
        exit 1
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_error "jq is not installed. Please install it first."
        exit 1
    fi

    # Fetch and display validator info
    validator_info=$(curl -s localhost:26657/status | jq -r '.result.validator_info')

    if [ -n "$validator_info" ]; then
        print_info "Validator Information:"
        echo "$validator_info"
    else
        print_error "Failed to fetch validator information. Please check if the service is running."
    fi

    # Return to node management menu
    node_management_menu
}



# Function to check balance
check_balance() {
    print_info "<================= Balance Checker ===============>"

    # Fetch the balance using the EVM address
    local balance_response=$(curl -s -X POST "https://testnet.storyrpc.io/" -H "Content-Type: application/json" -d '{
        "jsonrpc": "2.0",
        "method": "eth_getBalance",
        "params": ["'$ADDRESS_KEY'", "latest"],
        "id": 1
    }')

    # Extract the balance from the JSON response (in hex)
    local balance_hex=$(echo $balance_response | jq -r '.result' | sed 's/^0x//')

    # Convert the hexadecimal balance to decimal using Python
    balance_decimal=$(python3 -c "print(int('$balance_hex', 16))")

    # Convert decimal balance to IP balance (assuming 1 IP = 1e18)
    balance_in_ip=$(python3 -c "print(f'{${balance_decimal}/1000000000000000000:.4f}')")

    # Print the formatted balance
    print_info "EVM Address: $ADDRESS_KEY"
    print_info "Balance: $balance_in_ip IP"


    # Return to node management menu
    node_management_menu
}



# Function to check Private key
check_private_key() {
    print_info "<================= Private Key ===============>"

    # Decode base64 and convert to hex, then trim
    PRIV_KEY_TXT=$(echo "$PRIV_KEY" | base64 -d | xxd -p | tr -d '\n' | xargs)

    # Check if the private_key.txt file already exists
    if [ -f "$PRIVATE_KEY_PATH" ]; then
       # If the file exists, print information
       print_info "Private Key File already exists: $PRIVATE_KEY_PATH"
    else
       # If the file doesn't exist, create it and save the private key
       echo "PRIVATE_KEY=$PRIV_KEY_TXT" > "$PRIVATE_KEY_PATH"
       print_info "Private Key File saved: $PRIVATE_KEY_PATH"
    fi

    # Check if the private key file exists
    if [[ -f "$PRIVATE_KEY_PATH" ]]; then
        # Read the private key from the file
        PRIVATE_KEY=$(grep 'PRIVATE_KEY=' "$PRIVATE_KEY_PATH" | cut -d'=' -f2)

        # Print the private key directly
        print_info "Private key: $PRIVATE_KEY"

        # Check if the private key is empty
        if [[ -z "$PRIVATE_KEY" ]]; then
            echo "Private key is empty. Please check the file."
            return 1
        fi

        # Check if the private key is 64 characters long
        if [[ ${#PRIVATE_KEY} -ne 64 ]]; then
            echo "Invalid private key format. A valid key should be 64 characters long."
            return 1
        fi

        print_info "Private key is valid."
        return 0
    else
        echo "Private key file does not exist at path: $PRIVATE_KEY_PATH"
        return 1
    fi

    # Return to node management menu
    node_management_menu    
}




# Full Backup Function
full_backup() {
    print_info "<================= Full Backup ===============>"

    # Backup Create Directory
    print_info "Creating backup directory..."
    mkdir -p /root/.story_backup

    # Story Backup Create Directory
    print_info "Creating Story backup directory..."
    mkdir -p /root/.story_backup/story/data

    # Geth Backup Create Directory
    print_info "Creating Geth backup directory..."
    mkdir -p /root/.story_backup/geth/iliad/geth

    # Backup Directory File save
    print_info "Backing up priv_validator_state.json.backup..."
    sudo cp /root/.story/priv_validator_state.json.backup /root/.story_backup

    # Story Backup Directory File save
    print_info "Backing up Story configuration and data..."
    sudo cp -r /root/.story/story/config /root/.story_backup/story
    sudo cp -r /root/.story/story/cosmovisor /root/.story_backup/story
    sudo cp /root/.story/story/data/priv_validator_state.json /root/.story_backup/story/data

    # Geth Backup Directory File save
    print_info "Backing up Geth files..."
    sudo cp -r /root/.story/geth/geth /root/.story_backup/geth
    sudo cp /root/.story/geth/iliad/geth/nodekey /root/.story_backup/geth/iliad/geth
    sudo cp /root/.story/geth/iliad/geth/jwtsecret /root/.story_backup/geth/iliad/geth
    sudo cp -r /root/.story/geth/iliad/geth/blobpool /root/.story_backup/geth/iliad/geth

    print_info "Backup completed successfully!"

    # Return to node management menu
    node_management_menu    
}


# Restore Backup Function
restore_backup() {
    print_info "<================= Restore Backup ===============>"

    # Restore priv_validator_state.json.backup
    print_info "Restoring priv_validator_state.json.backup..."
    sudo cp /root/.story_backup/priv_validator_state.json.backup /root/.story/

    # Restore Story configuration and data
    print_info "Restoring Story configuration and data..."
    sudo cp -r /root/.story_backup/story/config /root/.story/story/
    sudo cp -r /root/.story_backup/story/cosmovisor /root/.story/story/
    sudo cp /root/.story_backup/story/data/priv_validator_state.json /root/.story/story/data/

    # Restore Geth files
    print_info "Restoring Geth files..."
    sudo cp -r /root/.story_backup/geth/geth /root/.story/geth/
    sudo cp /root/.story_backup/geth/iliad/geth/nodekey /root/.story/geth/iliad/geth/
    sudo cp /root/.story_backup/geth/iliad/geth/jwtsecret /root/.story/geth/iliad/geth/
    sudo cp -r /root/.story_backup/geth/iliad/geth/blobpool /root/.story/geth/iliad/geth/

    print_info "Restore completed successfully!"

    # Return to node management menu
    node_management_menu    
}



remove_node() {
    print_info "<================= Remove Node ================>"

    # Node removal section
    read -p "Are you sure you want to remove the node? Type 'Yes' to confirm or 'No' to cancel: " confirmation
    confirmation=$(echo "$confirmation" | tr '[:upper:]' '[:lower:]')  # Convert input to lowercase

    if [[ "$confirmation" == "yes" ]]; then
        print_info "Removing Node..."
        sudo systemctl stop story-geth
        sudo systemctl stop story
        sudo systemctl disable story-geth
        sudo systemctl disable story
        sudo rm /etc/systemd/system/story-geth.service
        sudo rm /etc/systemd/system/story.service
        sudo systemctl daemon-reload
        sudo rm -rf $HOME/.story
        sudo rm $HOME/go/bin/story-geth
        sudo rm $HOME/go/bin/story
        print_info "Node successfully removed!"
    else
        print_info "Node removal canceled."
    fi

    # Return to node management menu
    node_management_menu
}


# Function to display the Node Management Menu
node_management_menu() {

    print_info ""
    print_info "<============= Created by CryptoBuroMaster ============>"
    print_info ""
    print_info "<================= Node Management Menu ===============>"
    
    options=(
        "Install-Dependencies"
        "Story-Geth Binary Setup"
        "Story Binary Setup"
        "Setup Moniker Name"
        "Update-Peers"
        "Update-Snapshot"
        "Stop-Node"
        "Start-Node"
        "Refresh-Node"
        "Logs-Checker"
        "Node-Status"
        "Validator-Info"
        "Private-Key Checker"
        "Balance-Checker"
        "Stake-IP"
        "UnStake-IP"
        "Full-Backup"
        "Recovery-Backup"
        "Remove-Node"
        "Exit"
    )
   
    # Display options with numbers
    for i in "${!options[@]}"; do
        echo "$((i + 1)). ${options[$i]}"
    done

    while true; do
        read -p "Please select an option (1-20): " choice
         case $choice in
            1)
                print_info "You selected to install dependencies."
                install_dependencies  # Call the function here
                ;;
            2)
                print_info "You selected Story-Geth Binary Setup."
                setup_story_geth  # Call the Story-Geth setup function
                ;;
            3)
                print_info "You selected Story Binary Setup."
                setup_story_binary  # Call the Story binary setup function
                ;;
            4)
                print_info "You selected to setup Moniker Name."
                setup_moniker_name  # Call the setup moniker function
                ;;
            5)
                print_info "You selected to update peers."
                update_peers  # Call the update peers function
                ;;
            6)
                print_info "You selected to update snapshot."
                update_snapshot  # Call the update snapshot function
                ;;
            7)
                print_info "You selected to stop the node."
                stop_nodes  # Call the stop node function
                ;;
            8)
                print_info "You selected to start the node."
                start_nodes  # Call the start node function
                ;;
            9)
                print_info "You selected to start the node."
                refresh_nodes  # Call the start node function
                ;;
            10)
                print_info "You selected Logs Checker."
                logs_checker  # Call the Logs Checker function
                ;;
            11)
                print_info "Starting the node status check..."
                check_node_status # Call the Node Status function
                ;;
            12)
                print_info "Check Your Validator Info"
                show_validator_info  # Call the Validator Info function
                ;;
            13)
                print_info "Check Your Private Key."
                check_private_key  # Call the Private Key Checker function
                ;;
            14)
                print_info "Check Your Account Balance."
                check_balance  # Call the Account Balance Checker function
                ;;
            15)
                print_info "You selected to stake IP."
                stake_ip  # Call the stake IP function
                ;;
            16)
                print_info "You selected to unstake IP."
                unstake_ip  # Call the unstake IP function
                ;;
            17)
                print_info "You selected to Full Backup node."
                full_backup  # Call the remove node function
                ;;
            18)
                print_info "You selected to Full Backup node."
                restore_backup  # Call the remove node function
                ;;
            19)
                print_info "You selected to remove the node."
                remove_node  # Call the remove node function
                ;;
            20)
                print_info "Exiting the script."
                exit 0  # Exit the script after breaking the loop
                ;;
            *)


                print_info "Invalid option, please select a number between 1 and 20." 
                ;;
        esac
    done
}

# Call the Node Management Menu function
node_management_menu
