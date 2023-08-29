# This script must be sourced with the following variables already set:
#   * ANDROID_HOME: path to Android SDK
#   * prefix: path with `include` and `lib` subdirectories to add to CFLAGS and LDFLAGS.
#
# You may also override the following:
: ${abi:=$(basename $prefix)}
: ${api_level:=21}  # Should match MIN_SDK_VERSION in Common.java.

echo Prefix is: $prefix 2>&1
#read

# When moving to a new version of the NDK, carefully review the following:
# * The release notes (https://developer.android.com/ndk/downloads/revision_history)
# * https://android.googlesource.com/platform/ndk/+/ndk-release-rXX/docs/BuildSystemMaintainers.md,
#   where XX is the NDK version. Do a diff against the version you're upgrading from.
ndk_version=r25c  # Should match ndkDir in product/runtime/build.gradle.
#ndk=${ANDROID_HOME:?}/ndk/$ndk_version
ndk=${ANDROID_HOME:?}/ndk-bundle
# some scrits rely ion this being set
export ANDROID_NDK_HOME=$ndk
export OLD_PATH=$PATH
if ! [ -e $ndk ]; then
    # Print all messages on stderr so they're visible when running within build-wheel.
    echo "Installing NDK: this may take several minutes" >&2
    yes | $ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "ndk;$ndk_version"
fi

case $abi in
    armeabi-v7a)
        host_triplet=arm-linux-androideabi
        clang_triplet=armv7a-linux-androideabi
        ;;
    arm64-v8a)
        host_triplet=aarch64-linux-android
        ;;
    x86)
        host_triplet=i686-linux-android
        ;;
    x86_64)
        host_triplet=x86_64-linux-android
        ;;
    *)
        echo "Unknown ABI: '$abi'" >&2
        exit 1
        ;;
esac

# These variables are based on BuildSystemMaintainers.md above, and
# $ndk/build/cmake/android.toolchain.cmake.
: ${the_triplet:=${clang_triplet:-$host_triplet}}
export HOST_TRIPLE=$the_triplet
: ${toolchain:=$ndk/toolchains/llvm/prebuilt/linux-x86_64} # works
export NDK_TOOLCHAIN=$ndk/toolchains/llvm/prebuilt/linux-x86_64
export NDK_SYSROOT=$NDK_TOOLCHAIN/sysroot
#: ${api_sysroot:=$sysroot/usr/lib/aarch64-linux-android/$api_level}

export THE_TARGET=${clang_triplet:-$host_triplet}$api_level # the triple with api level, no path
export THE_TARGET_WITHOUT_API=${clang_triplet:-$host_triplet}
export ANDROID_API=$api_level
export THE_TRIPLE="$toolchain/bin/$HOST_TRIPLE" # specifies the complete path up to the tool's name
export THE_ABI=$abi
export THE_PREFIX=$prefix

export AR="$toolchain/bin/llvm-ar"
export FAUX_AR="$toolchain/bin/${clang_triplet:-$host_triplet}-ar"
export AS="$toolchain/bin/$host_triplet-as"
export CC_TRIPLE_TARGET="$toolchain/bin/clang --target=$THE_TARGET"
export CC_TRIPLE_PREFIX="$THE_TRIPLE$ANDROID_API-clang" 
export CXX_TRIPLE_PREFIX="$THE_TRIPLE$ANDROID_API-clang++"
export CC="$CC_TRIPLE_PREFIX"
#export CXX="$toolchain/bin/clang++ --target=${clang_triplet:-$host_triplet}$api_level -v -arch aarch64"
export CXX="$toolchain/bin/$THE_TARGET-clang++"
# clashes with gfortran! cannot link
#export LD="$CC -fuse-ld=lld"
#export LD=$CC
export FC=/usr/local/$HOST_TRIPLE/bin/$HOST_TRIPLE-gfortran
export LD=$toolchain/bin/ld
export NM="$toolchain/bin/llvm-nm"
export RANLIB="$toolchain/bin/llvm-ranlib"
export READELF="$toolchain/bin/llvm-readelf"
export STRIP="$toolchain/bin/llvm-strip"

export CFLAGS="-v -I${prefix:?}/include -I$NDK_SYSROOT/usr/include/$HOST_TRIPLE"
export CPPFLAGS="-v"
#export CPPFLAGS="-O0 -fno-optimize"

# clashes with gfortran when added -fus-ld=lld
export LDFLAGS="-L${prefix:?}/lib \
-Wl,--build-id=sha1 \
-Wl,--exclude-libs,libgcc.a -Wl,--exclude-libs,libgcc_real.a -Wl,--exclude-libs,libunwind.a"
export LDSHARED="$toolchain/bin/clang++ -fuse-ld=lld -shared --target=$THE_TARGET -triple=$THE_TRIPLE -m aarch64linux"

#
# Many packages get away with omitting this on standard Linux, but Android is stricter.
LDFLAGS+=" -lm"

case $abi in
    armeabi-v7a)
        CFLAGS+=" -march=armv7-a -mthumb -mfpu=vfpv3-d16"
        ;;
    x86)
        # -mstackrealign is unnecessary because it's included in the clang launcher script
        # which is pointed to by $CC.
        ;;
esac

export PKG_CONFIG="pkg-config --define-prefix"
export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig"
