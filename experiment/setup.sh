#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$CONTAINER_TAG") ]];
then
  echo -e "${RED}CONTAINER_TAG MISSING: setup.sh${NC}"
  exit
fi

sudo docker run -d --network=host --cpus=2.0 --cpuset-cpus="0,1" --rm --name container-${CONTAINER_TAG} image-${CONTAINER_TAG}
sleep 5