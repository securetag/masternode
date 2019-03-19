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

function systemd_reindex() {

  sleep 3
        echo "Stopping Worker"
        systemctl stop $WORKER.service
  sleep 3
        echo "Deleting old info"
        rm -r ../../home/STGMN/.securetag/blocks
        rm -r ../../home/STGMN/.securetag/backups
        rm -r ../../home/STGMN/.securetag/chainstate
        rm -r ../../home/STGMN/.securetag/database
        rm ../../home/STGMN/.securetag/peers.dat
        rm ../../home/STGMN/.securetag/mncache.dat
        rm ../../home/STGMN/.securetag/mnpayments.dat
        rm ../../home/STGMN/.securetag/netfulfilled.dat
        
  sleep 3
      echo "Reindexing....this will take awhile. Wait till IsSynced turns true then Ctrl-Z to exit and then start alias in wallet."
        systemctl start $WORKER.service
        su STGMN -c "watch /usr/local/bin/securetag-cli mnsync status"

    exit 1

}


function reindex_node() {
        systemd_reindex
exit 1
}

######################################################
#                      Main Script                   #
######################################################

clear

  systemd_reindex

