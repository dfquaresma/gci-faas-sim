#!/bin/bash
date
set -x

sudo docker rm -f container-gci container-nogci
sleep 5
