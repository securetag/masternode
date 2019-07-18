#!/bin/bash
# SecureTag Masternode Setup Script for Ubuntu 16.04 ,18.04 and 19.04 LTS
# Script will attempt to autodetect primary public IPV4 address
# and generate masternode private key unless specified in command line
#
# Usage:
# bash install.sh [Masternode_Private_Key]
#
# Example 1: Existing genkey created earlier is supplied
# bash install.sh 8tJ5mkkarwdqMkSbwtHKKnypRnpggTBxNK2GjjguDz9fsEDJ2Ac
#

#Color codes
RED='\033[0;91m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

#SecureTag TCP port
PORT=12919

#Clear keyboard input buffer
function clear_stdin { while read -r -t 0; do read -r; done; }

#Delay script execution for N seconds
function delay { echo -e "${GREEN}Sleep for $1 seconds...${NC}"; sleep "$1"; }

#Stop daemon if it's already running
function stop_daemon {
    if pgrep -x 'securetagd' > /dev/null; then
        echo -e "${YELLOW}Attempting to stop securetagd${NC}"
        securetag-cli stop
        delay 30
        if pgrep -x 'securetagd' > /dev/null; then
            echo -e "${RED}securetagd daemon is still running!${NC} \a"
            echo -e "${YELLOW}Attempting to kill...${NC}"
            pkill securetagd
            delay 30
            if pgrep -x 'securetagd' > /dev/null; then
                echo -e "${RED}Can't stop securetagd! Reboot and try again...${NC} \a"
                exit 2
            fi
        fi
    fi
}

#Process command line parameters
genkey=$1

clear
echo -e "${YELLOW}SecureTag Masternode Setup Script${NC}"
echo -e "${GREEN}Updating system and installing required packages...${NC}"
echo -e "Prepare the system to install ${NAME_COIN} master node."
	echo -e " "
	echo -e "  _____ ______ _____ _    _ _____  ______ _______       _____ "
	echo -e " / ____|  ____/ ____| |  | |  __ \|  ____|__   __|/\   / ____|"
	echo -e "| (___ | |__ | |    | |  | | |__) | |__     | |  /  \ | |  __ "
	echo -e " \___ \|  __|| |    | |  | |  _  /|  __|    | | / /\ \| | |_ |"
	echo -e " ____) | |___| |____| |__| | | \ \| |____   | |/ ____ \ |__| |"
	echo -e "|_____/|______\_____|\____/|_|  \_\______|  |_/_/    \_\_____|"
	echo -e " "                                                               
	echo -e " CODECT is a B*tch"
	echo -e " "

sudo apt-get update -y


# Determine primary public IP address
dpkg -s dnsutils 2>/dev/null >/dev/null || sudo apt-get -y install dnsutils
# change to google 
# public_ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

public_ip=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com | awk -F'"' '{ print $2}')

if [ -n "$public_ip" ]; then
    echo -e "${YELLOW}IPV4 Address detected:" $public_ip ${NC}
else
    echo -e "${RED}ERROR:${YELLOW} Public IPV4 Address was not detected!${NC} \a"
    clear_stdin
    read -e -p "Enter VPS Public IPV4 Address: " public_ip
    if [ -z "$public_ip" ]; then
        echo -e "${RED}ERROR:${YELLOW} Public IPV4 Address must be provided. Try again...${NC} \a"
        exit 1
    fi
fi

# update packages and upgrade Ubuntu
sudo apt-get -y upgrade
sudo apt-get -y dist-upgrade
sudo apt-get -y autoremove
sudo apt-get -y install wget nano htop jq
sudo apt-get -y install libzmq3-dev
sudo apt-get -y install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev
sudo apt-get -y install libevent-dev
sudo apt -y install software-properties-common

if [[ $(lsb_release -rs) < "19.04" ]]; then
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get -y update
sudo apt-get install -y libsodium-dev
sudo apt-get -y install libdb4.8-dev libdb4.8++-dev
else
sudo apt install -y libdb5.3-dev 
sudo apt install -y libdb5.3++-dev 
wget http://ftp.nl.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb
sudo dpkg -i libssl1.0.0_1.0.1t-1+deb8u8_amd64.deb
fi


sudo apt-get -y install libminiupnpc-dev

sudo apt-get -y install fail2ban
sudo service fail2ban restart

sudo apt-get install ufw -y
sudo apt-get update -y

sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow $PORT/tcp
echo -e "${YELLOW}"
sudo ufw --force enable
echo -e "${NC}"

#Generating Random Password for securetagd JSON RPC
rpcpassword=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

#Create 2GB swap file
sudo  echo "export PATH=$PATH:/sbin" >> ~/.profile
. ~/.profile


if  [[ $(sudo /sbin/swapon -s | wc -l) -gt 1 ]] ; then
    echo -e "${GREEN}Skipping disk swap configuration...${NC} \n"
else
    echo -e "${YELLOW}Creating 2GB disk swap file. \nThis may take a few minutes!${NC} \a"
   
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo /sbin/swapon /swapfile
     
    
    if [ $? -eq 0 ]; then
        sudo cp /etc/fstab /etc/fstab.bak
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
        sudo sysctl vm.vfs_cache_pressure=50
        sudo sysctl vm.swappiness=10
        echo -e "${GREEN}Swap was created successfully!${NC} \n"
    else
        echo -e "${YELLOW}Operation not permitted! Optional swap was not created.${NC} \a"
    fi
fi

#Installing Daemon
cd ~
stop_daemon


# Deploy binaries to /usr/bin
if [[ `lsb_release -rs` == "16.04" ]] 
then
sudo cp $PWD/masternode/securetag_daemon_16_04/securetag* /usr/bin/  
elif  [[ `lsb_release -rs` == "18.04" ]] 
then
sudo cp $PWD/masternode/securetag_daemon_18_04/securetag* /usr/bin/  
elif  [[ `lsb_release -rs` == "19.04" ]] 
then
sudo cp $PWD/masternode/securetag_daemon_19_04/securetag* /usr/bin/ 
fi
sudo chmod 755 -R $PWD/masternode
sudo chmod 755 /usr/bin/securetag*

# Deploy masternode monitoring script
sudo cp $PWD/masternode/nodemon.sh /usr/local/bin
sudo chmod 711 /usr/local/bin/nodemon.sh

#Create SecureTag datadir
if [ ! -f $PWD/.securetag/securetag.conf ]; then 
	sudo mkdir $PWD/.securetag
fi

echo -e "${YELLOW}Creating securetag.conf...${NC}"

# If genkey was not supplied in command line, we will generate private key on the fly
if [ -z $genkey ]; then
sudo tee <<EOF  $PWD/.securetag/securetag.conf  >/dev/null
rpcuser=securetagrpc
rpcpassword=$rpcpassword
EOF

    sudo chmod 755 -R $PWD/.securetag/securetag.conf

    #Starting daemon first time just to generate masternode private key
    sudo securetagd -daemon
    delay 30

    #Generate masternode private key
    echo -e "${YELLOW}Generating masternode private key...${NC}"
    genkey=$(sudo securetag-cli masternode genkey)
    if [ -z "$genkey" ]; then
        echo -e "${RED}ERROR:${YELLOW}Can not generate masternode private key.$ \a"
        echo -e "${RED}ERROR:${YELLOW}Reboot VPS and try again or supply existing genkey as a parameter."
        exit 1
    fi
    
    #Stopping daemon to create securetag.conf
    stop_daemon
    delay 30
fi

# Create securetag.conf
sudo tee <<EOF  $PWD/.securetag/securetag.conf  >/dev/null
rpcuser=securetagrpc
rpcpassword=$rpcpassword
rpcallowip=127.0.0.1
port=12919
listen=1
server=1
daemon=1
maxconnections=256
externalip=$public_ip
masternode=1
masternodeprivkey=$genkey
addnode=207.246.89.11
EOF

#Finally, starting SecureTag daemon with new securetag.conf
sudo securetagd -daemon
delay 5
#Install Sentinel
cd /root/.securetag
sudo apt-get install -y git python-virtualenv
sudo git clone https://github.com/securetag/sentinel.git
cd sentinel
export LC_ALL=C
sudo apt-get install -y virtualenv
virtualenv venv
venv/bin/pip install -r requirements.txt

#Setting auto star cron job for securetagd
#cronjob="@reboot sleep 30 && securetagd"
#crontab -l > tempcron
#if ! grep -q "$cronjob" tempcron; then
    echo -e "${GREEN}Configuring crontab job...${NC}"
#    echo $cronjob >> tempcron
#    crontab tempcron
#fi
#sudo rm tempcron
 (crontab -l 2>/dev/null; echo '@reboot sleep 30 && cd /usr/bin/securetagd -daemon -shrinkdebugfile') | crontab
    (crontab -l 2>/dev/null; echo '* * * * * cd /root/.securetag/sentinel && ./venv/bin/python bin/sentinel.py >/$') | crontab
echo -e "========================================================================
${YELLOW}Masternode setup is complete!${NC}
========================================================================
Masternode was installed with VPS IP Address: ${YELLOW}$public_ip${NC}
Masternode Private Key: ${YELLOW}$genkey${NC}
Now you can add the following string to the masternode.conf file
for your Hot Wallet (the wallet with your SecureTag collateral funds):
======================================================================== \a"
echo -e "${YELLOW}Alias $public_ip:$PORT $genkey txhash outputidx${NC}"
echo -e "========================================================================
Use your mouse to copy the whole string above into the clipboard by
triple-click + single-click (Dont use Ctrl-C) and then paste it 
into your ${YELLOW}masternode.conf${NC} file and replace:
    ${YELLOW}Alias${NC} - with your desired masternode name (alias)
    ${YELLOW}txhash${NC} - with Transaction Id from masternode outputs
    ${YELLOW}outputidx${NC} - with Transaction Index (0 or 1)
     Remember to save the masternode.conf and restart the wallet!
To introduce your new masternode to the SecureTag network, you need to
issue a masternode start command from your wallet, which proves that
the collateral for this node is secured."

clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "1) Wait for the node wallet on this VPS to sync with the other nodes
on the network. Eventually the 'IsSynced' status will change
to 'true', which will indicate a complete sync, although it may take
from several minutes to several hours depending on the network state.
Your initial Masternode Status may read:
    ${YELLOW}Node just started, not yet activated${NC} or
    ${YELLOW}Node  is not in masternode list${NC}, which is normal and expected.
2) Wait at least until 'IsBlockchainSynced' status becomes 'true'.
At this point you can go to your wallet and issue a start
command by either using Debug Console:
    Tools->Debug Console-> enter: ${YELLOW}startmasternode alias false alias${NC}
    where ${YELLOW}alias${NC} is the name of your masternode (alias)
    as it was entered in the masternode.conf file
    
or by using wallet GUI:
    Masternodes -> Select masternode -> RightClick -> ${YELLOW}start alias${NC}
Once completed step (2), return to this VPS console and wait for the
Masternode Status to change to: 'Masternode successfully started'.
This will indicate that your masternode is fully functional and
you can celebrate this achievement!
Currently your masternode is syncing with the SecureTag network...
The following screen will display in real-time
the list of peer connections, the status of your masternode,
node synchronization status and additional network and node stats.
"
clear_stdin
read -p "*** Press any key to continue ***" -n1 -s

echo -e "
${GREEN}...scroll up to see previous screens...${NC}
Here are some useful commands and tools for masternode troubleshooting:
========================================================================
To view masternode configuration produced by this script in securetag.conf:
${YELLOW}cat $PWD/.securetag/securetag.conf${NC}
Here is your securetag.conf generated by this script:
-------------------------------------------------${YELLOW}"
cat $PWD/.securetag/securetag.conf
echo -e "${NC}-------------------------------------------------
NOTE: To edit securetag.conf, first stop the securetagd daemon,
then edit the securetag.conf file and save it in nano: (Ctrl-X + Y + Enter),
then start the securetagd daemon back up:
to stop:   ${YELLOW}securetag-cli stop${NC}
to edit:   ${YELLOW}nano $PWD/.securetag/securetag.conf${NC}
to start:  ${YELLOW}securetagd${NC}
========================================================================
To view securetagd debug log showing all MN network activity in realtime:
${YELLOW}tail -f $PWD/.securetag/debug.log${NC}
========================================================================
To monitor system resource utilization and running processes:
${YELLOW}htop${NC}
========================================================================
To view the list of peer connections, status of your masternode, 
sync status etc. in real-time, run the nodemon.sh script:
${YELLOW}nodemon.sh${NC}
or just type 'node' and hit <TAB> to autocomplete script name.
========================================================================
Enjoy your SecureTag Masternode and thanks for using this setup script!
"
# Run nodemon.sh
# nodemon.sh

# EOF
