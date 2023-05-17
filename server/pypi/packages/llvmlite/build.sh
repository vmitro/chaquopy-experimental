#!/bin/bash

set -eu

export PYTHONNOUSERSITE=1
export LLVMLITE_CXX_STATIC_LINK=1

echo $PREFIX

#tar -xf $PREFIX/../../requirements/chaquopy/llvm-config.tar -C $PREFIX/../../requirements/chaquopy

#export LLVM_CONFIG=$(realpath $PREFIX/../../requirements/chaquopy/bin/llvm-config)
cp $HOME/projects/chaquopy/server/pypi/packages/chaquopy-llvm-11/build/11.1.0/py3-none-android_31_arm64_v8a/src/build-llmvconfig/bin/llvm-config $HOME/projects/chaquopy/server/pypi/packages/llvmlite/build/0.39.1/cp310-cp310-android_31_arm64_v8a/requirements/chaquopy/bin
export LLVM_CONFIG=$(realpath $PREFIX/../../requirements/chaquopy/bin/llvm-config)
echo "LLVM_CONFIG IS $LLVM_CONFIG"

#python setup.py build
python -m pip install . --target $PREFIX 
