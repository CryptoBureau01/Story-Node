#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}




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
    if ! sudo apt update && sudo apt-get upgrade -y && sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 pv -y; then
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
    rm -f geth-linux-amd64-0.9.3-b224fdf.tar.gz

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

    # Download and install Story v0.10.1
    print_info "Downloading and installing Story v0.10.1..."
    cd "$HOME" || exit 1
    if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.10.1-57567e5.tar.gz; then
        print_error "Failed to download Story binary"
        exit 1
    fi
    print_info "Successfully downloaded Story binary."

    # Extract Story v0.10.1 binary
    print_info "Extracting Story v0.10.1..."
    if ! tar -xzvf story-linux-amd64-0.10.1-57567e5.tar.gz; then
        print_error "Failed to extract Story binary"
        exit 1
    fi
    print_info "Successfully extracted Story binary."

    # Move Story binary to go/bin and make it executable
    print_info "Moving Story binary to go/bin..."
    if ! mv story-linux-amd64-0.10.1-57567e5/story "$HOME/go/bin/story"; then
        print_error "Failed to move Story binary"
        exit 1
    fi

    # Make the binary executable
    print_info "Making the binary executable..."
    if ! chmod +x "$HOME/go/bin/story"; then
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
    rm -f story-linux-amd64-0.10.1-57567e5.tar.gz

    print_info "Story has been successfully updated to version 0.10.1!"

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

    # Get active peers from the RPC server
    PEERS=$(curl -s -X POST https://rpc-story.josephtran.xyz -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_info","params":[],"id":1}' | jq -r '.result.peers[] | select(.connection_status.SendMonitor.Active == true) | "\(.node_info.id)@\(if .node_info.listen_addr | contains("0.0.0.0") then .remote_ip + ":" + (.node_info.listen_addr | sub("tcp://0.0.0.0:"; "")) else .node_info.listen_addr | sub("tcp://"; "") end)"' | tr '\n' ',' | sed 's/,$//' | awk '{print "\"" $0 "\""}')

    # Update the persistent_peers in config.toml
    sed -i "s/^persistent_peers *=.*/persistent_peers = $PEERS/" "$HOME/.story/story/config/config.toml"

    if [ $? -eq 0 ]; then
        print_info "Configuration file updated successfully with new peers."
    else
        print_error "Failed to update configuration file."
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

    print_info "Applying Mandragora snapshots (story client + story-geth)..."

    print_info "Check the height of the snapshot (v0.10.1): Block Number -> 1016207"

    print_info "Download and setup sync-snapshots file..."
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/update-snapshots.sh && chmod +x update-snapshots.sh && ./update-snapshots.sh

    print_info "Snapshots applied successfully!"

    # Return to node management menu
    node_management_menu
}



stake_ip() {
    print_info "<================= Stake IP ================>"

    # Path to the private key (automatically imported from file)
    PRIVATE_KEY=$(cat ~/.story/story/config/private_key.txt | sed 's/^PRIVATE_KEY=//; s/^[ \t]*//; s/[ \t]*$//')

    # Inform the user about the requirement to have at least 1 IP in their wallet
    print_info "You need to have at least 1 IP in your wallet to proceed with staking."
    print_info "Get it from the faucet: https://faucet.story.foundation/"

    while true; do
        # Check sync status (ensure 'catching_up' is false)
        print_info "Checking the sync status..."

        SYNC_STATUS=$(curl -s localhost:26657/status | jq '.result.sync_info.catching_up')

        if [ "$SYNC_STATUS" == "false" ]; then
            print_info "Node is still catching up. Please check the sync status:"
            print_info "Run the following command to check the sync info:"
            print_info "curl -s localhost:26657/status | jq '.result.sync_info'"
            print_info "The sync status is currently catching_up: true."

            # Ask user if they want to check again or return to the menu
            read -p "Do you want to check the sync status again? (y/n): " user_choice
            if [[ "$user_choice" =~ ^[Yy]$ ]]; then
                continue  # Check the sync status again
            else
                print_info "Returning to the Node Management Menu..."
                return  # Exit the function and return to the menu
            fi
        else
            print_info "Node sync complete. Proceeding to validator registration."
            break  # Exit the loop if the node is synced
        fi
    done

    # Ask the user how many IP they want to stake
    read -p "Enter the amount of IP you want to stake (minimum 1 IP): " STAKE_AMOUNT

    # Validate input (minimum stake must be 1)
    if [ "$STAKE_AMOUNT" -lt 1 ]; then
        print_info "The stake amount must be at least 1 IP. Exiting."
        exit 1
    fi

    # Convert stake amount to the required format (multiply by 10^18)
    STAKE_WEI=$(echo "$STAKE_AMOUNT * 1000000000000000000" | bc)

    # Register the validator using the imported private key
    story validator create --stake "$STAKE_WEI" --private-key "$PRIVATE_KEY"

    # Wait for 5 minutes (300 seconds) before proceeding
    print_info "Waiting for 5 minutes for the changes to reflect..."
    sleep 300

    # Inform the user where they can check their validator
    print_info "You can check your validator's status and stake on the following explorer:"
    print_info "Explorer: https://testnet.story.explorers.guru/"

    # Return to node management menu
    node_management_menu
}



remove_node() {
    print_info "<================= Remove Node ================>"

    # Node removal section
    read -p "Are you sure you want to remove the node? Type 'Yes' to confirm or 'No' to cancel: " confirmation
    if [[ "$confirmation" == "Yes" ]]; then
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



# Function to start nodes
start_nodes() {
    print_info "<================= Start Nodes ================>"
    print_info "Starting Story and Story Geth services..."
    sudo systemctl start story-geth.service
    sudo systemctl start story.service
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


# Function to show logs
show_logs() {
    print_info "Displaying logs for 'story' service..."
    
    # Check if journalctl is installed
    if ! command -v journalctl &> /dev/null; then
        print_error "journalctl is not installed. Please install it first."
        exit 1
    fi
    
    # Show logs for 'story' service
    journalctl -u story -f cat --lines=100

    print_info "Log display completed. Redirecting to the main menu..."
    
     # Return to node management menu
    node_management_menu
}

# Function to show logs
geth_logs() {
    print_info "Displaying logs for 'story-geth' service..."

    # Check if journalctl is installed
    if ! command -v journalctl &> /dev/null; then
        print_error "journalctl is not installed. Please install it first."
        exit 1
    fi

    # Show logs for 'story-geth' service
    sudo journalctl -u story-geth -f -o cat --lines=100


    print_info "Log display completed. Redirecting to the main menu..."
    
     # Return to node management menu
    node_management_menu
}


# Function to show logs for 'story' service
show_story_logs() {
    print_info "Displaying logs for 'story' service..."

    # Check if journalctl is installed
    if ! command -v journalctl &> /dev/null; then
        print_error "journalctl is not installed. Please install it first."
        exit 1
    fi

    # Show logs for 'story' service
    sudo journalctl -u story -f -o cat --lines=100

     print_info "Log display completed. Redirecting to the main menu..."
     
     # Return to node management menu
    node_management_menu
}



    # Function to display the Node Management Menu
node_management_menu() {
    print_info "<================= Node Management Menu ===============>"
    
    options=(
        "Install dependencies"
        "Story-Geth Binary Setup"
        "Story Binary Setup"
        "Setup Moniker Name"
        "Update Peers"
        "Update Snapshot"
        "Stake IP"
        "Stop Node"
        "Start Node"
        "Story-Logs"
        "Geth-Logs"
        "Nodes-Logs"
        "Remove Node"
        "Exit"
    )

    # Display options with numbers
    for i in "${!options[@]}"; do
        echo "$((i + 1)). ${options[$i]}"
    done

    while true; do
        read -p "Please select an option (1-11): " choice
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
                print_info "You selected to stake IP."
                stake_ip  # Call the stake IP function
                ;;
            8)
                print_info "You selected to stop the node."
                stop_nodes  # Call the stop node function
                ;;
            9)
               print_info "You selected to start the node."
                start_nodes  # Call the start node function
                ;;
            10)
                print_info "You selected to Nodes Logs."
                show_logs  # Call the remove node function
                ;;
            11)
                print_info "You selected to Geth Logs."
                geth_logs  # Call the remove node function
                ;;
            12)
                print_info "You selected to Story Logs."
                show_story_logs  # Call the remove node function
                ;;
            13)
                print_info "You selected to remove the node."
                remove_node  # Call the remove node function
                ;;
            14)
                print_info "Exiting the script."
                break
                ;;
            *)
                print_info "Invalid option, please select a number between 1 and 11." 
                ;;
        esac
    done
}

# Call the Node Management Menu function
node_management_menu
