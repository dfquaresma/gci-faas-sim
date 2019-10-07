#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$GCI_FLAG") || (-z "$FUNCTION_TARGET_IP") || (-z "$LOG_PATH") || (-z "$EXPID") ]];
then
  echo -e "${RED}MISSING FLAGS IN: setup.sh${NC}"
  exit
fi

RUNTIME_PATH="/home/ubuntu/gci-faas-sim/runtime/thumb-func/"
NOGCI_SETUP_COMMAND="entrypoint_port=8080 scale=0.1 image_url=http://s3.amazonaws.com/wallpapers2/wallpapers/images/000/000/408/thumb/375.jpg?1487671636 taskset 0x1 java -server -Xms128m -Xmx128m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -Xlog:gc:file=${LOG_PATH}thumb-gc-${EXPID}.log -jar ${RUNTIME_PATH}target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar >${LOG_PATH}thumb-stdout-${EXPID}.log 2>${LOG_PATH}thumb-stderr-${EXPID}.log"
GCI_SETUP_COMMAND="entrypoint_port=8082 scale=0.1 image_url=http://s3.amazonaws.com/wallpapers2/wallpapers/images/000/000/408/thumb/375.jpg?1487671636 taskset 0x1 nohup java -server -Xms128m -Xmx128m -XX:+UnlockExperimentalVMOptions -XX:+UseG1GC -XX:G1NewSizePercent=90 -XX:G1MaxNewSizePercent=90 -Xlog:gc:file=${LOG_PATH}thumb-gc-${EXPID}.log -Djvmtilib=${RUNTIME_PATH}gci/libgc.so -javaagent:${RUNTIME_PATH}gci/gciagent-0.1-jar-with-dependencies.jar=8500 -jar ${RUNTIME_PATH}target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar >${LOG_PATH}thumb-stdout-${EXPID}.log 2>${LOG_PATH}thumb-stderr-${EXPID}.log & taskset 0x2 ${RUNTIME_PATH}gci/gci-proxy --port=8080 --target=127.0.0.1:8082 --gci_target=127.0.0.1:8500 --ygen=104857600 >${LOG_PATH}proxy-stdout-${EXPID}.log 2>${LOG_PATH}proxy-stderr-${EXPID}.log"

SETUP_COMMAND="cd /home/ubuntu/gci-faas-sim/experiment/; ${NOGCI_SETUP_COMMAND}"
if [ "$GCI_FLAG" = "gci" ]
then
  SETUP_COMMAND="cd /home/ubuntu/gci-faas-sim/experiment/; ${GCI_SETUP_COMMAND}" 
fi

ssh-keygen -f "/home/ubuntu/.ssh/known_hosts" -R ${FUNCTION_TARGET_IP}
ssh -i ./id_rsa ubuntu@${FUNCTION_TARGET_IP} -o StrictHostKeyChecking=no "${SETUP_COMMAND}"
sleep 5
