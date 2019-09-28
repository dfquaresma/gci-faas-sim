#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "FLAGS: ${FLAGS:=gci nogci}"
echo "NUMBER_OF_EXPERIMENTS: ${NUMBER_OF_EXPERIMENTS:=1}"
echo "FUNCTION_TARGET_IP: ${FUNCTION_TARGET_IP:=10.11.16.93}"
echo "WORKLOAD_TARGET_IP: ${WORKLOAD_TARGET_IP:=10.11.16.117}"
echo "ID_RSA_PATH: ${ID_RSA_PATH:=id_rsa}"
echo "REPO_PATH: ${REPO_PATH:='./input-entries/'}"
echo "CD_TO_SCRIPTS_PATH: ${CD_TO_SCRIPTS_PATH:='cd /home/ubuntu/gci-faas-sim/experiment/'}"

ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${FUNCTION_TARGET_IP}
ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${WORKLOAD_TARGET_IP}

echo -e "${YELLOW}BUILDING UP CONTAINERS${NC}"
ssh -i ${ID_RSA_PATH} ubuntu@${TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; sudo bash build.sh"

for expid in `seq 1 ${NUMBER_OF_EXPERIMENTS}`;
do
    for flag in ${FLAGS};
    do
        echo -e "${YELLOW}TEARING DOWN CONTAINERS${NC}"
        ssh -i ${ID_RSA_PATH} ubuntu@${FUNCTION_TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; sudo bash teardown.sh"

        echo -e "${YELLOW}SETTING UP CONTAINERS${NC}"
        ssh -i ${ID_RSA_PATH} ubuntu@${FUNCTION_TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; sudo CONTAINER_TAG=${flag} bash setup.sh"

        echo -e "${RED}RUNNING WORKLOAD FOR ${CONTAINER_TAG} EXPID ${EXPID}${NC}"
        ssh -i ${ID_RSA_PATH} ubuntu@${WORKLOAD_TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; sudo REPO_PATH=${REPO_PATH} FILE_NAME=${REPO_PATH}${flag}${expid}.csv bash workload.sh"

        echo -e "${RED}GETTING RESULTS FOR ${CONTAINER_TAG} EXPID ${EXPID}${NC}"
        ssh -i ${ID_RSA_PATH} ubuntu@${FUNCTION_TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; sudo CONTAINER_TAG="${flag}" REPO_PATH=${REPO_PATH} FILE_NAME=${REPO_PATH}${flag}${expid}.log bash getlogs.sh"
    done;
done
