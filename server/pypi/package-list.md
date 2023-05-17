# Package: PACKAGE

## Description

This native Python package features a native shared objecct library that massively increases efficiency in some math functions.

## Challenges

In order to build the package, a third party code must be used. Luckily the devs supply a build script for building it on Android.

The package relies on `numpy` and imports the package in its `setup.py` script. A workaraound using `builtins` module is required in order to cross-compile (s. `common-pitfalls-and-solutions.md`).

The package features some Fortran code. It depends on the `libfortran.so` library at runtime. The NDK doesn't come with a Fortran compiler. We must build a Fortran compiler separately (s. `building-cross-fortran.md`).

## Code Composition

### Native code

[ ] `.pyx`: The package relies upon Cython code without any other native code to function.
    - Should build correctly by adding:
```
(...)
requirements:
  build:
    - Cython 0.29.XX
(...)
```
    - ...to `meta.yaml`
[ ] `.c`: There are one or more C source files (with/out corresponding `.h` files); this package should compile through NDK's clang, where `TARGET` (s. `all-about-ndk.md` in the project's root) set to `arch-triplet-abi-apilevel`. Doesn't rely on any external libraries.
[ ] `.c` with  external dependencies: the package has a native component which depends on code outside of standard library.
    - C standard:
        - [ ] ANSI-C (C89)
        - [ ] C99
        - [ ] C11
        - [ ] C17
        - [ ] C2x (C23)
[ ] `.cpp` similar to C code, the package features one or more `.cpp` i.e. C++ source files, with corresponding `.h`/`.hh`/`.hpp` header files which doesn't use any external dependencies
[ ] `.cpp` with external dependencies: like aboce, only with thir-party dependencies
    - C++ standard:
        - [ ] C++98
        - [ ] C++03
        - [ ] C++11
        - [ ] C++14
        - [ ] C++17
        - [ ] C++20
[ ] `.fXX`: There is legacy Fortran code in the package; it must be built with a Fortran cross compiler in the compile step (e.g. for ARM64: `aarch64-linux-android-gfortran`).
[ ] `.rs`: The package contains Rust native code with or without external dependencies.

### Python

[ ] This package has no Python bindings. By convention, we name this package (the directory in `server/pypi/packages/`) with a `chaquopy-*` prefix to avoid name collision with possible Python packages with the same name. It supplies (a) build script(s) to compile, link and build the finished package. 
[ ] This package contains native code inside a directory in the source folder. The package's build script(s) build the native component.
[ ] The package relies on another purely native package. In the package's `meta.yaml` a runtime requirement is needed to use the package on end device:
```
(...)
requirements:
  host:
    - libthirdparty 0.0.1
(...)
```

## Build Status

[ ] Doesn't compile: one or more (fatal) errors get reported which terminate the compilation process. No library gets linked. No wheel-file gets built. 
[ ] Compiles with warnings: the package's `setup.py` / `Makefile` / `CMakeLists.txt` [build script(s)] produce correct object files  but during the compilation one or more warnings get reported 
[x] Compiles cleanly: the package's build script(s) produce correct object files without any warnings
[x] Links: the package's build script(s) produce correct `.so` files
[x] Builds: The `build-wheel.py` script produces correct `.whl` files
[x] Passes: The supplied `test.py` passes all tests and assertions

## TODO:
    - Write a `build.sh` script to correctly build the native package
    - Generate pathes and put them in `packages/mypackage/patches` directory
    - Tweak the generated Wheel file.
