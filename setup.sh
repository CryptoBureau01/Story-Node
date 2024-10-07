#!/bin/bash


# Function to print info messages
print_info() {
    echo "[INFO] $1"
}

# Function to print error messages
print_error() {
    echo "[ERROR] $1"
}

# Print information function
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Print error function
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}

# Install dependencies
echo "Updating package lists and installing dependencies..."
sudo apt update
sudo apt-get update
sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 pv -y

print_info "<===========================Check Go Version =============================>"

# Function to compare versions
version_ge() { 
    # Check if version1 >= version2
    # Usage: version_ge 1.22.0 1.21.0
    dpkg --compare-versions "$1" ge "$2"
}

# Required Go version
required_version="1.22.0"

# Check if Go is installed
if command -v go &> /dev/null; then
    # Check Go version
    installed_version=$(go version | awk '{print $3}' | sed 's/go//')

    if version_ge "$installed_version" "$required_version"; then
        print_info "Go version $installed_version is installed and is >= $required_version."
    else
        print_info "Go version $installed_version is installed, but it's below $required_version. Updating..."
        
        # Install Go
        echo "Installing Go version $required_version..."
        cd $HOME
        wget "https://golang.org/dl/go$required_version.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$required_version.linux-amd64.tar.gz"
        rm "go$required_version.linux-amd64.tar.gz"
        
        print_info "Go version $required_version successfully installed."
    fi
else
    print_info "Go is not installed. Installing Go version $required_version..."

    # Install Go
    echo "Installing Go version $required_version..."
    cd $HOME
    wget "https://golang.org/dl/go$required_version.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$required_version.linux-amd64.tar.gz"
    rm "go$required_version.linux-amd64.tar.gz"

    print_info "Go version $required_version successfully installed."
fi

# Add Go binary to PATH
echo "Setting up Go paths..."
if ! grep -q "/usr/local/go/bin" $HOME/.bash_profile; then
  echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> $HOME/.bash_profile
fi

# Source the .bash_profile to update the current session
source $HOME/.bash_profile

# Display the Go version to confirm the installation
go version


print_info "<===========================Story-Geth Binary Setup=============================>"

# Ensure go/bin directory exists
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin

# Add go/bin to PATH if not already added
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.bash_profile
fi

# Source the .bash_profile to update the current session
source $HOME/.bash_profile

# Download the Story-Geth v0.9.3 binary
print_info "Downloading Story-Geth v0.9.3..."
cd $HOME
if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
    print_error "Failed to download Story-Geth binary"
    exit 1
fi

# Extract Story-Geth v0.9.3 binary
print_info "Extracting Story-Geth v0.9.3..."
if ! tar -xvzf geth-linux-amd64-0.9.3-b224fdf.tar.gz; then
    print_error "Failed to extract Story-Geth binary"
    exit 1
fi

# Move Story-Geth binary to go/bin and make it executable
print_info "Moving Story-Geth binary to go/bin..."
if ! sudo mv geth-linux-amd64-0.9.3-b224fdf/geth $HOME/go/bin/story-geth; then
    print_error "Failed to move Story-Geth binary"
    exit 1
fi

# Make the binary executable
print_info "Making the binary executable..."
if ! sudo chmod +x $HOME/go/bin/story-geth; then
    print_error "Failed to make the binary executable"
    exit 1
fi

# Check the Story-Geth version to confirm the update
print_info "Checking the Story-Geth version..."
if ! story-geth version; then
    print_error "Failed to check Story-Geth version"
    exit 1
fi

# Cleanup
print_info "Cleaning up downloaded files..."
rm -f geth-linux-amd64-0.9.3-b224fdf.tar.gz

print_info "Story-Geth has been successfully updated to version 0.9.3!"



print_info "<===========================Story Binary Setup=============================>"


# Ensure go/bin directory exists
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin

# Add go/bin to PATH if not already added
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
    echo "export PATH=\$PATH:\$HOME/go/bin" >> $HOME/.bash_profile
fi

# Source the .bash_profile to update the current session
source $HOME/.bash_profile

# Download and install Story v0.10.1
print_info "Downloading and installing Story v0.10.1..."
cd $HOME
if ! wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.10.1-57567e5.tar.gz; then
    print_error "Failed to download Story binary"
    exit 1
fi

# Extract Story v0.10.1 binary
print_info "Extracting Story v0.10.1..."
if ! tar -xzvf story-linux-amd64-0.10.1-57567e5.tar.gz; then
    print_error "Failed to extract Story binary"
    exit 1
fi

# Move Story binary to go/bin and make it executable
print_info "Moving Story binary to go/bin..."
if ! sudo mv story-linux-amd64-0.10.1-57567e5/story $HOME/go/bin/story; then
    print_error "Failed to move Story binary"
    exit 1
fi

# Make the binary executable
print_info "Making the binary executable..."
if ! sudo chmod +x $HOME/go/bin/story; then
    print_error "Failed to make the binary executable"
    exit 1
fi

# Check the Story version to confirm the update
print_info "Checking the Story version..."
if ! story version; then
    print_error "Failed to check Story version"
    exit 1
fi

# Cleanup
print_info "Cleaning up downloaded files..."
rm -f story-linux-amd64-0.10.1-57567e5.tar.gz

print_info "Story has been successfully updated to version 0.10.1!"



print_info "<===========================Setup Moniker Name=============================>"


# Please Typer Your Moniker Name.....
read -p "Enter your moniker: " moniker
print_info "Moniker '$moniker' has been saved."


# Initialize Story with the user's moniker
print_info "Initializing Story with moniker '$moniker'..."
if ! story init --network iliad --moniker "$moniker"; then
    print_error "Failed to initialize Story with moniker '$moniker'"
    exit 1
fi



print_info "<===========================Setup Peers=============================>"


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




print_info "<===========================SYNC using snapshot File=============================>"

print_info "Applying Mandragora snapshots (story client + story-geth)..."

print_info "Check the height of the snapshot (v0.10.1): Block Number -> 1016207"

print_info "Download and setup sync-snapshots file..."
cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/update-snapshots.sh && chmod +x update-snapshots.sh && ./update-snapshots.sh

print_info "Snapshots applied successfully!"




print_info "<===========================SYNC using snapshot File=============================>"



print_info "Setup completed!"



