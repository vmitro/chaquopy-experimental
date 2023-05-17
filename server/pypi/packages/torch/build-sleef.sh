#!/bin/bash

set -eu

echo ">>> NOW IN build-sleef.sh"

build_dir=$1

mkdir -p $build_dir
cd $build_dir

unset AR ARFLAGS AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS F77 F90 FARCH FC LD LDFLAGS LDSHARED \
      NM RANLIB READELF STRIP CMAKE_TOOLCHAIN_FILE

declare -a CMAKE_SLEEF_ARGS
#CMAKE_SLEEF_ARGS+=(-DCMAKE_TOOLCHAIN_FILE="../chaquopy.toolchain.cmake")
CMAKE_SLEEF_ARGS+=(-DCAFFE2_CUSTOM_PROTOC_EXECUTABLE=$(which protoc))
CMAKE_SLEEF_ARGS+=(-DONNX_CUSTOM_PROTOC_EXECUTABLE=$(which protoc))
CMAKE_SLEEF_ARGS+=(-DBLAS="OpenBLAS")
CMAKE_SLEEF_ARGS+=(-DNATIVE_BUILD_DIR=$build_dir)
CMAKE_SLEEF_ARGS+=(-DTORCH_BUILD_VERSION=$PKG_VERSION)
CMAKE_SLEEF_ARGS+=(-DNUMPY_INCLUDE_DIR=`python -c "import os.path; import sys; sys.path.insert(0, os.path.abspath('../requirements')); import builtins; builtins.__NUMPY_SETUP__ = True; import numpy as np; print(np.get_include())"`)
CMAKE_SLEEF_ARGS+=(-DUSE_CUDA=0)
CMAKE_SLEEF_ARGS+=(-DUSE_VULKAN=0)

cmake ../third_party/sleef "${CMAKE_SLEEF_ARGS[@]}"
cmake --build . -- -j $(nproc)
