#!/usr/bin/bash

# Check that a dependency is not already installed
# @param $1         in  name the lock should be associated with
# @param installed  out 1 if locked else 0
__check_lock()
{
  if [[ "$#" == 0 ]]; then
    __msg Must pass argument to ${FUNCNAME[0]}!
    exit 1
  fi

  installed=0
  name=$1

  local lockfile="$installdir/$name.lock"
  if [ -f $lockfile ]; then
    __msg $name is already built!
    installed=1
  fi
  
  export installed
}

# Writes to lockfile that indicates that the dep has already been built
__lock()
{
  if [[ "$#" == 0 ]]; then
    __msg Must pass argument to ${FUNCNAME[0]}!
    exit 1
  fi
  local lockfile="$installdir/$name.lock"
  touch $lockfile
}

cat >>/dev/null <<EOD

  Each install function should be responsible for the following:
    
    - Checking that the library has not already been installed
    - pulling any other sources needed by the library
    - documenting any of it's dependencies

EOD

install_eigen3()
{
  local eigen="eigen-3.3.7"
  export default_cmake_args="$default_cmake_args -DEigen3_DIR=$installdir"

  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  [ -f "$eigen.tar.gz" ] || \
    wget "https://gitlab.com/libeigen/eigen/-/archive/${eigen/eigen-/}/$eigen.tar.gz"
  tar xvzf "$eigen.tar.gz"
  pushd $eigen
  cp -r unsupported $installdir/include/unsupported
  cp -r Eigen $installdir/include/Eigen

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

install_FETK()
{
  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  pushd $root/FETK

  __msg Manually setting variables in FETK build script
  sed -i.bk \
    -e "s@^FETK_PREFIX=@FETK_PREFIX=$installdir #@" \
    -e "s@^FETK_MAKE=@FETK_MAKE='make -j $make_jobs' #@" ./fetk-build

  __msg Running FETK build script without confirmation
  yes | ./fetk-build all

  __msg Restoring original build script.
  __msg You can find the modified build script at $(pwd)/fetk-build.bk
  rm ./fetk-build
  mv ./fetk-build.bk ./fetk-build

  popd

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

install_geoflow_c()
{
  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  pushd $root/geoflow_c
  [ -d build ] && rm -rf build
  mkdir build
  pushd build

  cmake \
    -DENABLE_GEOFLOW_APBS=ON \
    -DBUILD_SHARED_LIBS=ON \
    $default_cmake_args \
    ..
  make -j $make_jobs
  make install

  popd; popd

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

install_pb_solvers()
{
  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  pushd $root/pb_solvers
  [ -d build ] && rm -rf build
  mkdir build
  pushd build

  cmake \
    -DENABLE_PBAM_APBS=ON \
    -DBUILD_SHARED_LIBS=ON \
    $default_cmake_args \
    ..
  make -j $make_jobs
  make install
  
  popd; popd

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

install_pybind11()
{
  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  pushd $root/pybind11
  [ -d build ] && rm -rf build
  mkdir build
  pushd build

  cmake \
    $default_cmake_args \
    ..
  make -j $make_jobs
  make install

  popd; popd

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

install_TABIPB()
{
  __check_lock ${FUNCNAME[0]}
  if [ "$installed" == "1" ]; then
    return
  fi

  pushd $root/TABIPB
  [ -d build ] && rm -rf build
  mkdir build
  pushd build

  cmake \
    -DENABLE_PBAM_APBS=ON \
    -DBUILD_SHARED_LIBS=ON \
    $default_cmake_args \
    ..
  make -j $make_jobs
  make install
  
  popd; popd

  __lock ${FUNCNAME[0]}
  __msg ${FUNCNAME[0]} successfully ran
}

