#!/bin/bash
date
set -x

# To avoid execution without passing environment variables
if [[ (-z "$FILE_NAME") ]];
then
  echo -e "${RED}FILE_NAME MISSING: workload.sh${NC}"
  exit
fi

echo -e "status;latency" > ${FILE_NAME}
for i in `seq 1 10000`
do
    curl -X GET -o /dev/null -s -w '%{http_code};%{time_total}\n' localhost:8080 >> ${FILE_NAME}
done

sed -i 's/,/./g' ${FILE_NAME}
sed -i 's/;/,/g' ${FILE_NAME}
