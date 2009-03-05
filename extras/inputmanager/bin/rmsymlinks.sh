#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`
cd $SRC_HOME

if [ -d ~/Library/InputManagers/JSTalkEverywhere ]; then
    rm -rf ~/Library/InputManagers/JSTalkEverywhere
fi
