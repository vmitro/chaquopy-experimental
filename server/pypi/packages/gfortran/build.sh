#!/bin/bash

set -eu

unset CC CXX LD RANLIB AR AS STRIP NM READELF CFLAGS CPPFLAGS LDFLAGS CXXFLAGS 

# =============================================================
# HOST_TRIPLE from build-common.sh defines the arch we want to 
# target
TARGET=$HOST_TRIPLE
INSTALL_PREFIX=$(realpath $SRC_DIR/../install)
# =============================================================
# get the host triple from make by cutting off the 'Build for '
# string of the make -v output
host_machine=$(make -v | grep 'Built for' | sed 's/Built for //g')
#host_machine=$(uname -m)
#echo ">>>> host_machine=$host_machine" && read

# =============================================================
# assume current directory as root of the build: change this if
# you add a `cd` before it
cd $SRC_DIR
mkdir -p install

# =============================================================
# some common ./configure options for all libs needed for 
# building gcc
common_binutils="\
	--prefix=$INSTALL_PREFIX \
	--target=$TARGET \
	--disable-nls \
	--disable-werror" # \
#	--with-pic "
#common_libs="\
#	$common_binutils \
#	--enable-shared=yes \
#	--enable-static=yes "

#sysroot_include="$NDK_SYSROOT/usr/include"
#sysroot_libs="$NDK_SYSROOT/usr/lib:$NDK_SYSROOT/usr/lib/$TARGET/$ANDROID_API"
#export PATH=$NDK_TOOLCHAIN/bin:$PATH

export CFLAGS=" --std=c99 -Wno-error -O2 --verbose " # \
#	-I$INSTALL_PREFIX/include "
#export CFLAGS

export CXXFLAGS=" -O2 -Wno-error -v " 
#	-I$INSTALL_PREFIX/include"
#export CXXFLAGS

# we set LDFLAGS to link to libc.so in ndk
#LDFLAGS="-L$INSTALL_PREFIX/lib -L$NDK_SYSROOT/usr/lib/$TARGET -L$NDK_SYSROOT/usr/lib/$TARGET/$ANDROID_API"
#export LDFLAGS=""

# =============================================================
# fix build time dependency on lib{mpc,gmp,mpfr}
#export LD_LIBRARY_PATH=r/lib/x86_64-linux-gnu:$INSTALL_PREFIX/lib

# =============================================================
# this step is important: the new binutils should be finadable
# i.e. in front of the $PATH
#export PATH=$INSTALL_PREFIX/bin:$PATH

# =============================================================
# download and build binutils
binutils_dir=$SRC_DIR/binutils
if [ ! -e binutils ]; then 
    git clone https://android.googlesource.com/toolchain/binutils 
    #... and build them!
    cd binutils
    mkdir -p build && cd build
		../binutils-2.27/configure \
	    $common_binutils \
		  && \
		make -j`nproc` && make install 

		if [ $? == 0 ]
		then
			echo ">>>> binutils built and installed"
		else
			echo ">>>> error installing binutils"
			exit 47
		fi
	else
		echo ">>>> binutils already built, skipping..."
fi
## get the basename (name after all the dirs have been discarded)
## of a directory in the binutils that starts with binutils-
## then cut with delimiter '-' and return the second part of it
cd $SRC_DIR
binutils_ver=$(basename $binutils_dir/binutils-* | cut -d '-' -f 2)
#
## next we download bionic, google's libc
## we only really need some header files
## ...or do we?
## TODO: copy these files only to save space
#
#cd $SRC_DIR
#[ ! -e bionic ] && git clone https://android.googlesource.com/platform/bionic
sysinclude=$INSTALL_PREFIX/$TARGET/sys-include
#if [ ! -e $sysinclude ]
#then
#	mkdir -p $sysinclude
#	cp -Rv bionic/libc/include/* $sysinclude/
#	for d in linux asm-generic
#	do
#		ln -s $NDK_SYSROOT/usr/include/$d $sysinclude/
#	done
#	ln -s $NDK_SYSROOT/usr/include/$TARGET/asm $sysinclude/
#fi

rm -rf $INSTALL_PREFIX/$TARGET/sys-include
cp -r /usr/local/aarch64-linux-android/aarch64-linux-android/sys-include $INSTALL_PREFIX/$TARGET/
ls -ls $INSTALL_PREFIX/$TARGET/sys-include && read

syslib=$INSTALL_PREFIX/$TARGET/lib
if [ ! -e $syslib ]
then
	mkdir -p $syslib
fi
cp -Rv $NDK_SYSROOT/usr/lib/$TARGET/$ANDROID_API/* $syslib/
ls -ls $syslib && read

## we're setting various variables FOR_TARGET so that GNU Make can find them
## and we don't polute $PATH with them
#
# TOOLS_FOR_TARGET from binutils

#export AR="$INSTALL_PREFIX/$TARGET/bin/ar"
#export LD="$INSTALL_PREFIX/$TARGET/bin/ld"
#export OBJDUMP="$INSTALL_PREFIX/$TARGET/bin/objdump"
#export NM="$INSTALL_PREFIX/$TARGET/bin/nm"
#export RANLIB="$INSTALL_PREFIX/$TARGET/bin/ranlib"
#export READELF="$INSTALL_PREFIX/$TARGET/bin/readelf"
#export STRIP="$INSTALL_PREFIX/$TARGET/bin/strip"
#export AS_FOR_TARGET="$INSTALL_PREFIX/$TARGET/bin/as"
#
ndk_binutils="$NDK_TOOLCHAIN/bin"

#export AR="$ndk_binutils/llvm-ar"
#export LD="$ndk_binutils/ld"
#export OBJDUMP="$ndk_binutils/llvm-objdump"
#export NM="$ndk_binutils/llvm-nm"
#export RANLIB="$ndk_binutils/llvm-ranlib"
#export READELF="$ndk_binutils/llvm-readelf"
#export STRIP="$ndk_binutils/llvm-strip"
#export AS="$INSTALL_PREFIX/$TARGET/bin/as"

#export CC="gcc -B$ndk_binutils"
#export CXX="g++ -B$ndk_binutils"

export VERBOSE=1
#
# step 0: download cloog, gmp, mpfr and mpc

cd $SRC_DIR
if [ -e cloog ] && [ -e gmp ] && [ -e mpfr ] && [ -e mpc ]
then
	echo ">>>>  prerequisites already downloaded, skipping"
else
	gcc-4.9/contrib/download_prerequisites
	echo ">>>> prerequisites downloaded"
fi


# step 1: build gmp
#echo ">>>> common_libs=$common_libs" && read
#gmp_dir=$SRC_DIR/gmp
#if [ ! -e $gmp_dir/.installed ]
#then
#	cd $gmp_dir
#  ./configure \
#		$common_libs \
#		LDFLAGS="$LDFLAGS -L$sysroot_libs" \
#		&& \
#	make -j `nproc` && make install
#
#	if [ $? == 0 ]
#	then
#		touch $gmp_dir/.installed
#		echo ">>>> gmp built and installed"
#	else
#		echo ">>>> error installing gmp"
#		exit 47
#	fi
#	#read
#else
#	echo ">>>> gmp already built, skipping"
#fi
cd $SRC_DIR
gmp_ver=$(readlink gmp | cut -d '-' -f 2)
#
## step 2: build cloog
#cloog_dir=$SRC_DIR/cloog
#if [ ! -e $cloog_dir/.installed ]
#then
#	cd $cloog_dir
#	./configure \
#		--target=$TARGET \
#		$common_libs \
#		&& \
#	make -j `nproc` && make install
#
#	if [ $? == 0 ]
#	then
#		touch $cloog_dir/.installed
#	  echo ">>>> cloog built and installed"
#	else
#		echo ">>>> error installing cloog"
#		exit 47
#	fi
#else
#	echo ">>>> cloog already built, skipping"
#fi
#cd $SRC_DIR
cloog_ver=$(readlink cloog | cut -d '-' -f 2)
#
## step 3: install mpfr
#mpfr_dir=$SRC_DIR/mpfr
#if [ ! -e $mpfr_dir/.installed ]
#then
#		cd $mpfr_dir
#		./configure \
#			$common_libs \
#			--target=$TARGET \
#			--with-gmp=$INSTALL_PREFIX \
#			&& \
#	make -j `nproc` && make install 
#		
#	if [ $? == 0 ]
#	then
#		touch $mpfr_dir/.installed
#		echo ">>>> mpfr built and installed"
#	else
#		echo ">>>> error installing mpfr"
#		exit 47
#	fi
#	#read
#else
#	echo ">>>> mpfr already built, skipping"
#fi
#cd $SRC_DIR
mpfr_ver=$(readlink mpfr | cut -d '-' -f 2)
#
## step 4: install mpc
#mpc_dir=$SRC_DIR/mpc
#if [ ! -e $mpc_dir/.installed ]
#then
#	cd $mpc_dir
#	./configure \
#		$common_libs \
#		--target=$TARGET \
#		--with-gmp=$INSTALL_PREFIX \
#		--with-mpfr=$INSTALL_PREFIX \
#		&& \
#	make -j `nproc` && make install 
#
#	if [ $? == 0 ]
#	then
#		touch $mpc_dir/.installed
#		echo ">>>> mpc built and installed"
#	else
#		echo ">>>> error installing mpc"
#		exit 47
#	fi
#	#read
#else
#	echo ">>>> mpc already built, skipping..."
#fi
#cd $SRC_DIR
mpc_ver=$(readlink mpc | cut -d '-' -f 2)


# finally, use google's patched GCC and build only gfortran (well, also c and lt compilers
# because gfortran depends on them but important is that we don't build c++ compiler and 
# its stdlib which is not needed for our build and I doubt if it's gonna compile anyways)
# target assembler and linker go into INSTALL_PREFIX/bin
# we need them for build


# =============================================================
# the LIBRARY_PATH env variable is used by gcc during build to
# find libraries to link to (doesn't work for configure!)
#export LIBRARY_PATH=$NDK_SYSROOT/usr/lib/$TARGET/$ANDROID_API:$INSTALL_PREFIX/lib
#ls -ls $NDK_SYSROOT/usr/lib/$TARGET/$ANDROID_API
#read

gcc_dir=$(realpath $SRC_DIR/../build-$TARGET)
#if [ ! -e build-$TARGET/.configured ]
#then
	rm -rf $gcc_dir && mkdir -p $gcc_dir && cd $gcc_dir

../src/gcc-4.9/configure \
			--target=$TARGET \
			--enable-languages=fortran \
			--enable-shared=libgfortran \
			--enable-bionic-libs \
			--enable-libatomic-ifuncs=no \
			--prefix=$INSTALL_PREFIX \
			--disable-nls \
			--disable-werror \
			--with-gnu-as \
			--with-gnu-ld
		if [ $? == o ]
		then
			touch .configured
		else
			echo ">>>> configuring gcc failed with exit code $?"
			#exit 47
		fi
#else
#	echo ">>>> gcc already configured, skipping"
#fi

#			--enable-shared=gmp,mpfr,mpc,libgfortran \
#			--disable-bootstrap \
#			--disable-multilib \
# we're building tho
#cd $SRC_DIR/build-$TARGET && \
	make -j1 && \
  make install
