#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$CONTAINER_TAG") ]];
then
  echo -e "${RED}CONTAINER_TAG MISSING: setup.sh${NC}"
  exit
fi

sudo docker run -d --network=host --cpus=1.0 --cpuset-cpus=0 --rm --name container-${CONTAINER_TAG} image-${CONTAINER_TAG}
