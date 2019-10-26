#!/bin/bash
date
set -x

cd ../gci-files/
JAVA_HOME="/usr/lib/jvm/java-1.11.0-openjdk-amd64" PATH_TO_GCI="/home/ubuntu/gci-faas-sim/gci-files" bash libgcso-entrypoint.sh
sudo chmod 775 gci-proxy

cd ../runtime/thumb-func/
mvn clean install

cd ../noop-func/
mvn clean install

cd ../../experiment
sudo chmod 775 vegeta
sudo chmod 775 workload
sudo chmod 400 id_rsa
