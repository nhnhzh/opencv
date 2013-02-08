#!/bin/sh
cd `dirname $0`/..

mkdir -p build_nonlinux_gnueabi
cd build_nonlinux_gnueabi

cmake -DCMAKE_TOOLCHAIN_FILE=../arm-nonlinux-gnueabi.toolchain.cmake $@ ../../..

