#!/bin/bash

set -eu

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &< /dev/null && pwd )
echo ">>>>  dirname $0 = $(dirname $0)"
echo ">>>> basename $0 = $(basename $0)"

echo ">>>> NOW IN build-protoc.sh"

unset AR ARFLAGS AS CC CFLAGS CPP CPPFLAGS CXX CXXFLAGS F77 F90 FARCH FC LD LDFLAGS LDSHARED \
      NM RANLIB READELF STRIP CMAKE_TOOLCHAIN_FILE

$SCRIPT_DIR/scripts/build_host_protoc.sh "${CMAKE_PROTOC_ARGS[@]}"

#cmake ../third_party/protoc "${CMAKE_PROTOC_ARGS[@]}"
#cmake --build . -- -j $(nproc)
