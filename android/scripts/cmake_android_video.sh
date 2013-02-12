#!/bin/sh
cd `dirname $0`/..

mkdir -p build_video
cd build_video

cmake -DBUILD_ANDROID_VIDEO_WRAPPER=ON -DCMAKE_TOOLCHAIN_FILE=../android.toolchain.cmake -DANDROID_TOOLCHAIN_NAME="arm-linux-androideabi-4.4.3" -DANDROID_STL=stlport_static -DANDROID_STL_FORCE_FEATURES=OFF -DANDROID_SOURCE_TREE=/home/alexander/Projects/AndroidSource/4.2 $@ ../..
