#!/bin/bash

SRC_DIR=`cd ${0%/*}/..; pwd`

FORK_SRC_DIR=$SRC_DIR/../jscocoafork

cd "$SRC_DIR/jscocoa/JSCocoa/"

for f in *.m  *.h; do
    echo =========== $f ============
    diff $f $FORK_SRC_DIR/JSCocoa/$f
done


for f in *.m  *.h; do
    echo cp $FORK_SRC_DIR/JSCocoa/$f $SRC_DIR/jscocoa/JSCocoa/.
done


