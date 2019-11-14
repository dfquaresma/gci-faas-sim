#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "INITIAL_EXPID: ${INITIAL_EXPID:=1}"
echo "NUMBER_OF_EXPERIMENTS: ${NUMBER_OF_EXPERIMENTS:=1}"
echo "LAMBDA: ${LAMBDA:=150}"
echo "WARMUP: ${WARMUP:=500}"
echo "OP: ${OP:=true false}" # to simulate the optimized scheduler 
echo "FLAGS: ${FLAGS:=pp-gci pp-nogci}"
echo "NUMBER_OF_INPUTS: ${NUMBER_OF_INPUTS:=8}"
echo "OUTPUT_PATH: ${OUTPUT_PATH:=/home/davidfq/Desktop/gci-faas-sim/simulation/results/}"
echo "INPUT_PATH: ${INPUT_PATH:=/home/davidfq/Desktop/gci-faas-sim/experiment/results/}"

echo -e "${YELLOW}CREATING PATHS${NC}"
mkdir -p ${OUTPUT_PATH}
for expid in `seq ${INITIAL_EXPID} ${NUMBER_OF_EXPERIMENTS}`;
do
    for flag in ${FLAGS};
    do

        echo -e "${YELLOW}CONCATENATING THE INPUTS${NC}"
        inputs="${INPUT_PATH}${flag}1.csv"
        for id in `seq 2 ${NUMBER_OF_INPUTS}`;
        do
            inputs="${inputs},${INPUT_PATH}${flag}${id}.csv"
        done;

        for op in ${OP};
        do
            echo -e "${RED}RUNNING SIMULATION, OP=${op}, FLAG=${flag}, EXPID=${expid}${NC}"
            ./simulator -lambda=${LAMBDA} -inputs=${inputs} -output=${OUTPUT_PATH} -optimized=${op} -filename=sim-${flag}${expid} --warmup=${WARMUP}
        done;
    done;
done


