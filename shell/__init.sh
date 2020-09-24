#!/usr/bin/bash

__msg()
{
  echo "($binname) -- $*"
}

__warn()
{
  __msg [Warning]
  while read line; do
    __msg [Warning] $line
  done
  __msg [Warning]
}

__error()
{
  __msg [Error]
  while read line; do
    __msg [Error] $line
  done
  __msg [Error]
  exit 1
}

# Trap handler
# Prints exit code if not 0
__cleanup()
{
  rc=$?
  if [[ "$rc" != "0" ]]
  then
    __msg 'Got exit code: ' $rc
  fi
  __msg Removing lock $global_lockfile
  [ -f $global_lockfile ] && rm $global_lockfile
}

trap __cleanup 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

__usage()
{
  cat <<EOD

  Usage: ./$binname <options>

  Options:

    -h|--help 

        Print this help message.
      
    --with-<dependency name>

        Build and install dependency <dependency name>, 
        where <dependency name> is one of: [ all ${deps[*]} ].

    --prefix=<prefix>

        Installation prefix.

    --clean

        Removes all files from the previous builds.

    -P|--create-package

        Create a tarball of the install if everything builds successfully.

    --make-jobs=<integer>

        Number of make jobs to build with.

EOD
  exit "${1:-1}"
}

# Is element $needle in array $haystack?
# in: needle
# in: haystack
# out: found
__find()
{
  if [ ! -v needle ]; then
    __msg Error in function ${FUNCNAME[0]}: no 'needle' argument found!
    exit 1
  fi

  if [ ! -v haystack ]; then
    __msg Error in function ${FUNCNAME[0]}: no 'needle' argument found!
    exit 1
  fi

  for hay in ${haystack[@]}
  do
    if [[ "$needle" == "$hay" ]]
    then
      found=1
      export found
      return
    fi
  done
  found=0
  export found
  return
}

__init_python()
{
  # Replace with specific version if you need
  python=$(which python)
  if [[ -z "$python" ]]
  then
    echo '
    Could not find python!

    Please ensure that python is in your PATH before attempting to build.
    ' | __error
  fi
  export python

  # Ensure sufficient numpy installation can be found
  $python -c 'import numpy; import sys; sys.exit(0)'
  if [[ "$?" != "0" ]]; then
    echo '
    Numpy is not installed!

    Please install numpy before attempting to build.
    ' | __error
  fi
}

__init_python

__realpath()
{
  $python -c 'import os
import sys
for p in sys.argv[1:]:
  print(os.path.realpath(p))' "$*"
}

__find_numpy()
{
  __msg Searching for numpy include directories.
  local np_inc=$($python -c 'import numpy; print(numpy.get_include())')
  if [[ "${np_inc:-unset}" == "unset" ]]; then
    echo '
    Could not find numpy include directory!

    Please install numpy before attempting to build.
    ' | __error
  fi
  
  __msg Found numpy include at $np_inc
  np_inc=$(__realpath $np_inc)
  export C_INCLUDE_PATH=$np_inc
  export CPATH=$np_inc
  export NUMPY_INCLUDE_DIRECTORY=$np_inc
}

__find_numpy

__msg Ensuring git submodules are initialized
git submodule init
git submodule update
