#!/bin/sh

SRC_DIR=`cd ${0%/*}/..; pwd`

if [ ! -d ~/Library/Application\ Support/JSTalk/Plug-ins/ ]; then
    mkdir -p ~/Library/Application\ Support/JSTalk/Plug-ins/
fi

cd ~/Library/Application\ Support/JSTalk/Plug-ins/

for i in /builds/Debug/*.jstplugin; do
    ln -s $i 
done
