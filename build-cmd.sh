#!/bin/sh

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

TOP="$(dirname "$0")"

OPENAL_VERSION="1.12.854"
OPENAL_SOURCE_DIR="openal-soft-$OPENAL_VERSION"

FREEALUT_VERSION="1.1.0"
FREEALUT_SOURCE_DIR="freealut-$FREEALUT_VERSION"

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
        build_sln "OpenAL.sln" "Debug|Win32" "OpenAL32"
        mkdir -p "$stage/lib"
        mv Debug "$stage/lib/debug"

        build_sln "OpenAL.sln" "Release|Win32" "OpenAL32"
        mv Release "$stage/lib/release"
        
        pushd "$TOP/$FREEALUT_SOURCE_DIR/admin/VisualStudioDotNET"
            build_sln "alut.sln" "Debug|Win32" "alut"
            build_sln "alut.sln" "Release|Win32" "alut"
            
            cp -a "alut/Debug/alut.dll" "$stage/lib/debug"
            cp -a "alut/Debug/alut.lib" "$stage/lib/debug"
            cp -a "alut/Release/alut.dll" "$stage/lib/release"            
            cp -a "alut/Release/alut.lib" "$stage/lib/release"            
        popd
    ;;
    "linux")
        make

        mkdir -p "$stage/lib/release"
        cp -P "$stage/libopenal.so" "$stage/lib/release"
        cp -P "$stage/libopenal.so.1" "$stage/lib/release"
        cp "$stage/libopenal.so.1.12.854" "$stage/lib/release"
    ;;
esac

cp -r "$TOP/$OPENAL_SOURCE_DIR/include" "$stage"
cp -r "$TOP/$FREEALUT_SOURCE_DIR/include" "$stage"

mkdir -p "$stage/LICENSES"
cp "$TOP/$OPENAL_SOURCE_DIR/COPYING" "$stage/LICENSES/openal.txt"

pass

