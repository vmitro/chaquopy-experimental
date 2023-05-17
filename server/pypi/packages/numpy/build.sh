#!/bin/bash

set -eu

cat > site.cfg <<EOF
[DEFAULT]
library_dirs = $PREFIX/lib
include_dirs = $PREFIX/include
[blas]
libraries = openblas
EOF

export NPY_LAPACK_ORDER=lapack
export NPY_BLAS_ORDER=openblas
#export NPY_USE_BLAS_ILP64=1 # doesn't work
export OPENBLAS=$PWD/packages/numpy/build/1.24.2/cp310-cp310-android_30_arm64_v8a/requirements/chaquopy/lib
export CC_TARGET=$THE_TARGET

echo PREFIX=$PREFIX
#python setup.py build_ext --inplace
ls -lsa $PREFIX
#read
#python setup.py install --no-deps --ignore-installed --install-lib=$PREFIX/..
python -m pip install --no-deps --ignore-installed -v . -t $PREFIX/..
ls -lsa $PREFIX
#read
#ls -lsa $PREFIX/lib
