#!/bin/bash

TMP_FOLDER=$(mktemp -d)
NAME_COIN="SecureTag"
GIT_REPO="https://github.com/securetag/securetag.git"
BINARY_FILE="securetagd"
BINARY_CLI="/usr/local/bin/securetag-cli"
BINARY_CLI_FILE="securetag-cli"
BINARY_PATH="/usr/local/bin/${BINARY_FILE}"
DIR_COIN=".securetag"
CONFIG_FILE="securetag.conf"
WORKER="STGMN"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function prepare_system() {

        echo -e "Checking if swap space is needed."
        PHYMEM=$(free -g|awk '/^Mem:/{print $2}')
        if [ "$PHYMEM" -lt "2" ];
          then
            echo -e "${GREEN}Server is running with less than 2G of RAM, creating 4G swap file."
            dd if=/dev/zero of=/swapfile bs=1024 count=4M
            chmod 600 /swapfile
            mkswap /swapfile
            swapon -a /swapfile
        else
          echo -e "${GREEN}Server running with at least 2G of RAM, no swap needed.${NC}"
   fi
        clear
}

function compile_server() {
        echo -e "Clone git repo and compile it. This may take some time. Press a key to continue."

        git clone $GIT_REPO $TMP_FOLDER
        cd $TMP_FOLDER

        ./autogen.sh
        ./configure
        make
}
function systemd_up() {

  sleep 3
        echo "Stopping Worker"
        systemctl stop $WORKER.service
  sleep 3
        cp -a $TMP_FOLDER/src/$BINARY_FILE $BINARY_PATH
        cp -a $TMP_FOLDER/src/$BINARY_CLI_FILE $BINARY_CLI
  sleep 3
        echo "Starting Worker"
        systemctl start $WORKER.service
        systemctl enable $WORKER.service >/dev/null 2>&1

  if [[ -z "$(pidof ${BINARY_FILE})" ]]; then
    echo -e "${RED}${NAME_COIN} is not running${NC}, please investigate. You should start by running"
    echo "systemctl start $WORKER.service"
    echo "systemctl status $WORKER.service"
    echo "less /var/log/syslog"
    exit 1
  fi
}


function setup_node() {
        systemd_up
exit 1
}

######################################################
#                      Main Script                   #
######################################################

clear

  prepare_system
  compile_server
  setup_node

