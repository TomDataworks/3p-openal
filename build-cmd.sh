#!/bin/sh

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

TOP="$(dirname "$0")"

OPENAL_VERSION="1.12.854"
OPENAL_SOURCE_DIR="openal-soft-$OPENAL_VERSION"

if [ -z "$AUTOBUILD" ] ; then 
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# load autbuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

stage="$(pwd)"
case "$AUTOBUILD_PLATFORM" in
    "windows")
    ;;
    "darwin")
    ;;
    "linux")
    ;;
esac
mkdir -p "$stage/LICENSES"
cp "$TOP/$OPENAL_SOURCE_DIR/COPYING > "$stage/LICENSES/openal.txt"

pass

