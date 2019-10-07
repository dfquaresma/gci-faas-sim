#!/bin/bash
date
set -x

cd ../runtime/thumb-func/
mvn clean install

cd ../../experiment