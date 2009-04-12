#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

# remove the old one.
if [ -d ~/Library/InputManagers/JSTalkEverywhere ]; then
    rm -rf ~/Library/InputManagers/JSTalkEverywhere
fi

./bin/makedist.sh

mkdir -p ~/Library/InputManagers

cp -r dist/JSTalkEverywhere ~/Library/InputManagers/
