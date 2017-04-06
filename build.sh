#!/bin/sh -ex
IMAGE=navbuild
uid=$(id -u)
# Build the Docker image needed to build the NAV source code
docker build -f Dockerfile.build -t "$IMAGE" .
# Run the NAV build inside a container based on the previous image, placing
# the output in $PWD/.build
docker run -ti --rm -v "$PWD:/source" --cap-drop=all -u "$uid" "$IMAGE"

# Use docker compose to build all the related images for production
docker-compose build

# Make mount directories for docker-compose
# FIXME need to look at privileges and logging
mkdir -p data
mkdir -p data/log ; chmod a+rwx data/log
mkdir -p data/roomimages ; chmod a+rwx data/roomimages
