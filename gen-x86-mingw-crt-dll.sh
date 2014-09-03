#!/usr/bin/env bash

export LC_ALL=C
set -e

if [[ $(uname -s) != *NT* ]]; then
  if [ -z "$ARCH" ]; then
    MINGWHOST=i686-w64-mingw32
  elif [ $ARCH == "x64" ]; then
    MINGWHOST=x86_64-w64-mingw32
  fi
fi

if [ -z "$ARCH" ]; then
  ARCHFLAG="-m32"
elif [ $ARCH == "x64" ]; then
  ARCHFLAG="-m64"
else
  exit 1
fi

if [ -n "$MINGWHOST" ]; then
  MINGWHOST+="-"
fi

if [ -z "$SUFFIX" ]; then
  if [[ $MINGWHOST == x86_64-* ]]; then
    SUFFIX=-x64
  elif [[ $MINGWHOST == i*-* ]]; then
    SUFFIX=-x86
  fi
fi

NM=${MINGWHOST}nm
GCC="${MINGWHOST}gcc $ARCHFLAG"
STRIP=${MINGWHOST}strip

DLLNAME=mingw-crt${SUFFIX}.dll
IMPLIBNAME=mingw-crt${SUFFIX}.lib
DEFNAME=mingw-crt${SUFFIX}.def

LIBDIRS=$($GCC --print-search-dirs | grep libraries: | \
          awk '{print $2}' | tail -c +2)

function findfile
{
  local IFS=':'
  for dir in $LIBDIRS
  do
      if [ -e "$dir/$1" ]; then
        echo "$dir/$1"
        exit
      fi
  done
  exit 1
}

function findlibrary
{
  findfile "lib$1.a"
}

function findobject
{
  findfile "$1.o"
}

function addsymbol
{
  echo "$1" >> exports.def
}

function addsymbols
{
  $NM $(findlibrary $1) --demangle | grep " T " | awk '{print $3}' \
    >> exports.def
}

function addlibrary
{
  LIBS+="$(findlibrary $1) "
  addsymbols $1
}

function addsymbols2
{
  $NM $1 --demangle | grep " T " | awk '{print $3}' >> exports.def
}

function addsymbols3
{
  $NM $(findlibrary $1) --demangle | grep " T " | grep $2 | \
    awk '{print $3}' >> exports.def
}

echo "EXPORTS" > exports.def


### crt2.o ###
addsymbol _gnu_exception_handler


### libgcc ###
addsymbols2 $($GCC -print-libgcc-file-name)


### libgcc_s ###
addsymbols gcc_s


### mingwex ###
addsymbols3 mingwex mingw_
addsymbols3 mingwex __ms_
addsymbols3 mingwex getopt
addsymbols3 mingwex execv
addsymbol basename
addsymbol dirname
addsymbol sleep
addsymbol usleep
addsymbol strtok_r


### msvcrt ###
addsymbol _vsnwprintf
addsymbol _snprintf
addsymbol sprintf
addsymbol _stat
addsymbol _stati64
addsymbol _fstati64
addsymbol fseeko64
addsymbol ftello64
addsymbol _ftime
addsymbol _getch
addsymbol _strrev
addsymbol _strupr
addsymbol _strlwr
addsymbol _stricmp
addsymbol _toupper
addsymbol _tolower

# If you are using Visual C++ 2014, comment these:
addsymbol _fstat64
addsymbol _stat64
addsymbol _wfopen

# If you are using Visual C++ 2014, uncomment these:
# addsymbol __iob_func


### (win)pthread ###
addsymbols pthread


### dxguid ###
addlibrary dxguid


### ssp (stack protector) ###
addlibrary ssp

### quadmath ###
# addlibrary quadmath

# main for crt2.o, not exported
echo "int main(){return 0;}" | \
  $GCC -shared exports.def  $(findobject crt2) $LIBS \
  -static-libgcc -Wl,--enable-stdcall-fixup \
  -Wl,--out-implib,$IMPLIBNAME \
  -o $DLLNAME -xc -

$STRIP --strip-unneeded $DLLNAME $IMPLIBNAME
mv -f exports.def $DEFNAME
