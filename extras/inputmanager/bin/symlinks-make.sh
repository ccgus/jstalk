#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`

cd $SRC_HOME

if [ -d ~/Library/InputManagers/JSTalkEverywhere ]; then
    rm -rf ~/Library/InputManagers/JSTalkEverywhere
fi

#ln -s 

mkdir ~/Library/InputManagers/JSTalkEverywhere

cd ~/Library/InputManagers/JSTalkEverywhere

ln -s $SRC_HOME/resources/Info .

if [ -d ~/builds ]; then
    echo ehy!
    ln -s ~/builds/Debug/JSTalkEverywhere.bundle .
else
    ln -s $SRC_HOME/build/JSTalkEverywhere.bundle .
fi