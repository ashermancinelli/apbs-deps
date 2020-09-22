#!/bin/bash

# Use strict bash
set -o errexit
set -o nounset
set -o pipefail

# Dependencies to be built
declare -a deps=(FETK geoflow_c pb_solvers pybind11 TABIPB)

# Configure better error handling
binname=$(basename $0)

__msg()
{
  echo "($binname) -- $*"
}

__cleanup()
{
  if [[ "$1" != "0" ]]
  then
    __msg 'Got exit code: ' $*
  fi
}

trap __cleanup 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

__usage()
{
  cat <<EOD

  Usage: ./$binname --build [all|$(echo ${deps[@]} | tr ' ' '|')]

EOD
  exit 1
}

while [[ $# -gt 0 ]]
do
  case $1 in
    -h|--help)
      __usage
      ;;
    *)
      __msg Option not found!
      __usage
      ;;
  esac
done

# Replace with specific version if you need
python=$(which python)
if [[ -z "$python" ]]
then
  __msg Could not find python! Please ensure that python is in your PATH.
fi

__realpath()
{
  $python -c 'import os
import sys
for p in sys.argv[1:]:
  print(os.path.realpath(p))' $*
}

builddir=$(__realpath ./build)
installdir=$(__realpath ./install)

for dep in FETK geoflow_c pb_solvers pybind11 TABIPB
do
  __msg Building $dep
done

