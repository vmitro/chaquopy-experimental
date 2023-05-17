#!/bin/bash
set -eu

echo ">>>>>> NOW IN BUILD-LLVMCONFIG.SH"

#echo ">>>>>> before unset"
#export

build_dir=$1

mkdir -p $build_dir
cd $build_dir

unset AR ARFLAGS AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS F77 F90 FARCH FC LD LDFLAGS LDSHARED \
      NM RANLIB READELF STRIP CMAKE_TOOLCHAIN_FILE

#echo ">>>>>> after unset"
#export
#read

#CC=/usr/bin/clang
#CXX=/usr/bin/clang++
#declare -a _cmake_llvm_config
#_cmake_llvm_config+=(-DCMAKE_BUILD_TYPE="Release")
#_cmake_llvm_config+=(-DLLVM_TARGETS_TO_BUILD="host")
#_cmake_llvm_config+=(-DLLVM_TARGETS_TO_BUILD="host")
#_cmake_llvm_config+=(-DCMAKE_C_COMPILER=/usr/bin/clang)
#_cmake_llvm_config+=(-DCMAKE_CXX_COMPILER=/usr/bin/clang++)
#_cmake_llvm_config+=(-DLLVM_TARGETS_TO_BUILD=X86)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_BENCHMARKS=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_DOCS=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_EXAMPLES=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_RUNTIMES=ON)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_TESTS=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_GO_TESTS=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_TOOLS=OFF)
#_cmake_llvm_config+=(-DLLVM_INCLUDE_UTILS=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_BENCHMARKS=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_DOCS=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_EXAMPLES=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_RUNTIME=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_RUNTIMES=ON)
#_cmake_llvm_config+=(-DLLVM_BUILD_TESTS=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_TOOLS=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_LLVM_DYLIB=OFF)
#_cmake_llvm_config+=(-DLLVM_BUILD_UTILS=OFF)

declare -a _cmake_llvm_config
_cmake_llvm_config+=(-DCMAKE_BUILD_TYPE:STRING=MinSizeRel)
_cmake_llvm_config+=(-DLLVM_HOST_TRIPLE=native)
_cmake_llvm_config+=(-DLLVM_TARGETS_TO_BUILD=$_TARGET)
_cmake_llvm_config+=(-DLLVM_TARGET_ARCH=$_TARGET)
_cmake_llvm_config+=(-DLLVM_DEFAULT_TARGET_TRIPLE=$triple)
_cmake_llvm_config+=(-DLLVM_ENABLE_LIBXML2:BOOL=OFF)
_cmake_llvm_config+=(-DHAVE_TERMINFO_CURSES=OFF)
_cmake_llvm_config+=(-DHAVE_TERMINFO_NCURSES=OFF)
_cmake_llvm_config+=(-DHAVE_TERMINFO_NCURSESW=OFF)
_cmake_llvm_config+=(-DHAVE_TERMINFO_TERMINFO=OFF)
_cmake_llvm_config+=(-DHAVE_TERMINFO_TINFO=OFF)
_cmake_llvm_config+=(-DHAVE_TERMIOS_H=OFF)
_cmake_llvm_config+=(-DCLANG_ENABLE_LIBXML=OFF)
_cmake_llvm_config+=(-DLIBOMP_INSTALL_ALIASES=OFF)
_cmake_llvm_config+=(-DLLVM_ENABLE_RTTI=OFF)

echo _cmake_llvm_config

#cmake -G Ninja "${_cmake_llvm_config[@]}" ../llvm
echo ">>>> Running cmake -G Ninja"
cmake -G Ninja "${_cmake_llvm_config[@]}" ..
echo ">>>> Running cmake --build . --target llvm-config -- -j $(nproc)"

cmake --build . --target llvm-config -- -j $(nproc)
echo ">>>> FINISHED BUILDING NATIVE LLMVCONFIG"
