#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "FLAGS: ${FLAGS:=gci nogci}"
echo "NUMBER_OF_EXPERIMENTS: ${NUMBER_OF_EXPERIMENTS:=8}"

echo -e "${YELLOW}BUILDING UP CONTAINERS${NC}"
bash build.sh

mkdir -p ./input-entries/
for expid in `seq 1 ${NUMBER_OF_EXPERIMENTS}`;
do
    for flag in ${FLAGS};
    do
        echo -e "${YELLOW}TEARING DOWN CONTAINERS${NC}"
        bash teardown.sh

        echo -e "${YELLOW}SETTING UP CONTAINERS${NC}"
        CONTAINER_TAG="${flag}" bash setup.sh

        echo -e "${RED}RUNNING WORKLOAD FOR ${CONTAINER_TAG} EXPID ${EXPID}${NC}"
        FILE_NAME="./input-entries/${flag}${expid}.csv" bash workload.sh
    done;
done
