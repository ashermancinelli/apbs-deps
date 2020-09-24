#!/usr/bin/bash

./build.sh \
  --with-eigen3 \
  --with-pybind11 \
  --with-FETK \
  --make-jobs=8 \
  --create-package

