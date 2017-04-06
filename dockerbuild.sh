#!/bin/bash -ex
# This script is designed to build NAV inside a docker container
DESTDIR="$PWD/.build"
mkdir -p "$DESTDIR"

cd nav

make clean || true
./autogen.sh
./configure NAV_USER="nav"
make
make install DESTDIR="$DESTDIR"

cd ..

if [ -d /wheelhouse ]; then
    mkdir -p .wheels
    cp -a /wheelhouse/*.whl .wheels/
fi
