#!/bin/bash
CACHE_ARGS=""
if [ "$1" != "no-cache" ]
then
    docker pull archlinux
    CACHE_ARGS="--no-cache --pull"
fi
docker build $CACHE_ARGS --build-arg VERS=v1.4.0-$(date +%Y%m%d)-${BUILD_NUM:-001} -t maul-os-desktop:latest .
