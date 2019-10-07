#!/bin/bash
date
set -x

cd ../containers/nogci-thumbnailator/
docker build -t image-nogci .

cd ../gci-thumbnailator/
docker build -t image-gci .

cd ../../experiment