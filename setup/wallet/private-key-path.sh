# To read the private key and format it with spaces:

PRIVATE_KEY=$(cat /root/.story/story/config/private_key.txt | sed 's/../& /g')
echo "PRIVATE_KEY=\"$PRIVATE_KEY\"" > private-key-path.sh
echo 'PRIVATE_KEY_PATH="/root/.story/story/config/private_key.txt"' >> private-key-path.sh
