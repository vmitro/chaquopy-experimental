#!/bin/bash
set -eu

#toolchain=$(realpath $(dirname $CC)/..)
toolchain=$NDK_TOOLCHAIN
#arch=$(echo $CHAQUOPY_TRIPLET | sed 's/-.*//; s/i686/i386/')
arch=$(echo $HOST_TRIPLE | sed 's/-.*//; s/i686/i386/')
echo $HOST_TRIPLE
echo $arch
# /opt/android-sdk/ndk-bundle/toolchains/llvm/prebuilt/linux-x86_64/lib64/clang/14.0.7/lib/linux/aarch64/

mkdir -p $PREFIX/lib
cp $toolchain/lib64/clang/$PKG_VERSION/lib/linux/$arch/libomp.so $PREFIX/lib
