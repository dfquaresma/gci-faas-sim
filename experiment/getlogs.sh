#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$CONTAINER_TAG") || (-z "$FILE_NAME") || (-z "$REPO_PATH") ]];
then
  echo -e "${RED}CONTAINER_TAG AND/OR FILE_NAME AND/OR REPO_PATH MISSING: getlogs.sh${NC}"
  exit
fi

mkdir -p ${REPO_PATH}
docker cp "container-${CONTAINER_TAG}:/home/app/gc_thumb.log" ${FILE_NAME}
