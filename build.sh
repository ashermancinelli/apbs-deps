#!/bin/bash

get_version()
{
  if [[ $(git show-ref | grep tags | wc -l) -gt 0 ]]; then
    # Get tag from git ref if it exists
    local tag=$(git show-ref | grep tags | head -n 1)
    local tag=${tag##*/}
  fi
  local hash=$(git rev-parse HEAD)
  export version=${tag:-$hash}
}
get_version

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
do_all=0
do_clean=0
do_package=0

binname=$(basename "$0")

source shell/__init.sh

# set root directory so we can use global paths later on
root=$(__realpath "$(dirname "$0")")

# Ensure that build.sh is not running in two instances
# trap handler will clean this up
global_lockfile=$(__realpath ./$binname.lock)
__msg Creating lockfile for $binname
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
      -P|--create-package)
        do_package=1
        shift
        ;;
      --clean)
        do_clean=1
        shift
        ;;
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
      -h|--help)
        __usage 0
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

packname="apbs-dependencies-$version"
[ -d $packname ] || mkdir $packname
installdir=$(__realpath ./$packname)
make_jobs=${make_jobs:-8}
default_cmake_args="-DCMAKE_INSTALL_PREFIX=$installdir"

export installdir
export make_jobs
export default_cmake_args

__msg Using install directory "$installdir"
for d in lib lib64 include share bin; do
  __msg Creating "$installdir/$d"
  mkdir -p "$installdir/$d"
done

source shell/install_functions.sh

__msg Build configuration:
__msg
__msg "$( printf "%-20s : %20s" Package Build? )"
for bc in ${!builds[@]}
do
  __msg "$( printf "%-20s : %20s" $bc ${builds[$bc]} )"
done
__msg "$( printf "%-20s : %20s" all $do_all )"
__msg "$( printf "%-20s : %20s" clean $do_clean )"
__msg "$( printf "%-20s : %20s" package $do_package )"
__msg "$( printf "%-20s : %20s" version $version )"

__msg
__msg Press any key to continue or CTRL-C CTRL-C to quit...
__msg
read

if [[ "$do_clean" = "1" ]]; then
  __msg Cleaning install directory...
  # Just remove the lockfiles... That should be enough. Users can manually 
  # remove the build directory if they really screw things up.
  find $installdir -name '*.lock' -exec rm {} \;
fi

if [[ ! -d $installdir ]]; then
  __msg Creating installation directory
  mkdir -p $installdir
fi

for dep in ${deps[@]}
do
  if [[ "$do_all" == "1" ]] || [[ ${builds[$dep]} == "1" ]]
  then
    __msg Building $dep
    eval "install_$dep"
  fi
done

if [[ "$do_package" == "1" ]]; then
  create_package
fi

generate_activate_script()
{
  local actscript=activate.sh
  __msg Generating activation script:
  pushd $installdir
  [ -f "$actscript" ] && rm "$actscript"
  cat >>"$actscript" <<EOD
# Save these values to deactivate later if need be
export __APBS_OLD_LD_LIBRARY_PATH=\$LD_LIBRARY_PATH
export __APBS_OLD_PATH=\$PATH

# Many of these variables may be wrong!
. ./fetk-env
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$(pwd)/lib:\$(pwd)/lib64
export PATH=\$PATH:\$(pwd)/bin
export pybind11_DIR=\$(pwd)/share/cmake/pybind11

deactivate()
{
export LD_LIBRARY_PATH=\$__APBS_OLD_LD_LIBRARY_PATH
export PATH=\$__APBS_OLD_PATH
}

EOD
  chmod +x "$actscript"
  popd

  echo "
  See $installdir for installation. 

  Run the following: 

  prompt> cd $installdir
  prompt> . $actscript

  to activate environment, and run 
  
  prompt> deactivate

  to deactivate the environment at any time.
  " | fold -w 80 | __block_msg "Installation Note"
}

generate_activate_script

__msg Done! Installation complete.
exit 0
