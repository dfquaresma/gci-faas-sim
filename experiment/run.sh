#!/bin/bash
date
set -x

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

mkdir -p ./input-entries/

echo -e "${YELLOW}TEARING DOWN CONTAINERS${NC}"
bash teardown.sh

echo -e "${YELLOW}BUILDING UP CONTAINERS${NC}"
bash build.sh

echo -e "${YELLOW}SETTING UP CONTAINERS${NC}"
CONTAINER_TAG="TODO" bash setup.sh

echo -e "${RED}RUNNING WORKLOAD FOR ${CONTAINER_TAG} EXPID ${EXPID}${NC}"
FILE_NAME="TODO" bash workload.sh
