#!/bin/bash

# Function to print info messages
print_info() {
    echo -e "\e[32m[INFO] $1\e[0m"
}

# Function to print error messages
print_error() {
    echo -e "\e[31m[ERROR] $1\e[0m"
}


# Story Node services ko refresh aur start karna
sudo systemctl daemon-reload && sudo systemctl enable story-geth && sudo systemctl enable story && sudo systemctl start story-geth && sudo systemctl start story


# Function to check and install required packages
function install_dependencies {
    # Check if curl is installed
    if ! command -v curl &> /dev/null
    then
        print_info "Installing curl..."
        sudo apt update && sudo apt install -y curl
    else
        print_info "curl is already installed."
    fi

    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        print_info "Installing jq..."
        sudo apt update && sudo apt install -y jq
    else
        print_info "jq is already installed."
    fi
}



# Functions for each menu option
function geth_logs {
    print_info "Displaying Geth Logs..."
    sudo journalctl -u story-geth -f -o cat
}

function story_logs {
    print_info "Displaying Story Logs..."
    sudo journalctl -u story -f -o cat
}

function sync_status {
    print_info "Displaying Sync Status..."
    curl localhost:26657/status | jq
}

function geth_status {
    print_info "Displaying Geth Status..."
    sudo systemctl status story-geth
}

function story_status {
    print_info "Displaying Story Status..."
    sudo systemctl status story
}



# Function to display the logs menu
function show_logs_menu {
    echo "Logs Menu:"
    echo "1. Geth-Logs"
    echo "2. Story-Logs"
    echo "3. Sync-Status"
    echo "4. Geth-Status"
    echo "5. Story-Status"
    echo "6. Exit"
    echo -n "Select an option (1-6): "
}


# Main script loop
while true; do
    show_logs_menu
    read option

    case $option in
        1)
            geth_logs
            ;;
        2)
            story_logs
            ;;
        3)
            sync_status
            ;;
        4)
            geth_status
            ;;
        5)
            story_status
            ;;
        6)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_info "Invalid option. Please select a valid option."
            ;;
    esac
done