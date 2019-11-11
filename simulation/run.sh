#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "LAMBDA: ${LAMBDA:=25}"
echo "OP: ${OP:=true false}"
echo "FLAGS: ${FLAGS:=gci nogci}"
echo "ID_RSA_PATH: ${ID_RSA_PATH:=../experiment/id_rsa}"
echo "SIM_TARGET_IP: ${FUNCTION_TARGET_IP:=10.11.16.117}"
echo "NUMBER_OF_INPUTS: ${NUMBER_OF_INPUTS:=32}"
echo "OUTPUT_PATH: ${OUTPUT_PATH:=/home/ubuntu/gci-faas-sim/simulation/results/}"
echo "INPUT_PATH: ${INPUT_PATH:=/home/ubuntu/gci-faas-sim/experiment/results/}"
echo "CD_TO_SCRIPTS_PATH: ${CD_TO_SCRIPTS_PATH:=cd /home/ubuntu/gci-faas-sim/experiment}"

mkdir -p ${OUTPUT_PATH}
for flag in ${FLAGS};
do
    inputs=""
    if [ "$flag" = "gci" ]
    then
        inputs="${INPUT_PATH}gci1.csv"
    else
        inputs="${INPUT_PATH}nogci1.csv"
    fi

    for id in `seq 2 ${NUMBER_OF_INPUTS}`;
    do
        if [ "$flag" = "gci" ]
        then
            inputs="${inputs},${INPUT_PATH}gci${id}.csv"
        else
            inputs="${inputs},${INPUT_PATH}nogci${id}.csv"
        fi
    done;

    for op in ${OP};
    do
        ssh -i ${ID_RSA_PATH} ubuntu@${SIM_TARGET_IP} -o StrictHostKeyChecking=no "${CD_TO_SCRIPTS_PATH}; ./simulator -lambda=${LAMBDA} -inputs=${inputs} -output=${OUTPUT_PATH} -optimized=${op}"
    done;
    
done;
