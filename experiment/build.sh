#!/bin/bash
date
set -x

cd ../runtime/thumbnailator-server-maven/
mvn clean install

cd ../../experiment