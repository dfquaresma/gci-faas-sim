#!/bin/bash
date
set -x

cd ../runtime/thumb-func/
mvn clean install

cd ./gci/
JAVA_HOME="/usr/lib/jvm/java-1.11.0-openjdk-amd64" PATH_TO_GCI="/home/ubuntu/gci-faas-sim/runtime/thumb-func/gci" bash libgcso-entrypoint.sh

cd ../../../experiment
