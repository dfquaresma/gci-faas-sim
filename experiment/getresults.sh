#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$CONTAINER_TAG") || (-z "$FILE_NAME") ]];
then
  echo -e "${RED}CONTAINER_TAG MISSING: setup.sh${NC}"
  exit
fi

docker cp "container-${CONTAINER_TAG}:/home/app/gc_thumb.log" ${FILE_NAME}
