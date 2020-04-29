#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "INITIAL_EXPID: ${INITIAL_EXPID:=1}"
echo "NUMBER_OF_EXPERIMENTS: ${NUMBER_OF_EXPERIMENTS:=4}"
echo "LAMBDA: ${LAMBDA:=20}"
echo "SIM_DURATION: ${SIM_DURATION:=2h30m}"
echo "IDLENESS: ${IDLENESS:=5m}"
echo "WARMUP: ${WARMUP:=500}"
echo "SCHEDULERS: ${SCHEDULERS:=0 1 2}"
echo "FLAGS: ${FLAGS:=pp-gci pp-nogci pp-nogc}"
echo "NUMBER_OF_INPUTS: ${NUMBER_OF_INPUTS:=8}"
echo "OUTPUT_PATH: ${OUTPUT_PATH:=/home/ubuntu/gci-faas-sim/simulation/results/}"
echo "INPUT_PATH: ${INPUT_PATH:=/home/ubuntu/gci-faas-sim/experiment/results/}"

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
        for sched in ${SCHEDULERS};
        do
            echo -e "${RED}RUNNING SIMULATION, SCHEDULER=${sched}, FLAG=${flag}, EXPID=${expid}${NC}"
            ./simulator -idleness=${IDLENESS} -lambda=${LAMBDA} -duration=${SIM_DURATION} -inputs=${inputs} -output=${OUTPUT_PATH} -scheduler=${sched} -scenario=${flag}${IDLENESS}${expid} --warmup=${WARMUP}
        done;
    done;
    metrics_file_name="${OUTPUT_PATH}sim${expid}-metrics"
    EXP_PATH=$(pwd)
    cd ${OUTPUT_PATH}
    files=$(ls | grep "metrics" | grep "gc" | grep "${i}")
    for f in ${files}; do cat "$f" >> "${metrics_file_name}.log"; done
    header=$(head -1 "${metrics_file_name}.log")
    grep -v "${header}" "${metrics_file_name}.log" > "${metrics_file_name}.csv"
    sed -i '1 i\'$header "${metrics_file_name}.csv"
    cd ${EXP_PATH}
    rm -rf ${OUTPUT_PATH}*.log
done

