#!/bin/bash
set -eu

echo ">>>>>> NOW IN BUILD-TBLGEN.SH"

#echo ">>>>>> before unset"
#export

build_dir=$1

mkdir -p $build_dir
cd $build_dir

unset AR ARFLAGS AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS F77 F90 FARCH FC LD LDFLAGS LDSHARED \
      NM RANLIB READELF STRIP CMAKE_TOOLCHAIN_FILE

cmake -G 'Unix Makefiles' ..
cmake --build . --target llvm-tblgen -- -j $(nproc)
