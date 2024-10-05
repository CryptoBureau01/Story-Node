# Story Protocol Validator Node Setup Guide

Story raised $140M from Tier1 investors. Story is a blockchain making IP protection and licensing programmable and efficient. It automates IP management, allowing creators to easily license, remix, and monetize their work. With Story, traditional legal complexities are replaced by on-chain smart contracts and off-chain legal agreements, simplifying the entire process.

## System Requirements

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 4 Cores                 |
| **RAM**      | 8 GB                    |
| **Disk**     | 200 GB                  |
| **Bandwidth**| 10 MBit/s               |




Follow our TG : https://t.me/CryptoBuroOfficial






# Setup Story Install dependencies

  ## Install && run its automatically : 

  ```

  cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup.sh && chmod +x setup.sh && ./setup.sh
  ```



# Initiate Iliad node

Replace "Your_moniker_name" with any name you want 
(Ex: story init --network iliad --moniker cryptoburo )

```
story init --network iliad --moniker "Your_moniker_name"
```


# Peers setup
```
PEERS=$(curl -s -X POST https://rpc-story.josephtran.xyz -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"net_info","params":[],"id":1}' | jq -r '.result.peers[] | select(.connection_status.SendMonitor.Active == true) | "\(.node_info.id)@\(if .node_info.listen_addr | contains("0.0.0.0") then .remote_ip + ":" + (.node_info.listen_addr | sub("tcp://0.0.0.0:"; "")) else .node_info.listen_addr | sub("tcp://"; "") end)"' | tr '\n' ',' | sed 's/,$//' | awk '{print "\"" $0 "\""}')

sed -i "s/^persistent_peers *=.*/persistent_peers = $PEERS/" "$HOME/.story/story/config/config.toml"

if [ $? -eq 0 ]; then
    echo -e "Configuration file updated successfully with new peers"
else
    echo "Failed to update configuration file."
fi
```

# Create story-geth service file
```
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
```

# Create story service file

```
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
```

# Reload and start story-geth
```
sudo systemctl daemon-reload && \
sudo systemctl enable story-geth && \
sudo systemctl enable story && \
sudo systemctl start story-geth && \
sudo systemctl start story && \
sudo systemctl status story-geth
```



# Check logs

## Geth logs
```
sudo journalctl -u story-geth -f -o cat
```
## Story logs
```
sudo journalctl -u story -f -o cat
```
## Check sync status

```
curl localhost:26657/status | jq
```



# SYNC using snapshot File

**Apply Mandragora snapshots (story client+story-geth)**

Check the height of the snapshot (v0.10.1): Block Number -> 1016207



   ## Download And Setup Sync-Snapshots File : 
    
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/sync-snapshots.sh && chmod +x sync-snapshots.sh && ./sync-snapshots.sh



    

# Upgrade to Story v0.11.1


   ## Download And Setup Story v0.11.1 File : 
    
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/story-v0.11.0.sh && chmod +x story-v0.11.0.sh && ./story-v0.11.0.sh

    

   ## Ensure your node is running correctly by checking the logs:
    
      journalctl -u story -f
    


# Upgrade to Story-Geth v0.9.3 version


   ## Download Story-Geth v0.9.3 File : 
    
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/story-geth-v0.9.3.sh && chmod +x story-geth-v0.9.3.sh && ./story-geth-v0.9.3.sh

    
  
   ## Ensure your node is running correctly by checking the logs:
    
     journalctl -u story -f
    




# Register your Validator

### 1. Export wallet:
```
story validator export --export-evm-key
```
### 2. Private key preview
```
sudo nano ~/.story/story/config/private_key.txt
```
### 3. Import Key to Metamask 

Get the wallet address for faucet

### 4. You need at least have 1 IP on wallet

Get it from faucet : https://faucet.story.foundation/

Check the sync, the catching up must be 'false'
```
curl -s localhost:26657/status | jq
```
Stake only after "catching_up": false

### 5. Validator registering

Replace "your_private_key" with your key from the step2

```
story validator create --stake 1000000000000000000 --private-key "your_private_key"
```

### 6. Check your validator INFO
```
curl -s localhost:26657/status | jq -r '.result.validator_info' 
```

### 7. check your validator

Explorer: https://testnet.story.explorers.guru/

## BACK UP FILE

### 1. Wallet private key:
```
sudo nano ~/.story/story/config/private_key.txt
```
### 2. Validator key:

```
sudo nano ~/.story/story/config/priv_validator_key.json
```

Join our TG : https://t.me/CryptoBuroOfficial
