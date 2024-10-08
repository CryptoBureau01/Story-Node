# Story Protocol Validator Node Setup Guide

Story raised $140M from Tier1 investors. Story is a blockchain making IP protection and licensing programmable and efficient. It automates IP management, allowing creators to easily license, remix, and monetize their work. With Story, traditional legal complexities are replaced by on-chain smart contracts and off-chain legal agreements, simplifying the entire process.

## System Requirements

| **Hardware** | **Minimum Requirement** |
|--------------|-------------------------|
| **CPU**      | 4 Cores                 |
| **RAM**      | 8 GB                    |
| **Disk**     | 600 GB                  |
| **Bandwidth**| 50 MBit/s               |




Follow our TG : https://t.me/CryptoBuroOfficial






# Setup Story Install dependencies

  ## Install && run its automatically : 

  ```

  cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/setup.sh && chmod +x setup.sh && ./setup.sh
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


    

# Upgrade to Story v0.11.1


   ## Download And Setup Story v0.11.1 File : 
    
    cd $HOME && wget https://raw.githubusercontent.com/CryptoBuroMaster/Story-Node/main/story-v0.11.0.sh && chmod +x story-v0.11.0.sh && ./story-v0.11.0.sh

    

   ## Ensure your node is running correctly by checking the logs:
    
      journalctl -u story -f
    
    

# Node Reload : 

   ## stop node 

    sudo systemctl stop story
    sudo systemctl stop story-geth


  ## Start Node 

    sudo systemctl start story
    sudo systemctl start story-geth



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
