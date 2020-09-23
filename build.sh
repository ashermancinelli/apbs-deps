#!/bin/bash

# Use strict bash
set -o errexit
set -o nounset
set -o pipefail

# Dependencies to be built
declare -a deps=(FETK eigen3 pybind11 geoflow_c pb_solvers TABIPB)

# Hash table, where each key with a value of 1 will be built
declare -A builds
for d in ${deps[@]}
do
  builds[$d]=0
done
builds['all']=0

binname=$(basename "$0")

source shell/__init.sh

# set root directory so we can use global paths later on
root=$(__realpath "$(dirname "$0")")

# Ensure that build.sh is not running in two instances
# trap handler will clean this up
global_lockfile=$(__realpath ./$binname.lock)
touch $global_lockfile

export binname
export root
export global_lockfile

__msg 'Running from root directory ' "$root"

# Define as a function to allow early returning
parse_args()
{
  while [[ $# -gt 0 ]]
  do
    arg="$1"
    case $arg in
      --make-jobs=*)
        make_jobs=${arg/--make-jobs=/}
        shift
        ;;
      --with-*)

        # If building all deps, just return
        needle=${arg/--with-/}
        if [[ "$needle" == "all" ]]; then all=1; return; fi

        # Otherwise, ensure dependency is valid
        haystack="${deps[*]}"
        __find
        if [[ "$found" != "1" ]]; then
          __msg Could not find package "$needle" from argument "$1" 
          __usage
        fi

        # If found, set corresponding variable so the dep is built
        builds[$needle]=1

        shift
        ;;
      --prefix=*)
        prefix=${arg/--prefix=/}
        shift
        ;;
      -h|--help)
        __usage
        ;;
      *)
        __msg Option not found!
        __usage
        ;;
    esac
  done
}

# We want default word-splitting behavior in bash, so disable these warnings
# shellcheck disable=SC2048 disable=SC2086
parse_args $*

builddir=$(__realpath ./build)
installdir=$(__realpath ${prefix:-./install})
make_jobs=${make_jobs:-8}
default_cmake_args="-DCMAKE_INSTALL_PREFIX=$installdir"

export builddir
export installdir
export make_jobs
export default_cmake_args

__msg Using build directory "$builddir"
__msg Using install directory "$installdir"

source shell/install_functions.sh

__msg Build configuration:
__msg
for bc in ${!builds[@]}
do
  __msg "$( printf "%-20s : %20s" $bc ${builds[$bc]} )"
done

__msg

for dep in ${deps[@]}
do
  if [[ ${builds['all']} == "1" ]] || [[ ${builds[$dep]} == "1" ]]
  then
    __msg Building $dep
    eval "install_$dep"
  fi
done

