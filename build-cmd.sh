#!/bin/bash

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

TOP="$(readlink -f $(dirname "$0"))"

OPENAL_VERSION="1.15.1"
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
        cmake "../$OPENAL_SOURCE_DIR" -G"Visual Studio 11" -DCMAKE_INSTALL_PREFIX=$stage
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
        mkdir -p openal
        pushd openal
            cmake ../../$OPENAL_SOURCE_DIR -DCMAKE_C_FLAGS="-m32" -DCMAKE_C_COMPILER=gcc-4.1
            make
        popd

        mkdir -p "$stage/lib/release"
        cp -P "$stage/openal/libopenal.so" "$stage/lib/release"
        cp -P "$stage/openal/libopenal.so.1" "$stage/lib/release"
        cp "$stage/openal/libopenal.so.1.12.854" "$stage/lib/release"

        mkdir -p freealut
        pushd freealut
            cmake ../../$FREEALUT_SOURCE_DIR -DCMAKE_C_FLAGS="-m32" -DCMAKE_C_COMPILER=gcc-4.1 \
                -DOPENAL_LIB_DIR="$stage/openal" -DOPENAL_INCLUDE_DIR="$TOP/$OPENAL_SOURCE_DIR/include"
            make
            cp -P libalut.so "$stage/lib/release"
            cp -P libalut.so.0 "$stage/lib/release"
            cp -P libalut.so.0.0.0 "$stage/lib/release"
        popd
    ;;
esac

cp -r "$TOP/$OPENAL_SOURCE_DIR/include" "$stage"
cp -r "$TOP/$FREEALUT_SOURCE_DIR/include" "$stage"

mkdir -p "$stage/LICENSES"
cp "$TOP/$OPENAL_SOURCE_DIR/COPYING" "$stage/LICENSES/openal.txt"

pass

