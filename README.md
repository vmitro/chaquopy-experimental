# An experimental Chaquopy repository targeting CPython 3.10 with Android API 31

## From the official README.md:

Chaquopy provides everything you need to include Python components in an Android app,
including:

* Full integration with Android Studio's standard Gradle build system.
* Simple APIs for calling Python code from Java/Kotlin, and vice versa.
* A wide range of third-party Python packages, including SciPy, OpenCV, TensorFlow and many
  more.

To get started, see the [documentation](https://chaquo.com/chaquopy/doc/current/).

## What this repository is:

- A fork of the official Chaquopy repository on a new branch, aimed at adapting the existing build scripts to target:
  - newer versions of the CPython (3.10)
  - newer version of the Android API (31)
  - newer versions of some native packages and libraries, including but not limited to
    - LLVM 11.1.0
    - Numpy 1.24.2
    - Numba XX.YY
    - PyTorch 1.13.1
- Experimental
    - Tiktoken, a Python package with some heavy-lifting written in Rust can be built with some hacking on the `setuptools-rust` package
- Untested
    - Many packages build successfully but are untested, pull requests with tests welcome
- Fully open to requests, pull requests, critique and extension
- An (experimental, have I mentioned this yet?) way to build Chaquopy Wheels for the aformentioned targets

## What this repository is NOT:

- Production-ready
- Stable
- Associated in any way with the official Chaquopy repository
- Aimed at changing the Chaquopy Core in any way
- Humorous (see [server/pypi/common-pitfalls-and-solutions.md])

# The original Chaquopy README.md continues --HERE--

## Repository layout

This repository contains the following components:

* `product` contains Chaquopy itself.
* `target` contains build processes for Python and its dependencies.
* `server/pypi` contains build processes for third-party Python packages.

## Build

For build instructions, see the README files in each subdirectory.

Or to build everything at once, follow the instructions below on a Linux x86-64 machine:

If necessary, install Docker using the [instructions on its
website](https://docs.docker.com/install/#supported-platforms).

Make sure all submodules are up to date:

    git submodule init && git submodule update

Then run the script `build-maven.sh`. This will generate a `maven` directory containing the
Chaquopy repository.

To use this repository to build an app, edit the `repositories` block in your `settings.gradle`
or `build.gradle` file to [declare your
repository](https://docs.gradle.org/current/userguide/declaring_repositories.html#sec:declaring_multiple_repositories)
before `mavenCentral`. Either an HTTP URL or a local path can be used.
