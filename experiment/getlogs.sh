#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$CONTAINER_TAG") || (-z "$FILE_NAME") || (-z "$PATH") ]];
then
  echo -e "${RED}CONTAINER_TAG AND/OR FILE_NAME AND/OR PATH MISSING: getlogs.sh${NC}"
  exit
fi

mkdir -p ${PATH}
docker cp "container-${CONTAINER_TAG}:/home/app/gc_thumb.log" ${FILE_NAME}
