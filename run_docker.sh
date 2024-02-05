#!/bin/bash

if [ $# -lt 2 ]; then
  echo 'usage: ./run_docker.sh <mount_path> <image_name>'
  exit
fi

ws=$(realpath $1)
image=$2
echo "-- to mount workspace: $ws"
echo "-- image is          : $image"

docker run -d --cap-add=SYS_ADMIN --privileged --security-opt seccomp=unconfined --name=$image \
        --add-host=host.docker.internal:host-gateway \
        -v${ws}:/workspace/whippet_docker -it $image

