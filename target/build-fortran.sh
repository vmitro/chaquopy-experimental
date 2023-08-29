#!/bin/bash
set -eu

# WARNING: this script was last tested in January 2020, to build this commit:
# https://android.googlesource.com/toolchain/gcc/+/f236b449daeff96112b586ed4f06980e88012d39
# It has not been updated for the current layout of the `target` directory.

# This script builds the Fortran compiler, which is required for building SciPy and
# OpenBLAS.
#
# The stock GCC has Android support for ARM, but only Google's fork extends that to ARM64. So
# we're building the Google fork of GCC 4.9, which was the last version to be included in the
# NDK before they switched over to Clang. We install it into the toolchain in such a way that
# it's only used for Fortran: C and C++ will still use the NDK's current version of Clang.
#
# The Google fork has many changes, so it's hard to tell how much work it would be to move to
# the stock GCC, but it would at least require updating gcc/config/aarch64 to use the correct
# Android filenames for start files (crt[...].o) and the dynamic linker (/system/bin/linker64).

target_dir=$(dirname $(realpath $0))
toolchain=$(realpath ${1:?})

cd $target_dir
. build-common.sh

src_dir=$target_dir/gcc/gcc-4.9
cd $src_dir
contrib/download_prerequisites

build_dir=$target_dir/gcc/build
rm -rf $build_dir
mkdir -p $build_dir
cd $build_dir
export PATH=$PATH:$toolchain/bin  # For target assembler and linker.

config_args="--host=x86_64-linux-gnu --target=$host_triplet --enable-languages=c,fortran"

# Since the sysroot is a subdirectory of the prefix, "it will be found relative to the GCC
# binaries if the installation tree is moved" (https://gcc.gnu.org/install/configure.html).
config_args+=" --prefix=$toolchain --with-sysroot=$NDK_SYSROOT"

# Not simply using `--enable-shared`, because this would also enable a shared libgcc
# (libgcc_s.so), which has the surprising effect of causing the static libgcc.a, which all
# builds use by default, to have some things removed from it:
#
# * "Unwinding" logic for C++ exception handlers (see also comment in build-wheel.py).
#
# * Thread-local storage emulation (emutls), which is required on Android to work around
#   limitations in the dynamic linker (https://bugs.llvm.org/show_bug.cgi?id=23566#c4 and
#   https://stackoverflow.com/a/27195324).
#
# These things are moved to a separate file libgcc_eh.a, intended for linking into an
# executable build, because on some platforms they should only exist once per program (see
# https://gcc.gnu.org/ml/gcc/2012-03/msg00104.html, and LIB2ADDEH in libgcc/Makefile.in).
#
# However, the NDK's recommendation is to use a static libgcc.a, and build so that "each linked
# binary has a full (and hidden!) copy of the unwinder it was built against"
# (https://github.com/android-ndk/ndk/issues/289#issuecomment-289170461). This is done using
# the -Wl,--exclude-libs flags in build-common-tools.sh and build-wheel.py.
config_args+=" --enable-shared=libgfortran"
export PATH=$PATH:$toolchain/bin  # For target assembler and linker.

# libquadmath isn't available for ARM, so be consistent and disable it on all ABIs. This also
# prevents the build system from giving libgfortran a RUNPATH entry pointing at the temporary
# build directory. RUNPATH is recognized by Android API level 24 and later
# (https://github.com/aosp-mirror/platform_bionic/blob/master/android-changes-for-ndk-developers.md),
# but would probably be harmless since it won't exist anyway.
config_args+=" --disable-libquadmath --disable-libquadmath-support"

# On x86_64, prevent it from trying to build a native compiler rather than a cross compiler
# (https://stackoverflow.com/a/48019473).
config_args+=" --disable-bootstrap"

# Avoid building alternative variants:
#   * On armeabi-v7a, all 4 combinations of armv5/armv7 and thumb/no-thumb.
#   * On x86_64, the m32 and mx32 ABIs.
config_args+=" --disable-multilib"

$src_dir/configure $config_args
make -j $(nproc)

# We copy into the toolchain selectively to minimize the chance of breaking anything. However,
# we do overwrite the existing copy of libgcc. The two copies should be very similar, but I
# think GCC is more likely than Clang to make assumptions about exactly what's in it.
install_dir=$(realpath ../install)
rm -rf $install_dir
make install DESTDIR=$install_dir
cd $install_dir/$toolchain
for path in \
    $host_triplet/lib*/libgfortran.* \
    bin/$host_triplet-gfortran \
    lib/gcc/$host_triplet/4.9.x/{finclude,include,include-fixed} \
    lib/gcc/$host_triplet/4.9.x/{libgcc.*,libgfortranbegin.*} \
    libexec/gcc; do
    rm -rf $toolchain/$path
    mkdir -p $toolchain/$(dirname $path)
    cp -a $path $toolchain/$path
done
rm -r $install_dir

rm -r $build_dir
