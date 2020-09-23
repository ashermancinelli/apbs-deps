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

  echo '
  If you were installing FETK and something failed or you cancelled 
  the job, you may have to restore the original build script from the
  backup.
  
  You most likely just have to run:

  mv FETK/fetk-build.bk FETK/fetk-build

  from the root directory of this repo.' | __warn

}

trap __cleanup 0 SIGHUP SIGINT SIGQUIT SIGABRT SIGTERM

__usage()
{
  cat <<EOD

  Usage: ./$binname <options>

  Options:

    -h|--help 

        Print this help message
      
    --with-<dependency name>

        Build and install dependency <dependency name>, 
        where <dependency name> is one of: [ all ${deps[*]} ]

    --prefix=<prefix>

        Installation prefix

    --make-jobs=<integer>

        Number of make jobs to build with

EOD
  exit 1
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

# Replace with specific version if you need
python=$(which python)
if [[ -z "$python" ]]
then
  __msg Could not find python! Please ensure that python is in your PATH.
fi
export python

__realpath()
{
  $python -c 'import os
import sys
for p in sys.argv[1:]:
  print(os.path.realpath(p))' "$*"
}

__msg Ensuring git submodules are initialized
git submodule init
git submodule update
