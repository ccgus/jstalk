#!/bin/bash

SRC_HOME=`cd ${0%/*}/..;pwd`
BUILD_DIR="/tmp/fo"
cd $SRC_HOME

xcodebuild -configuration Release -project jstalkeverywhere.xcodeproj build OBJROOT=$BUILD_DIR SYMROOT=$BUILD_DIR

mkdir -p dist/JSTalkEverywhere

cp -r /tmp/fo/Release/JSTalkEverywhere.bundle dist/JSTalkEverywhere/.
cp resources/Info dist/JSTalkEverywhere/.

cd dist

tar cvfz JSTalkEverywhere.tgz JSTalkEverywhere
