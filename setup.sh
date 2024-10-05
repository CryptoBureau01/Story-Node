#!/bin/bash

# Install dependencies
echo "Updating package lists and installing dependencies..."
sudo apt update
sudo apt-get update
sudo apt install curl git make jq build-essential gcc unzip wget lz4 aria2 pv -y

# Install Go
echo "Installing Go version 1.22.0..."
cd $HOME
ver="1.22.0"
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
rm "go$ver.linux-amd64.tar.gz"

# Add Go binary to PATH
echo "Setting up Go paths..."
if ! grep -q "/usr/local/go/bin" $HOME/.bash_profile; then
  echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bash_profile
fi
source ~/.bash_profile
go version

# Download and install Story-Geth binary
echo "Downloading and installing Story-Geth v0.9.2..."
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/geth-public/geth-linux-amd64-0.9.2-ea9f0d2.tar.gz
tar -xzvf geth-linux-amd64-0.9.2-ea9f0d2.tar.gz

# Ensure go/bin directory exists
[ ! -d "$HOME/go/bin" ] && mkdir -p $HOME/go/bin

# Add go/bin to PATH if not already added
if ! grep -q "$HOME/go/bin" $HOME/.bash_profile; then
  echo 'export PATH=$PATH:$HOME/go/bin' >> $HOME/.bash_profile
fi

# Move Story-Geth binary to go/bin and check version
sudo cp geth-linux-amd64-0.9.2-ea9f0d2/geth $HOME/go/bin/story-geth
source $HOME/.bash_profile

# Download and install Story binary
echo "Downloading and installing Story v0.9.11..."
wget https://story-geth-binaries.s3.us-west-1.amazonaws.com/story-public/story-linux-amd64-0.9.11-2a25df1.tar.gz
tar -xzvf story-linux-amd64-0.9.11-2a25df1.tar.gz

# Move Story binary to go/bin and check version
sudo cp story-linux-amd64-0.9.11-2a25df1/story $HOME/go/bin/story
source $HOME/.bash_profile

# Print Story-Geth and Story versions
echo "Story-Geth version:"
story-geth version

echo "Story version:"
story version

echo "Setup completed!"
