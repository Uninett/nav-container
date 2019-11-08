#!/bin/bash -ex
# This script is designed to build NAV inside a docker container
VERSION=5.0.0

ORIG="$PWD"
DESTDIR="$PWD/.build"

export GIT_COMMITTER_NAME='Dummy' GIT_COMMITTER_EMAIL='dummy@example.org'

# Clean the destdir
rm -rf "$DESTDIR"; mkdir -p "$DESTDIR"

# Clone or update existing nav working copy
if [ -d nav ]; then
    cd nav
    git fetch origin
    git checkout $VERSION
    cd ..
else
    git clone https://github.com/Uninett/nav.git nav --branch $VERSION --depth 1
fi


# Build wheel from Python deps
mkdir -p .wheels
pip wheel -w ./.wheels/ -r nav/requirements.txt

#TODO: Install those wheels and build the NAV documentation
#pip install --no-index --find-links=./.wheels -r nav/requirements.txt

# Install NAV
pip install --root="$DESTDIR" ./nav
