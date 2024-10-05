#!/bin/bash

# Install lz4 and wget if not already installed
echo "Installing lz4 and wget..."
sudo apt-get install wget lz4 -y

# Stop Story and Story-Geth services
echo "Stopping the Story and Story-Geth services..."
sudo systemctl stop story
sudo systemctl stop story-geth

# Backup priv_validator_state.json
echo "Backing up priv_validator_state.json..."
sudo cp $HOME/.story/story/data/priv_validator_state.json $HOME/.story/priv_validator_state.json.backup

# Download the Geth snapshot
echo "Downloading the Geth snapshot..."
cd $HOME && rm -f Geth_snapshot.lz4 && wget -O Geth_snapshot.lz4 https://snapshots.mandragora.io/geth_snapshot.lz4

# Download the Story snapshot
echo "Downloading the Story snapshot..."
cd $HOME && rm -f Story_snapshot.lz4 && wget -O story_snapshot.lz4 https://snapshots.mandragora.io/story_snapshot.lz4

# Unzip Geth snapshot
echo "Extracting Geth snapshot..."
lz4 -c -d Geth_snapshot.lz4 | tar -xv -C $HOME/.story/geth/iliad/geth

# Unzip Story snapshot
echo "Extracting Story snapshot..."
lz4 -c -d story_snapshot.lz4 | tar -xv -C $HOME/.story/story

# Restore priv_validator_state.json
echo "Restoring priv_validator_state.json..."
sudo cp $HOME/.story/priv_validator_state.json.backup $HOME/.story/story/data/priv_validator_state.json

# Restart Story and Story-Geth services
echo "Restarting the Story and Story-Geth services..."
sudo systemctl start story
sudo systemctl start story-geth

# Check if the services have started successfully
echo "Checking Story and Story-Geth status..."
sudo systemctl status story
sudo systemctl status story-geth
