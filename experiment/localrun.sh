#!/bin/bash
date
set -x

echo "EXPID: ${EXPID:=14}"
echo "FLAGS: ${FLAGS:=gci}"
echo "NUMBER_OF_REQUESTS: ${NUMBER_OF_REQUESTS:=2500}"
echo "REPO_PATH: ${REPO_PATH:=./local-input-entries/}"

mkdir -p ${REPO_PATH}
sudo bash build.sh

for flag in ${FLAGS};
do
    sudo bash teardown.sh
    sudo CONTAINER_TAG=${flag} bash setup.sh

    echo -e "servicetime;status;latency" > ${REPO_PATH}${flag}${EXPID}.csv
    for i in `seq 1 ${NUMBER_OF_REQUESTS}`;
    do
        #curl -X GET -o /dev/null -s -w '%{http_code};%{time_total}\n' localhost:8080 >> ${REPO_PATH}${flag}${EXPID}.csv
        curl -X GET -s -w ';%{time_total};%{http_code}\n' localhost:8080 >> ${REPO_PATH}${flag}${EXPID}.csv
    done
    sed -i 's/,/./g' ${REPO_PATH}${flag}${EXPID}.csv
    sed -i 's/;/,/g' ${REPO_PATH}${flag}${EXPID}.csv

    docker cp "container-${flag}:/home/app/gc_thumb.log" "${REPO_PATH}${flag}${EXPID}-gc.log"
    docker cp "container-${flag}:/home/app/proxy-stdout.log" "${REPO_PATH}${flag}${EXPID}-proxy-stdout.log"
    docker cp "container-${flag}:/home/app/proxy-stderr.log" "${REPO_PATH}${flag}${EXPID}-proxy-stderr.log"
    docker logs container-${flag} >${REPO_PATH}${flag}${EXPID}-stdout.log 2>${REPO_PATH}${flag}${EXPID}-stderr.log
done



