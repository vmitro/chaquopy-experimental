#!/bin/bash
set -eu

echo ">>>>>> NOW IN BUILD-TBLGEN.SH"o

echo ">>>>>> before unset"
export

build_dir=$1

mkdir -p $build_dir
cd $build_dir

unset AR ARFLAGS AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS F77 F90 FARCH FC LD LDFLAGS LDSHARED \
      NM RANLIB READELF STRIP CMAKE_TOOLCHAIN_FILE

echo ">>>>>> after unset"
export
#read

#CC=/usr/bin/clang
#CXX=/usr/bin/clang++
#declare -a _cmake_config
#_cmake_config+=(-DCMAKE_BUILD_TYPE="Release")
#_cmake_config+=(-DLLVM_TARGETS_TO_BUILD="host")
#_cmake_config+=(-DLLVM_TARGETS_TO_BUILD="host")
#_cmake_config+=(-DCMAKE_C_COMPILER=/usr/bin/clang)
#_cmake_config+=(-DCMAKE_CXX_COMPILER=/usr/bin/clang++)
#_cmake_config+=(-DLLVM_TARGETS_TO_BUILD=X86)
#_cmake_config+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_DOCS=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_RUNTIMES=ON)
#_cmake_config+=(-DLLVM_INCLUDE_TESTS=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_GO_TESTS=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_TOOLS=OFF)
#_cmake_config+=(-DLLVM_INCLUDE_UTILS=OFF)
#_cmake_config+=(-DLLVM_BUILD_BENCHMARKS=OFF)
#_cmake_config+=(-DLLVM_BUILD_DOCS=OFF)
#_cmake_config+=(-DLLVM_BUILD_EXAMPLES=OFF)
#_cmake_config+=(-DLLVM_BUILD_RUNTIME=OFF)
#_cmake_config+=(-DLLVM_BUILD_RUNTIMES=ON)
#_cmake_config+=(-DLLVM_BUILD_TESTS=OFF)
#_cmake_config+=(-DLLVM_BUILD_TOOLS=OFF)
#_cmake_config+=(-DLLVM_BUILD_LLVM_DYLIB=OFF)
#_cmake_config+=(-DLLVM_BUILD_UTILS=OFF)

#cmake -G Ninja "${_cmake_config[@]}" ../llvm
cmake -G'Unix Makefiles' ../llvm
cmake --build . --target llvm-tblgen -- -j $(nproc)
