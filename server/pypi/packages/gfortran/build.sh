#!/bin/bash

set -eu

unset CC CXX LD RANLIB AR AS STRIP NM READELF CFLAGS LDFLAGS CXXFLAGS 
# HOST_TRIPLE from build-common.sh defines the arch we want to target
TARGET=$HOST_TRIPLE
INSTALL_PREFIX=$PREFIX/$TARGET

# assume current directory as root of the build: change this if you add a `cd` before
# clone binutils from google's server
#cd $SRC_DIR/..
#binutils_dir=$SRC_DIR/binutils
#if [ ! -e binutils ]; then 
#    git clone https://android.googlesource.com/toolchain/binutils 
#    #... and build them!
#    cd binutils
#    mkdir -p build-$TARGET && cd build-$TARGET
#		../binutils-2.27/configure \
#			--target=$TARGET \
#			--prefix=$binutils_dir/install \
#			--program-prefix=$TARGET- \
#			--disable-nls \
#			--disable-werror
#		make -j`nproc` && make install
#fi

# we're setting various variables FOR_TARGET so that GNU Make can find them
# and we don't polute $PATH with them

export AR_FOR_TARGET=$NDK_TOOLCHAIN/bin/llvm-ar
export LD_FOR_TARGET=$NDK_TOOLCHAIN/bin/ld
export OBJDUMP_FOR_TARGET=$NDK_TOOLCHAIN/bin/llvm-objdump
export NM_FOR_TARGET=$NDK_TOOLCHAIN/bin/llvm-nm
export RANLIB_FOR_TARGET=$NDK_TOOLCHAIN/bin/bin/llvm-ranlib
export READELF_FOR_TARGET=$NDK_TOOLCHAIN/bin/bin/llvm-readelf
export STRIP_FOR_TARGET=$NDK_TOOLCHAIN/bin/bin/llvm-strip
export AS_FOR_TARGET=$NDK_TOOLCHAIN/bin/llvm-as

export VERBOSE=1

# step 0: download cloog, gmp, mpfr and mpc

cd $SRC_DIR
if [ -e cloog ] && [ -e gmp ] && [ -e mpfr ] && [ -e mpc ]
then
	echo ">>>> warning: prerequisites already donloaded, skipping..."
	read
else
	gcc-4.9/contrib/download_prerequisites
fi

# step 1: build cloog
cloog_dir=$SRC_DIR/cloog
cd $cloog_dir
./configure --disable-shared \
	--prefix=$cloog_dir/install \
	--with-pic \
	--with-gnu-ld

make -j `nproc`
make install

# step 2: build gmp
gmp_dir=$SRC_DIR/gmp
cd $gmp_dir
./configure --disable-shared \
	--prefix=$gmp_dir/install \
	--with-pic \
	--with-gnu-ld

make -j `nproc`
make install

# step 3: install mpfr
mpfr_dir=$SRC_DIR/mpfr
cd $mpfr_dir
./configure --disable-shared \
	--prefix=$mpfr_dir/install \
	--with-gmp=$gmp_dir/install \
	--with-pic \
	--with-gnu-ld
	
make -j `nproc`
make install

# step 4: install mpc
mpc_dir=$SRC_DIR/mpc
cd $mpc_dir
./configure --disable-shared \
	--prefix=$mpc_dir/install \
	--with-gmp=$gmp_dir/install \
	--with-mpfr=$mpfr_dir/install \
	--with-pic \
	--with-gnu-ld
make -j `nproc`
make install

# finally, use google's patched GCC and build only gfortran (well, also c and lt compilers
# because gfortran depends on them but important is that we don't build c++ compiler and 
# its stdlib which is not needed for our build and I doubt if it's gonna compile anyways)
cd $SRC_DIR
[ -e build-$TARGET ] && rm -rf build-$TARGET
mkdir -p build-$TARGET && cd build-$TARGET
CFLAGS="--std=gnu89 -Wno-error -O3"
# this assumes a recent Ubuntu system with mcp installed globally... don't ask
#export LD_LIBRARY_PATH=$(dirname `dpkg -L libmpfr6 | grep 'libmpfr.so.6$'`)
#echo ">>>> ${LD_LIBRARY_PATH}"
#read

# target assembler and linker go into INSTALL_PREFIX/bin
# we need them for build
export PATH=$PATH:$INSTALL_PREFIX/bin

../gcc-4.9/configure \
    --target=$TARGET \
		--enable-languages=c,fortran \
		--prefix=$INSTALL_PREFIX \
		--program-prefix=$HOST_TRIPLE \
		--with-sysroot=$NDK_SYSROOT \
		--enable-shared=libgfortran \
		--disable-libquadmath \
		--disable-libquadmath-support \
		--disable-bootstrap \
		--disable-multilib \
		--with-cloog=$cloog_dir/install \
		--with-gmp=$gmp_dir/install \
		--with-mpfr-lib=$mpfr_dir/install/lib \
		--with-mpfr-include=$mpfr_dir/install/include \
		--with-mpc=$mpc_dir/install \
		--disable-nls \
		--disable-werror
#		--with-gnu-as \
#		--with-gnu-ld \

make -j`nproc`
make install
